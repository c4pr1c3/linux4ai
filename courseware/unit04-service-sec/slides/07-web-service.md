---
title: "第四单元：服务交付与安全基线"
subtitle: "Nginx, 反向代理 & 日志"
author: 黄玮
date: 2026-01
output: revealjs::revealjs_presentation
---

# Topic 1: Web 服务架构

---

## 为什么需要反向代理 (Reverse Proxy)?

你写的 Python/Node.js 程序通常监听在 `localhost:8000`。
为什么不直接暴露给公网？

1.  **安全**: Nginx 更加健壮，能抗住慢连接攻击。
2.  **性能**: 处理静态文件、Gzip 压缩、缓存。
3.  **灵活**: 负载均衡、SSL 卸载、统一日志。

---

## Nginx 核心配置

`/etc/nginx/sites-available/default`:

```nginx
server {
    listen 80;
    server_name example.com;

    # 静态文件
    location /static/ {
        root /var/www/html;
    }

    # 反向代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

# Topic 2: 日志与观测

---

## Access Log 黄金指标

`tail -f /var/log/nginx/access.log`

```text
192.168.1.5 - - [12/Jan/2026:10:00:00 +0800] "GET /api/v1/users HTTP/1.1" 200 1024 "-" "Mozilla/5.0..."
```

关注点：
1. **$remote_addr**: 谁在访问？
2. **$status**: 200(OK), 404(Not Found), 500(Server Error)。
3. **$request_time**: 响应慢吗？(需自定义配置)

---

# 任务 07: 部署你的个人主页

1. **后端**: 用 Python 启动一个最简单的 HTTP 服务。
   `python3 -m http.server 8000`
2. **代理**: 配置 Nginx (或 Caddy) 反向代理到 8000 端口。
3. **验证**:
   - 访问 Nginx 端口，看到 Python 服务的内容。
   - 查看 Nginx 日志，确认请求被转发。
