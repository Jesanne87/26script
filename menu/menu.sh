#!/bin/bash
MYIP=$(curl -s https://icanhazip.com)

if curl -fsSL https://cdn.jsdelivr.net/gh/msi8888/allow@main/access2 | grep -Fxq "$MYIP"; then
    echo "Permission Accepted"
else
    echo "Permission Denied"
fi
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
PB='\e[0;35m'
LG='\033[37m'
IPVPS=$(curl -s ipinfo.io/ip)
tram=$(free -m | awk 'NR==2 {print $2}')
uram=$(free -m | awk 'NR==2 {print $3}')
fram=$(free -m | awk 'NR==2 {print $4}')
xray_service=$(systemctl status xray | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
nginx_service=$(systemctl status nginx | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
autoclear_service=$(systemctl status auto-clear-ram | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
cek_user_login_bot=$(systemctl status cek_user_login_bot | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
check_usage_bot=$(systemctl status check_usage_bot | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
#warp_service=$(systemctl status warp-svc | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
#wireproxy=$(systemctl is-active wireproxy | awk '/active/{print "active"}')
if [[ $xray_service == "running" ]]; then
status_xray="${WB}[${GB}ON${WB}]${NC}"
else
status_xray="${WB}[${RB}OFF${WB}]${NC}"
fi
if [[ $nginx_service == "running" ]]; then
status_nginx="${WB}[${GB}ON${WB}]${NC}"
else
status_nginx="${WB}[${RB}OFF${WB}]${NC}"
fi
if [[ $autoclear_service == "running" ]]; then
status_autoclear="${WB}[${GB}ON${WB}]${NC}"
else
status_autoclear="${WB}[${RB}OFF${WB}]${NC}"
fi
if systemctl status warp-svc &> /dev/null; then
status_warp="${WB}[${GB}ON${WB}]${NC}"
else
status_warp="${WB}[${RB}OFF${WB}]${NC}"
fi
#if [[ $warp_service == "running" ]]; then
#status_warp="${WB}[${GB}ON${WB}]${NC}"
#else
#status_warp="${WB}[${RB}OFF${WB}]${NC}"
#fi
if [ "$(systemctl is-active wireproxy)" = "active" ]; then
status_warp_wireproxy="${WB}[${GB}ON${WB}]${NC}"
else
status_warp_wireproxy="${WB}[${RB}OFF${WB}]${NC}"
fi
if [[ $cek_user_login_bot == "running" ]]; then
cek_user_login_bot="${GB}[ON]${NC}"
else
cek_user_login_bot="${RB}[OFF]${NC}"
fi
if [[ $check_usage_bot == "running" ]]; then
check_usage_bot="${GB}[ON]${NC}"
else
check_usage_bot="${RB}[OFF]${NC}"
fi
iface=$(ip route | grep '^default' | awk '{print $5}')
ttoday="$(vnstat -i "$iface" | grep "today" | awk '{print $8" "substr ($9, 1, 1)}')"
tmon="$(vnstat -m | grep `date +"%Y-%m"` | awk '{print $8" "substr ($9, 1 ,3)}')" #Ubuntu
domain=$(cat /usr/local/etc/xray/domain)
#ISP DETECTION
ORG_FILE="/usr/local/etc/xray/org"
ORG_IP="/usr/local/etc/xray/org.ip"

CURRENT_IP=$(curl -4 -s --max-time 5 icanhazip.com)

if [ -n "$CURRENT_IP" ]; then
    OLD_IP=$(cat "$ORG_IP" 2>/dev/null)

    if [ "$CURRENT_IP" != "$OLD_IP" ] || [ ! -s "$ORG_FILE" ]; then
        NEW_ORG=$(curl -4 -s --max-time 5 ipinfo.io/org | cut -d " " -f 2-10)

        if [ -n "$NEW_ORG" ]; then
            echo "$NEW_ORG" > "$ORG_FILE"
            echo "$CURRENT_IP" > "$ORG_IP"
        fi
    fi
fi
ISP=$(cat "$ORG_FILE" 2>/dev/null)
CITY=$(cat /usr/local/etc/xray/city)
WKT=$(cat /usr/local/etc/xray/timezone)
DATE=$(date -R | cut -d " " -f -4)
uptime=$(uptime -p | cut -d " " -f 2-10)
dns=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' /etc/resolv.conf | head -n 1)
#Status certificate
modifyTime=$(stat /root/.acme.sh/${domain}_ecc/${domain}.cer | sed -n '7,6p' | awk '{print $2" "$3" "$4" "$5}')
modifyTime1=$(date +%s -d "${modifyTime}")
currentTime=$(date +%s)
stampDiff=$(expr ${currentTime} - ${modifyTime1})
days=$(expr ${stampDiff} / 86400)
remainingDays=$(expr 90 - ${days})
tlsStatus=${remainingDays}
if [[ ${remainingDays} -le 0 ]]; then
	tlsStatus="expired"
fi
# Get the current timestamp
now=$(date +%s)

# Status DNS
haribulan="$(cat /home/exp 2>/dev/null)"

# Validate haribulan format
if ! date -d "$haribulan" +"%Y%m%d" &>/dev/null; then
    dns_status="⇲ ${YB}DNS status           ${WB}: ${RB}DNS Expiry Not Setup${NC}"
else
    # Convert expiration date to timestamp
    target=$(date -d "$haribulan" +%s 2>/dev/null)
    
    # Ensure target is valid
    if [[ -z "$target" || "$target" -le 0 ]]; then
        dns_status="⇲ ${YB}DNS status           ${WB}: ${RB}DNS Expiry Not Setup${NC}"
    else
        # Calculate remaining days
        hari=$(( (target - now) / 86400 ))

        if [[ $hari -le 0 ]]; then
            dns_status="⇲ ${YB}DNS status           ${WB}: ${GB}Unlimited ${NC}Duration"
        else
            dns_status="⇲ ${YB}DNS status           ${WB}: Expired in ${RB}${hari} ${NC}Days"
        fi
    fi
fi

# Status CDN (Fastly)
haribulan2="$(cat /home/exp2 2>/dev/null)"

# Validate haribulan2 format
if ! date -d "$haribulan2" +"%Y%m%d" &>/dev/null; then
    fastly_status="⇲ ${YB}CDN status           ${WB}: ${RB}CDN Expiry Not Setup${NC}"
else
    # Convert expiration date to timestamp
    target2=$(date -d "$haribulan2" +%s 2>/dev/null)

    # Ensure target2 is valid
    if [[ -z "$target2" || "$target2" -le 0 ]]; then
        fastly_status="⇲ ${YB}CDN status           ${WB}: ${RB}CDN Expiry Not Setup${NC}"
    else
        # Calculate remaining days
        hari2=$(( (target2 - now) / 86400 ))

        if [[ $hari2 -le 0 ]]; then
            fastly_status="⇲ ${YB}CDN status           ${WB}: ${GB}Unlimited ${NC}Duration${NC}"
        else
            fastly_status="⇲ ${YB}CDN status           ${WB}: Expired in ${RB}${hari2} ${NC}Days"
        fi
    fi
fi

#CDN Update
update_cdn() {
    local file=$1
    local cname_var=$2

    if [[ -f $file ]]; then
        eval $cname_var=\"$(cat $file)\"
    else
        echo "Not Found!" > $file
        eval $cname_var=\"${RB}Not found!${NC}\"
    fi
}

update_cdn "/home/cname" "cname"
update_cdn "/home/cname2" "cname2"

# TOTAL ACC CREATE
xray=$(grep -c -E "^#= |^#@ " "/usr/local/etc/xray/config.json")
# // script version
myver="$(cat /home/ver)"
# // script version check
serverV=$( curl -sS https://cdn.jsdelivr.net/gh/Jesanne87/combo@main/version_check)
# Xray Version
XRAY_BIN="/usr/local/bin/xray"
CURRENT_VER=$($XRAY_BIN version 2>/dev/null | head -n1 | awk '{print $2}')
function updatews(){
clear
echo -e "[ ${GB}INFO${NC} ] Check for Script updates . . ."
sleep 2
cd
wget -q -O /root/update.sh "https://raw.githubusercontent.com/Jesanne87/combo/main/update.sh" && chmod +x update.sh && ./update.sh
sleep 2
}

clear
echo -e ""
echo -e "${GB}╭═══════════════════════════════════════════════════════╮${NC}"
echo -e "${GB}├───────────────────────────────────────────────────────┤${NC}"
echo -e "${GB}│   ${YB}•••───[ Moded Script By ${RB}JsPhantom${NC} ${YB}@ 2023${NC}${YB} ]───•••    ${NC}${GB}│${NC}"
echo -e "${GB}╰═══════════════════════════════════════════════════════╯${NC}"
echo -e "${GB} ${WB}NGINX : ${NC}$status_nginx${WB} XRAY : ${NC}$status_xray${WB} WARP : ${NC}$status_warp ${BB}${NC}${WB}WireProxy : ${NC}$status_warp_wireproxy ${BB}${NC}"
echo -e "${GB} ${WB}AUTOCLEAR RAM : ${NC}$status_autoclear ${WB}BOT-LOGIN : ${NC}$cek_user_login_bot ${WB}BOT-USAGE : ${NC}$check_usage_bot${WB} ${NC}"
echo -e "${GB}╭───────────────────────────────────────────────────────╮${NC}"
echo -e "${GB}│             ${WB}───[ Server Information ]───${NC}              ${GB}│ ${NC}     "
echo -e "${GB}╰───────────────────────────────────────────────────────╯${NC}"
echo -e " ${LB}⇲ ${YB}Operating System${NC}     ${WB}: ${NC}$(hostnamectl | grep "Operating System" | awk '{$1=$2=""; print $0}' | sed 's/^ *//')${NC}"
echo -e " ${LB}⇲ ${YB}Service Provider${NC}     ${WB}: $ISP${NC}"
echo -e " ${LB}⇲ ${YB}Kernel	        ${WB}: ${WB}$(uname -r)${NC}"
echo -e " ${LB}⇲ ${YB}City${NC}                 ${WB}: $CITY${NC}"
echo -e " ${LB}⇲ ${YB}Date${NC}                 ${WB}: $DATE${NC}"
echo -e " ${LB}⇲ ${YB}System Uptime${NC}        ${WB}: $uptime${NC}"
echo -e " ${LB}⇲ ${YB}Domain${NC}               ${WB}: ${PB}$domain${NC}"
echo -e " ${LB}⇲ ${YB}IP Address           ${WB}: ${NC}$IPVPS${NC}"
echo -e " ${LB}⇲ ${YB}Domain CDN           ${WB}: ${PB}${cname} ${NC}"
echo -e " ${LB}⇲ ${YB}Second Domain CDN    ${WB}: ${PB}${cname2} ${NC}"
echo -e " ${LB}⇲ ${YB}Xray Version         ${WB}: ${GB}$CURRENT_VER${NC}"
echo -e " ${LB}⇲ ${YB}Current DNS          ${WB}: ${NC}$dns${NC}"
echo -e " ${LB}⇲ ${YB}Certificate statuss  ${WB}: ${WB}Expired in ${RB}$tlsStatus ${NC}${WB}Days${NC}"
echo -e " ${LB}$dns_status          "
echo -e " ${LB}$fastly_status"
echo -e " ${LB}⇲ ${YB}Memory Usage         ${WB}: ${NC}${GB}$uram MB ${NC}/ ${RB}$tram ${WB}MB${NC}"
echo -e " ${LB}⇲ ${YB}Bandwidth Data Usage ${WB}: ${GB}$ttoday Daily${NC}/${RB}$tmon ${WB}Monthly${NC}"
echo -e " ${LB}⇲ ${YB}Total User Created${NC}${WB}   : ${PB}$xray${NC}"
if [[ $serverV > $myver ]]; then
echo -e " ${YB}UPDATE AUTOSCRIPT TO Ver ${GB}$serverV${NC} ${MB}[${NC}ok${MB}]${NC} Type ok TO Update "                 
up2u="updatews"
else
up2u="menu"
fi
echo -e "${GB}╭═══════════════════════════════════════════════════════╮${NC}"
echo -e "${GB}├───────────────────────────────────────────────────────┤${NC}"
echo -e "${GB}│                  ${WB}───[ Xray Menu ]───${NC}                  ${GB}│${NC} "
echo -e "${GB}├──────────────────────────┬────────────────────────────┤${NC}"
echo -e "${GB}│ ${MB}[${NC}01${MB}]${NC} ${YB}Vmess Menu${NC}          ${GB}│ ${MB}[${NC}02${MB}]${NC} ${YB}Vless Menu            ${GB}│${NC}"
echo -e "${GB}├──────────────────────────┴────────────────────────────┤${NC}"
echo -e "${GB}│                 ${WB}───[ System Menu ]───${NC}                 ${GB}│ ${NC}     "
echo -e "${GB}├──────────────────────────┬────────────────────────────┤${NC}"
echo -e "${GB}│ ${MB}[${NC}03${MB}]${NC} ${YB}Log Create Account${NC}  ${GB}│ ${MB}[${NC}10${MB}]${NC} ${YB}DNS Setting           ${GB}│${NC}"
echo -e "${GB}│ ${MB}[${NC}04${MB}]${NC} ${YB}Speedtest${NC}           ${GB}│ ${MB}[${NC}11${MB}]${NC} ${YB}Xray Switcher         ${GB}│${NC}"
echo -e "${GB}│ ${MB}[${NC}05${MB}]${NC} ${YB}Change Domain${NC}       ${GB}│ ${MB}[${NC}12${MB}]${NC} ${YB}Netflix Checker       ${GB}│${NC}"
echo -e "${GB}│ ${MB}[${NC}06${MB}]${NC} ${YB}Cert Acme.sh${NC}        ${GB}│ ${MB}[${NC}13${MB}]${NC} ${YB}WARP                  ${GB}│${NC}"
echo -e "${GB}│ ${MB}[${NC}07${MB}]${NC} ${YB}About Script        ${GB}│                            ${GB}│${NC}"
echo -e "${GB}│ ${MB}[${NC}08${MB}]${NC} ${YB}Check id Xray       ${GB}│                            ${GB}│${NC}"
echo -e "${GB}│ ${MB}[${NC}09${MB}]${NC} ${YB}Lock/Unlock ID      ${GB}│                            │${NC}"
echo -e "${GB}├──────────────────────────┴────────────────────────────┤${NC}"
echo -e "${GB}│                  ${WB}───[ Misc Menu ]───${NC}                  ${GB}│${NC} "
echo -e "${GB}├──────────────────────────┬────────────────────────────┤${NC}"
echo -e "${GB}│ ${MB}[${NC}97${MB}]${NC} ${YB}USER USAGE${NC}          ${GB}│ ${MB}[${NC}103${MB}]${NC} ${YB}Autoclear Menu       ${GB}│${NC}"
echo -e "${GB}│ ${MB}[${NC}98${MB}]${NC} ${YB}BACKUP PANEL${NC}        ${GB}│ ${MB}[${NC}104${MB}]${NC} ${YB}BOT Menu             ${GB}│${NC}"                         
echo -e "${GB}│ ${MB}[${NC}101${MB}]${NC} ${YB}DNS Update Status${NC}  ${GB}│                            ${GB}│${NC}"
echo -e "${GB}│ ${MB}[${NC}102${MB}]${NC} ${YB}TUNING PANEL ${NC}      ${GB}│                            ${GB}│${NC}"
echo -e "${GB}├──────────────────────────┴────────────────────────────┤${NC}"
echo -e "${GB}│   ${WB} ©${WB}Autoscripts Multiport/Dynamic Path Version ${GB}$myver${NC}    ${GB}│ ${NC}     "
echo -e "${GB}├───────────────────────────────────────────────────────┤${NC}"
echo -e "${GB}╰═══════════════════════════════════════════════════════╯${NC}"
echo -e ""
read -p " Select Menu :  "  opt
echo -e ""
case $opt in
1) clear ; vmess ;;
2) clear ; vless ;;
3) clear ; log-create ;;
4) clear ; speedtest ;;
5) clear ; dns ;;
6) clear ; certxray ;;
7) clear ; about ;;
8) clear ; log-vless ;;
9) clear ; lock_unlock_id ;;
10) clear ; changer ;;
11) clear ; xray_switcher ;;
12) clear ; nf ;;
13) clear ; warp-menu ;;
97) clear ; traffic ;;
98) clear ; telegram-backup ;;
101) clear ; dnsstatus ;;
102) clear ; tweak-menu ;;
103) clear ; autoclear-menu ;;
104) clear ; bot_menu ;;
ok) clear ; $up2u ;;
x) exit ;;
*)
    echo -e "\e[1;31mPlease enter an correct number\e[0m"
    sleep 1
    menu
    ;;
esac