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
3.  **Registry (镜像仓库)**: 存储 Docker 镜像的地方（如 Docker Hub）。
    - 类比: GitHub（存储代码） vs Docker Hub（存储镜像）
    - 注意：与软件包管理中的"软件源"、Git 中的"代码仓库"不同

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
- 可以使用镜像加速器来加速拉取，但要明确其信任边界（避免把生产/敏感环境指向不可信源）。

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
docker exec -it my-nginx sh

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

---

# Topic 5: 调试、安全与实战进阶

---

## 容器排障三板斧

> 容器启动失败时，90% 的问题可以通过这三个命令定位。

```bash
# 1. 看日志 — 第一步永远是日志
docker logs -f my-app          # 实时跟踪
docker logs --tail 50 my-app  # 最近 50 行
docker logs my-app 2>&1 | grep -i error

# 2. 进容器 — 确认文件和进程状态
docker exec -it my-app sh      # 进入 Shell
docker exec my-app cat /etc/nginx/nginx.conf  # 查看配置

# 3. 看元数据 — 确认镜像、网络、挂载是否正确
docker inspect my-app --format '{{.State.ExitCode}}'
docker inspect my-app --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}'
```

**常见失败模式**:

| 现象 | 可能原因 | 排查方式 |
|:---|:---|:---|
| 容器立即退出 | CMD 执行失败 / 入口脚本有错 | `docker logs` 看退出前输出 |
| OOM Killed | 内存限制不足 | `docker inspect` 看 OOMKilled 字段 |
| 端口冲突 | 主机端口已被占用 | `ss -tlnp` 检查端口 |
| 权限不足 | 文件挂载权限问题 | 检查挂载目录的 UID/GID |

---

## Docker 安全基础

> AI Agent 可以帮你写 Dockerfile，但它无法帮你判断安全边界——这需要你自己理解。

```dockerfile
# ❌ 反面示例：以 root 运行 + 安装不必要的软件
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y curl vim git wget
COPY app.py .
CMD ["python3", "app.py"]  # 以 root 身份运行

# ✅ 正面示例：最小镜像 + 非 root 用户
FROM python:3.12-slim
RUN useradd -m appuser
WORKDIR /app
COPY --chown=appuser:appuser requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY --chown=appuser:appuser . .
USER appuser
CMD ["python", "app.py"]
```

**安全清单**:

- **最小基础镜像**: `slim`/`alpine` 优于完整版
- **不要以 root 运行**: `USER` 指令切换到非特权用户
- **不要信任未知镜像**: 只使用官方或可信源
- **`.dockerignore`**: 排除 `.git`/`.env`/`credentials.json`
- **不要在镜像中硬编码密钥**: 用环境变量或 secrets 机制

---

## Docker Compose 入门

> 真实项目几乎都是多容器：Web 应用 + 数据库 + 缓存。Compose 是定义和运行多容器应用的标配。

`docker-compose.yml`:
```yaml
services:
  web:
    build: .
    ports:
      - "5000:5000"
    environment:
      - REDIS_HOST=redis
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data

volumes:
  redis-data:
```

```bash
# 启动所有服务
docker compose up -d

# 查看服务状态
docker compose ps

# 查看所有服务日志
docker compose logs -f

# 停止并清理
docker compose down -v
```

---

## 容器与 AI 工作流

> Claude Code、GitHub Codespaces、Dev Containers 等工具都用容器作为隔离的运行环境。

**为什么 AI 工具偏爱容器**:

- **一致性**: Agent 在容器中执行命令，结果可复现
- **隔离性**: 避免污染宿主环境，`docker run --rm` 用完即弃
- **沙箱**: 限制 Agent 的文件系统和网络访问范围

**`docker run` 的高级参数**:

```bash
# 限制资源 — 防止失控
docker run --memory=512m --cpus=1 my-app

# 只读文件系统 — 防止意外写入
docker run --read-only my-app

# 临时容器 — 用完自动删除
docker run --rm my-app

# 环境变量注入 — 不暴露在镜像中
docker run -e API_KEY=$API_KEY my-app
```
