---
title: "第二单元: 系统运维与排障"
subtitle: "系统可观测性 & 故障排查"
author: 黄玮
date: 2026-01
output: revealjs::revealjs_presentation
---

# Topic 1: 系统日志 (Systemd Journal)

---

## journalctl: 现代日志中心

不再需要 grep `/var/log/syslog` (虽然它还在)。

```bash
# 查看所有日志 (按时间倒序)
journalctl -r

# 查看特定服务的日志
journalctl -u nginx.service

# 查看本次启动以来的日志
journalctl -b

# 实时跟随日志 (类似 tail -f)
journalctl -f
```

---

# Topic 2: 网络排障进阶

---

## IP 与路由

> 忘记 ifconfig，拥抱 iproute2

- **查看地址**: `ip addr` (关注 scope global, state UP)
- **查看路由**: `ip route` (关注 default via)
- **排障流程**:
  1. 物理层/链路层: 网卡亮吗？`ip link`
  2. 网络层: IP 有吗？路由对吗？`ping gateway`
  3. 传输层: 端口开了吗？防火墙挡了吗？`nc -z -v <host> <port>`
  4. 应用层: HTTP 状态码？DNS 解析？

---

## DNS 排障

当 "ping 8.8.8.8 通，但 ping google.com 不通" 时：

1. **查看配置**: `cat /etc/resolv.conf`
2. **测试解析**: `dig google.com` 或 `nslookup google.com`
3. **systemd-resolved**: 
   - `resolvectl status`

---

# 任务 04: 故障取证

服务器发生了一次“服务中断”演习。请根据日志回答：

1. 服务 `fake-web` 何时崩溃的？(journalctl)
2. 崩溃时的错误堆栈是什么？
3. 当时系统的负载情况如何？(SAR 或 dmesg 线索)
4. 提交一份简短的《故障分析报告 (RCA)》。
