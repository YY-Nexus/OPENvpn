## 🧱 项目结构清单（可直接打包为 ZIP）


OPENvpn/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── systemd/
│   ├── vpn-client.service
│   ├── vpn-health.service
│   ├── vpn-health.timer
│   ├── model-health.service
├── scripts/
│   ├── register-node.sh
│   ├── renew-client-cert.sh
│   ├── vpn-health-check.sh
│   ├── model-health-check.sh
├── docker/
│   └── docker-compose.yml
├── README.md
└── LICENSE

## 📘 README.md 内容（完整）


# OPENvpn 🚀

这是一个用于部署分布式 VPN + AI 节点的模板仓库，支持 GitHub Actions 自动部署与 systemd 本地服务管理。

## ✨ 功能亮点

- 自动注册节点并连接 VPN Mesh
- 定时健康检查与自愈机制（systemd + timer）
- 支持 Docker Compose 启动模型服务
- 自动续签客户端证书
- 一键部署到 TANS 节点或阿里云服务端

## 📦 快速开始

### 1. 克隆仓库并修改配置


git clone https://github.com/YY-Nexus/OPENvpn.git
cd OPENvpn


### 2. 安装 systemd 服务


sudo cp systemd/*.service /etc/systemd/system/
sudo cp systemd/*.timer /etc/systemd/system/
sudo systemctl daemon-reexec
sudo systemctl enable vpn-client
sudo systemctl enable vpn-health.timer
sudo systemctl start vpn-client
sudo systemctl start vpn-health.timer


### 3. 配置 GitHub Secrets

| Key             | 说明             |
|----------------|------------------|
| TANS_HOST     | 节点 IP 地址     |
| TANS_USER     | SSH 用户名       |
| TANS_SSH_KEY  | SSH 私钥内容     |



## 🛠 GitHub Actions 工作流：.github/workflows/deploy.yml


name: VPN-AI Deploy

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout repo
      uses: actions/checkout@v3
    - name: Copy files to remote node
      uses: appleboy/scp-action@v0.1.4
      with:
        host: ${{ secrets.TANS_HOST }}
        username: ${{ secrets.TANS_USER }}
        key: ${{ secrets.TANS_SSH_KEY }}
        source: "scripts/*"
        target: "/opt/vpn-ai-deploy"
    - name: Run deployment script remotely
      uses: appleboy/ssh-action@v0.1.10
      with:
        host: ${{ secrets.TANS_HOST }}
        username: ${{ secrets.TANS_USER }}
        key: ${{ secrets.TANS_SSH_KEY }}
        script: |
          cd /opt/vpn-ai-deploy
          bash register-node.sh
          docker compose -f ../docker/docker-compose.yml up -d

---

## 🧩 systemd 服务文件（简化版）

### `vpn-client.service`

[Unit]
Description=OpenVPN Client YYC
After=network.target

[Service]
ExecStart=/usr/sbin/openvpn --config /etc/openvpn/client/YYC/YYC.ovpn
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target


### `vpn-health.service`


[Unit]
Description=VPN Health Check

[Service]
Type=oneshot
ExecStart=/opt/vpn-ai-deploy/vpn-health-check.sh


### `vpn-health.timer`


[Unit]
Description=Run VPN Health Check Every 5 Minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target

---

语，如果你愿意，我可以直接把这些内容打包成一个 ZIP 清单（文本形式），或者继续帮你生成每个脚本的内容，比如 `register-node.sh`、`vpn-health-check.sh` 等。你想我接下来专注在哪一块？脚本？Docker Compose？还是直接生成打包命令？
