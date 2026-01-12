---
title: "第一单元: 环境构建与 CLI 生存指南"
subtitle: "WSL, SSH & 远程开发"
author: 黄玮
date: 2026-01
output: revealjs::revealjs_presentation
---

# Topic 1: 现代 Linux 开发环境

---

## 为什么是 Linux?

- **服务器事实标准**: 全球 96.3% 的 Top 1M 服务器运行 Linux
- **云原生基石**: Docker, Kubernetes, DevOps 工具链
- **AI 基础设施**: PyTorch, TensorFlow, CUDA 训练环境

---

## Linux 内核 vs 发行版

- **Kernel (内核)**: 操作系统的心脏 (由 Linus Torvalds 创立并维护主线版本，同时有全球成千上万的社区开发者、公司（如Red Hat、IBM、SUSE）参与贡献代码和维护特定发行版的分支
  - 负责硬件驱动、内存管理、进程调度
  - 查看版本: `uname -r`
- **Distribution (发行版)**: 内核 + GNU 工具 + 包管理器 + 桌面环境
  - **Debian 系**: Ubuntu, Kali (使用 `apt`, `.deb`)
  - **RedHat 系**: RHEL, CentOS, Fedora (使用 `dnf`/`yum`, `.rpm`)
  - **Arch 系**: Arch Linux, Manjaro (使用 `pacman`)
  - 查看版本: `cat /etc/os-release`

---

## 课程环境策略

| 环境 | 角色 | 典型用途 | 权限 |
| :--- | :--- | :--- | :--- |
| **WSL 2 (Ubuntu 22.04)** | **本地主战场** | 编码、测试、Docker 容器 | Root (sudo) |
| **共享服务器** | **远程演练场** | 模拟生产环境、长时任务、审计 | 普通用户 |
| **VirtualBox** | **兜底方案** | 兼容性测试、网络隔离实验 | Root |

---

## WSL 2: Windows Subsystem for Linux

> "在 Windows 上原生运行 Linux 二进制文件"

- **架构**: 轻量级虚拟机，深度集成 Windows 文件系统与网络
- **安装**: `wsl --install` (管理员 PowerShell)
- **优势**: 
  - 秒级启动
  - 与 VS Code 无缝集成
  - 直接调用 Windows 进程 (如 `explorer.exe .`)

---

# Topic 2: SSH 远程连接艺术

---

## SSH (Secure Shell)

> 远程登录的安全标准

- **加密**: 所有传输数据（包括密码）均加密
- **认证**: 密码认证 vs **密钥认证** (推荐)
- **端口**: 默认 22

---

## 密钥认证原理

1. **生成密钥对**: `ssh-keygen -t ed25519 -C "your_email"`
   - 私钥 (`id_ed25519`): **绝对保密**，留在本地
   - 公钥 (`id_ed25519.pub`): **公开**，放到服务器
2. **分发公钥**: `ssh-copy-id user@host`
3. **连接**: 服务器用公钥加密挑战，客户端用私钥解密验证

---

## 高效 SSH 配置 (`~/.ssh/config`)

别再每次输入 `ssh user@192.168.1.100 -p 2222` 了！

```ssh
# ~/.ssh/config

Host lab-server
    HostName 192.168.1.100
    User student_01
    Port 2222
    IdentityFile ~/.ssh/id_ed25519

Host github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
```

使用: `ssh lab-server`

---

## 端口转发 (Port Forwarding)

让内网服务“暴露”给本地。

- **本地转发 (-L)**: 访问本地端口 -> 远程服务器访问目标
  - `ssh -L 8080:localhost:80 lab-server`
  - 场景: 访问服务器上只监听 127.0.0.1 的 Web 服务
- **远程转发 (-R)**: 远程访问端口 -> 本地服务
  - 场景: 让外网服务器访问你本地调试的 API

---

# 任务 01: 环境自检

1. 确认 WSL 2 安装就绪
2. 配置 VS Code + Remote SSH/WSL 插件
3. 生成 SSH 密钥并配置 `config`
4. 成功免密登录共享服务器
