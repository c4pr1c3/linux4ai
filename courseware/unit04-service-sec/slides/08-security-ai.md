---
title: "第四单元：服务交付与安全基线"
subtitle: "安全基线、防火墙与 AI 辅助运维"
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

编辑 `/etc/ssh/sshd_config`：

1. **禁用 Root 登录**:
   `PermitRootLogin no`
2. **禁用密码认证** (强制密钥):
   `PasswordAuthentication no`
3. **修改默认端口** (可选，防扫描):
   `Port 2222`

修改后：`sudo systemctl restart sshd`

> **警告**：改 SSH 配置前，先开一个备用终端连着，防止改错锁死自己！

---

## SSH 日志分析：谁在暴力破解你？

`/var/log/auth.log` 记录了所有 SSH 登录尝试：

```bash
# 登录失败最多的前 5 个 IP（攻击来源）
grep "Failed password" /var/log/auth.log | \
  awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head -5

# 被尝试最多的用户名（含无效用户）
grep "Failed password" /var/log/auth.log | \
  grep "invalid user" | awk '{print $(NF-5)}' | sort | uniq -c | sort -rn

# 登录成功记录（确认合法访问）
grep "Accepted" /var/log/auth.log
```

---

> **管道思维回顾**：`grep 过滤` → `awk 提取字段` → `sort 排序` → `uniq -c 计数` → `sort -rn 按数量排序`。这套路和 Nginx 日志分析完全一样！

---

# Topic 2: 防火墙

---

## UFW：防火墙傻瓜式管理

Ubuntu 默认防火墙工具 **UFW** (Uncomplicated Firewall)：

```bash
# 查看状态
sudo ufw status verbose

# 放行规则（先放行 SSH，再启用！）
sudo ufw allow 22/tcp       # SSH
sudo ufw allow 80/tcp       # HTTP
sudo ufw allow 443/tcp      # HTTPS

# 启用防火墙
sudo ufw enable

# 拒绝特定 IP
sudo ufw deny from 192.168.1.100

# 删除规则
sudo ufw delete allow 80/tcp
```

---

> **铁律**：`ufw enable` 之前，务必先 `ufw allow 22/tcp`，否则 SSH 立刻断开！

---

## UFW 与 Nginx 联动：最小暴露面

<iframe src="assets/ufw-nginx-arch.html" style="width:100%;height:620px;border:none;border-radius:8px;"></iframe>

---

原则：**只暴露反向代理端口，后端端口全部封闭**。

- 外部只能访问 :80 (HTTP) / :443 (HTTPS)
- 后端 :8080 只有 Nginx 能访问，外部无法直连
- 攻击面从「所有端口」缩小到「仅 80/443」

---

# Topic 3: AI 辅助运维

---

## AI 是副驾驶，你是机长

LLM (ChatGPT/Claude/DeepSeek) 非常擅长写脚本，但它们会犯错（幻觉）。

**经典翻车案例**：

- 用户: "帮我删除旧日志"
- AI: `find / -name "*.log" -delete`
- **后果**: 删除了 `/usr` 下的系统日志甚至应用日志，导致系统崩溃。

---

## AI 危险案例 1：命令注入

AI 生成的脚本直接拼接用户输入：

```python
# AI 生成的 "Ping 检测工具"
import os
ip = input("请输入 IP 地址: ")
os.system("ping -c 3 " + ip)
```

---

攻击者输入：`127.0.0.1; rm -rf /`

实际执行：`ping -c 3 127.0.0.1; rm -rf /`

**修复**：使用参数化调用，禁止 shell 拼接：

```python
import subprocess
subprocess.run(["ping", "-c", "3", ip], check=True)
```

---

## AI 危险案例 2：路径遍历

AI 生成的文件读取代码未校验路径：

```python
# AI 生成的 "日志查看工具"
filename = input("请输入日志文件名: ")
with open(f"/var/log/{filename}") as f:
    print(f.read())
```

---

攻击者输入：`../../etc/shadow`

实际读取：`/var/log/../../etc/shadow` = `/etc/shadow`

**修复**：校验真实路径，限制在允许目录内：

```python
import os
real_path = os.path.realpath(f"/var/log/{filename}")
if not real_path.startswith("/var/log/"):
    raise ValueError("非法路径")
```

---

## AI 危险案例 3：过度权限

AI 生成脚本时倾向于「先让它跑起来」，经常给出危险的权限设置：

| 危险模式 | 后果 | 安全替代 |
|----------|------|---------|
| `chmod 777 /var/www` | 任何人可修改网站文件 | `chmod 755` + 合理的属主 |
| `curl xxx \| bash` | 下载的脚本可能包含恶意代码 | 先下载审查，再执行 |
| `docker run --privileged` | 容器获得宿主机全部权限 | 去掉 `--privileged`，按需挂载 |
| `sudo` 在脚本中 | 提权操作无审计 | 仅在必要时 sudo，记录日志 |

> **原则**：AI 给的权限如果超过你的需求，立即降级。

---

## AI 危险案例 4：一个真实案例 — AI 如何反复犯错

> **本案例 100% 真实**：以下是课件制作者本人让 AI 编写 TOCTOU（竞态条件）教学示例时的完整纠偏过程。每一轮都是 AI 实际输出的内容。

---

### 第 1 轮：AI 提交初稿

> **教师需求**：在课件中增加一个 TOCTOU 竞态条件的安全案例。

**AI 输出**：

```bash
# AI 生成的 "安全删除临时文件"
if [ -f "/tmp/$FILENAME" ]; then    # 检查
    rm "/tmp/$FILENAME"              # 删除
fi
```

---

AI 声称：攻击者将 `/tmp/data` 替换为指向 `/etc/passwd` 的符号链接，`rm` 会跟踪链接删除系统文件。

---

### 第 1 轮：教师纠偏

> `rm` 对符号链接的行为是**删除链接本身**，不会跟踪到目标文件。这个举例在技术上是错误的。

**核心知识点**：`rm`、`mv` 作用于符号链接时，只操作链接本身，**不跟踪**到目标。

---

### 第 2 轮：AI 修正（仍然有错）

**AI 修改后**：改用「硬链接 + mv」场景：

```bash
# AI 修改后的 "日志轮转工具"
LOG="/tmp/$APPNAME.log"
if [ -f "$LOG" ]; then
    mv "$LOG" "${LOG}.$(date +%s).bak"   # 重命名
fi
```

---

AI 声称：攻击者创建指向 `/etc/crontab` 的硬链接，`mv` 会泄漏文件内容。

---

### 第 2 轮：教师纠偏

> 两个问题：
>
> 1. **硬链接不可行**：普通用户无法对 `/etc/crontab` 创建硬链接（需要对该文件的写权限）。
> 2. **mv 行为理解错误**：`mv` 对符号链接只移动链接本身，不跟踪目标。对硬链接，`mv` 只是重命名目录项，原文件不受影响——说「获得副本」完全错误。
>
> 真正跟踪符号链接的是**写入操作**：`>`、`>>`、`cp`、`touch`、`chmod`。

---

### 第 3 轮：AI 修正（场景仍有问题）

**AI 修改后**：改用 `>` 写入 + `/tmp` 目录：

```bash
LOG="/tmp/$APPNAME.log"
if [ -f "$LOG" ]; then
    > "$LOG"    # 清空文件（跟踪符号链接）
fi
```

---

AI 声称：攻击者在 `/tmp` 中将文件替换为符号链接。

---

### 第 3 轮：教师纠偏

> `/tmp` 目录有 **sticky bit**（`drwxrwxrwt`），只有文件属主、目录属主或 root 才能删除/重命名文件。如果文件是脚本创建的，攻击者（非属主）无法替换它。
>
> 应将场景放在**无 sticky bit 的共享目录**中，并说明 sticky bit 的防护作用。

---

### 最终版：AI 输出正确案例

```bash
# 正确的 TOCTOU 示例
# 工作目录：/var/www/logs/ （多人可写的共享目录，无 sticky bit）
LOG="/var/www/logs/$APPNAME.log"
if [ -f "$LOG" ]; then        # 检查文件存在
    > "$LOG"                   # 清空文件（跟踪符号链接到目标！）
fi
```

---

攻击前提明确：

1. 目录无 sticky bit，有写权限的任何用户可替换文件
2. `>` 跟踪符号链接到目标文件（与 `rm`/`mv` 不同）
3. 攻击者在检查与操作之间的瞬间替换文件

---

### 本案例的教训

| 轮次 | AI 犯了什么错 | 教训 |
|------|-------------|------|
| 第 1 轮 | `rm` 不跟踪符号链接 | AI 对命令行为的理解可能**根本性错误** |
| 第 2 轮 | 硬链接不可行 + `mv` 不跟踪链接 | AI 会「换个错误」而非真正理解问题 |
| 第 3 轮 | 忽略 sticky bit 防护 | AI 缺乏**系统级上下文**（文件系统权限模型） |
| 最终 | 经过 3 轮人工纠偏才正确 | **AI 不会自己发现这些错误** |

> **结论**：AI 一口气生成了「看起来专业」的案例，但连续 3 轮都存在事实性错误。如果没有具备专业知识的人审核，这些错误会直接进入教材，误导学生。**你，才是最终的把关人。**

---

## 安全的 AI 工作流

<iframe src="assets/ai-secure-workflow.html" style="width:100%;height:620px;border:none;border-radius:8px;"></iframe>

---

**Prompt 阶段**：增加安全约束

- "写一个 Bash 脚本备份 /var/www，保留最近 7 天。**必须检查目录是否存在，操作前打印日志**。"

---

**Review 阶段**：高危命令检查清单

- `rm` / `rmdir` — 确认删除目标和条件
- `chmod 777` — 几乎总是错误的
- `dd` / `mkfs` — 磁盘操作，不可逆
- `> /dev/sda` — 写裸设备
- `curl | bash` / `wget | sh` — 远程代码执行
- 未引号的变量 — 空值或含空格时行为异常

--- 

**Test 阶段**：在 VM/WSL 中验证，不要在生产环境直接跑。

---

## 小结：安全不是一次性的

1. **最小权限** — root 少用，端口少开，权限收紧
2. **防御纵深** — SSH 加固 + 防火墙 + 反向代理，多层防护
3. **AI 审计意识** — AI 生成的代码必须经过 Review → Test → Run 流程
4. **持续观测** — 日志是你的眼睛，定期检查 access.log 和 auth.log

> 安全是一个过程，不是一个产品。
