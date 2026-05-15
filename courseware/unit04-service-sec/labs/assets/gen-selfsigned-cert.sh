#!/bin/bash
# 生成自签名 TLS 证书（用于开发/测试环境）
# 用途：为 Nginx HTTPS 配置提供证书
#
# 使用方法：
#   bash gen-selfsigned-cert.sh
# 证书生成在 ~/certs/ 目录下：
#   cert.pem — 证书文件
#   key.pem  — 私钥文件

set -euo pipefail

CERT_DIR="$HOME/certs"
mkdir -p "$CERT_DIR"

openssl req -x509 -newkey rsa:2048 \
  -keyout "$CERT_DIR/key.pem" \
  -out "$CERT_DIR/cert.pem" \
  -days 365 -nodes \
  -subj "/CN=localhost"

echo "证书已生成："
echo "  证书: $CERT_DIR/cert.pem"
echo "  私钥: $CERT_DIR/key.pem"
echo ""
echo "Nginx 配置参考："
echo "  ssl_certificate     $CERT_DIR/cert.pem;"
echo "  ssl_certificate_key $CERT_DIR/key.pem;"
