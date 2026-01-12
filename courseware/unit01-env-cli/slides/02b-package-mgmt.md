---
title: "第一单元: 环境构建与 CLI 生存指南"
subtitle: "软件包管理艺术与技术"
author: 黄玮
date: 2026-01
output: revealjs::revealjs_presentation
---

# Topic 1: 软件包管理哲学

---

## 为什么需要包管理器?

- **解决依赖地狱**: 自动处理库文件依赖 (`libssl`, `libc`...)
- **统一分发渠道**: 安全、签名、官方维护的仓库
- **版本控制**: 轻松升级、回滚、保持系统更新
- **对比 Windows**: 类似 App Store vs 也就是到处下载 `.exe`

---

## Ubuntu/Debian 包管理体系

- **dpkg**: 底层工具，处理 `.deb` 文件 (类似 `.rpm`)
- **apt (Advanced Package Tool)**: 上层前端，处理依赖、下载 (类似 `yum`/`dnf`)
- **Repository (软件源)**: 存放软件包的服务器

---

# Topic 2: APT 实战指南

---

## 核心命令 (Lifecycle)

```bash
# 1. 更新软件包列表 (从服务器获取最新索引)
sudo apt update

# 2. 搜索软件包
apt search nginx
apt show nginx

# 3. 安装软件包
sudo apt install nginx
sudo apt install vim git curl -y  # 批量安装

# 4. 升级所有已安装软件
sudo apt upgrade
```

---

## 清理与维护

```bash
# 移除软件 (保留配置文件)
sudo apt remove nginx

# 彻底移除 (删除配置文件)
sudo apt purge nginx

# 清理无用的依赖包 (推荐定期执行)
sudo apt autoremove

# 清理下载的缓存包 (.deb 文件)
sudo apt clean
```

---

# Topic 3: 镜像源配置

---

## `/etc/apt/sources.list`

```plaintext
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted
...
```

- **deb**: 二进制包仓库
- **deb-src**: 源代码包仓库
- **URL**: 镜像地址 (如阿里云、清华源)
- **Codename**: 发行版代号 (如 `jammy` 对应 22.04)
- **Component**: `main` (官方支持), `restricted` (专有驱动), `universe` (社区), `multiverse` (非自由)

---

## 换源 (加速下载)

1. **备份**: `cp /etc/apt/sources.list /etc/apt/sources.list.bak`
2. **替换**: 将 `archive.ubuntu.com` 替换为 `mirrors.tuna.tsinghua.edu.cn`
3. **更新**: `sudo apt update`

> 💡 提示: 很多云服务器(阿里云/腾讯云)默认已经配置了内网镜像源，速度最快，无需更改。

---

# Topic 4: DPKG 与离线安装

---

## 处理 `.deb` 文件

当软件不在官方源中 (如 Chrome, VS Code) 时：

```bash
# 1. 下载 .deb 文件
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

# 2. 使用 dpkg 安装
sudo dpkg -i google-chrome-stable_current_amd64.deb

# 3. 如果报错 "Dependency missing" (缺依赖)
sudo apt install -f  # Fix broken dependencies (自动下载缺少的依赖)
```

---

## 查询已安装文件

```bash
# 列出系统所有已安装包
dpkg -l 

# 查看某个包安装了哪些文件 (文件清单)
dpkg -L nginx

# 反查某个文件属于哪个包
dpkg -S /bin/ls
# 输出: coreutils: /bin/ls
```

---

# Topic 5: 源码编译安装 (The Hard Way)

---

## 经典三部曲

当官方源没有你需要的软件，或需要开启特殊功能时：

1.  **下载源码**: `wget http://example.com/app-1.0.tar.gz`
2.  **解压**: `tar -xzvf app-1.0.tar.gz`
3.  **配置 (Configure)**: `./configure --prefix=/usr/local/app`
    - 检查依赖、生成 Makefile
4.  **编译 (Make)**: `make` (多核加速: `make -j4`)
5.  **安装 (Install)**: `sudo make install`

---

## ⚠️ 为什么现代 Linux 不推荐这样做?

1.  **依赖地狱 (Dependency Hell)**: 缺什么库都要自己手动找、手动装。
2.  **难以卸载**: 没有 `make uninstall` 的话，文件散落在系统各处，无法通过 `apt remove` 清理。
3.  **无自动更新**: 安全漏洞无法通过 `apt upgrade` 修复，必须手动重新编译。
4.  **系统污染**: 容易覆盖系统关键库，导致系统不稳定。

> **最佳实践**: 优先用 `apt` -> 其次 `Docker` -> 再次 `Snap/Flatpak` -> 最后才考虑源码编译。

