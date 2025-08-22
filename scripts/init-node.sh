#!/bin/bash
set -e

echo "🚀 开始初始化节点..."

# 1️⃣ 创建模型与音频目录
echo "📁 创建挂载目录..."
mkdir -p /opt/models/llama
mkdir -p /opt/audio

# 2️⃣ 下载或复制示例模型与音频文件（可替换为实际路径）
echo "📦 准备模型与音频文件..."
curl -o /opt/models/llama/ggml-model.bin https://your-storage.example.com/models/ggml-model.bin
curl -o /opt/audio/input.wav https://your-storage.example.com/audio/sample.wav
touch /opt/audio/output.txt

# 3️⃣ 安装 Docker & Docker Compose（如未安装）
if ! command -v docker &> /dev/null; then
  echo "🐳 安装 Docker..."
  apt update && apt install -y docker.io docker-compose
fi

# 4️⃣ 部署模型服务容器
echo "🔧 启动模型服务容器..."
mkdir -p /opt/vpn-ai-deploy/docker
cp ./docker-compose.yml /opt/vpn-ai-deploy/docker/
docker compose -f /opt/vpn-ai-deploy/docker/docker-compose.yml up -d

# 5️⃣ 初始化 VPN 客户端配置
echo "🔐 配置 VPN 客户端..."
mkdir -p /etc/openvpn/client/YYC
cp ./certs/* /etc/openvpn/client/YYC/
cp ./YYC.ovpn /etc/openvpn/client/YYC/YYC.ovpn
chmod 600 /etc/openvpn/client/YYC/client.key

# 6️⃣ 注册 systemd 服务与定时器
echo "⚙️ 注册 systemd 服务..."
cp ./systemd/*.service /etc/systemd/system/
cp ./systemd/*.timer /etc/systemd/system/
systemctl daemon-reexec
systemctl enable vpn-client
systemctl enable vpn-health.timer
systemctl start vpn-client
systemctl start vpn-health.timer

# 7️⃣ 输出部署状态
echo "✅ 节点初始化完成！"
echo "📡 VPN 状态：$(ip a | grep tun0 || echo '未连接')"
echo "🧠 模型服务容器：$(docker ps --format '{{.Names}} - {{.Status}}')"
