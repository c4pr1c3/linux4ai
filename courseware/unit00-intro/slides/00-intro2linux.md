---
title: "第零单元: Linux 概论"
subtitle: "为什么 AI 时代需要 Linux？"
author: 黄玮
date: 2026-02
output: revealjs::revealjs_presentation
---

# Topic 1: 为什么 AI 时代需要 Linux?

---

## 核心问题

> "AI 已经发展到动动嘴就可以写代码、操作系统和软件了，为什么还需要学习 Linux？"

---

## AI 是副驾驶，你是机长

**AI (Co-pilot) vs Human (Captain)**

- **AI 的幻觉**: AI 是概率模型，可能生成 `rm -rf /` 这样看似合理但危险的命令。
- **确定性基石**: Linux 是确定性系统。你需要具备**审计**能力，才能安全驾驶。
- **案例**: AI 建议的防火墙规则可能是错误的（如直接阻断 SSH 22 端口导致失联），只有懂网络栈的人才能发现并修正。

---

## Linux: AI 的基础设施

**AI Training & Inference**

- **训练与推理**: PyTorch, TensorFlow, CUDA 均原生运行在 Linux。
- **物理层**: 不懂 Linux，无法优化 GPU，无法排查驱动问题，无法部署集群。
- **排障 (Debugging)**: 当系统崩溃时，AI 难以获取完整上下文，你需要 `strace`, `tcpdump` 等工具进行兜底。

---

## 网络安全战场

**Attack & Defense**

- **攻防工具**: Metasploit, Kali, C2, WAF, SIEM 均基于 Linux。
- **漏洞挖掘**: 缓冲区溢出、提权、容器逃逸，深度依赖内存管理与内核机制。
- **代码审计**: 必须有能力审计 AI 生成的脚本，防止供应链投毒。

---

# Topic 2: Linux 简史与哲学

---

## 什么是 Linux?

> "Linux is a clone of the operating system Unix, written from scratch by Linus Torvalds with assistance from a loosely-knit team of hackers across the Net."

- **Kernel (内核)**: 硬件与软件的桥梁 (CPU, Memory, Devices)。
- **OS (操作系统)**: Kernel + GNU Tools + Shell + Desktop。

---

## 极简历史

1.  **Unix (1969)**: 贝尔实验室 (Ken Thompson, Dennis Ritchie)，商业化，昂贵。
2.  **GNU (1983)**: Richard Stallman, "GNU's Not Unix", 自由软件运动 (GPL)。
3.  **Linux (1991)**: Linus Torvalds, 个人爱好项目，开放源代码。
4.  **Open Source Explosion**: Linux Kernel + GNU Tools = 完整的自由操作系统。

---

## Linux 哲学

1. - **Everything is a file**: 硬盘、键盘、屏幕、网络连接，都是文件。(注意路径分隔符：Linux 使用正斜杠 `/`，Windows 使用反斜杠 `\`)
2.  **Keep It Simple and Stupid (KISS)**: 每个工具只做一件事，并把它做好 (ls, grep, awk)。
3.  **Pipe (管道)**: 组合简单工具完成复杂任务 (`|`)。

---

# Topic 3: 发行版与环境选择

---

## 发行版 (Distributions)

> Kernel 只有一个，发行版有成千上万。

- **Debian 系**: Ubuntu, Kali. 使用 `apt` / `.deb`. (稳定，社区庞大)
- **RedHat 系**: RHEL, CentOS, Fedora. 使用 `dnf` / `.rpm`. (企业级，严谨)
- **Arch 系**: Arch, Manjaro. 使用 `pacman`. (滚动更新，极客)

---

## 为什么选择 Ubuntu?

1.  **AI 首选**: NVIDIA 驱动、深度学习框架通常最先支持 Ubuntu。
2.  **WSL 默认**: Windows Subsystem for Linux 默认发行版。
3.  **社区支持**: 遇到问题最容易搜到答案 (StackOverflow)。

---

## 为什么选择 LTS?

**Long Term Support (长期支持版)**

- **稳定性**: 经过严格测试，不会轻易引入破坏性变更。
- **支持周期**: 通常 5 年安全更新 (非 LTS 只有 9 个月)。
- **生产环境标准**: 服务器、企业应用首选。
- **本课程选择**: Ubuntu 22.04/24.04 LTS。

---

# Topic 4: 迈入命令行

---

## AI 巨舰的隐形引擎

- **无处不在**: 电影流媒体、GitHub、AI 模型训练，背后都是 Linux 服务器。
- **隐形脊梁**: 它是互联网和现代计算的隐形引擎。

---

## 容器、Linux 与 AI

- **Namespace & Cgroups**: Linux 内核特性。
- **Sealed Glass Box**: 互不干扰，但共享内核 (Kernel) 和硬件(Hardware)。
- **Docker**: 就是在这个机制上构建的标准化交付工具。(Podman 是无守护进程的更安全替代品，但 Docker 依然是事实标准)

---

## CLI vs GUI

- **GUI (图形界面)**: 直观，但难以自动化。
- **CLI (命令行)**:
    - **精确**: 消除歧义。
    - **可复现**: 脚本可以运行千次。
    - **可组合**: 管道连接一切。
    - **AI 友好**: LLM 生成命令比生成鼠标点击容易得多。

---

## TUI (Text User Interface)

- **CLI 的用户体验进化**: 一些工具提供 TUI，如 `htop`, `nvtop`, `tmux`, `claude code`.
    - `htop` 显示系统资源
    -`nvtop` 监控 GPU
    - `tmux` 终端会话管理
    - `claude code` 代码智能体 (底层驱动多为 Bash 脚本与标准 Linux 工具)



