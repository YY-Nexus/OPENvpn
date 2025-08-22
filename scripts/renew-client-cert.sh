#!/bin/bash
set -e

NODE_NAME="YYC"
CERT_PATH="/etc/openvpn/certs/$NODE_NAME/$NODE_NAME.crt"
EXPIRY_THRESHOLD=30  # 剩余天数阈值
REMOTE_CA="vpn-master.example.com"

# 获取证书过期时间
EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$CERT_PATH" | cut -d= -f2)
EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
NOW=$(date +%s)
REMAINING_DAYS=$(( (EXPIRY_TIMESTAMP - NOW) / 86400 ))

if [ "$REMAINING_DAYS" -lt "$EXPIRY_THRESHOLD" ]; then
  echo "[!] 证书即将过期（剩余 $REMAINING_DAYS 天），开始续签"
  scp root@$REMOTE_CA:/etc/openvpn/clients/$NODE_NAME.crt "$CERT_PATH"
  systemctl restart vpn-client
else
  echo "[✓] 证书有效（剩余 $REMAINING_DAYS 天）"
fi
