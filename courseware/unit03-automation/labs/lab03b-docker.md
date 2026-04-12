# Lab 03b: Docker 容器实战

## 实验目标

1.  掌握 Docker CLI 的基本操作 (pull, run, ps, stop, rm)
2.  学会编写 Dockerfile 构建自定义镜像
3.  理解端口映射与数据持久化

## 实验环境

- 预装 Docker Engine 的 Linux 环境 (WSL 2 或 虚拟机)
- 互联网连接 (用于拉取镜像)

## 任务 1: Hello Docker

1.  **检查版本**:
    ```bash
    docker --version
    ```
2.  **运行 Nginx**:
    ```bash
    docker run -d -p 8080:80 --name my-web nginx:alpine
    ```
3.  **验证**: 打开浏览器访问 `http://localhost:8080`，应看到 "Welcome to nginx!" 页面。
4.  **停止并清理**:
    ```bash
    docker stop my-web
    docker rm my-web
    ```

## 任务 2: 构建 Python Web 应用

1.  **准备代码**:

创建目录 `docker-lab`，并在其中创建 `app.py`:

```python
from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return f"Hello from Container! Hostname: {os.environ.get('HOSTNAME')}"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```
创建 `requirements.txt`:

```plaintext
flask
```

2.  **编写 Dockerfile**:
    在同一目录下创建 `Dockerfile`:

```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
COPY app.py .
CMD ["python", "app.py"]
```

3.  **构建镜像**:

```bash
docker build -t my-flask-app:v1 .
```

4.  **运行并验证**:

```bash
docker run -d -p 5000:5000 my-flask-app:v1
curl http://localhost:5000
```

## 任务 3: 数据持久化

1.  **创建挂载目录**:

```bash
mkdir -p ~/html
echo "<h1>Custom Home Page</h1>" > ~/html/index.html
```

2.  **挂载运行 Nginx**:

```bash
docker run -d -p 8081:80 -v ~/html:/usr/share/nginx/html nginx:alpine
```

3.  **验证**: 访问 `http://localhost:8081`，应看到 "Custom Home Page"。

## 任务 4: Docker Compose 多容器应用

1.  **创建项目目录**:

```bash
mkdir -p docker-compose-lab && cd docker-compose-lab
```

2.  **编写 `app.py`**:

```python
from flask import Flask
import redis
import os

app = Flask(__name__)
redis_client = redis.Redis(host='redis', port=6379)

@app.route('/')
def hello():
    count = redis_client.incr('visits')
    return f"Visit #{count} from container {os.environ.get('HOSTNAME', 'unknown')}"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

3.  **编写 `Dockerfile`**:

```dockerfile
FROM python:3.12-slim
WORKDIR /app
RUN pip install --no-cache-dir flask redis
COPY app.py .
CMD ["python", "app.py"]
```

4.  **编写 `docker-compose.yml`**:

```yaml
services:
  web:
    build: .
    ports:
      - "5000:5000"
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data

volumes:
  redis-data:
```

5.  **启动并验证**:

```bash
# 启动所有服务
docker compose up -d --build

# 查看服务状态
docker compose ps

# 多次访问，观察计数器递增
curl http://localhost:5000
curl http://localhost:5000

# 查看日志
docker compose logs web

# 清理（数据卷一并删除）
docker compose down -v
```

6.  **思考题**:
    - 为什么 `app.py` 中 `host='redis'` 而不是 `host='localhost'`？（提示：容器网络隔离）
    - 如果去掉 `redis-data` volume，重启后计数器还在吗？为什么？

## 提交物

提交 `lab03b/report.md`：

1. **任务 2**: `curl` 命令的输出结果截图。
2. **任务 3**: 浏览器访问 `http://localhost:8081` 的页面截图。
3. **操作录屏**: asciinema 录屏转存文件 `.cast`（建议命名 `lab03b/lab03b.cast`，便于后续转为 text 进行智能批改）。录屏应包含 Docker 镜像构建、容器运行和验证的全过程。
4. **问题复盘**: 记录在配置过程中遇到的至少 1 个问题及解决方法。
