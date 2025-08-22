#!/bin/bash
set -e

SERVICE="vpn-client"
LOG="/var/log/vpn-health.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

echo "[$TIMESTAMP] 开始 VPN 健康检查" >> "$LOG"

# 检查 tun0 是否存在
if ip a | grep -q "tun0"; then
  echo "[$TIMESTAMP] VPN 正常运行" >> "$LOG"
else
  echo "[$TIMESTAMP] VPN 未连接，尝试重启服务" >> "$LOG"
  systemctl restart "$SERVICE"
fi
