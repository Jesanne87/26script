## 🔄 Update & Upgrade Your VPS (Debian 10 & 11)
```bash
apt update -y && apt upgrade -y && apt dist-upgrade -y && reboot
```

## 🔄 Update & Upgrade Your VPS (Ubuntu 18.04 & 20.04)
```bash
apt-get update && apt-get upgrade -y && apt dist-upgrade -y && update-grub && sleep 2 && reboot
```

## 🔑 Root Access
```bash
wget https://raw.githubusercontent.com/Jesanne87/Root-Access/main/rootpass.sh && chmod +x rootpass.sh && ./rootpass.sh
```

## 🚀 INSTALLATION SCRIPT
```bash
sysctl -w net.ipv6.conf.all.disable_ipv6=1 && sysctl -w net.ipv6.conf.default.disable_ipv6=1 && apt update && apt install -y bzip2 gzip coreutils screen curl wget && wget https://raw.githubusercontent.com/Jesanne87/26script/main/xray.sh && chmod +x xray.sh && sed -i -e 's/\r$//' xray.sh && ./xray.sh
```
