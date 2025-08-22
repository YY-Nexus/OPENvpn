#!/bin/bash
set -e

NODE_NAME="YYC"
VPN_CONF_DIR="/etc/openvpn/client/$NODE_NAME"
CERT_DIR="/etc/openvpn/certs/$NODE_NAME"
REMOTE_CA="vpn-master.example.com"
REMOTE_PORT=443

echo "[+] 注册节点：$NODE_NAME"

# 创建配置目录
mkdir -p "$VPN_CONF_DIR"
mkdir -p "$CERT_DIR"

# 拉取 CA 和客户端证书（可替换为 scp 或 curl）
scp root@$REMOTE_CA:/etc/openvpn/ca.crt "$CERT_DIR/"
scp root@$REMOTE_CA:/etc/openvpn/clients/$NODE_NAME.crt "$CERT_DIR/"
scp root@$REMOTE_CA:/etc/openvpn/clients/$NODE_NAME.key "$CERT_DIR/"
scp root@$REMOTE_CA:/etc/openvpn/clients/$NODE_NAME.ovpn "$VPN_CONF_DIR/$NODE_NAME.ovpn"

# 设置权限
chmod 600 "$CERT_DIR/$NODE_NAME.key"
chmod 644 "$CERT_DIR/$NODE_NAME.crt" "$CERT_DIR/ca.crt"
chmod 644 "$VPN_CONF_DIR/$NODE_NAME.ovpn"

echo "[✓] 节点注册完成，配置已就绪"
