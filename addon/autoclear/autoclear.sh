#!/bin/bash
OS=$(lsb_release -si)
VER=$(lsb_release -sr)
if [ "$OS" == "Ubuntu" ] && [ $(echo "$VER >= 20.04" | bc) -eq 1 ]; then
wget -q -O /usr/bin/menu "https://raw.githubusercontent.com/Jesanne87/combo/main/menu/menu_ubuntu.sh"; chmod +x /usr/bin/menu
elif [ "$OS" == "Debian" ] && [ $(echo "$VER >= 10" | bc) -eq 1 ]; then
wget -q -O /usr/bin/menu "https://raw.githubusercontent.com/Jesanne87/combo/main/menu/menu.sh"; chmod +x /usr/bin/menu
fi
wget -q -O /usr/bin/autoclear-menu "https://raw.githubusercontent.com/Jesanne87/combo/main/addon/autoclear/autoclear-menu.sh"; chmod +x /usr/bin/autoclear-menu
wget -q -O /usr/bin/auto-clear-ram "https://raw.githubusercontent.com/Jesanne87/combo/main/addon/autoclear/auto-clear-ram.sh"; chmod +x /usr/bin/auto-clear-ram
wget -q -O /home/autoclear.conf "https://raw.githubusercontent.com/Jesanne87/combo/main/addon/autoclear/autoclear.conf"; chmod +x /home/autoclear.conf
wget -q -O /etc/systemd/system/auto-clear-ram.service "https://raw.githubusercontent.com/Jesanne87/combo/main/addon/autoclear/auto-clear-ram.service"
systemctl enable auto-clear-ram
systemctl start auto-clear-ram
rm -f autoclear.sh
clear
