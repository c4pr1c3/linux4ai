# Lab 04: 服务交付与安全审计

## 1. 实验目标

- **能力交付**:
  1. 能够部署并配置 Nginx 反向代理。
  2. 掌握 SSH 服务加固的基本配置。
  3. 建立 AI 辅助代码生成的安全审计意识。

## 2. 任务清单

### 任务 A: Web 服务闭环

1. **后端准备**: 创建 `index.html` (写上你的学号)，用 Python 启动服务：
   ```bash
   mkdir -p ~/www && echo "<h1>Hello Linux4AI</h1>" > ~/www/index.html
   cd ~/www && python3 -m http.server 8080 &
   ```
2. **Nginx 配置**:
   - 在共享服务器上，你可能没有 root 权限修改 `/etc/nginx`。
   - **替代方案**: 下载 Nginx 二进制版或使用 Caddy (用户态运行)，或者仅在 WSL 完成此步骤。
   - 配置反向代理：访问 `http://localhost:8000` -> 转发到 `http://127.0.0.1:8080`。
3. **验证**: `curl -v http://localhost:8000`。

### 任务 B: 谁在敲门？(日志分析)

1. 下载并查看脱敏的 SSH 日志样本：[auth.log](assets/auth.log)。
2. 使用 `grep` 和 `awk` 统计最近 1000 条登录失败记录中，来源 IP 排名前 5 的地址。
   ```bash
   grep "Failed password" auth.log | ...
   ```
3. 提交统计命令和结果。

### 任务 C: AI 脚本审计挑战

1. **场景**: 你需要一个脚本来“自动杀死占用 CPU 超过 80% 的进程”。
2. **生成**: 使用 ChatGPT/DeepSeek 生成该脚本。
3. **审计**:
   - 分析该脚本的危险性（它会杀死系统关键进程吗？）。
   - 修改脚本，增加“白名单”功能（不杀 root 进程，不杀 systemd）。
   - 增加 `dry-run` 模式（只打印不杀）。
4. **提交**: 原始脚本 + 审计意见 + 修正后的脚本。

## 3. 提交要求

提交 `lab04/report.md`：
1. **任务 A**: `curl` 结果截图。
2. **任务 B**: 统计命令与 Top 5 IP 列表。
3. **任务 C**: 完整的 AI 审计报告 (Markdown)。
4. **操作录屏**: asciinema 录屏转存文件 `.cast`（建议命名 `lab04/lab04.cast`，便于后续转为 text 进行智能批改）。
