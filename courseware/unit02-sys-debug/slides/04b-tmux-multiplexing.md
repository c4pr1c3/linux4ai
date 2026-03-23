---
title: "第二单元: 系统运维与排障"
subtitle: "tmux 终端复用与多环境对比"
author: 黄玮
date: 2026-01
output: revealjs::revealjs_presentation
---

# Topic 1: 为什么需要终端复用

---

## 终端工作的痛点

- **SSH 连接中断** = 工作丢失
- **多窗口切换** 效率低下
- **多环境对比** 需要反复切换
- **AI Coding Agent** 的最佳搭档

> 在服务器上同时运行多个任务时，tmux 是必备技能

---

# Topic 2: tmux 基础操作

---

## 会话与窗格

```bash
# 启动新会话
tmux new -s mysession

# 列出所有会话
tmux ls

# 接入已有会话
tmux attach -t mysession
```

---

## 基本快捷键 (Prefix: Ctrl+B)

| 快捷键 | 功能 |
| :--- | :--- |
| `Ctrl+B "` | 水平分割窗格 |
| `Ctrl+B %` | 垂直分割窗格 |
| `Ctrl+B ↑↓←→` | 切换窗格 |
| `Ctrl+B 0-9` | 切换到对应窗格 |
| `Ctrl+B :` | 进入命令模式 |

---

# Topic 3: 进阶技巧：同步窗格

---

## 多环境同时操作

```bash
# 进入 tmux 命令模式 (Ctrl+B :)
# 输入以下命令开启同步
set synchronized-panes

# 关闭同步
set synchronized-panes off
```

> **实用场景**: 同时在本机、WSL、远程服务器执行相同命令，观察差异

---

## 三环境对比演示

```bash
# 上方窗格: 本地环境
# 中间窗格: WSL 环境
# 下方窗格: 远程服务器

# 同步执行，观察输出差异
uname -a
id
ps aux
```

> 通过对比学习，理解 "权限隔离" 和 "环境差异"

---

# Topic 4: 鼠标与配置

---

## 启用鼠标支持

```bash
# 在 ~/.tmux.conf 中添加
set -g mouse on

# 配置后可通过鼠标:
# - 点击切换窗格
# - 拖拽调整窗格大小
# - 滚动查看历史输出
```

---

## 推荐配置片段

```bash
# 状态栏美化
set -g status-style bg=colour235,fg=colour136
set -g window-status-current-style fg=colour166,bg=default

# 窗格边框
set -g pane-border-style fg=colour238
set -g pane-active-border-style fg=colour166
```

---

# Topic 5: 与 AI 工具配合

---

## AI Coding Agent 的最佳实践

- 在多个 tmux 窗格中运行不同的 AI Agent
- 长时间运行的任务不担心 SSH 中断
- 通过 `tmux attach` 随时查看进度

> "在 AI 时代，tmux 是绝配、必学必会的工具"

