# Lab 04: 服务交付与安全审计

## 1. 实验目标

- **能力交付**:
  1. 能够部署并配置 Nginx/Caddy 反向代理。
  2. 掌握 systemd 服务管理的基本操作（启动、自启、查看日志）。
  3. 能够为 Web 服务配置 HTTPS（自签名证书或自动 HTTPS）。
  4. 掌握使用 grep/awk/sort/uniq 管道分析日志的基本方法。
  5. 建立 AI 辅助代码生成的安全审计意识。

## 2. 实验环境说明

本实验支持两种环境，根据你的实际情况选择：

| 环境 | 反向代理 | HTTPS 方案 | systemd |
|------|---------|-----------|---------|
| **WSL / VirtualBox (有 root)** | Nginx | openssl 自签名 | 完整支持 |
| **共享服务器 (无 root)** | Caddy | Caddy 自动 HTTPS | 使用 `--user` 模式 |

> 两条路线都能完成实验。推荐：在 WSL/VirtualBox 中使用 Nginx 路线（完整体验）。

## 3. 任务清单

### 任务 A: Web 服务全闭环（建议用时：40 分钟）

#### A1: 后端准备

创建静态页面，用 Python 启动 HTTP 服务：

```bash
mkdir -p ~/www
echo "<h1>Hello Linux4AI - 学号: YOUR_ID</h1>" > ~/www/index.html
cd ~/www && python3 -m http.server 8080 &
curl http://localhost:8080    # 验证服务运行
```

#### A2: 配置反向代理

**路线 1 — Nginx（有 root 环境）**：

参考 `assets/nginx-reverse-proxy.conf`，创建配置：

```bash
# 复制模板到 Nginx 配置目录
sudo cp assets/nginx-reverse-proxy.conf /etc/nginx/sites-available/myweb
sudo ln -sf /etc/nginx/sites-available/myweb /etc/nginx/sites-enabled/myweb
sudo nginx -t                  # 检查语法
sudo systemctl reload nginx    # 重载配置
```

验证：`curl http://localhost:8000`

**路线 2 — Caddy（共享服务器 / 无 root）**：

```bash
# 下载 Caddy（参考课件中的链接）
# 启动反向代理
caddy reverse-proxy --from :8000 --to :8080 &
```

验证：`curl http://localhost:8000`

#### A3: 注册为 systemd 服务

参考 `assets/myweb.service.template`，编写你的 service 文件：

```bash
# 路线 1：系统级服务（有 root）
sudo cp assets/myweb.service.template /etc/systemd/system/myweb.service
# 编辑文件中的 用户名 和路径
sudo systemctl daemon-reload
sudo systemctl enable --now myweb
sudo systemctl status myweb

# 路线 2：用户级服务（无 root）
mkdir -p ~/.config/systemd/user/
cp assets/myweb.service.template ~/.config/systemd/user/myweb.service
# 编辑文件，去掉 User= 行，调整路径
systemctl --user daemon-reload
systemctl --user enable --now myweb
systemctl --user status myweb
```

**关键验证**：杀掉之前手动启动的 Python 进程，确认 systemd 管理的服务仍然运行：

```bash
kill %1                           # 杀掉之前的后台进程
curl http://localhost:8080         # 仍然能访问 = systemd 生效
```

#### A4: 添加 HTTPS

**路线 1 — Nginx + openssl 自签名**：

```bash
# 参考 assets/gen-selfsigned-cert.sh 生成证书
bash assets/gen-selfsigned-cert.sh
# 证书生成在 ~/certs/ 目录下

# 修改 Nginx 配置添加 SSL（参考课件中的 HTTPS 配置段）
# 在 server 块中添加：
#   listen 443 ssl;
#   ssl_certificate /home/你的用户名/certs/cert.pem;
#   ssl_certificate_key /home/你的用户名/certs/key.pem;

sudo nginx -t && sudo systemctl reload nginx
curl -k https://localhost          # -k 跳过自签名证书警告
```

**路线 2 — Caddy 自动 HTTPS**：

```bash
# 停止之前的 Caddy 进程
# 重新启动，监听 443
caddy reverse-proxy --from :443 --to :8080 &
curl -k https://localhost
```

验证：`curl -kv https://localhost 2>&1 | grep -i "subject\|issuer"` 查看证书信息。

---

### 任务 B: 谁在敲门？（日志分析）（建议用时：30 分钟）

#### B1: SSH auth.log 分析

1. 下载并查看脱敏的 SSH 日志样本：[auth.log](assets/auth.log)。
2. 使用 `grep` 和 `awk` 完成以下分析：

```bash
# 统计登录失败次数最多的前 5 个 IP
grep "Failed password" auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head -5

# 统计登录成功记录
grep "Accepted" auth.log | wc -l

# 找出尝试登录次数最多的用户名（含无效用户）
grep "Failed password" auth.log | awk '{
  if (/invalid user/) print $(NF-5)
  else print $(NF-5)
}' | sort | uniq -c | sort -rn | head -5
```

3. 记录你的统计命令和结果。

#### B2: Nginx access.log 分析

在任务 A 的服务运行一段时间后（或使用教师提供的样本日志），分析 Nginx/Caddy 的访问日志：

```bash
# 日志位置：
# Nginx: /var/log/nginx/access.log
# Caddy: 查看 Caddy 进程输出

# 1. 状态码分布 — 服务健康吗？
awk '{print $9}' access.log | sort | uniq -c | sort -rn

# 2. 访问量 Top 5 IP
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -5

# 3. 找出所有 404 请求（可能有人在扫描你的网站）
awk '$9 == 404 {print $7}' access.log | sort | uniq -c | sort -rn

# 4. 找出响应最慢的请求（假设日志中包含 $request_time）
awk '{print $NF, $7}' access.log | sort -rn | head -5
```

4. **观察与思考**：对比 SSH 暴力破解和 Web 扫描的攻击特征差异（1-2 句话），记录在报告中。

---

### 任务 C: AI 脚本审计挑战（建议用时：30 分钟）

#### C1: 生成脚本

使用任意 AI 工具（ChatGPT / Claude / DeepSeek / GitHub Copilot 等），输入以下 Prompt：

> "写一个 Bash 脚本，自动检测 CPU 使用率超过 80% 的进程并将其杀死。"

保存 AI 生成的原始脚本为 `lab04/kill-cpu-hog-raw.sh`。

#### C2: 安全审计

对照课件中的 **AI 危险案例**，审计该脚本：

1. 该脚本会杀死系统关键进程吗？（如 systemd、sshd）
2. 变量是否可能为空导致意外行为？
3. 是否存在命令注入风险？
4. 杀进程的方式是否安全？（`kill -9` vs `kill -15`）

将审计结论写入报告，至少识别 **2 类**安全风险。

#### C3: 修正脚本

对原始脚本进行修正，要求增加以下功能：

- **白名单**：不杀 root 进程、不杀 PID 1 (systemd)、不杀 sshd
- **dry-run 模式**：默认只打印将要执行的操作，不真正杀进程
- **使用方法**：`./kill-cpu-hog.sh` (dry-run) 或 `./kill-cpu-hog.sh --force` (真正执行)

保存修正后的脚本为 `lab04/kill-cpu-hog-fixed.sh`。

#### C4: 测试验证

在 WSL/VM 中运行修正后的脚本：

```bash
chmod +x lab04/kill-cpu-hog-fixed.sh

# dry-run 模式（安全，不杀进程）
./lab04/kill-cpu-hog-fixed.sh

# 确认 dry-run 输出合理后，可选执行 --force 模式
# ./lab04/kill-cpu-hog-fixed.sh --force
```

记录 dry-run 的输出结果。

---

## 4. 提交要求

提交 `lab04/` 目录，包含以下内容：

### report.md 结构模板

```markdown
# Lab 04 实验报告

**学号**：YOUR_ID
**姓名**：YOUR_NAME
**实验环境**：WSL / VirtualBox / 共享服务器（选择你的实际环境）

## 任务 A: Web 服务全闭环

### A2 反向代理配置
- 使用的方案：Nginx / Caddy
- 配置文件内容：（粘贴）
- `curl http://localhost:8000` 结果截图

### A3 systemd 服务
- myweb.service 文件内容：（粘贴）
- `systemctl status myweb` 输出
- 关掉终端后 curl 验证结果

### A4 HTTPS
- 使用的方案：openssl 自签名 / Caddy 自动 HTTPS
- `curl -k https://localhost` 结果截图
- 证书信息（subject/issuer）

## 任务 B: 日志分析

### B1 SSH auth.log
- 统计命令和 Top 5 IP 结果
- 被攻击最多的用户名

### B2 Nginx access.log
- 状态码分布结果
- 404 请求统计
- SSH 暴力破解 vs Web 扫描的特征差异观察

## 任务 C: AI 脚本审计

### C2 审计报告
- AI 工具：XXX
- 识别的安全风险（至少 2 类，引用课件中的危险模式）
- 原始脚本：见 kill-cpu-hog-raw.sh

### C3 修正说明
- 做了哪些修改及原因
- 修正后脚本：见 kill-cpu-hog-fixed.sh

### C4 测试结果
- dry-run 输出
- 是否测试了 --force 模式

## 问题复盘

记录在配置过程中遇到的至少 1 个问题及解决方法。
```

### 文件清单

```
lab04/
├── report.md                  # 实验报告
├── lab04.cast                 # asciinema 录屏（建议）
├── kill-cpu-hog-raw.sh        # AI 生成的原始脚本
└── kill-cpu-hog-fixed.sh      # 修正后的脚本
```

## 5. 评分标准

| 任务 | 分值 | 评分要点 |
|------|------|---------|
| A2 反向代理 | 15 分 | 配置正确，curl 验证通过 |
| A3 systemd | 15 分 | service 文件正确，服务可管理，关终端不中断 |
| A4 HTTPS | 10 分 | HTTPS 访问成功，证书信息正确 |
| B1 SSH 日志 | 15 分 | 命令正确，结果合理 |
| B2 Nginx 日志 | 10 分 | 分析命令正确，观察有思考 |
| C 审计报告 | 25 分 | 风险识别准确，修正合理，dry-run 正常 |
| 录屏 + 复盘 | 10 分 | 操作录屏完整，问题复盘有深度 |
| **合计** | **100 分** | |
