---
title: "第二单元: 系统运维与排障"
subtitle: "网络配置管理"
author: 黄玮
date: 2026-01
output: revealjs::revealjs_presentation
---

# Topic 1: 网络接口命名

---

## 你的网卡叫什么?

- **传统命名**: `eth0`, `wlan0` (不再保证顺序)
- **可预测命名 (Predictable Network Interface Names)**:
  - `en`: Ethernet (以太网)
  - `wl`: Wireless (无线)
  - `o`: Onboard (板载)
  - `s`: Slot (插槽)
  - **例如**: `ens33`, `enp3s0`

```bash
ip link show
```

---

# Topic 2: Netplan 配置 (Ubuntu)

---

## Netplan 简介

Ubuntu 18.04+ 引入的 YAML 网络配置抽象层。
后端可以是 `systemd-networkd` (服务器默认) 或 `NetworkManager` (桌面默认)。

配置文件路径: `/etc/netplan/*.yaml`

---

## 静态 IP 配置示例

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      dhcp4: no
      addresses:
        - 192.168.1.100/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
```

> ⚠️ YAML 对缩进非常敏感！

---

## 应用配置

1. **编辑配置**: `sudo nano /etc/netplan/00-installer-config.yaml`
2. **测试配置** (安全机制，配置错误会自动回滚):
   ```bash
   sudo netplan try
   ```
3. **强制应用**:
   ```bash
   sudo netplan apply
   ```

---

# Topic 3: 路由与 DNS

---

## 查看路由表

```bash
# 现代命令
ip route show

# 传统命令
netstat -rn
route -n
```

关键看 `default via <gateway-ip>` (默认网关)。

---

## DNS 解析

- **传统文件**: `/etc/resolv.conf`
  - 在 Systemd 系统中，通常是指向 `systemd-resolved` 的软链接
  - **不要直接修改它** (重启会覆盖)

- **查看 DNS 状态**:
  ```bash
  resolvectl status
  ```

---

# 任务 04b: 网络配置挑战

1. 使用 `ip addr` 查看当前 IP
2. 备份现有的 Netplan 配置文件
3. 将你的虚拟机配置为**静态 IP** (确保在同一网段，不要冲突)
4. 设置 DNS 为 `223.5.5.5` (阿里 DNS)
5. `netplan apply` 生效并验证联网 (`ping baidu.com`)
