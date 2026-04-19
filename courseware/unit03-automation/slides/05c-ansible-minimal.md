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

# Topic 3: 变量、模板与调试

---

## 变量与 Jinja2 模板

> 模板是 "数据驱动配置" 的核心——把变化的值抽成变量，不变的逻辑写成模板。

---

## 变量定义方式

```yaml
# 方式 1: Playbook 内联
- name: Deploy App
  hosts: webservers
  vars:
    app_port: 8080
    app_user: www-data
  tasks:
    - name: Write config
      template:
        src: config.j2
        dest: /etc/myapp/config.conf

# 方式 2: group_vars/ 目录结构
# group_vars/webservers.yml
app_port: 8080
app_user: www-data
db_host: db.internal
```

---

## Jinja2 模板语法

config.j2:

```jinja2
server {
    listen {{ app_port }};
    user {{ app_user }};

    {% if env == "production" %}
    error_log /var/log/nginx/error.log warn;
    {% endif %}

    {% for upstream in backends %}
    upstream {{ upstream.name }} {
        server {{ upstream.host }}:{{ upstream.port }};
    }
    {% endfor %}
}
```

---

## Playbook 调试三板斧

> Playbook 写错了不要慌，Ansible 提供了三层调试手段。

```bash
# 1. Dry-run: 预览变更，不实际执行
ansible-playbook site.yml --check

# 2. Step 模式: 逐个 task 确认执行
ansible-playbook site.yml --step

# 3. 详细输出: 看到每个 task 的详细信息
ansible-playbook site.yml -v   # 简要
ansible-playbook site.yml -vvv # 极其详细
```

---

## 常见失败模式

| 报错 | 含义 | 解决方案 |
|:---|:---|:---|
| `unreachable` | SSH 连不上 | 检查 Inventory 地址/密钥 |
| `fatal: FAILED` | 命令执行失败 | `-register` + `debug` 打印变量 |
| `changed` vs `failed` | 非预期变更 | `--check` 对比差异 |
| `template error` | Jinja2 语法错 | `ansible-playbook -v` 看行号 |

---

## Handler 触发调试

```yaml
handlers:
  - name: reload nginx
    service:
      name: nginx
      state: reloaded

# Handler 只在 task 状态真正变化时触发
# 如果 restart 总触发，说明 task 没有做好幂等性
```

---

# Topic 4: 组织与 AI 协同

---

## Role 组织结构

> 当 Playbook 超过 30 行，就该拆成 Role 了。Role 是 Ansible 可复用的基本单元。

---

```
roles/
└── nginx/
    ├── tasks/
    │   └── main.yml      # 任务列表
    ├── handlers/
    │   └── main.yml      # 处理器
    ├── templates/
    │   └── config.j2     # 模板文件
    ├── defaults/
    │   └── main.yml      # 默认变量（优先级最低）
    ├── vars/
    │   └── main.yml      # 角色变量（优先级较高）
    └── meta/
        └── main.yml      # 角色依赖
```

---

```yaml
# Playbook 中引用 Role
- name: Deploy Full Stack
  hosts: webservers
  roles:
    - nginx
    - python-app
    - { role: monitoring, tags: ["observability"] }
```

---

## AI 辅助 Ansible 实战

> AI 可以帮你快速生成 Playbook，但验证和审计必须自己来。

---

## 正确的工作流

```bash
# 1. 让 AI 生成初版 Playbook
#    提示词示例:
#    "写一个 Ansible Playbook，在 Ubuntu 上安装 Nginx，
#     使用 Jinja2 模板配置反向代理，变量通过 vars 定义"

# 2. 先 dry-run 验证
ansible-playbook site.yml --check -v

# 3. 逐步执行确认
ansible-playbook site.yml --step

# 4. 幂等性验证 — 连续执行两次，第二次应 changed=0
ansible-playbook site.yml
ansible-playbook site.yml  # 第二次应全绿
```

---

## AI 幻觉风险与应对

| 幻觉类型 | 示例 | 应对策略 |
|:---|:---|:---|
| 不存在的模块 | `ansible.builtin.magic` | 用 `ansible-doc <module>` 验证 |
| 废弃的参数 | `apt: update_cache=yes` (旧语法) | `--check` 会报错 |
| 错误的默认值 | `state: installed` (应为 `present`) | 查阅官方文档 |
| 过度复杂化 | 写了 100 行做 10 行的事 | 自己先理清需求再提问 |

> 记住 Unit 06 的原则：AI 是副驾驶，你是机长。Playbook 的每一行，你都要理解它的含义和副作用。
