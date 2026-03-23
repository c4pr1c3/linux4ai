---
title: "第二单元: 系统运维与排障"
subtitle: "用户与权限管理"
author: 黄玮
date: 2026-01
output: revealjs::revealjs_presentation
---

# Topic 1: 用户身份标识

---

## 核心文件三剑客

- **/etc/passwd**: 用户账户信息 (公开可读)
  - `root:x:0:0:root:/root:/bin/bash`
  - 用户名 : 密码占位符 : UID : GID : 描述 : 家目录 : Shell
- **/etc/shadow**: 加密后的密码 (仅 root 可读)
  - 存放密码哈希、过期策略
- **/etc/group**: 组信息
  - `sudo:x:27:huangwei`
  - 组名 : 密码占位符 : GID : 组成员列表

---

## UID 与 GID

- **UID (User ID)**:
  - `0`: **root** (超级用户，至高无上)
  - `1-999`: **系统用户** (运行服务，如 www-data, mysql)
  - `1000+`: **普通用户** (我们创建的登录账号)
- **GID (Group ID)**:
  - 每个用户至少属于一个**主组** (Primary Group)
  - 可以属于多个**附加组** (Secondary Groups)

---

# Topic 2: 用户生命周期管理

---

## 创建用户 (useradd)

```bash
# 推荐: 使用 adduser (交互式，更友好)
sudo adduser newuser

# 传统方式 (useradd)
# -m: 创建家目录
# -s: 指定 shell
sudo useradd -m -s /bin/bash newuser

# 设置密码
sudo passwd newuser
```

---

## 修改用户 (usermod)

```bash
# 将用户加入 sudo 组 (授予管理员权限)
# -a: append (追加)
# -G: groups (附加组)
sudo usermod -aG sudo newuser

# 锁定账户 (禁止登录)
sudo usermod -L newuser

# 解锁账户
sudo usermod -U newuser
```

---

## 删除用户 (userdel)

```bash
# 删除用户，但保留家目录
sudo userdel newuser

# 删除用户及其家目录 (慎用!)
sudo userdel -r newuser
```

---

# Topic 3: Sudo 提权机制

---

## 为什么不直接用 root?

- **最小权限原则**: 平时用普通用户，仅在需要时提权
- **审计追踪**: `sudo` 会记录谁执行了什么命令
- **防止误操作**: 高危命令需谨慎；例如 GNU `rm` 默认会保护 `/`（`--preserve-root`）

---

## 配置 sudoers

- 配置文件: `/etc/sudoers`
- **严禁直接编辑!** 必须使用 `visudo` 命令 (会检查语法错误)

```bash
sudo visudo
```

```plaintext
# 允许 wheel 组免密执行所有命令
%wheel ALL=(ALL) NOPASSWD: ALL
```


