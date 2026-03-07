---
title: "第二单元: 系统运维与排障"
subtitle: "权限, 访问控制列表 & 文件系统结构"
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

## ACL (访问控制列表): 超越 UGO 的细粒度控制

> **ACL (Access Control List)**: 访问控制列表，提供比 UGO 更灵活的权限控制

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

## umask: 默认权限掩码

> 为什么新创建的文件权限通常是 644，目录是 755？

- **作用**: 决定新建文件/目录的默认权限
- **计算公式**: `Final_Mode = Base_Mode & ~umask`
  - **目录基准**: `777` (rwxrwxrwx)
  - **文件基准**: `666` (rw-rw-rw-, 文件默认不给 x)
- **典型值 (0022)**:
  - 目录: `777 & ~022 = 755` (rwxr-xr-x)
  - 文件: `666 & ~022 = 644` (rw-r--r--)
- **设置**: `umask 027` (更安全，屏蔽 Other 权限)

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
