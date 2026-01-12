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

- **可组合性**: 小工具通过管道 (`|`) 组合成大威力
- **自动化**: 所有命令都可写入脚本
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
  | awk '{print $1}' \    # 提取 IP
  | sort \                # 排序 (uniq 前必须排序)
  | uniq -c \             # 去重并计数
  | sort -nr \            # 按数字(n)倒序(r)排列
  | head -n 5             # 取前 5
```

---

# Topic 3: 寻求帮助

---

## 不要死记硬背

- **`man <command>`**: 查阅手册 (Manual)
  - `man ls`
  - 按 `q` 退出, `/` 搜索
- **`<command> --help`**: 快速简要帮助
- **tldr**: Too Long; Didn't Read (需安装)
  - `tldr tar` -> 只显示常用例子

---

# 任务 02: 日志取证

给定一份服务器日志：
1. 找出攻击者的 IP 地址
2. 统计攻击发生的具体时间段
3. 提取被尝试访问的文件路径
4. 输出一份 Markdown 格式的简报
