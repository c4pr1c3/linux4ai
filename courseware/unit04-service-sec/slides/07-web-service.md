---
title: "第四单元：服务交付与安全基线"
subtitle: "Web 服务、反向代理、HTTPS 与 systemd"
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

## 直接暴露 vs 反向代理

```
# 方案 A：直接暴露（不推荐）
用户浏览器 ──────────────────> Python 应用 (:8000)
                 公网直达

# 方案 B：反向代理（推荐）
用户浏览器 ────> Nginx (:80/:443) ────> Python 应用 (:8000)
                 公网入口          内网转发
```

反向代理 = 在用户和应用之间加一层「门卫」。

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

## Nginx 配置验证与重载

修改配置后，**不要**直接重启服务（会断开现有连接）：

```bash
# 检查语法（养成习惯：每次改配置都先检查）
sudo nginx -t

# 输出示例：
# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# nginx: configuration file /etc/nginx/nginx.conf test is successful

# 平滑重载配置（不断开连接）
sudo systemctl reload nginx
```

> **口诀**：改配置 → `nginx -t` → `reload`。永远不要跳过测试步骤。

---

## Caddy：无需 root 的替代方案

在共享服务器上你没有 root 权限，无法安装/配置 Nginx。
**Caddy** 可以在用户态运行，一行命令启动反向代理：

```bash
# 安装（无需 root，下载二进制即可）
# https://github.com/caddyserver/caddy/releases

# 一行命令：反向代理 :8000 → :8080
caddy reverse-proxy --from :8000 --to :8080

# 指定域名时自动申请 HTTPS 证书
caddy reverse-proxy --from myapp.example.com --to :8080
```

Caddy 的设计哲学：**默认安全，零配置 HTTPS**。

---

## Nginx vs Caddy 对比

| 特性 | Nginx | Caddy |
|------|-------|-------|
| 行业地位 | 事实标准，33%+ 市场份额 | 新兴选择，快速成长 |
| 配置复杂度 | 手动编写 conf 文件 | 极简命令行 / Caddyfile |
| 需要 root | 是（监听 80/443） | 否（可监听高端口） |
| HTTPS | 需手动配置证书 | 自动申请/续期 |
| 适合场景 | 生产环境、复杂需求 | 开发环境、共享服务器 |

> **策略**：生产用 Nginx，开发/共享服务器用 Caddy。两条路都掌握。

---

# Topic 2: 日志与观测

---

## Access Log 黄金指标

`tail -f /var/log/nginx/access.log`：

```text
192.168.1.5 - - [12/Jan/2026:10:00:00 +0800] "GET /api/v1/users HTTP/1.1" 200 1024 "-" "Mozilla/5.0..."
```

关注点：

1. **$remote_addr** — 谁在访问？
2. **$status** — 200(OK), 404(Not Found), 500(Server Error)。
3. **$request_time** — 响应慢吗？（需在 nginx.conf 中自定义 log_format）

自定义 log_format 添加 `$request_time`：

```nginx
log_format timed '$remote_addr - $remote_user [$time_local] '
                 '"$request" $status $body_bytes_sent '
                 '"$http_referer" "$http_user_agent" $request_time';
access_log /var/log/nginx/access.log timed;
```

---

## 日志分析实战

**场景**：老板说「网站好像有点慢」，你需要用数据说话。

```bash
# 1. 状态码分布 — 服务健康吗？
awk '{print $9}' access.log | sort | uniq -c | sort -rn
#   1523 200
#    234 404
#     12 500    ← 500 错误需要关注！

# 2. 响应最慢的 5 个请求（假设已配置 $request_time）
awk '{print $NF, $0}' access.log | sort -rn | head -5

# 3. 访问量 Top 10 IP
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -10

# 4. 实时监控 500 错误
tail -f access.log | awk '$9 == 500 {print $0}'
```

---

> **管道思维**：`awk 提取字段` → `sort 排序` → `uniq -c 计数` → `sort -rn 按数量排序`。这套组合拳适用于任何文本日志分析。

---

# Topic 3: HTTPS 与 TLS

---

## 为什么需要 HTTPS？

HTTP 是明文传输，任何人都可以截获你的数据：

```
# HTTP（明文）
客户端 ──── 用户名/密码明文 ────> 服务器
           ↗ 中间人可以窃听

# HTTPS（加密）
客户端 ──── 加密数据 ────> 服务器
           ↗ 中间人只能看到乱码
```

**TLS 握手**（简化版）：客户端和服务器协商密钥 → 之后所有数据加密传输。

> 2018 年起，Chrome 对所有 HTTP 站点标记「不安全」。HTTPS 已是**必选项**，不是可选项。

---

## 自签名证书（Nginx）

局域网/开发环境，没有公网域名？用自签名证书：

```bash
# 生成自签名证书（一行命令）
openssl req -x509 -newkey rsa:2048 \
  -keyout key.pem -out cert.pem \
  -days 365 -nodes \
  -subj "/CN=localhost"
```

---

Nginx 配置 HTTPS：

```nginx
server {
    listen 443 ssl;
    server_name localhost;

    ssl_certificate     /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://127.0.0.1:8080;
    }
}
```

---

验证：`curl -k https://localhost`（`-k` 跳过证书验证警告）

---

## 自动 HTTPS（Caddy）

Caddy 的 HTTPS 是**零配置**的：

```bash
# 有公网域名 → 自动申请 Let's Encrypt 证书
caddy reverse-proxy --from example.com --to :8080

# 局域网/localhost → 自动生成自签名证书
caddy reverse-proxy --from :443 --to :8080
```

---

| 场景 | Nginx | Caddy |
|------|-------|-------|
| 公网域名 | 手动配置 certbot + 证书 | 自动（Let's Encrypt） |
| 局域网/localhost | 手动 openssl + 配置 | 自动（自签名） |
| 证书续期 | 手动 crontab | 自动后台续期 |

> **实验时**：两条路都走一遍，体验「手动 vs 自动」的差异。

---

# Topic 4: systemd 服务管理

---

## 从临时进程到系统服务

`python3 -m http.server 8080 &` 的问题：

1. **关终端就停** — SIGHUP 信号杀死后台进程
2. **开机不自动启动** — 每次手动运行
3. **没有日志管理** — 输出丢失，难以排查
4. **没有重启策略** — 崩溃后无人拉起

**systemd** = Linux 的「服务管家」，解决以上所有问题。

---

## systemd 基础命令

```bash
# 服务生命周期管理
sudo systemctl start   myweb     # 启动
sudo systemctl stop    myweb     # 停止
sudo systemctl restart myweb     # 重启
sudo systemctl status  myweb     # 查看状态（最常用！）

# 开机自启动
sudo systemctl enable  myweb     # 开机自动启动
sudo systemctl disable myweb     # 取消自动启动

# 查看日志（神器）
sudo journalctl -u myweb              # 查看全部日志
sudo journalctl -u myweb -f           # 实时跟踪日志（类似 tail -f）
sudo journalctl -u myweb --since today # 今天的日志
```

> **记忆技巧**：`systemctl` = 「系统控制」，所有服务操作都走它。

---

## 编写你的第一个 .service 文件

创建 `/etc/systemd/system/myweb.service`：

```ini
[Unit]
Description=My Python Web Server
After=network.target

[Service]
Type=simple
User=你的用户名
WorkingDirectory=/home/你的用户名/www
ExecStart=/usr/bin/python3 -m http.server 8080
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

---

启用并启动：

```bash
sudo systemctl daemon-reload    # 通知 systemd 读取新配置
sudo systemctl enable myweb     # 开机自启
sudo systemctl start myweb      # 立即启动
sudo systemctl status myweb     # 确认运行状态
```

> **验证闭环**：关掉终端 → `curl http://localhost:8080` → 仍然可以访问 = 成功！

---

## 无 root？用户级 systemd（共享服务器）

没有 sudo 权限也能用 systemd，使用 `--user` 模式：

```bash
# 创建用户级服务目录
mkdir -p ~/.config/systemd/user/

# 放置 service 文件（去掉 User= 行，默认当前用户）
cp myweb.service ~/.config/systemd/user/

# 所有命令加 --user，无需 sudo
systemctl --user daemon-reload
systemctl --user enable --now myweb
systemctl --user status myweb
systemctl --user journalctl -u myweb   # 查看日志也不需要 sudo
```

---

| 特性 | 系统级 (`/etc/systemd/system/`) | 用户级 (`~/.config/systemd/user/`) |
|------|------|------|
| 需要 root | 是 | 否 |
| 用户登录时才运行 | 否（开机即运行） | 默认是（可配置 lingering） |
| 端口限制 | 无 | 只能绑定 >1024 端口 |

> **开启 lingering**（用户注销后服务继续运行）：`loginctl enable-linger 你的用户名`

---

## 小结：Web 服务交付完整链路

```
1. 编写应用  →  python3 -m http.server 8080
2. 反向代理  →  Nginx/Caddy 转发 :80 → :8080
3. 服务化    →  systemd 管理，开机自启，崩溃自动重启
4. 加密传输  →  HTTPS（自签名 / Let's Encrypt）
5. 观测日志  →  access.log + journalctl 排查问题
```

每一步都是生产环境的基本要求。你现在已经掌握了 Web 服务交付的完整链路。
