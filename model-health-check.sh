#!/bin/bash
set -e

SERVICE_NAME="ai-model"
LOG="/var/log/model-health.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

echo "[$TIMESTAMP] 检查模型服务状态" >> "$LOG"

# 检查容器是否运行
if ! docker ps | grep -q "$SERVICE_NAME"; then
  echo "[$TIMESTAMP] 模型服务未运行，尝试重启" >> "$LOG"
  docker compose -f /opt/vpn-ai-deploy/docker/docker-compose.yml up -d
else
  echo "[$TIMESTAMP] 模型服务正常运行" >> "$LOG"
fi
