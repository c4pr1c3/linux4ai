---
title: "第三单元：自动化与可复现"
subtitle: "代码即基础设施：Ansible 基础"
author: 黄玮
date: 2026-01
output: revealjs::revealjs_presentation
---

# Topic 1: 从脚本到 IaC

---

## 脚本的困境

当你有 100 台服务器：
- 用 Shell 循环 SSH？效率低，串行慢。
- 有的服务器已经装了软件，有的没装？脚本逻辑变得极度复杂。
- 如何保证所有服务器状态**最终一致**？

---

## Ansible 简介

- **无 Agent**: 只需要 SSH，受控端无需安装 Agent。
- **声明式**: "我想要 Nginx 处于运行状态"，而不是 "运行命令启动 Nginx"。
- **幂等性**: 核心模块天然幂等。

---

# Topic 2: 核心组件

---

## Inventory (主机清单)

`hosts.ini`:
```ini
[webservers]
server01 ansible_host=192.168.1.10
server02 ansible_host=192.168.1.11

[all:vars]
ansible_user=student
ansible_ssh_private_key_file=~/.ssh/id_ed25519
```

---

## Ad-Hoc 命令 (一次性任务)

```bash
# 测试连通性
ansible webservers -m ping -i hosts.ini

# 查内存
ansible webservers -m shell -a "free -h" -i hosts.ini

# 复制文件
ansible webservers -m copy -a "src=./index.html dest=/tmp/" -i hosts.ini
```

---

## Playbook (剧本)

`site.yml`:
```yaml
- name: Deploy Web Server
  hosts: webservers
  tasks:
    - name: Ensure Nginx is installed
      apt:
        name: nginx
        state: present
      become: yes  # 需要 sudo

    - name: Ensure Nginx is running
      service:
        name: nginx
        state: started
        enabled: yes
```

---

# 任务 06: 你的第一个 Playbook

1. 在本地 WSL 安装 Ansible。
2. 编写 Inventory，将 **共享服务器** 定义为目标主机。
3. 编写 Playbook：
   - 在你的家目录下创建一个文件夹 `ansible_demo`。
   - 使用 `copy` 模块上传一个 `README.txt`。
   - 使用 `cron` 模块为你自己添加一个定时任务（每分钟 echo hello）。
