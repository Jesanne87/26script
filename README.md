# 🚀 JsPhantom Xray VPN Script

**All-in-One Xray VPN Management Script**

Script pengurusan Xray untuk VPS yang direka supaya pemasangan, pengurusan akaun dan monitoring server lebih mudah melalui menu terminal.

---

## ✨ Main Features

### 👤 Account Management
- Create / Delete / Extend VPN account
- Support **VLESS & VMESS**
- Auto generate UUID & configuration link
- Username confirmation sebelum account dibuat
- Account expiry management
- Auto delete expired account
- View active / registered accounts

### 🛡️ Account Control
- **IP / Multi-Login Limit**
- **Traffic Quota (GB)**
- Auto Lock apabila melebihi limit
- Auto Unlock selepas tempoh lock
- Manual Lock / Unlock
- Reset Usage
- Edit IP Limit
- List account status
- Policy management per user
- Designed supaya lock/unlock user **tidak perlu restart keseluruhan Xray**

### 📊 Monitoring & Diagnostic
- Monitor user login & IP
- Account usage monitoring
- Xray status
- Nginx status
- Account Control status
- System diagnostic
- Detect configuration / service problems
- Server resource monitoring

### ⚡ Xray & Network
- Xray Core management
- VLESS WebSocket
- VLESS XHTTP
- VMESS WebSocket
- Nginx reverse proxy
- BBR & network optimization
- DNS optimization / caching support
- Cloudflare WARP routing support

### 🧠 Smart Protection
- Multi-login detection
- ISP / IP detection support
- Automatic account enforcement
- Account Control timer/service
- Avoid unnecessary Xray restart to reduce user disconnection

### 🧹 Automatic Maintenance
- Auto delete expired users
- Automatic service checking
- Log management
- Scheduled maintenance support
- Nginx memory protection / monitoring

### 🤖 Telegram Integration
- Telegram Bot configuration
- Save newly created account information to Telegram
- Easier account reference & recovery
- Backup notification support

### 💾 Backup & Restore
- Server configuration backup
- Restore VPN configuration
- Telegram backup support
- Easier VPS migration
- Domain/configuration migration support

---

## 🖥️ Supported OS

Recommended:

- Debian 11 / 12 / 13
- Ubuntu Server

> Fresh VPS installation is recommended.

---

## 🔄 Update VPS

### Debian

```bash
apt update -y && apt upgrade -y && apt dist-upgrade -y && reboot
```

### Ubuntu

```bash
apt-get update && apt-get upgrade -y && apt dist-upgrade -y && update-grub && reboot
```

---

## 🔑 Enable Root Access

```bash
wget https://raw.githubusercontent.com/Jesanne87/Root-Access/main/rootpass.sh
chmod +x rootpass.sh
./rootpass.sh
```

---

## 🚀 Installation

Login VPS sebagai **root**, kemudian jalankan:

```bash
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1

apt update
apt install -y bzip2 gzip coreutils screen curl wget

wget https://raw.githubusercontent.com/Jesanne87/26script/main/xray.sh
chmod +x xray.sh
sed -i -e 's/\r$//' xray.sh
./xray.sh
```

---

## ⭐ Highlight Latest Version

**JsPhantom** kini bukan sekadar installer Xray.

Ia merangkumi:

**VPN Account Management + Account Control + Multi-Login Protection + Traffic Quota + Auto Expiry + Monitoring + Backup + Telegram + Network Optimization**

Semuanya direka untuk diurus melalui menu terminal yang mudah.

---

## 👨‍💻 Developer

**JsPhantom**

GitHub: **Jesanne87**

---

> ⚠️ Gunakan script ini hanya pada server dan rangkaian yang anda mempunyai kebenaran untuk urus.
