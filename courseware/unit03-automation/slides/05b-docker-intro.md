---
title: "第三单元：自动化运维与可复现"
subtitle: "Docker 容器技术入门"
author: 黄玮
date: 2026-01
output: revealjs::revealjs_presentation
---

# Topic 1: 容器化革命

---

## 为什么需要 Docker?

- **环境一致性**: "It works on my machine" -> "It works everywhere"
- **隔离性**: 进程级隔离，比虚拟机更轻量
- **微服务**: 独立部署、独立扩展
- **交付标准**: Image (镜像) 成为软件交付的新标准

---

## Docker vs 虚拟机 (VM)

| 特性 | 虚拟机 (VM) | 容器 (Container) |
| :--- | :--- | :--- |
| **隔离级别** | 硬件虚拟化 (Guest OS) | 操作系统级虚拟化 (共享 Kernel) |
| **启动速度** | 分钟级 | 秒级 |
| **占用空间** | GB 级 | MB 级 |
| **性能损耗** | 较高 | 接近原生 |

---

# Topic 2: Docker 核心概念

---

## 三大基石

1.  **Image (镜像)**: 只读模板，包含代码、运行时、库、环境变量等。
    - 类比: 软件安装包 / ISO 镜像
2.  **Container (容器)**: 镜像的运行实例，可读写。
    - 类比: 运行中的进程
3.  **Registry (仓库)**: 存储镜像的地方 (如 Docker Hub)。
    - 类比: GitHub / Maven Central

---

## 常用命令 (Lifecycle)

```bash
# 拉取镜像
docker pull nginx:latest

# 运行容器
# -d: 后台运行
# -p: 端口映射 (主机端口:容器端口)
# --name: 指定名称
docker run -d -p 8080:80 --name my-nginx nginx:latest

# 查看运行中的容器
docker ps

# 停止与删除
docker stop my-nginx
docker rm my-nginx
```

---

# Topic 3: 容器管理实战

---

## 使用镜像加速器

- 从 Docker Hub 拉取镜像时，可能会遇到网络问题。
- 可以使用镜像加速器 (如 DaoCloud) 来加速拉取。

---

### Docker国内镜像加速和状态监控

* **仅限教学环境使用，请勿用于商业用途或生产环境**
* [https://status.anye.xyz/](https://status.anye.xyz/)
* [https://mirror.kentxxq.com/image](https://mirror.kentxxq.com/image)

---

## 调试与交互

```bash
# 查看容器日志
docker logs -f my-nginx

# 进入容器内部 Shell
docker exec -it my-nginx bash

# 查看容器详细信息
docker inspect my-nginx
```

---

## Dockerfile: 构建镜像

`Dockerfile` 是构建镜像的蓝图。

```dockerfile
# 1. 基础镜像
FROM python:3.9-slim

# 2. 设置工作目录
WORKDIR /app

# 3. 复制依赖并安装
COPY requirements.txt .
RUN pip install -r requirements.txt

# 4. 复制代码
COPY . .

# 5. 启动命令
CMD ["python", "app.py"]
```

构建命令: `docker build -t my-app:v1 .`

---

# Topic 4: 数据持久化与网络

---

## Volume (数据卷)

容器销毁后，内部数据会丢失。使用 Volume 持久化数据。

```bash
# 挂载主机目录 (Bind Mount)
docker run -v /home/user/data:/data my-app

# 使用 Docker 管理的 Volume
docker volume create my-vol
docker run -v my-vol:/data my-app
```

---

## Network (网络)

- **bridge**: 默认网络，通过 NAT 访问外网
- **host**: 共享主机网络栈 (高性能，但端口易冲突)
- **none**: 无网络

```bash
# 创建自定义网络 (推荐，支持容器名 DNS 解析)
docker network create my-net
docker run --network my-net my-app
```
