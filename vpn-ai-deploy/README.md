# VPN AI 自动化部署脚本

自动化脚本打包为 `.sh` 文件清单的结构化方案，并附带一个部署模板，便于你快速初始化新节点或更新现有节点。你可以将这些脚本保存到一个 Git 仓库或打包为 `.tar.gz` 文件用于分发。

---

## 📁 文件清单结构

```plaintext
vpn-ai-deploy/
├── register-node.sh
├── renew-client-cert.sh
├── vpn-health-check.sh
├── model-health-check.sh
├── docker-compose.yml
├── README.md
└── templates/
    └── client.ovpn.template
```

---

## 🧩 脚本文件内容

### 1. `register-node.sh`

用于初始化 VPN 客户端配置并启动连接。

```bash
#!/bin/bash
# register-node.sh

VPN_NAME="YYC"
VPN_DIR="/etc/openvpn/client/$VPN_NAME"
CERT_SRC="./certs"

mkdir -p $VPN_DIR
cp $CERT_SRC/{client.crt,client.key,ca.crt,ta.key} $VPN_DIR/
chmod 600 $VPN_DIR/client.key

# 生成配置文件
envsubst < ./templates/client.ovpn.template > $VPN_DIR/$VPN_NAME.ovpn

systemctl restart openvpn@$VPN_NAME
ping -c 2 10.8.0.1
```

---

### 2. `renew-client-cert.sh`

用于服务端签发新证书并替换客户端证书。

```bash
#!/bin/bash
# renew-client-cert.sh

CLIENT_NAME="$1"
EASYRSA_DIR="/etc/openvpn/easy-rsa"

cd $EASYRSA_DIR
./easyrsa gen-req $CLIENT_NAME nopass
./easyrsa sign-req client $CLIENT_NAME

cp pki/issued/$CLIENT_NAME.crt /etc/openvpn/client/$CLIENT_NAME/client.crt
systemctl restart openvpn@$CLIENT_NAME
```

---

### 3. `vpn-health-check.sh`

定时检查 VPN 隧道是否可达，自动重连。

```bash
#!/bin/bash
# vpn-health-check.sh

VPN_IP="10.8.0.1"
LOG="/var/log/vpn-health.log"

if ! ping -c 2 $VPN_IP > /dev/null; then
  echo "$(date) VPN unreachable, restarting..." >> $LOG
  systemctl restart openvpn@YYC
else
  echo "$(date) VPN healthy." >> $LOG
fi
```

---

### 4. `model-health-check.sh`

检查模型服务是否在线，异常时自动重启容器。

```bash
#!/bin/bash
# model-health-check.sh

declare -A endpoints=(
  ["llama"]="http://localhost:11434/api"
  ["whisper"]="http://localhost:5000/"
  ["embedding"]="http://localhost:8000/"
)

for name in "${!endpoints[@]}"; do
  if ! curl -s --max-time 3 "${endpoints[$name]}" > /dev/null; then
    echo "$(date) $name DOWN, restarting..."
    docker restart $name
  fi
done
```

---

### 5. `docker-compose.yml`

部署所有模型服务容器。

```yaml
version: '3.8'
services:
  llama:
    image: ghcr.io/ggerganov/llama.cpp:latest
    ports: ["11434:11434"]
    volumes: ["./models:/models"]
    restart: always

  whisper:
    image: whispercpp/server:latest
    ports: ["5000:5000"]
    volumes: ["./audio:/audio"]
    restart: always

  embedding:
    image: sentence-transformers/server:latest
    ports: ["8000:8000"]
    restart: always
```

---

### 6. `templates/client.ovpn.template`

用于生成客户端配置文件，支持变量替换。

```ini
client
dev tun
proto udp
remote 8.152.195.33 1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca /etc/openvpn/client/$VPN_NAME/ca.crt
cert /etc/openvpn/client/$VPN_NAME/client.crt
key /etc/openvpn/client/$VPN_NAME/client.key
tls-auth /etc/openvpn/client/$VPN_NAME/ta.key 1
remote-cert-tls server
data-ciphers AES-256-GCM:AES-256-CBC
data-ciphers-fallback AES-256-CBC
auth SHA256
ping 10
ping-restart 60
verb 3
```

---

## 📦 部署模板建议

你可以将整个 `vpn-ai-deploy/` 文件夹打包：

```bash
tar -czvf vpn-ai-deploy.tar.gz vpn-ai-deploy/
```

然后在新节点上解压并执行：

```bash
tar -xzvf vpn-ai-deploy.tar.gz
cd vpn-ai-deploy
bash register-node.sh
```

---
