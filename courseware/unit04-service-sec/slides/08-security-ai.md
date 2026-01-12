---
title: "Unit 04: 安全基线与 AI 辅助运维"
subtitle: "Security Baseline & AI-Assisted Ops"
author: 黄玮
date: 2026-01
output: revealjs::revealjs_presentation
---

# Topic 1: Linux 安全基线

---

## 最小权限原则 (Least Privilege)

> "只给予完成工作所需的最小权限。"

- **Root**: 尽量不用。使用 `sudo` 进行审计。
- **文件权限**: 配置文件不应为 `777`。
- **网络**: 仅开放必要的端口 (UFW / iptables)。

---

## SSH 加固清单

编辑 `/etc/ssh/sshd_config`:

1. **禁用 Root 登录**:
   `PermitRootLogin no`
2. **禁用密码认证** (强制密钥):
   `PasswordAuthentication no`
3. **修改默认端口** (可选，防扫描):
   `Port 2222`

---

# Topic 2: AI 辅助运维

---

## AI 是副驾驶，你是机长

LLM (ChatGPT/Claude) 非常擅长写脚本，但它们会犯错（幻觉）。

**风险案例**:
- 用户: "帮我删除旧日志"
- AI: `find / -name "*.log" -delete`
- **后果**: 删除了 `/usr` 下的系统日志甚至应用日志，导致系统崩溃。

---

## 安全的 AI 工作流

1. **Prompt**: 清晰描述需求，增加约束。
   - "写一个 Bash 脚本备份 /var/www，保留最近 7 天。**必须检查目录是否存在，操作前打印日志**。"
2. **Review**: 人工审计代码。
   - 检查高危命令: `rm`, `dd`, `mkfs`, `> /dev/sda`。
   - 检查逻辑漏洞: 变量是否为空？循环是否有边界？
3. **Test**: 在非生产环境 (WSL/VM) 验证。
4. **Run**: 记录执行结果。

---

# 任务 08: AI 脚本审计

1. 让 AI 生成一个 "自动清理磁盘空间" 的脚本。
2. **不要运行它！**
3. 撰写一份审计报告：
   - 它的逻辑是什么？
   - 哪里有潜在风险（误删）？
   - 如何改进它的安全性（增加 `dry-run` 模式）？
4. 修正脚本并提交安全版本。
