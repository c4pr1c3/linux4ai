---
title: "第二单元：系统运维与排障"
subtitle: "存储管理基础"
author: 黄玮
date: 2026-01
output: revealjs::revealjs_presentation
---

# Topic 1: 块设备与分区

---

## 设备命名规则

- **IDE 硬盘**: `/dev/hda`, `/dev/hdb` (古老)
- **SATA/SCSI/USB**: `/dev/sda`, `/dev/sdb`
  - `/dev/sda1`: 第一块盘的第一个分区
- **NVMe SSD**: `/dev/nvme0n1`
  - `/dev/nvme0n1p1`: 分区 1
- **虚拟磁盘 (KVM/Xen)**: `/dev/vda`

---

## 分区工具

- **fdisk**: 传统 MBR 分区 (适用于 < 2TB)
  - `sudo fdisk /dev/sdb` -> `n` (new) -> `w` (write)
- **gdisk**: GPT 分区 (现代标准，支持 > 2TB)
- **parted**: 命令行脚本友好

```bash
# 查看所有磁盘和分区
lsblk
sudo fdisk -l
```

---

# Topic 2: 文件系统与挂载

---

## 格式化 (Format)

创建文件系统 (Filesystem) 的过程。

- **ext4**: Linux 默认，成熟稳定
- **xfs**: CentOS/RHEL 默认，高性能，适合大文件
- **fat32/exfat**: 兼容 Windows/macOS USB 盘

```bash
# 格式化分区为 ext4
sudo mkfs.ext4 /dev/sdb1
```

---

## 挂载 (Mount)

Linux 没有盘符 (C:, D:)，只有目录树。

```bash
# 1. 创建挂载点 (空目录)
sudo mkdir /mnt/data

# 2. 挂载
sudo mount /dev/sdb1 /mnt/data

# 3. 验证
df -h
```

---

## 持久化挂载 (`/etc/fstab`)

`mount` 命令重启后失效。需写入 `/etc/fstab`。

```plaintext
# <file system>    <mount point>   <type>  <options>       <dump>  <pass>
UUID=a1b2-c3d4     /mnt/data       ext4    defaults        0       2
```

> ⚠️ **警告**: `fstab` 写错会导致系统无法启动！修改后务必运行 `sudo mount -a` 测试。

---

# Topic 3: LVM 逻辑卷管理

---

## 为什么需要 LVM?

传统的磁盘分区大小固定，扩容困难。
**LVM (Logical Volume Manager)** 提供了抽象层：

- **PV (Physical Volume)**: 物理卷 (硬盘/分区)
- **VG (Volume Group)**: 卷组 (存储池，由多个 PV 组成)
- **LV (Logical Volume)**: 逻辑卷 (从 VG 分配空间，可动态扩缩)

---

## LVM 实战流程

```bash
# 1. 创建物理卷
sudo pvcreate /dev/sdb /dev/sdc

# 2. 创建卷组 (合并 sdb 和 sdc)
sudo vgcreate data_vg /dev/sdb /dev/sdc

# 3. 创建逻辑卷 (分配 10G)
sudo lvcreate -n my_lv -L 10G data_vg

# 4. 格式化并挂载 LV
sudo mkfs.ext4 /dev/data_vg/my_lv
sudo mount /dev/data_vg/my_lv /mnt/data
```

---

## 动态扩容 (LVM 的魔力)

```bash
# 1. 扩容 LV (增加 5G)
sudo lvextend -L +5G /dev/data_vg/my_lv

# 2. 在线扩容文件系统 (无需卸载!)
sudo resize2fs /dev/data_vg/my_lv
```
