#!/bin/bash
# =========================================
# Renew SSL Certificate via acme.sh
# =========================================

# Warna
NC='\e[0m'
DEFBOLD='\e[39;1m'
RB='\e[31;1m'
GB='\e[32;1m'
YB='\e[33;1m'
BB='\e[34;1m'
MB='\e[35;1m'
CB='\e[35;1m'
WB='\e[37;1m'

clear
echo -e "${GB}[ INFO ]${NC} ${YB}Starting SSL certificate renew...${NC}"
sleep 1

# Matikan nginx sementara
systemctl stop nginx

# Ambil domain
if [[ -f "/var/lib/dnsvps.conf" ]]; then
    domain=$(cut -d'=' -f2 < /var/lib/dnsvps.conf)
else
    echo -e "${RB}[ ERROR ]${NC} ${YB}Domain config not found (/var/lib/dnsvps.conf)!${NC}"
    exit 1
fi

# Check port 80 ada service lain jalan
Cek=$(lsof -i:80 -sTCP:LISTEN -t | head -n1)

if [[ -n "$Cek" ]]; then
    svc=$(ps -p "$Cek" -o comm=)
    echo -e "${RB}[ WARNING ]${NC} ${YB}Port 80 is used by service: $svc (PID: $Cek)${NC}"
    systemctl stop "$svc" 2>/dev/null || kill -9 "$Cek"
    sleep 1
    echo -e "${GB}[ INFO ]${NC} ${YB}Stopped $svc temporarily${NC}"
fi

# Renew cert dengan acme.sh
echo -e "${GB}[ INFO ]${NC} ${YB}Issuing/Renewing cert for domain: $domain${NC}"
/root/.acme.sh/acme.sh --issue -d "$domain" \
    --server letsencrypt \
    --keylength ec-256 \
    --fullchain-file /usr/local/etc/xray/fullchain.crt \
    --key-file /usr/local/etc/xray/private.key \
    --standalone --force

if [[ $? -ne 0 ]]; then
    echo -e "${RB}[ ERROR ]${NC} ${YB}Certificate renewal failed!${NC}"
    systemctl start nginx
    [[ -n "$svc" ]] && systemctl start "$svc"
    exit 1
fi

echo -e "${GB}[ INFO ]${NC} ${YB}Certificate successfully renewed${NC}"

# Simpan domain ke file Xray
echo "$domain" > /usr/local/etc/xray/domain

# Hidupkan balik service yang dihentikan
if [[ -n "$svc" ]]; then
    systemctl restart "$svc"
    echo -e "${GB}[ INFO ]${NC} ${YB}Service $svc restarted${NC}"
fi

# Hidupkan balik nginx
systemctl restart nginx
echo -e "${GB}[ INFO ]${NC} ${YB}Nginx restarted${NC}"

# Selesai
echo -e "${GB}[ INFO ]${NC} ${YB}All finished! SSL cert updated.${NC}"
echo ""
read -n 1 -s -r -p "Press any key to return to menu"
menu
