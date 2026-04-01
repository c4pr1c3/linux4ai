#!/bin/bash
# ============================================================
# Ubuntu 22.04 Server 无人值守安装 - cidata ISO 构建脚本
# 课程：Linux 系统与网络管理
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# --- 默认配置 ---
HOSTNAME="linux4ai"
USERNAME="ubuntu"
PASSWORD_PLAIN="123456"
SSH_PUB_KEY_FILE=""
MIRROR="http://mirrors.tuna.tsinghua.edu.cn/ubuntu"
OUTPUT_ISO="seed-cidata.iso"
BOOT_MODE="bios"  # bios 或 uefi
UBUNTU_ISO=""     # Ubuntu Server ISO 路径（可选，用于生成单文件自动安装 ISO）

# --- 颜色输出 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[信息]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[警告]${NC} $*"; }
log_error() { echo -e "${RED}[错误]${NC} $*" >&2; }

usage() {
cat <<'EOF'
用法: create-cloudinit-iso.sh [选项]

选项:
  -H, --hostname NAME     设置主机名 (默认: linux4ai)
  -u, --username NAME     设置安装用户名 (默认: ubuntu)
  -p, --password PASS     设置明文密码 (默认: 123456)
  -k, --ssh-key FILE      SSH 公钥文件路径，注入到 cuc 用户的 authorized_keys
  -m, --mirror URL        APT 镜像源地址 (默认: http://mirrors.tuna.tsinghua.edu.cn/ubuntu)
  -o, --output FILE       输出 ISO 文件名 (默认: seed-cidata.iso)
  -n, --dry-run           仅生成配置文件，不创建 ISO
  --uefi                  使用 UEFI 引导模式 (默认: BIOS Legacy)
  -U, --ubuntu-iso PATH   Ubuntu Server ISO 路径（可选，生成单文件自动安装 ISO）
  --help                  显示此帮助信息

示例:
  # 使用默认配置（BIOS 引导），仅生成 cidata ISO
  ./create-cloudinit-iso.sh

  # 使用 UEFI 引导模式
  ./create-cloudinit-iso.sh --uefi

  # 自定义主机名和密码
  ./create-cloudinit-iso.sh -H myserver -p mypassword

  # 注入 SSH 公钥
  ./create-cloudinit-iso.sh -k ~/.ssh/id_ed25519.pub

  # 生成单文件自动安装 ISO（需指定 Ubuntu Server ISO）
  # 输出 ISO 包含 autoinstall 内核参数 + cidata 配置，挂载一个 ISO 即可
  ./create-cloudinit-iso.sh -U ubuntu-22.04.5-live-server-amd64.iso

  # 完整自定义（UEFI + 自动安装 ISO）
  ./create-cloudinit-iso.sh --uefi -U ubuntu-22.04.5-live-server-amd64.iso -H myserver -p mypassword -k ~/.ssh/id_ed25519.pub
EOF
}

# --- 参数解析 ---
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -H|--hostname)   HOSTNAME="$2"; shift 2 ;;
        -u|--username)   USERNAME="$2"; shift 2 ;;
        -p|--password)   PASSWORD_PLAIN="$2"; shift 2 ;;
        -k|--ssh-key)    SSH_PUB_KEY_FILE="$2"; shift 2 ;;
        -m|--mirror)     MIRROR="$2"; shift 2 ;;
        -o|--output)     OUTPUT_ISO="$2"; shift 2 ;;
        -n|--dry-run)    DRY_RUN=true; shift ;;
        --uefi)          BOOT_MODE="uefi"; shift ;;
        -U|--ubuntu-iso) UBUNTU_ISO="$2"; shift 2 ;;
        --help)          usage; exit 0 ;;
        *)               log_error "未知参数: $1"; usage; exit 1 ;;
    esac
done

# --- 依赖检查 ---
check_dependencies() {
    local missing=()

    # 密码哈希工具
    if ! command -v openssl &>/dev/null; then
        missing+=("openssl")
    fi

    # YAML 校验
    if ! command -v python3 &>/dev/null; then
        missing+=("python3")
    fi

    # ISO 创建工具（至少需要一个）
    local iso_tool=""
    if command -v genisoimage &>/dev/null; then
        iso_tool="genisoimage"
    elif command -v mkisofs &>/dev/null; then
        iso_tool="mkisofs"
    elif command -v xorrisofs &>/dev/null; then
        iso_tool="xorrisofs"
    fi

    if [[ -z "$iso_tool" && "$DRY_RUN" == "false" ]]; then
        missing+=("genisoimage (或 mkisofs / xorrisofs)")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "缺少必要依赖: ${missing[*]}"
        echo ""
        echo "安装方法（Debian/Ubuntu）:"
        echo "  sudo apt update && sudo apt install -y genisoimage openssl python3"
        exit 1
    fi

    echo "$iso_tool"
}

ISO_TOOL=$(check_dependencies)

# --- 生成密码哈希 ---
generate_password_hash() {
    openssl passwd -6 "$PASSWORD_PLAIN"
}

log_info "密码哈希生成中..."
PASSWORD_HASH=$(generate_password_hash)

# --- 读取 SSH 公钥 ---
SSH_KEY_LINE=""
if [[ -n "$SSH_PUB_KEY_FILE" ]]; then
    if [[ ! -f "$SSH_PUB_KEY_FILE" ]]; then
        log_error "SSH 公钥文件不存在: $SSH_PUB_KEY_FILE"
        exit 1
    fi
    SSH_KEY_LINE=$(head -1 "$SSH_PUB_KEY_FILE")
    if [[ -z "$SSH_KEY_LINE" ]]; then
        log_error "SSH 公钥文件为空: $SSH_PUB_KEY_FILE"
        exit 1
    fi
    log_info "已读取 SSH 公钥: ${SSH_KEY_LINE:0:50}..."
fi

# --- 生成 user-data ---
WORK_DIR=$(mktemp -d)
cleanup() {
    chmod -Rf u+w "$WORK_DIR" 2>/dev/null
    rm -rf "$WORK_DIR"
}
trap 'cleanup' EXIT

log_info "生成 user-data..."

# 读取模板（根据引导模式选择）
if [[ "$BOOT_MODE" == "uefi" ]]; then
    USER_DATA_TEMPLATE="$SCRIPT_DIR/user-data_uefi"
else
    USER_DATA_TEMPLATE="$SCRIPT_DIR/user-data"
fi
if [[ ! -f "$USER_DATA_TEMPLATE" ]]; then
    log_error "未找到 user-data 模板: $USER_DATA_TEMPLATE"
    exit 1
fi

# 替换模板中的占位值
sed \
    -e "s|    hostname: .*|    hostname: ${HOSTNAME}|" \
    -e "s|username: ubuntu|username: ${USERNAME}|" \
    -e "s|uri: http://mirrors.tuna.tsinghua.edu.cn/ubuntu|uri: ${MIRROR}|g" \
    "$USER_DATA_TEMPLATE" > "$WORK_DIR/user-data"

# 替换密码哈希（autoinstall.identity.password）
sed -i "s|password: \"\$6\$[^\"]*\"|password: \"${PASSWORD_HASH}\"|g" "$WORK_DIR/user-data"

# 替换 cuc 用户密码哈希（user-data.users[].passwd）
# 因为有两个 password/passwd 字段需要替换，使用行号区分
# identity.password 在前，users[].passwd 在后
sed -i "0,/passwd:/! {0,/passwd:/s|passwd: \"\$6\$[^\"]*\"|passwd: \"${PASSWORD_HASH}\"|}" "$WORK_DIR/user-data"

# 注入 SSH 公钥
if [[ -n "$SSH_KEY_LINE" ]]; then
    # 替换注释行 "# - ssh-ed25519 ..." 为实际的公钥行
    sed -i "s|# - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI\.\.\..*|  - ${SSH_KEY_LINE}|" "$WORK_DIR/user-data"
fi

# --- 生成 meta-data ---
log_info "生成 meta-data..."
cat > "$WORK_DIR/meta-data" <<EOF
instance-id: ${HOSTNAME}-vbox-001
local-hostname: ${HOSTNAME}
EOF

# --- YAML 语法校验 ---
log_info "校验 user-data YAML 语法..."
if python3 -c "import yaml, sys; yaml.safe_load(open(sys.argv[1]))" "$WORK_DIR/user-data"; then
    log_info "YAML 语法校验通过"
else
    log_error "YAML 语法校验失败，请检查 user-data 文件"
    exit 1
fi

# --- Dry run 模式 ---
if [[ "$DRY_RUN" == "true" ]]; then
    log_info "Dry-run 模式，配置文件已生成到: $WORK_DIR"
    log_info "user-data: $WORK_DIR/user-data"
    log_info "meta-data: $WORK_DIR/meta-data"
    echo ""
    echo "--- user-data 内容预览 ---"
    cat "$WORK_DIR/user-data"
    echo ""
    echo "--- meta-data 内容预览 ---"
    cat "$WORK_DIR/meta-data"
    # 阻止 trap 清理临时文件（dry-run 时方便查看）
    trap - EXIT
    exit 0
fi

# --- 输出路径处理 ---
if [[ "$OUTPUT_ISO" == /* ]]; then
    OUTPUT_PATH="$OUTPUT_ISO"
else
    OUTPUT_PATH="$SCRIPT_DIR/$OUTPUT_ISO"
fi

# --- 分支：生成单文件自动安装 ISO 或 cidata ISO ---
if [[ -n "$UBUNTU_ISO" ]]; then
    # ============================================================
    # 模式 A：生成单文件自动安装 ISO
    # ============================================================

    # 验证 Ubuntu ISO
    UBUNTU_ISO_REAL="$(realpath "$UBUNTU_ISO" 2>/dev/null || echo "$UBUNTU_ISO")"
    if [[ ! -f "$UBUNTU_ISO_REAL" ]]; then
        log_error "Ubuntu Server ISO 不存在: $UBUNTU_ISO"
        exit 1
    fi

    # 检查 xorriso 依赖
    if ! command -v xorriso &>/dev/null; then
        log_error "重打包 ISO 需要 xorriso"
        echo "  安装: sudo apt install -y xorriso" >&2
        exit 1
    fi

    # 默认输出文件名
    if [[ "$OUTPUT_ISO" == "seed-cidata.iso" ]]; then
        BASENAME="$(basename "$UBUNTU_ISO_REAL")"
        OUTPUT_PATH="${UBUNTU_ISO_REAL%/*}/${BASENAME%.iso}-autoinstall.iso"
    fi

    log_info "========================================="
    log_info "生成单文件自动安装 ISO"
    log_info "========================================="

    EXTRACT_DIR="$WORK_DIR/extracted"
    mkdir -p "$EXTRACT_DIR"

    # [1/4] 解包 Ubuntu ISO
    log_info "[1/4] 解包 Ubuntu ISO..."
    xorriso -osirrox on -indev "$UBUNTU_ISO_REAL" \
        -extract / "$EXTRACT_DIR" 2>/dev/null

    # 修复提取文件的权限（ISO 中的文件保留 root-only 权限，普通用户无法修改/删除）
    chmod -Rf u+w "$EXTRACT_DIR" 2>/dev/null

    # [2/4] 注入 autoinstall 内核参数
    GRUB_CFG=""
    for f in "$EXTRACT_DIR/boot/grub/grub.cfg" "$EXTRACT_DIR/boot/grub/loopback.cfg"; do
        if [[ -f "$f" ]]; then
            GRUB_CFG="$f"
            break
        fi
    done

    if [[ -z "$GRUB_CFG" ]]; then
        log_error "未找到 GRUB 配置文件"
        exit 1
    fi

    log_info "[2/4] 注入 autoinstall 内核参数到 GRUB..."
    sed -i 's|linux\s*/casper/vmlinuz|linux   /casper/vmlinuz autoinstall|' "$GRUB_CFG"

    if grep -q "autoinstall" "$GRUB_CFG"; then
        log_info "      autoinstall 参数注入成功"
    else
        log_error "autoinstall 参数注入失败"
        exit 1
    fi

    # [3/4] 注入 cidata 配置文件并重打包
    log_info "[3/4] 注入 cidata 配置文件..."
    cp "$WORK_DIR/user-data" "$EXTRACT_DIR/user-data"
    cp "$WORK_DIR/meta-data" "$EXTRACT_DIR/meta-data"

    # 构建 xorriso 启动参数
    # 正确顺序：BIOS 启动项 → -eltorito-alt-boot → EFI 启动项
    BOOT_ARGS=()
    BOOT_ARGS+=(-r -V cidata)

    if [[ -f "$EXTRACT_DIR/boot/grub/i386-pc/eltorito.img" ]]; then
        BOOT_ARGS+=(
            -b boot/grub/i386-pc/eltorito.img
            -c boot/grub/i386-pc/boot.cat
            -no-emul-boot -boot-load-size 4 -boot-info-table
        )
    fi

    if [[ -f "$EXTRACT_DIR/boot/grub/efi.img" ]]; then
        BOOT_ARGS+=(
            -eltorito-alt-boot
            -e boot/grub/efi.img
            -no-emul-boot
            -append_partition 2 0xef "$EXTRACT_DIR/boot/grub/efi.img"
        )
    fi

    BOOT_ARGS+=(
        --modification-date=$(date +%Y%m%d%H%M%S00)
        -isohybrid-gpt-basdat
        -output "$OUTPUT_PATH"
        "$EXTRACT_DIR"
    )

    log_info "[4/4] 重新打包 ISO..."
    xorriso -as mkisofs "${BOOT_ARGS[@]}" 2>&1 | tail -5

    if [[ ! -f "$OUTPUT_PATH" ]]; then
        log_error "ISO 创建失败"
        exit 1
    fi

    ISO_SIZE=$(du -h "$OUTPUT_PATH" | cut -f1)

    echo ""
    log_info "========================================="
    log_info "单文件自动安装 ISO 创建成功！"
    log_info "========================================="
    log_info "文件: $OUTPUT_PATH"
    log_info "大小: $ISO_SIZE"
    echo ""
    log_info "使用方法："
    echo "  1. 创建 VirtualBox 虚拟机（双网卡 + 25GB 磁盘）"
    echo "  2. 存储控制器挂载 $OUTPUT_PATH 作为唯一光驱"
    echo "  3. 启动虚拟机，安装将全自动完成（无需确认）"
    echo ""
    echo "  安装用户: $USERNAME"
    echo "  课程用户: cuc"
    echo "  主机名:   $HOSTNAME"
    echo "  引导模式: $BOOT_MODE"
    if [[ -n "$SSH_KEY_LINE" ]]; then
        echo "  SSH 公钥: 已注入到 /home/cuc/.ssh/authorized_keys"
    else
        log_warn "未注入 SSH 公钥（使用 -k 参数指定公钥文件）"
    fi

else
    # ============================================================
    # 模式 B：仅生成 cidata ISO（向后兼容）
    # ============================================================

    log_info "创建 cidata ISO..."

    case "$ISO_TOOL" in
        genisoimage)
            genisoimage -output "$OUTPUT_PATH" \
                -volid cidata \
                -joliet -rock \
                "$WORK_DIR/user-data" \
                "$WORK_DIR/meta-data"
            ;;
        mkisofs)
            mkisofs -o "$OUTPUT_PATH" \
                -V cidata \
                -J -R \
                "$WORK_DIR/user-data" \
                "$WORK_DIR/meta-data"
            ;;
        xorrisofs)
            xorrisofs -o "$OUTPUT_PATH" \
                -V cidata \
                -J -R \
                -graft-points \
                "/user-data=$WORK_DIR/user-data" \
                "/meta-data=$WORK_DIR/meta-data"
            ;;
    esac

    if [[ ! -f "$OUTPUT_PATH" ]]; then
        log_error "ISO 创建失败"
        exit 1
    fi

    ISO_SIZE=$(du -h "$OUTPUT_PATH" | cut -f1)

    echo ""
    log_info "========================================="
    log_info "cidata ISO 创建成功！"
    log_info "========================================="
    log_info "文件: $OUTPUT_PATH"
    log_info "大小: $ISO_SIZE"
    echo ""
    log_info "使用方法："
    echo "  1. 创建 VirtualBox 虚拟机（双网卡 + 25GB 磁盘）"
    echo "  2. 存储控制器同时挂载："
    echo "     - Ubuntu 22.04 Server ISO（主光驱）"
    echo "     - $OUTPUT_ISO（次光驱，cidata 卷标）"
    echo "  3. 启动虚拟机，需手动确认 autoinstall"
    echo ""
    echo "  提示：使用 -U 参数指定 Ubuntu ISO 可生成单文件自动安装 ISO，跳过确认"
    echo ""
    echo "  安装用户: $USERNAME"
    echo "  课程用户: cuc"
    echo "  主机名:   $HOSTNAME"
    if [[ -n "$SSH_KEY_LINE" ]]; then
        echo "  SSH 公钥: 已注入到 /home/cuc/.ssh/authorized_keys"
    else
        log_warn "未注入 SSH 公钥（使用 -k 参数指定公钥文件）"
    fi
fi
