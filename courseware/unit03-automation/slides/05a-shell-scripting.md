---
title: "第三单元：自动化与可复现"
subtitle: "脚本编程: 从单行脚本到生产级"
author: 黄玮
date: 2026-01
output: revealjs::revealjs_presentation
---

# Topic 1: 编写健壮的脚本

---

## 你的脚本安全吗？

大多数脚本死于：变量未定义、命令失败继续执行、管道中途断裂。

**黄金标准头**:
```bash
#!/bin/bash
set -euo pipefail
```

- `-e`: 遇到错误立即退出 (Exit on error)
- `-u`: 使用未定义变量报错 (Undefined variable)
- `-o pipefail`: 管道中任何一个命令失败，整个管道视为失败

---

## 变量的艺术

```bash
# 默认值
NAME="${1:-World}"  # 如果 $1 为空，则使用默认值 "World"

# 字符串操作
FILE="image.png"
echo "${FILE%.*}"   # 输出 image (去掉后缀)
echo "${FILE#*.}"   # 输出 png (去掉前缀)

# 只读变量
readonly VERSION="1.0.0"
```

---

## 幂等性 (Idempotency)

> "无论执行多少次，结果状态一致，且不产生副作用。"

**反例**:
```bash
mkdir mydir  # 第二次执行会报错 "File exists"
```

**正例**:
```bash
mkdir -p mydir  # 无论执行多少次都成功
```

**实战**: 追加配置前先检查
```bash
if ! grep -q "my_alias" ~/.bashrc; then
    echo "alias my_alias='ls -l'" >> ~/.bashrc
fi
```

---

# Topic 2: 自动化任务

---

## 函数与模块化

```bash
# 日志函数：记录带时间戳的日志
log() {
    echo "[$(date +%F_%T)] $1"
}

# 检查是否以 root 权限运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
       log "错误: 必须以 root 用户运行" >&2
       exit 1
    fi
}

# 主函数
main() {
    check_root
    log "开始更新系统..."
    apt update && apt upgrade -y
}

# 执行主函数，传入所有参数
main "$@"
```

---

# Topic 3: Shell 安全与防御性编程

---

## 命令注入：看不见的敌人

> 来自 Claude Code 的安全启示：一个 AI 编程助手花了数千行代码去防御 Shell 注入，说明这比你想象的更危险。

**最经典的漏洞 — 未引号包裹的变量**:

```bash
# ❌ 危险：文件名含空格时被拆分
FILE="my important.txt"
rm -rf $FILE        # → rm -rf my important.txt (删了两个东西)

# ❌ 危险：文件名含特殊字符时被解释为命令
FILE="test; rm -rf /"
cat $FILE            # → cat test; rm -rf / (执行了两个命令!)

# ✅ 安全：双引号包裹一切
rm -rf "$FILE"
cat "$FILE"
```

**经验法则**: 永远用双引号包裹变量展开，除非你明确需要 word splitting 或 glob 展开。

---

## 引号的精确语义

```bash
# 单引号：完全字面量，$ 和 \ 都是字面量
NAME="world"
echo 'Hello $NAME'    # → Hello $NAME

# 双引号：允许 $ 展开，\ 转义特定字符
echo "Hello $NAME"    # → Hello world
echo "tab:\there"    # → tab:\there (单字符 t)
echo 'tab:\there'    # → tab:\there (原样输出)

# ANSI-C 引用 $'...' ：解释转义序列
echo $'line1\nline2'  # → 两行输出
echo $'\tindented'    # → 制表符缩进

# Locale 引用 $"..." ：翻译字符串 (国际化)
```

> Claude Code 的安全引擎手工实现了引号状态跟踪器 — 因为理解引号语义是防御注入的第一步。

---

## eval 的危险与替代

```bash
# ❌ 危险：eval 执行任意代码
USER_INPUT="; rm -rf /"
eval "echo hello $USER_INPUT"  # → 执行了 echo hello ; rm -rf /

# ✅ 安全替代 1：使用数组
CMD=(ls -la "my dir")
"${CMD[@]}"

# ✅ 安全替代 2：使用函数
run_backup() {
    tar czf "$1" "$2"
}
run_backup "backup.tar.gz" "$TARGET_DIR"
```

**Claude Code 的做法**: 完全禁止 `eval`，转而使用结构化的命令解析器。在脚本中，能用函数和数组解决的问题，绝不碰 eval。

---

## 管道陷阱进阶

**`set -o pipefail` 解决了什么，没解决什么**:

```bash
set -euo pipefail

# ❌ pipefail 只影响退出码，不影响管道中的变量作用域
echo "hello" | read WORD
echo "$WORD"    # → 空！因为管道右侧在子 shell 中执行

# ✅ 解决方案：使用进程替代 (process substitution)
read WORD < <(echo "hello")
echo "$WORD"    # → hello

# ❌ 管道中每个段独立失败
false | true | false
echo $?    # → 1 (最后一段的退出码)

# Claude Code 的做法：逐段独立验证每个管道段的安全性
```

---

## 调试与信号处理

```bash
# set -x: 追踪每一行命令的执行
#!/bin/bash
set -x          # 开启调试
echo "step 1"
ls /nonexistent 2>/dev/null || true
echo "step 2"
set +x          # 关闭调试

# trap: 信号捕获与资源清理
#!/bin/bash
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT  # 脚本退出时自动清理

process_data() {
    head -100 "$1" > "$TMPFILE"
    # 即使脚本中途失败，TMPFILE 也会被清理
    grep "error" "$TMPFILE"
}

process_data "$1"
```

> `trap ... EXIT` 是「资源即用即释」的 Shell 实现，类似编程语言中的 `try/finally`。

---

# Topic 4: 生产级脚本进阶模式

---

## Heredoc 最佳实践

```bash
# ✅ 安全模式：单引号分隔符 = 无变量展开
cat <<'EOF'
This is literal text.
$HOME will not expand.
$(whoami) will not execute.
EOF

# ⚠️ 危险模式：无引号分隔符 = 变量和命令都会展开
cat <<EOF
Current user: $(whoami)  # ← 会执行!
Home: $HOME               # ← 会展开!
EOF

# 实战：用 heredoc 写多行配置文件
cat > /tmp/myconfig.conf <<'CONF'
[database]
host = 127.0.0.1
port = 5432
CONF
```

> Claude Code 的 heredoc 安全检查验证了三点：分隔符必须引号包裹、分隔符必须是独立行、不允许嵌套 heredoc 模式。

---

## 输入验证与参数处理

```bash
#!/bin/bash
set -euo pipefail

# 参数数量检查
if [[ $# -lt 1 ]]; then
    echo "用法: $0 <文件名> [输出目录]" >&2
    exit 1
fi

INPUT="$1"
OUTPUT="${2:-./output}"

# 输入验证：文件是否存在？
if [[ ! -f "$INPUT" ]]; then
    echo "错误: 文件 '$INPUT' 不存在" >&2
    exit 1
fi

# 输入验证：路径是否包含危险字符？
if [[ "$INPUT" == *../* ]]; then
    echo "错误: 路径遍历攻击已阻止" >&2
    exit 1
fi
```

> Claude Code 的启示：检查命令是否以 `-`、`&&`、`||`、`;` 开头 — 这些往往是命令拼接注入的信号。

---

## 脚本安全自查清单

> 真正的生产级脚本，不在于功能多强大，而在于有多难被 misuse。

- [ ] **`set -euo pipefail`** — 三件套缺一不可
- [ ] **变量引号包裹** — `$VAR` → `"$VAR"`，无例外
- [ ] **不用 `eval`** — 用函数、数组或 `declare -A` 代替
- [ ] **heredoc 分隔符带引号** — `<<'EOF'` 而非 `<<EOF`
- [ ] **`trap` 清理临时文件** — `trap 'rm -f $TMP' EXIT`
- [ ] **输入验证** — 检查参数数量、文件存在性、路径合法性
- [ ] **函数优先于内联** — 每个逻辑块封装为函数
- [ ] **幂等性** — `mkdir -p`、`grep -q` 模式
- [ ] **最小权限** — 只 `sudo` 真正需要的命令
- [ ] **日志输出** — `>&2` 分流错误信息，带时间戳

---

## 小结

| 层级 | 关键原则 |
|:---|:---|
| 基础 | `set -euo pipefail` + 幂等性 + 模块化 |
| 安全 | 引号包裹一切 + 不用 eval + 输入验证 |
| 调试 | `set -x` / `trap` + 结构化日志 |
| 进阶 | heredoc 安全 + 管道陷阱 + 信号处理 |

> 从单行命令到生产级脚本，核心不在于语法多熟练，而在于**防御性思维**——永远假设输入是恶意的，永远假设环境是不可控的。
