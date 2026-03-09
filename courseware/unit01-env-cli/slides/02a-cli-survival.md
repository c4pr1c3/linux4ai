---
title: "第一单元: 环境构建与 CLI 生存指南"
subtitle: "命令行的艺术与技术"
author: 黄玮
date: 2026-01
output: revealjs::revealjs_presentation
---

# Topic 1: CLI 哲学

---

## 为什么还要用命令行?

- **AI 时代的一等公民**: 
  - **可组合性**: 它是 AI Agent (如 Open Interpreter) 的原生接口
  - **确定性**: 相比自然语言的概率模型，CLI 提供精确的执行边界
- **自动化**: 所有命令都可写入脚本，构建 Agent 工作流
- **远程友好**: 低带宽，无 GUI 依赖
- **精确**: 图形界面隐藏细节，命令行暴露真相

---

## 核心概念

- **Shell**: 命令解释器 (Bash, Zsh)
- **STDIN/STDOUT/STDERR**: 标准输入(0)、输出(1)、错误(2)
- **管道 (`|`)**: 前一个命令的输出 = 后一个命令的输入
  - `cat access.log | grep "404"`
- **重定向**:
  - `>`: 覆盖写入
  - `>>`: 追加写入
  - `2>`: 错误重定向

---

## 环境感知: 我是谁? 我在哪?

> REPL (Read-Eval-Print Loop): 交互式环境不仅是执行命令，更是感知状态

- **我是谁**: `id` (UID/GID), `whoami`
- **我在哪**: `pwd`, `hostname`, `cat /etc/os-release`
- **环境负载**: `w`, `uptime` (Load Average)
- **解释器**: `echo $SHELL` (Bash vs Zsh 差异)

---

# Topic 2: 文本处理实战

---

## grep: 过滤行

> Global Regular Expression Print

```bash
grep "error" app.log            # 查找包含 error 的行
grep -i "error" app.log         # 忽略大小写
grep -v "debug" app.log         # 反向选择（不包含 debug）
grep -r "TODO" ./src            # 递归查找目录
```

---

## awk: 处理列

> 强大的文本分析工具，默认按空格/Tab 分割

```bash
# 打印第 1 列和第 9 列 (如 Apache 日志的 IP 和 状态码)
awk '{print $1, $9}' access.log

# 统计特定列的总和
ls -l | awk '{sum += $5} END {print sum}'
```

---

## sort & uniq: 统计

```bash
# 统计访问量最高的 Top 5 IP
cat access.log \
  | awk '{print $1}' \
  | sort \
  | uniq -c \
  | sort -nr \
  | head -n 5
```

---

# Topic 3: 文件高阶生存术

---

## find: 精确打击

> 在文件系统中根据条件搜索文件

```bash
find . -name "*.py"             # 按文件名查找
find . -type f -size +100M      # 查找大于 100M 的文件
find /var/log -mtime +7         # 查找 7 天前修改过的文件
find . -name "*.tmp" -delete    # 找到并删除 (慎用!)
```

---

## 管道进阶: xargs

> 很多命令不支持从标准输入读取参数，xargs 来救场

```bash
# 错误: rm 不接受标准输入
find . -name "*.tmp" | rm       

# 正确: xargs 将输入转换为参数列表
find . -name "*.tmp" | xargs rm
```

---

## 压缩与解压缩

- **tar**: Linux 标准归档工具
  - `c`: Create (创建) / `x`: Extract (解压)
  - `z`: Gzip (压缩) / `v`: Verbose (详细) / `f`: File (文件)

```bash
tar -czvf project.tar.gz ./src  # 打包压缩
tar -xzvf project.tar.gz        # 解压到当前目录
unzip material.zip              # 解压 zip 文件
```

---

## 字符编码: 拒绝乱码

- **问题**: Windows (GBK) vs Linux/Web (UTF-8)
- **file**: 查看文件类型和编码
- **iconv**: 转换编码

```bash
file -i data.csv                # 查看编码
# output: charset=iso-8859-1

iconv -f GBK -t UTF-8 old.txt > new.txt
```

---

## 字节视角: 还原真相

> **Don't trust your eyes, trust the bytes.**
> 文本文件在二进制层面可能大相径庭 (如 CRLF vs LF)

- **xxd**: 十六进制查看器 ("显微镜"模式)
  - `xxd filename`: 查看文件的十六进制表示
  - `xxd -r`: 逆向还原
- **场景**: 排查 Windows 编辑的文件在 Linux 下的隐形字符问题

---

## 校验: 数字指纹

> 验证文件完整性，确保未被篡改或损坏

```bash
# 生成指纹
md5sum release.iso > release.md5
sha256sum sensitive.data

# 验证 (检查 release.md5 中的指纹是否匹配)
md5sum -c release.md5
```

---

# Topic 4: 极简 Vim 入门

---

## 为什么要学 Vim?

> "I can't exit Vim" 是 StackOverflow 上的经典问题

- **普遍性**: 几乎所有 Linux 系统都预装
- **极端场景**: 
  - 物理机房维护 (没有 VS Code Remote)
  - 网络故障排查 (SSH 连接不稳定)
  - 救援模式 (只有最基础的 Shell)
- **效率**: 手不离键盘的极速编辑

---

## 核心概念: 模式 (Modes)

Vim 是**模态**编辑器，不同模式下按键含义不同：

1. **Normal Mode (普通模式)**: 默认模式，用于移动光标、删除、复制
   - 按 `Esc` 永远回到这里
2. **Insert Mode (插入模式)**: 像记事本一样打字
   - 按 `i` 进入
3. **Command Mode (命令模式)**: 保存、退出、搜索
   - 按 `:` 进入

---

## 生存指令: 记住这几个就够了

1. **进入编辑**: `vim filename`
2. **开始打字**: 按 `i` (Insert)
3. **停止打字**: 按 `Esc` (回到 Normal)
4. **保存退出**: 输入 `:wq` (Write & Quit) + `Enter`
5. **强制退出 (不保存)**: 输入 `:q!` + `Enter`

> 💡 进阶: 在终端输入 `vimtutor` 开启 30 分钟互动教程

---

# Topic 5: 寻求帮助

---

## 不要死记硬背

- **`man <command>`**: 查阅手册 (Manual)
  - `man ls`
  - 按 `q` 退出, `/` 搜索
- **`<command> --help`**: 快速简要帮助
- **tldr**: Too Long; Didn't Read (需安装)
  - `tldr tar` -> 只显示常用例子

---

## man pages 阅读技巧

### man 文档结构

```
NAME        # 命令名称和简短描述
SYNOPSIS    # 命令语法
DESCRIPTION # 详细描述
OPTIONS     # 选项说明
EXAMPLES    # 使用示例
FILES       # 相关文件
SEE ALSO    # 相关命令
BUGS        # 已知问题
```

---

## 高效阅读技巧

**1. 先看 NAME 和 SYNOPSIS**

快速了解命令用途，理解基本语法

**2. 再看 EXAMPLES**

通过示例理解用法，复制示例到命令行测试

**3. 遇到问题看 OPTIONS**

按需查找选项说明，不需要记住所有选项

**4. 最后看 DESCRIPTION**

需要时深入理解细节

---

## man 的分类

Linux 文档分为多个章节（section）：

```bash
man 1 ls        # 用户命令
man 2 open      # 系统调用
man 3 printf    # 库函数
man 5 crontab   # 配置文件格式
man 8 iptables  # 管理员命令
```

**默认**：显示第一个匹配的章节

**指定章节**：`man 5 crontab`（查看配置文件格式，而非 crontab 命令）

---

## 查找相关文档

```bash
# 搜索包含关键词的所有 man 页
man -k "copy"       # 等同于 apropos "copy"

# 搜索命令的特定章节
man -f crontab      # 等同于 whatis crontab
```

---

## 现场演示：阅读陌生工具的文档

### 案例：`strace` 工具

**第一步：快速了解**

```bash
$ man strace

# NAME 段落
strace - trace system calls and signals

# 快速了解：这是一个追踪系统调用的工具
```

---

## 第二步：查看示例

在 man 页内输入 `/EXAMPLES` 跳转到示例部分

---

## 第三步：理解常用选项

```
-p PID     # 追踪指定进程
-f         # 追踪子进程
-T         # 显示时间戳
```

---

## 第四步：实际测试

```bash
# 复制示例命令测试
strace ls

# 追踪指定进程
strace -p $PID
```

---

## 其他文档资源

```bash
# info pages（更详细的文档）
info coreutils
info libc

# 软件包文档目录
ls /usr/share/doc/
ls /usr/share/doc/*/examples/

# 配置文件模板
ls /etc/*.default/
```
