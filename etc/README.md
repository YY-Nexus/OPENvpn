# 自动化脚本集成指南

自动化脚本集成进 GitHub Actions 和 systemd 服务，不仅能提升部署效率，还能实现持续运维与自愈机制。下面我为你分别展示两种集成方式：

---

## ⚙️ 一、GitHub Actions 集成（适用于远程部署与版本控制）

### ✅ 适用场景

适用于每个 TANS 节点本地运行脚本，实现系统启动时自动连接 VPN、启动模型服务，并通过定时任务检查服务健康状态，确保服务自愈和持续运行。

- 你将脚本和配置文件托管在 GitHub 仓库
- 每次 push 或 tag 都触发自动部署到远程 TANS 节点或阿里云服务端

### 📁 文件结构建议

```plaintext
.github/
└── workflows/
    └── deploy.yml
vpn-ai-deploy/
├── register-node.sh
├── renew-client-cert.sh
├── docker-compose.yml
├── vpn-health-check.sh
├── model-health-check.sh
```

### 🧩 示例 workflow：`.github/workflows/deploy.yml`

```yaml
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
        source: "vpn-ai-deploy/*"
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
          docker compose up -d

> 💡 你可以在 GitHub 仓库的 `Settings > Secrets` 中添加：
> - `TANS_HOST`：TANS 节点（如本地 NAS 服务器）的公网 IP 或内网 IP
> - `TANS_USER`：TANS 节点的 SSH 用户名（如 NAS 的登录用户）
> - `TANS_SSH_KEY`：用于登录 TANS 节点的 SSH 私钥内容
>
> 💡 如果阿里云服务器仅作为 VPN 跳板，无需配置其 SSH 信息到 Secrets。

---

## 🔁 二、systemd 服务集成（适用于本地节点自启动与自愈）

### ✅ 场景适用

- 每个 TANS 节点本地运行脚本
- 系统启动时自动连接 VPN、启动模型服务
- 定时检查健康状态并重启服务

### 📁 建议服务文件结构

```plaintext
/etc/systemd/system/
├── vpn-client.service
├── model-health.service
├── vpn-health.timer
├── vpn-health.service
```

---

### 🧩 示例：`vpn-client.service`

```ini
[Unit]
Description=OpenVPN Client YYC
After=network.target

[Service]
ExecStart=/usr/sbin/openvpn --config /etc/openvpn/client/YYC/YYC.ovpn
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

---

### 🧩 示例：`vpn-health.service`

```ini
[Unit]
Description=VPN Health Check

[Service]
Type=oneshot
ExecStart=/usr/local/bin/vpn-health-check.sh
```

---

### 🧩 示例：`vpn-health.timer`

```ini
[Unit]
Description=Run VPN Health Check Every 5 Minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

启用服务与定时器：

```bash
systemctl enable vpn-client
systemctl enable vpn-health.timer
systemctl start vpn-client
systemctl start vpn-health.timer
```

---
