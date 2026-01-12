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
NAME="${1:-World}"  # 如果 $1 为空，NAME="World"

# 字符串操作
FILE="image.png"
echo "${FILE%.*}"   # 输出 image (去后缀)
echo "${FILE#*.}"   # 输出 png (去前缀)

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
log() {
    echo "[$(date +%F_%T)] $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
       log "Error: Must be run as root" >&2
       exit 1
    fi
}

main() {
    check_root
    log "Starting update..."
    apt update && apt upgrade -y
}

main "$@"
```

---

# 任务 05: 批量处理脚本

编写一个脚本 `batch_rename.sh`：
1. 接受一个目录作为参数。
2. 将该目录下所有 `.txt` 文件重命名为 `.bak`。
3. **要求**: 
   - 必须使用 `set -euo pipefail`。
   - 必须检查参数是否存在。
   - 必须是幂等的（如果已经是 .bak 不应报错或重复添加）。
