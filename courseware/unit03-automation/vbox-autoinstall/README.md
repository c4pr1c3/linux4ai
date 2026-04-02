# Ubuntu 22.04 Server 无人值守安装指南（VirtualBox）

## 概述

本工具集用于在 VirtualBox 中全自动安装 Ubuntu 22.04 Server，无需任何人工交互。基于 Ubuntu Subiquity 安装器的 **autoinstall** 机制，配合 cloud-init 实现安装后自动配置。

### 工作原理

```
┌─────────────────┐    ┌──────────────┐    ┌───────────────────────────────┐
│ Ubuntu Server   │    │ seed-cidata  │    │       安装完成后              │
│ ISO（系统镜像） │ +  │ ISO（配置）  │ →  │ cloud-init 首次启动配置      │
│                 │    │              │    │ → 创建 cuc 用户 + SSH 公钥   │
│ Subiquity       │    │ user-data    │    │ → 重置 machine-id            │
│ 无人值守安装    │    │ meta-data    │    │ → 自动重启                   │
└─────────────────┘    └──────────────┘    └───────────────────────────────┘
```

### autoinstall vs 传统 cloud-init

| | autoinstall（本工具） | 传统 cloud-init |
|---|---|---|
| 用途 | **安装阶段**的全自动配置 | **已安装系统**的首次启动配置 |
| 分区 | 支持（LVM/普通分区） | 不支持 |
| 用户 | 创建安装用户 | 创建额外用户 |
| 触发方式 | `autoinstall:` 顶级键 | `#cloud-config` 标准格式 |
| 本工具 | 两者结合使用 | 作为嵌套 user-data 段 |

## 文件说明

| 文件 | 说明 |
|------|------|
| `user-data` | autoinstall + cloud-init 配置（BIOS Legacy 引导） |
| `user-data_uefi` | autoinstall + cloud-init 配置（UEFI 引导） |
| `meta-data` | NoCloud 元数据（主机名、实例 ID） |
| `create-cloudinit-iso.sh` | 一站式构建脚本：生成 cidata ISO 或单文件自动安装 ISO（支持 `--uefi`、`-U`） |
| `README.md` | 本文档 |

## 前置条件

- **VirtualBox** 6.x+ 及 Extension Pack
- **Ubuntu 22.04 Server ISO**：[官方下载](https://ubuntu.com/download/server)（`ubuntu-22.04.x-live-server-amd64.iso`）
- **ISO 构建工具**（宿主机上）：
  ```bash
  # Debian/Ubuntu
  sudo apt update && sudo apt install -y genisoimage
  # macOS
  brew install cdrtools
  ```

## 快速开始

### 第 1 步：生成 ISO

```bash
cd courseware/unit03-automation/vbox-autoinstall/

# 方式 A：生成单文件自动安装 ISO（推荐，全自动无需确认）
./create-cloudinit-iso.sh -U /path/to/ubuntu-22.04.5-live-server-amd64.iso

# 方式 B：仅生成 cidata ISO（需同时挂载 Ubuntu ISO，启动时需手动确认）
./create-cloudinit-iso.sh

# UEFI 引导模式（添加 --uefi 参数）
./create-cloudinit-iso.sh --uefi -U /path/to/ubuntu-22.04.5-live-server-amd64.iso

# 自定义配置
./create-cloudinit-iso.sh -U /path/to/ubuntu.iso -H myhost -p mypassword -k ~/.ssh/id_ed25519.pub
```

**方式 A** 输出单个 ISO 文件（如 `ubuntu-22.04.5-live-server-amd64-autoinstall.iso`），包含 autoinstall 内核参数 + cidata 配置，只需挂载一个光驱。

**方式 B** 输出 `seed-cidata.iso`，需与 Ubuntu Server ISO 同时挂载。

> 方式 A 依赖 `xorriso`（`sudo apt install -y xorriso`），方式 B 仅需 `genisoimage`。

### 第 2 步：配置 VirtualBox 虚拟机

创建新虚拟机，关键配置：

| 配置项 | 推荐值 |
|--------|--------|
| 名称 | linux4ai（或其他） |
| 类型 | Linux, Ubuntu (64-bit) |
| 内存 | >= 2048MB |
| 处理器 | >= 2 核 |
| 磁盘 | >= 25GB VDI（动态分配即可，百分比分区自适应） |
| 网卡 1 | NATNetwork 或 NAT（Intel PRO/1000） |
| 网卡 2 | Host-Only（Intel PRO/1000） |

**存储配置**：

- **方式 A（单文件 ISO）**：挂载自动安装 ISO 作为唯一光驱即可
- **方式 B（双 ISO）**：在虚拟机的存储控制器上挂载两个 ISO：
  1. **主光驱**：Ubuntu 22.04 Server ISO
  2. **次光驱**：`seed-cidata.iso`（本工具生成的配置 ISO，卷标 `cidata`）

> 方式 B 中两个 ISO 必须同时挂载。cidata ISO 的卷标为 `cidata`，Subiquity 会自动识别。

### 第 3 步：启动安装

启动虚拟机，安装过程全自动完成（约 5-10 分钟）。安装完成后：

1. 系统首次启动 → cloud-init 执行（创建 cuc 用户、注入 SSH 密钥、重置 machine-id）
2. 自动重启 → machine-id 生效
3. 再次启动后系统即可使用

## 自定义配置

### 方法 1：使用构建脚本参数

```bash
./create-cloudinit-iso.sh [选项]
```

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-H, --hostname` | 主机名 | linux4ai |
| `-u, --username` | 安装用户名 | ubuntu |
| `-p, --password` | 明文密码 | 123456 |
| `-k, --ssh-key` | SSH 公钥文件路径 | 无 |
| `-m, --mirror` | APT 镜像源 | http://mirrors.tuna.tsinghua.edu.cn/ubuntu |
| `-o, --output` | 输出 ISO 文件名 | seed-cidata.iso |
| `-n, --dry-run` | 仅预览，不创建 ISO | - |
| `--uefi` | 使用 UEFI 引导模式 | BIOS Legacy |
| `-U, --ubuntu-iso` | Ubuntu Server ISO 路径，生成单文件自动安装 ISO | 无 |

### 方法 2：直接编辑 user-data

`user-data` 文件中的【可自定义配置】区域已标注清晰注释，可直接编辑：

```yaml
# 修改主机名
identity:
  hostname: my-server

# 修改密码（替换哈希值）
# 生成哈希：openssl passwd -6 '你的密码'
password: "$6$..."

# 添加 SSH 公钥
ssh_authorized_keys:
  - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... your-comment

# 更换镜像源
apt:
  primary:
    - arches: [amd64, i386]
      uri: http://mirrors.aliyun.com/ubuntu
```

### 调整磁盘分区

默认分区方案使用百分比，自适应不同磁盘容量：

```yaml
# 当前默认值（相对于 VG 可用空间）
- id: lv-root
  type: lvm_partition
  size: 50%    # 根文件系统

- id: lv-home
  type: lvm_partition
  size: 35%    # 用户家目录

- id: lv-swap
  type: lvm_partition
  size: 8%     # 交换空间
# 剩余约 7% 保留在 VG 中，便于后续扩展
```

可按需修改百分比值，或改用绝对值（如 `20G`、`15G`）。

### 更换镜像源

可选的中国大陆镜像：

| 镜像站 | 地址 |
|--------|------|
| 清华大学 TUNA（默认） | `http://mirrors.tuna.tsinghua.edu.cn/ubuntu` |
| 阿里云 | `http://mirrors.aliyun.com/ubuntu` |
| 中科大 | `http://mirrors.ustc.edu.cn/ubuntu` |
| 华为云 | `http://repo.huaweicloud.com/ubuntu` |

## 引导模式选择

本工具支持 BIOS Legacy 和 UEFI 两种引导模式，通过不同模板实现：

| 项目 | BIOS Legacy（默认） | UEFI |
|------|---------------------|------|
| 模板文件 | `user-data` | `user-data_uefi` |
| 构建参数 | （默认） | `--uefi` |
| VirtualBox 设置 | 默认固件 | 设置→系统→勾选「启用 EFI」 |
| 引导分区 | `bios_grub`（1MB） | ESP（512MB，FAT32，挂载 /boot/efi） |
| 分区表 | GPT | GPT |

> 注意：VirtualBox 的 EFI 设置必须与构建参数一致。UEFI 模式下需在虚拟机设置中启用 EFI。

## 加速安装优化

本工具内置多项优化，将安装时间从 15-30 分钟缩短至 5-10 分钟：

### 安装阶段优化（autoinstall 级别）

| 优化项 | 配置 | 效果 |
|--------|------|------|
| 跳过安装器更新 | `refresh-installer: {update: false}` | 节省 2-5 分钟 |
| 安全更新仅安装必要项 | `updates` 默认值为 `security`（最小化） | 减少不必要的更新 |
| 跳过驱动搜索 | `source: {search_drivers: false}` | 节省 1-2 分钟 |
| 跳过编解码器/专有驱动 | `codecs: {install: false}`, `drivers: {install: false}` | 节省数十秒 |
| 预配置软件包 | `debconf-selections` 禁用 unattended-upgrades | 避免交互提示 |

### 首次启动优化（cloud-init 级别）

| 优化项 | 配置 | 效果 |
|--------|------|------|
| 跳过 apt update/upgrade | `package_update: false`, `package_upgrade: false` | 节省 2-5 分钟 |
| 强制 NoCloud 数据源 | `/etc/cloud/cloud.cfg.d/99-enable-datasource.cfg` | 跳过 AWS/Azure/OpenStack 探测 |
| 禁用 cloud-init 网络配置 | `/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg` | 避免 netplan 冲突 |
| machine-id 重置前移 | `late-commands`（安装阶段执行） | 减少首次启动等待 |
| 精简 runcmd | 仅保留 `dbus-uuidgen` | 最小化首次启动命令 |

### VirtualBox 优化建议

- 分配 >= 2048MB 内存和 >= 2 核 CPU
- **存储控制器 I/O 缓存**：虚拟机「设置」→「存储」→ 选中「控制器: SATA」→ 右侧勾选「使用主机输入输出（I/O）缓存」，可显著提升虚拟磁盘读写性能
- **固态驱动器标记**：选中 VDI 虚拟磁盘 → 右侧勾选「固态驱动器」。若宿主机使用 SSD，勾选后虚拟机会将磁盘识别为 SSD，调度器会采用更适合 SSD 的 I/O 策略；若宿主机为机械硬盘则不建议勾选

## VirtualBox 虚拟机配置详解

### 双网卡设置

VirtualBox 虚拟机需要配置两块网卡，模拟课程中常用的「NAT 上网 + Host-Only 管理」架构：

**网卡 1（enp0s3）**：
- 连接方式：NATNetwork 或 NAT
- 用途：虚拟机访问外网（apt、wget 等）
- VirtualBox 设置：「设置」→「网络」→「网卡 1」→ 勾选「启用网络连接」→ 选择 NATNetwork 或 NAT

**网卡 2（enp0s8）**：
- 连接方式：Host-Only
- 用途：宿主机 SSH 连接虚拟机
- VirtualBox 设置：「设置」→「网络」→「网卡 2」→ 勾选「启用网络连接」→ 选择「仅主机(Host-Only)网络」
- 确保已创建 Host-Only 网络：「管理」→「主机网络管理器」

> 网卡类型保持默认的 **Intel PRO/1000** 即可，这决定了网卡命名为 enp0s3/enp0s8。

### ISO 挂载方法

**方式 A（单文件 ISO，推荐）**：

1. 打开虚拟机「设置」→「存储」
2. 点击控制器下的「空」光驱图标
3. 点击右侧光驱图标 →「选择磁盘文件」→ 选择 `-autoinstall.iso` 文件
4. 仅需挂载这一个 ISO

**方式 B（双 ISO）**：

1. 打开虚拟机「设置」→「存储」
2. 点击控制器下的「空」光驱图标 → 选择 Ubuntu Server ISO
3. 点击控制器旁的「添加光驱」→ 选择 `seed-cidata.iso`
4. 确认两个 ISO 均已挂载

## 安装后验证清单

安装完成、系统启动后，通过 SSH 或 VirtualBox 控制台登录，逐项检查：

```bash
# 1. 主机名
hostname
# 预期：linux4ai（或你自定义的主机名）

# 2. 用户检查
id ubuntu          # 安装用户
id cuc             # 课程用户
groups cuc         # 应包含 adm, sudo

# 3. SSH 连接（从宿主机执行）
ssh cuc@192.168.56.xxx    # 使用 Host-Only 网卡 IP

# 4. LVM 分区
lsblk
# 应看到 ubuntu-vg 卷组下有 root-lv, home-lv, swap-lv
lvs
# root-lv 应挂载在 /，home-lv 应挂载在 /home

# 5. machine-id 唯一性
cat /etc/machine-id
# 不同虚拟机应具有不同的 machine-id

# 6. 双网卡 IP
ip -4 addr show enp0s3   # 应有 10.0.2.x（NAT 网络）
ip -4 addr show enp0s8   # 应有 192.168.56.x（Host-Only）

# 7. APT 镜像源
grep -r "tuna" /etc/apt/sources.list
# 应看到 mirrors.tuna.tsinghua.edu.cn

# 8. Python3 可用（Ansible 依赖）
python3 --version
```

## 克隆虚拟机注意事项

克隆虚拟机是课程实验中的常见操作，需注意以下问题：

### machine-id 冲突

**现象**：克隆后的虚拟机与原虚拟机获得相同的 IP 地址。

**原因**：`/etc/machine-id` 相同 → systemd-networkd 使用相同标识发 DHCP 请求 → DHCP 服务器返回相同 IP。

**本工具的解决方案**：
- cloud-init 的 `runcmd` 会在首次启动时自动重置 machine-id
- 网络配置使用 `dhcp-identifier: mac`，双重保险

**手动重置方法**（如需）：
```bash
sudo echo -n '' > /etc/machine-id
sudo /bin/systemd-machine-id-setup
sudo rm -f /var/lib/dbus/machine-id
sudo dbus-uuidgen --ensure=/etc/machine-id
sudo dbus-uuidgen --ensure
sudo reboot
```

### cloud-init 重新执行

如需克隆后重新执行 cloud-init（例如更改 cuc 用户的 SSH 公钥）：

1. 修改 `meta-data` 中的 `instance-id` 为新值
2. 重新生成 cidata ISO 并挂载
3. 启动虚拟机

或手动触发：
```bash
sudo cloud-init clean
sudo reboot
```

### VirtualBox 克隆建议

1. 使用「链接克隆」节省磁盘空间
2. 克隆时选择「重新初始化所有网卡的 MAC 地址」
3. 克隆完成后首次启动前，挂载新的 cidata ISO（含新 instance-id）

## 常见问题排查

### 安装未自动开始，仍出现交互菜单

**可能原因**：
- 未使用 `-U` 参数生成单文件 ISO（双 ISO 模式下 Subiquity 会要求确认 autoinstall）
- cidata ISO 未正确挂载
- cidata ISO 卷标不是 `cidata`
- user-data 文件语法错误

**排查**：
```bash
# 推荐方案：使用 -U 参数生成单文件自动安装 ISO（跳过确认）
./create-cloudinit-iso.sh -U /path/to/ubuntu-22.04.5-live-server-amd64.iso

# 检查 ISO 卷标
isoinfo -d -i seed-cidata.iso | grep "Volume id"
# 应输出：Volume id: cidata

# 校验 YAML 语法
python3 -c "import yaml; yaml.safe_load(open('user-data'))"
```

### 网卡名称不是 enp0s3/enp0s8

**可能原因**：VirtualBox 网卡类型被修改（如改为半虚拟化 virtio）。

**解决**：保持网卡类型为默认的 **Intel PRO/1000 MT Desktop (82540EM)**。或修改 user-data 中的网卡名称。

### 安装失败：分区相关错误

**可能原因**：磁盘容量不足 25GB。

**解决**：增大虚拟磁盘容量，或调整 user-data 中各逻辑卷的 size 值。

### cuc 用户未创建

**排查**：
```bash
# 检查 cloud-init 执行日志
cat /var/log/cloud-init.log
cat /var/log/cloud-init-output.log

# 检查 cloud-init 状态
cloud-init status
```

### SSH 免密登录不生效

**排查**：
```bash
# 检查 authorized_keys 文件
sudo cat /home/cuc/.ssh/authorized_keys

# 检查 SSH 服务配置
grep PasswordAuthentication /etc/ssh/sshd_config
grep PubkeyAuthentication /etc/ssh/sshd_config

# 调试连接
ssh -vvv cuc@192.168.56.xxx
```

## 参考资料

- [Ubuntu Autoinstall 官方文档](https://ubuntu.com/server/docs/install/autoinstall)
- [Subiquity 自动安装参考](https://subiquity.readthedocs.io/en/latest/reference/autoinstall-reference.html)
- [Curtin 存储配置](https://curtin.readthedocs.io/en/latest/topics/storage.html)
- [cloud-init 官方文档](https://cloudinit.readthedocs.io/)
- [cloud-init NoCloud 数据源](https://cloudinit.readthedocs.io/en/latest/reference/datasources/nocloud.html)
- [Netplan 配置参考](https://netplan.io/reference)
- [旧的课程 cloud-init 课件](https://github.com/c4pr1c3/LinuxSysAdmin/blob/master/cloud-init.md)
