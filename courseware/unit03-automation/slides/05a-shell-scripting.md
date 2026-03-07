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
