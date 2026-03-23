# Lab 03: 自动化运维实战

## 1. 实验目标

- **能力交付**:
  1. 掌握编写“生产级”Shell 脚本的规范 (Error handling, Arguments)。
  2. 理解 Ansible 的 Inventory 和 Playbook 结构。
  3. 实现“配置即代码” (Configuration as Code)。

## 2. 任务清单

### 任务 A: 服务器体检脚本 (Shell)

编写脚本 `health_check.sh`，要求：

1. **头部规范**: 包含 `set -euo pipefail`。
2. **功能**:
   - 检查磁盘空间：如果根分区使用率超过 80%，输出警告。
   - 检查负载：输出最近 1 分钟的 Load Average。
   - 检查 SSH 服务：确认 sshd 进程是否存在。
3. **输出**: 结果以 JSON 格式输出到标准输出 (STDOUT)。
   ```json
   {
     "disk_usage": "45%",
     "load_avg": 0.12,
     "sshd_status": "active"
   }
   ```
4. **验证**: 在 WSL 和共享服务器上分别运行，确保兼容性。

### 任务 B: 个人环境自动化 (Ansible)

使用 Ansible 管理你在共享服务器上的个人配置 (Dotfiles)。

1. **准备**: 在本地创建一个目录 `my_config`，包含一个自定义的 `.bash_aliases` 文件（写几个常用的 alias）。
2. **Inventory**: 创建 `hosts.ini`，配置连接到共享服务器的信息。
3. **Playbook**: 编写 `deploy.yml`：
   - 使用 `file` 模块确保 `~/.config` 目录存在。
   - 使用 `copy` 模块将本地的 `.bash_aliases` 同步到服务器的 `~/.bash_aliases`。
   - 使用 `lineinfile` 模块确保 `~/.bashrc` 中包含 `source ~/.bash_aliases` (幂等性！)。
4. **执行**: 运行 `ansible-playbook -i hosts.ini deploy.yml`。
5. **验证**: 再次运行 Playbook，确保 `changed=0` (验证幂等性)。

## 3. 提交要求

提交 `lab03/report.md`：

1. **任务 A**: 脚本源代码链接 + 两次运行的截图（一次正常，一次模拟故障/不同环境）。
2. **任务 B**: `deploy.yml` 源码 + Ansible 执行结果截图（包含第一次执行和第二次幂等执行的对比）。
3. **操作录屏**: asciinema 录屏转存文件 `.cast`（建议命名 `lab03/lab03.cast`，便于后续转为 text 进行智能批改）。
4. **问题复盘**: 记录在配置过程中遇到的至少 1 个问题及解决方法。
