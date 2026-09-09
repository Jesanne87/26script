#!/bin/bash
GitUser="Jesanne87"
rm -rf xray.sh
clear
NC='\e[0m'
DEFBOLD='\e[39;1m'
RB='\e[31;1m'
GB='\e[32;1m'
YB='\e[33;1m'
BB='\e[34;1m'
MB='\e[35;1m'
CB='\e[35;1m'
WB='\e[37;1m'
export Server_URL="msi8888"

# =========================================
# JsPhantom Debian 13 Compatibility
# =========================================
if [ "$(id -u)" != "0" ]; then
    echo "Please run this script as root."
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

if [ -r /etc/os-release ]; then
    . /etc/os-release
else
    echo "Cannot detect operating system."
    exit 1
fi

case "${ID:-}" in
    debian)
        OS_FAMILY="debian"
        ;;
    ubuntu)
        OS_FAMILY="ubuntu"
        ;;
    *)
        echo "Unsupported OS: ${PRETTY_NAME:-unknown}"
        echo "Supported: Debian 11/12/13 and Ubuntu 20.04/22.04/24.04."
        exit 1
        ;;
esac

case "${VERSION_ID:-}" in
    11|12|13)
        [ "$OS_FAMILY" = "debian" ] || {
            echo "Unsupported Ubuntu version: ${VERSION_ID}"
            echo "Supported Ubuntu: 20.04, 22.04 and 24.04."
            exit 1
        }
        ;;
    20.04|22.04|24.04)
        [ "$OS_FAMILY" = "ubuntu" ] || {
            echo "Unsupported Debian version: ${VERSION_ID}"
            echo "Supported Debian: 11, 12 and 13."
            exit 1
        }
        ;;
    *)
        echo "Unsupported ${OS_FAMILY^} version: ${VERSION_ID:-unknown}"
        echo "Supported: Debian 11/12/13 and Ubuntu 20.04/22.04/24.04."
        exit 1
        ;;
esac

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

ARCH="$(dpkg --print-architecture 2>/dev/null || uname -m)"
case "$ARCH" in
    amd64|arm64|armhf)
        ;;
    *)
        echo "Warning: architecture $ARCH is not explicitly tested."
        ;;
esac

echo "Detected OS : ${PRETTY_NAME:-unknown}"
echo "OS Family   : ${OS_FAMILY}"
echo "Version     : ${VERSION_ID:-unknown}"

apt-get update -y
apt-get install -y ca-certificates curl wget git sudo cron lsb-release
# Check Register IP
MYIP=$(wget -qO- icanhazip.com/ip);
clear
echo "Checking VPS"
sleep 1
IZIN=$( curl https://raw.githubusercontent.com/msi8888/allow/main/access2 | grep "$MYIP" )
if [ "$MYIP" = "$IZIN" ]; then
clear
echo -e "${NC}${GB}Permission Accepted...${NC}"
sleep 2
else
clear
echo -e "${NC}${RB}Permission Denied!${NC}";
echo -e "Please Contact ${GB}Admin${NC}"
echo -e "Telegram :t.me/JsPhantom"
exit 1
fi
clear
secs_to_human() {
echo -e "${WB}Installation time : $(( ${1} / 3600 )) hours $(( (${1} / 60) % 60 )) minute's $(( ${1} % 60 )) seconds${NC}"
}
download_file() {
    local url="$1"
    local dest="$2"

    if ! wget -q -O "$dest" "$url"; then
        echo "[ ERROR ] Download failed: $url"
        rm -f "$dest"
        return 1
    fi

    if [ ! -s "$dest" ]; then
        echo "[ ERROR ] Downloaded file is empty: $dest"
        rm -f "$dest"
        return 1
    fi

    return 0
}

start=$(date +%s)
echo -e "[ ${GB}INFO${NC} ] Preparing the autoscript installation ~"
echo -e "[ ${GB}INFO${NC} ] Installation file is ready to begin !"
sleep 1
apt-get upgrade -y
apt-get full-upgrade -y
echo iptables-persistent iptables-persistent/autosave_v4 boolean false | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean false | debconf-set-selections
apt-get install -y socat netfilter-persistent iptables iptables-persistent
apt-get install -y vnstat lsof fail2ban
apt-get install -y curl sudo cron
apt-get install -y screen cron
apt-get install -y zip
apt-get install -y unzip
apt-get install -y htop
apt-get install -y jq
apt-get install -y bsdextrautils
apt-get install -y dnsutils
mkdir -p /backup
mkdir -p /user
mkdir -p /tmp
echo "The configuration is not set." > /user/current
mkdir -p /usr/local/etc/xray
rm -f /usr/local/etc/xray/city
rm -f /usr/local/etc/xray/org
rm -f /usr/local/etc/xray/timezone
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
curl -s ipinfo.io/city >> /usr/local/etc/xray/city
curl -s ipinfo.io/org | cut -d " " -f 2-10 >> /usr/local/etc/xray/org
curl -s ipinfo.io/timezone >> /usr/local/etc/xray/timezone
cd
clear
if curl -fsSL https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash; then
    apt-get update -y >/dev/null 2>&1
    apt-get install -y speedtest || echo "Speedtest installation skipped."
else
    echo "Speedtest repository unavailable. Skipping speedtest."
fi
clear
ln -fs /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime
apt-get install -y nginx
rm /var/www/html/*.html >> /dev/null 2>&1
rm /etc/nginx/sites-enabled/default >> /dev/null 2>&1
rm /etc/nginx/sites-available/default >> /dev/null 2>&1
mkdir -p /var/www/html/vmess
mkdir -p /var/www/html/vless
systemctl restart nginx
clear
touch /usr/local/etc/xray/domain
echo -e "${YB}Input Domain${NC} "
echo " "
read -rp "Input domain kamu : " -e dns
if [ -z "${dns:-}" ]; then
echo -e "Nothing input for domain!"
else
echo "$dns" > /usr/local/etc/xray/domain
echo "DNS=$dns" > /var/lib/dnsvps.conf
fi
clear
systemctl stop nginx
systemctl stop xray
domain=$(cat /usr/local/etc/xray/domain)
curl https://get.acme.sh | sh
source ~/.bashrc
cd .acme.sh
bash acme.sh --issue -d "$domain" --server letsencrypt --keylength ec-256 --fullchain-file /usr/local/etc/xray/fullchain.crt --key-file /usr/local/etc/xray/private.key --standalone --force
clear
echo -e "${GB}[ INFO ]${NC} ${YB}Setup Nginx & Xray Conf${NC}"
echo "UQ3w2q98BItd3DPgyctdoJw4cqQFmY59ppiDQdqMKbw=" > /usr/local/etc/xray/serverpsk
download_file "https://raw.githubusercontent.com/msi8888/hehe/main/config2026.json" "/usr/local/etc/xray/config.json" || exit 1
download_file "https://raw.githubusercontent.com/Jesanne87/Version/main/nginx.conf" "/etc/nginx/nginx.conf" || exit 1
download_file "https://raw.githubusercontent.com/Jesanne87/Version/main/xray.conf" "/etc/nginx/conf.d/xray.conf" || exit 1
systemctl restart nginx
systemctl restart xray
echo -e "${GB}[ INFO ]${NC} ${YB}Setup Done${NC}"
sleep 2
clear
iptables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
iptables -A FORWARD -m string --string "announce_peer" --algo bm -j DROP
iptables -A FORWARD -m string --string "find_node" --algo bm -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
iptables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -A FORWARD -m string --algo bm --string "torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce" -j DROP
iptables -A FORWARD -m string --algo bm --string "info_hash" -j DROP
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload
clear
cd /usr/bin
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Main Menu${NC}"
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/menu/menu.sh" "menu" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/menu/vmess.sh" "vmess" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/menu/vless.sh" "vless" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/menu/traffic.sh" "traffic" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/menu/warp-menu.sh" "warp-menu" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/menu/tweak-menu.sh" "tweak-menu" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/menu/lock_unlock_id.sh" "lock_unlock_id" || exit 1
sleep 0.5
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Menu Vmess${NC}"
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/vmess/add-vmess.sh" "add-vmess" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/vmess/del-vmess.sh" "del-vmess" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/vmess/extend-vmess.sh" "extend-vmess" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/vmess/trialvmess.sh" "trialvmess" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/vmess/cek-vmess.sh" "cek-vmess" || exit 1
sleep 0.5
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Menu Vless${NC}"
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/vless/add-vless.sh" "add-vless" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/vless/del-vless.sh" "del-vless" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/vless/extend-vless.sh" "extend-vless" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/vless/trialvless.sh" "trialvless" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/vless/cek-vless.sh" "cek-vless" || exit 1
sleep 0.5
sleep 0.5
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Menu Log${NC}"
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/log/log-vmess.sh" "log-vmess" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/log/log-vless.sh" "log-vless" || exit 1
sleep 0.5
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Other Menu${NC}"
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/other/xp.sh" "xp" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/other/dns.sh" "dns" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/other/certxray.sh" "certxray" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/other/xray_switcher.sh" "xray_switcher" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/other/about.sh" "about" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/other/clear-log.sh" "clear-log" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/other/changer.sh" "changer" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/other/nf.sh" "nf" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/other/telegram-backup.sh" "telegram-backup" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/other/dnsstatus.sh" "dnsstatus" || exit 1
download_file "https://raw.githubusercontent.com/Jesanne87/26script/main/addon/autoclear/autoclear-menu.sh" "autoclear-menu" || exit 1
download_file "https://raw.githubusercontent.com/Jesanne87/26script/main/addon/autoclear/auto-clear-ram.sh" "auto-clear-ram" || exit 1
download_file "https://raw.githubusercontent.com/Jesanne87/26script/main/addon/autoclear/autoclear.conf" "/home/autoclear.conf" || exit 1
chmod +x /home/autoclear.conf
download_file "https://raw.githubusercontent.com/Jesanne87/26script/main/bot/bot_menu.sh" "bot_menu" || exit 1
download_file "https://raw.githubusercontent.com/${GitUser}/26script/main/other/auto_logger.sh" "/usr/local/bin/auto_logger" || exit 1
echo -e "${GB}[ INFO ]${NC} ${YB}Download All Menu Done${NC}"
download_file "https://raw.githubusercontent.com/Jesanne87/26script/main/addon/autoclear/auto-clear-ram.service" "/etc/systemd/system/auto-clear-ram.service" || exit 1
download_file "https://raw.githubusercontent.com/Jesanne87/26script/main/other/auto_logger.service" "/etc/systemd/system/auto_logger.service" || exit 1
systemctl daemon-reload
systemctl enable auto-clear-ram
systemctl start auto-clear-ram
systemctl enable auto_logger
systemctl start auto_logger
sleep 2
chmod +x add-vmess
chmod +x del-vmess
chmod +x extend-vmess
chmod +x trialvmess
chmod +x cek-vmess
chmod +x add-vless
chmod +x del-vless
chmod +x extend-vless
chmod +x trialvless
chmod +x cek-vless
chmod +x log-vmess
chmod +x log-vless
chmod +x menu
chmod +x vmess
chmod +x vless
chmod +x traffic
chmod +x xp
chmod +x dns
chmod +x certxray
chmod +x xray_switcher
chmod +x about
chmod +x clear-log
chmod +x changer
chmod +x nf
chmod +x telegram-backup
chmod +x warp-menu
chmod +x tweak-menu
chmod +x autoclear-menu
chmod +x auto-clear-ram
chmod +x bot_menu
chmod +x lock_unlock_id
chmod +x /usr/local/bin/auto_logger
cd
grep -qxF "0 4 * * * root reboot" /etc/crontab || echo "0 4 * * * root reboot" >> /etc/crontab
grep -qxF "*/15 * * * * root xp" /etc/crontab || echo "*/15 * * * * root xp" >> /etc/crontab
grep -qxF "*/3 * * * * root clear-log" /etc/crontab || echo "*/3 * * * * root clear-log" >> /etc/crontab
systemctl restart cron
cat > /root/.profile << END
if command -v bash >/dev/null 2>&1; then
if [ -f ~/.bashrc ]; then
. ~/.bashrc
fi
fi
mesg n || true
clear
menu
END
# Version
serverV=$( curl -sS https://raw.githubusercontent.com/Jesanne87/26script/main/version_check)
echo "$serverV" > /home/ver
# Update your DNS rental/controld expired date after install
echo "500828" > /home/exp
chmod 644 /root/.profile
clear
echo -e "${BB}—————————————————————————————————————————————————————————${NC}"
echo -e "              ${WB}Lite Script Modded BY JsPhantom${NC}"
echo -e "${BB}—————————————————————————————————————————————————————————${NC}"
echo -e "  ${WB}»»» Protocol Service «««  |  »»» Network Protocol «««${NC}  "
echo -e "${BB}—————————————————————————————————————————————————————————${NC}"
echo -e "  ${YB}- Vless${NC}                   ${WB}|${NC}  ${YB}- Websocket (CDN) non TLS${NC}"
echo -e "  ${YB}- Vmess${NC}                   ${WB}|${NC}  ${YB}- Websocket (CDN) TLS${NC}"
echo -e "  ${YB}- Trojan${NC}                  ${WB}|${NC}"
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "               ${WB}»»» Network Port Service «««${NC}             "
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "  ${YB}- HTTPS : 443, 2053, 2083, 2087, 2096, 8443${NC}"
echo -e "  ${YB}- HTTP  : 80, 8080, 8880, 2052, 2082, 2086, 2095${NC}"
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo ""
rm -f ./xray
secs_to_human "$(($(date +%s) - ${start}))"
echo ""
echo -e "${YB}[ WARNING ] reboot now ? (Y/N)${NC} "
read answer
if [ "$answer" == "${answer#[Yy]}" ] ;then
exit 0
else
reboot
fi
