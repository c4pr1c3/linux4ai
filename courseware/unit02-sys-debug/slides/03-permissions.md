---
title: "Unit 02: 权限迷宫与文件系统"
subtitle: "Permissions, ACL & Filesystem Hierarchy"
author: 黄玮
date: 2026-01
output: revealjs::revealjs_presentation
---

# Topic 1: Linux 权限模型

---

## 一切皆文件，一切皆权限

在共享服务器上，“我是谁”决定了“我能做什么”。

```bash
$ ls -l
drwxr-xr-x 2 student01 student01 4096 Jan 12 10:00 my_project
-rw-r--r-- 1 student01 student01  123 Jan 12 10:01 README.md
```

- **Type**: `d` (目录), `-` (文件), `l` (链接)
- **UGO**: User (u), Group (g), Other (o)
- **Mode**: Read (r=4), Write (w=2), Execute (x=1)

---

## 目录的 rwx vs 文件的 rwx

| 权限 | 对文件的意义 | 对目录的意义 |
| :--- | :--- | :--- |
| **r (Read)** | 查看文件内容 | 列出目录内容 (`ls`) |
| **w (Write)** | 修改文件内容 | **增删目录下的文件** |
| **x (Exec)** | 运行脚本/程序 | **进入目录** (`cd`) |

> **思考**: 如果我对一个目录有 `w` 权限，但我对里面的文件没有 `w` 权限，我能删除这个文件吗？
> **答案**: 能！删除文件是对目录的修改操作。

---

## ACL: 超越 UGO 的细粒度控制

当各组无法满足需求时（例如：想给特定同学 student02 读权限，但不给其他人）：

```bash
# 查看 ACL
getfacl my_file

# 设置 ACL: 给 student02 读写权限
setfacl -m u:student02:rw my_file

# 移除 ACL
setfacl -x u:student02 my_file
```

---

# Topic 2: 进程与排障

---

## 进程观测

- **ps**: 静态快照
  - `ps aux | grep nginx`
- **top / htop**: 动态监控
  - 关注 Load Average, CPU%, MEM%
- **kill**: 发送信号
  - `kill -15 <PID>` (SIGTERM, 优雅退出)
  - `kill -9 <PID>` (SIGKILL, 强制查杀 - 慎用！)

---

## 网络排障四件套

在没有 root 权限的情况下：

1. **ping**: 连通性 (ICMP)
2. **curl -v**: 应用层测试 (HTTP/DNS)
3. **ss -ant**: 查看自己的连接 (Socket Statistics)
   - 代替 netstat
   - `ss -lnt`: 监听中的 TCP 端口
4. **nslookup / dig**: DNS 解析

---

# 任务 03: 权限逃脱

在 `/tmp/challenge` 目录下：
1. 创建一个只有你自己能写，别人只能读的目录。
2. 在其中创建一个文件，使用 ACL 授权给你的同桌（指定 UID）只读权限。
3. 尝试删除别人创建的设置了 Sticky Bit 目录下的文件，观察报错。
