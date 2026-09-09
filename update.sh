#!/bin/bash
GitUser="Jesanne87"
red='\e[1;31m'
green='\e[0;32m'
purple='\e[0;35m'
orange='\e[0;33m'
NC='\e[0m'
DEFBOLD='\e[39;1m'
RB='\e[31;1m'
GB='\e[32;1m'
YB='\e[33;1m'
BB='\e[34;1m'
MB='\e[35;1m'
CB='\e[35;1m'
WB='\e[37;1m'
OS=$(lsb_release -si)
VER=$(lsb_release -sr)
#Style
fun_bar() {
    CMD[0]="$1"
    CMD[1]="$2"
    (
        [[ -e $HOME/fim ]] && rm $HOME/fim
        ${CMD[0]} -y >/dev/null 2>&1
        ${CMD[1]} -y >/dev/null 2>&1
        touch $HOME/fim
    ) >/dev/null 2>&1 &
    tput civis
    echo -ne "\033[0;33mDowloading Scripts \033[1;37m- \033[0;33m["
    while true; do
        for ((i = 0; i < 18; i++)); do
            echo -ne "\033[0;32m#"
            sleep 0.1s
        done
        [[ -e $HOME/fim ]] && rm $HOME/fim && break
        echo -e "\033[0;33m]"
        sleep 1s
        tput cuu1
        tput dl1
        echo -ne "\033[0;33mPlease Wait \033[1;37m- \033[0;33m["
    done
    echo -e "\033[0;33m]\033[1;37m -\033[1;32mDownload Complete !\033[1;37m"
    tput cnorm
    }
cd /usr/bin
rm -f add-vmess
rm -f del-vmess
rm -f extend-vmess
rm -f trialvmess
rm -f cek-vmess
rm -f add-vless
rm -f del-vless
rm -f extend-vless
rm -f trialvless
rm -f cek-vless
rm -f log-vmess
rm -f log-vless
rm -f menu
rm -f vmess
rm -f vless
rm -f traffic
rm -f xp
rm -f dns
rm -f certxray
rm -f xray_switcher
rm -f about
rm -f clear-log
rm -f changer
rm -f nf
rm -f telegram-backup
rm -f warp-menu
rm -f tweak-menu
rm -f autoclear-menu
rm -f auto-clear-ram
rm -f bot_menu
rm -f lock_unlock_id
rm -f /usr/local/bin/auto_logger
clear
echo -e "${GB}[ INFO ]${NC} ${YB}Files are currently being downloaded${NC}"
install_scripts () {
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Main Menu${NC}"
wget -q -O menu "https://raw.githubusercontent.com/${GitUser}/26script/main/menu/menu.sh"
wget -q -O vmess "https://raw.githubusercontent.com/${GitUser}/26script/main/menu/vmess.sh"
wget -q -O vless "https://raw.githubusercontent.com/${GitUser}/26script/main/menu/vless.sh"
wget -q -O traffic "https://raw.githubusercontent.com/${GitUser}/26script/main/menu/traffic.sh"
wget -q -O warp-menu "https://raw.githubusercontent.com/${GitUser}/26script/main/menu/warp-menu.sh"
wget -q -O tweak-menu "https://raw.githubusercontent.com/${GitUser}/26script/main/menu/tweak-menu.sh"
wget -q -O lock_unlock_id "https://raw.githubusercontent.com/${GitUser}/26script/main/menu/lock_unlock_id.sh"
sleep 0.5
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Menu Vmess${NC}"
wget -q -O add-vmess "https://raw.githubusercontent.com/${GitUser}/26script/main/vmess/add-vmess.sh"
wget -q -O del-vmess "https://raw.githubusercontent.com/${GitUser}/26script/main/vmess/del-vmess.sh"
wget -q -O extend-vmess "https://raw.githubusercontent.com/${GitUser}/26script/main/vmess/extend-vmess.sh"
wget -q -O trialvmess "https://raw.githubusercontent.com/${GitUser}/26script/main/vmess/trialvmess.sh"
wget -q -O cek-vmess "https://raw.githubusercontent.com/${GitUser}/26script/main/vmess/cek-vmess.sh"
sleep 0.5
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Menu Vless${NC}"
wget -q -O add-vless "https://raw.githubusercontent.com/${GitUser}/26script/main/vless/add-vless.sh"
wget -q -O del-vless "https://raw.githubusercontent.com/${GitUser}/26script/main/vless/del-vless.sh"
wget -q -O extend-vless "https://raw.githubusercontent.com/${GitUser}/26script/main/vless/extend-vless.sh"
wget -q -O trialvless "https://raw.githubusercontent.com/${GitUser}/26script/main/vless/trialvless.sh"
wget -q -O cek-vless "https://raw.githubusercontent.com/${GitUser}/26script/main/vless/cek-vless.sh"
sleep 0.5
sleep 0.5
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Menu Log${NC}"
wget -q -O log-vmess "https://raw.githubusercontent.com/${GitUser}/26script/main/log/log-vmess.sh"
wget -q -O log-vless "https://raw.githubusercontent.com/${GitUser}/26script/main/log/log-vless.sh"
sleep 0.5
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Other Menu${NC}"
wget -q -O xp "https://raw.githubusercontent.com/${GitUser}/26script/main/other/xp.sh"
wget -q -O dns "https://raw.githubusercontent.com/${GitUser}/26script/main/other/dns.sh"
wget -q -O certxray "https://raw.githubusercontent.com/${GitUser}/26script/main/other/certxray.sh"
wget -q -O xray_switcher "https://raw.githubusercontent.com/${GitUser}/26script/main/other/xray_switcher.sh"
wget -q -O about "https://raw.githubusercontent.com/${GitUser}/26script/main/other/about.sh"
wget -q -O clear-log "https://raw.githubusercontent.com/${GitUser}/26script/main/other/clear-log.sh"
wget -q -O changer "https://raw.githubusercontent.com/${GitUser}/26script/main/other/changer.sh"
wget -q -O nf "https://raw.githubusercontent.com/${GitUser}/26script/main/other/nf.sh"
wget -q -O telegram-backup "https://raw.githubusercontent.com/${GitUser}/26script/main/other/telegram-backup.sh"
wget -q -O dnsstatus "https://raw.githubusercontent.com/${GitUser}/26script/main/other/dnsstatus.sh"
wget -q -O autoclear-menu "https://raw.githubusercontent.com/Jesanne87/26script/main/addon/autoclear/autoclear-menu.sh"
wget -q -O auto-clear-ram "https://raw.githubusercontent.com/Jesanne87/26script/main/addon/autoclear/auto-clear-ram.sh"
wget -q -O /home/autoclear.conf "https://raw.githubusercontent.com/Jesanne87/26script/main/addon/autoclear/autoclear.conf"; chmod +x /home/autoclear.conf
wget -q -O bot_menu "https://raw.githubusercontent.com/Jesanne87/26script/main/bot/bot_menu.sh"
wget -q -O /usr/local/bin/auto_logger "https://raw.githubusercontent.com/${GitUser}/26script/main/other/auto_logger.sh"
echo -e "${GB}[ INFO ]${NC} ${YB}Download All Menu Done${NC}"
wget -q -O /etc/systemd/system/auto-clear-ram.service "https://raw.githubusercontent.com/Jesanne87/26script/main/addon/autoclear/auto-clear-ram.service"
wget -q -O /etc/systemd/system/auto_logger.service "https://raw.githubusercontent.com/Jesanne87/26script/main/other/auto_logger.service"
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
chmod +x /usr/bin/local/auto_logger
rm -f /root/update.sh
rm -f /home/ver
sleep 1
systemctl daemon-reload
systemctl enable auto-clear-ram
systemctl start auto-clear-ram
systemctl enable auto_logger
systemctl start auto_logger
version_check=$( curl -sS https://raw.githubusercontent.com/Jesanne87/combo/main/version_check)
echo "$version_check" >> /home/ver
clear
sleep 1
echo -e "[${green}INFO${NC}] The update file has been successfully installed!"
sleep 1.5
menu
