# Lab 01: 环境构建与 CLI 初探

## 1. 实验目标

- **能力交付**:
  1. 能够独立配置现代 Linux 开发环境 (WSL 2 或 macOS Terminal)。
  2. 熟练掌握 SSH 密钥认证与配置文件管理，实现高效远程连接。
  3. 初步掌握 CLI 交互，完成基本的服务器状态巡检。

## 2. 环境准备

- **本地**: Windows 10/11 (推荐安装 WSL 2 Ubuntu 22.04) 或 macOS。
- **远程**: 课程共享服务器 (IP/端口/账号由教师分发)。

## 3. 任务清单

### 任务 A: 本地环境就绪

1. **安装终端**: 推荐 Windows Terminal 或 iTerm2。
2. **Shell 配置**: 确保本地 Shell 可用 (PowerShell 7+ 或 Zsh)。
3. **VS Code**: 安装 "Remote - SSH" 和 "WSL" 插件。

### 任务 B: SSH 密钥管理 (关键)

1. 在本地生成 Ed25519 密钥对：
   ```bash
   ssh-keygen -t ed25519 -C "your_student_id"
   ```
2. 配置 `~/.ssh/config` 文件，为共享服务器设置别名（如 `linux4ai`）：
   ```ssh
   Host linux4ai
       HostName <Server_IP>
       User <Your_Username>
       Port <Server_Port>
       IdentityFile ~/.ssh/id_ed25519
   ```
3. 将公钥上传至服务器（首次连接需密码）：
   ```bash
   ssh-copy-id linux4ai
   ```
   *注：如果无法使用 ssh-copy-id，请手动将 `id_ed25519.pub` 内容追加到服务器的 `~/.ssh/authorized_keys`。*

### 任务 C: 服务器巡检与录屏

1. 安装 [asciinema](https://asciinema.org/) (本地或服务器端均可)。
2. 开始录制：`asciinema rec lab01_check.cast`
3. 执行以下操作：
   - 登录服务器：`ssh linux4ai`
   - 查看当前用户：`id`
   - 查看当前路径：`pwd`
   - 查看系统负载：`uptime`
   - 查看谁在线：`w`
   - 退出服务器：`exit`
4. 结束录制 (Ctrl+D 或 exit)，并上传：`asciinema upload lab01_check.cast`

### 任务 D: 日志取证 (Log Forensics)

假设你截获了一份服务器访问日志 [access.log](assets/access.log) (点击下载或在仓库中查看)。

请使用 `grep`, `awk`, `sort`, `uniq` 等工具分析日志，回答以下问题：
1. **攻击者 IP**: 哪个 IP 地址发起了疑似攻击（SQL 注入、敏感文件扫描）？
2. **攻击时间**: 攻击行为集中在什么时间段？
3. **目标路径**: 攻击者尝试访问了哪些敏感路径？

**注意**: 你不需要编写复杂的脚本，只需在报告中记录你使用的命令和分析结论。

## 4. 提交要求

在你的 Git 仓库中创建 `lab01/report.md`，包含：

1. **环境截图**: 展示 VS Code 连接到 WSL 或 SSH 的状态栏截图。
2. **SSH Config**: 你的 `~/.ssh/config` 内容（**注意打码 IP 和敏感信息**）。
3. **巡检录屏**: asciinema 的分享链接 + 对应的 `.cast` 录屏转存文件（例如 `lab01/lab01_check.cast`，便于后续转为 text 进行智能批改）。
4. **日志取证**: 针对任务 D 的简报（包含分析命令和结论）。
5. **问题复盘**: 记录在配置过程中遇到的 1 个问题及解决方法。

## 5. 评分标准

| 维度 | 权重 | 评分点 |
| :--- | :--- | :--- |
| **SSH 配置** | 40% | 使用了密钥认证；配置了 config 别名；未使用默认端口直连。 |
| **CLI 操作** | 30% | 录屏中命令输入准确，无过多无效回退。 |
| **文档规范** | 30% | Markdown 格式规范，截图清晰，问题记录真实。 |
