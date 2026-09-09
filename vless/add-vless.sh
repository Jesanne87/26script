#!/bin/bash
MYIP=$(wget -qO- icanhazip.com/ip | tr -d '[:space:]')

if curl -fsSL https://cdn.jsdelivr.net/gh/msi8888/allow@main/access2 | grep -Fxq "$MYIP"; then
    echo -e "${NC}${GB}Permission Accepted...${NC}"
else
    clear
    echo -e "${NC}${RB}Permission Denied!${NC}"
    echo -e "Please Contact ${GB}Admin${NC}"
    echo -e "Telegram :t.me/JsPhantom"
    exit 1
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
PLE='\033[0;35m'
masa="$(date +"%Y-%m-%d %T")"
cname="$(cat /home/cname)"
cname2="$(cat /home/cname2)"
clear
MYIP=$(curl -sS ipv4.icanhazip.com)
domain=$(cat /usr/local/etc/xray/domain)
until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
echo -e "${BB}┌─────────────────────────────────────────────────┐${NC}" 
echo -e "${BB}│${NC}           ───[ Add Vless Account ]───           ${BB}│${NC}    " 
echo -e "${BB}└─────────────────────────────────────────────────┘${NC}"
read -rp "User: " -e user
CLIENT_EXISTS=$(grep -w $user /usr/local/etc/xray/config.json | wc -l)
if [[ ${CLIENT_EXISTS} == '1' ]]; then
clear
echo -e "${BB}┌─────────────────────────────────────────────────┐${NC}" 
echo -e "${BB}│${NC}           ───[ Add Vless Account ]───           ${BB}│${NC}    " 
echo -e "${BB}└─────────────────────────────────────────────────┘${NC}"
echo -e "${YB}A client with the specified name was already created, please choose another name.${NC}"
echo -e "${BB}——————————————————————————————————————————————————${NC}"
read -n 1 -s -r -p "Press any key to back on menu"
add-vless
fi
done
read -p "UUID : " id
uuid=$id
if [[ $id == "" ]]; then
uuid=$(cat /proc/sys/kernel/random/uuid)
fi
read -p "Expired (days): " masaaktif
exp=`date -d "$masaaktif days" +"%Y-%m-%d %T"`
echo ""
echo "1. VLESS WS"
echo "2. VLESS XHTTP"
read -rp "Choose: " pilih
if [[ $pilih == "1" ]]; then

sed -i '/#vless$/a\#= '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/config.json

sed -i '/#vless-grpc$/a\#gr '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/config.json

elif [[ $pilih == "2" ]]; then

sed -i '/#xvless$/a\#= '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/config.json

fi
vlesslink1="vless://$uuid@$domain:443?path=/vless&security=tls&encryption=none&host=$domain&type=ws&sni=$domain#$user$exp"
vlesslink2="vless://$uuid@$domain:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp"
vlesslink3="vless://$uuid@$domain:443?security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=$domain#$user$exp"
vlesslink25="vless://$uuid@$domain:80?path=/vless&security=none&encryption=none&host=pmsc.pubgmobile.com&type=ws#$user$exp@Umo"
vlesslink26="vless://$uuid@172.66.40.170:80?path=/vless&security=none&encryption=none&host=cdn.opensignal.com.$domain&type=ws#$user$exp@Umo"
vlesslink4="vless://$uuid@biorecovery.com:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@Umo"
vlesslink5="vless://$uuid@$MYIP:443?path=/vless&security=tls&encryption=none&host=pmsc.pubgmobile.com&type=ws&sni=pmsc.pubgmobile.com#$user$exp@Umo"
vlesslink6="vless://$uuid@yes.hate-me.eu.org:80?path=wss://$domain/vless&security=none&encryption=none&host=cdn.who.int&type=ws#$user$exp@Yes"
vlesslink7="vless://$uuid@104.17.147.22:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@Yes"
vlesslink8="vless://$uuid@nga.celcomdigi.com.$domain:80?path=/vless&security=none&encryption=none&host=nga.celcomdigi.com&type=ws#$user$exp@Clcom"
vlesslink9="vless://$uuid@104.17.148.22:80?path=/vless&security=none&encryption=none&host=www.speedtest.net.$domain&type=ws#$user$exp@Clcom2"
vlesslink10="vless://$uuid@biruls1.u-pro.fun:80?path=/xvless&security=none&encryption=none&host=$domain&type=xhttp#$user$exp@Celcom"
vlesslink11="vless://$uuid@codecademy.com:80?path=/vless&security=none&encryption=none&host=silent-auth.u.com.my.$domain&type=ws#$user$exp$2in1"
vlesslink12="vless://$uuid@api-faceid.maxis.com.my.$domain:443?path=/vless&security=tls&encryption=none&host=www.mosti.gov.my&type=ws&sni=www.mosti.gov.my#$user$exp@MaxExp"
vlesslink13="vless://$uuid@162.159.134.61:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@DG3mb"
vlesslink14="vless://$uuid@m.google.com.my.$domain:80?path=/vless&security=none&encryption=none&host=api.instagram.com&type=ws#$user$exp@DGsosial"
vlesslink15="vless://$uuid@104.18.20.212:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@DGexp"
vlesslink16="vless://$uuid@$domain:443?path=/vless&security=tls&encryption=none&host=sso.pokemon.com&type=ws&sni=sso.pokemon.com#$user$exp@DGPoke"
vlesslink17="vless://$uuid@104.17.10.12:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@Unifi"
vlesslink18="vless://$uuid@$MYIP:443?path=/vless&security=tls&encryption=none&host=esports.pubgmobile.com.esports.mobilelegends.com&type=ws&sni=esports.pubgmobile.com.esports.mobilelegends.com#$user$exp@YdoAddon"
vlesslink19="vless://$uuid@$MYIP:443?path=/vless&security=tls&encryption=none&host=www.opensignal.com&type=ws&sni=www.opensignal.com#$user$exp@Uni5gWOW"
vlesslink20="vless://$uuid@$domain:80?path=/vless&security=none&encryption=none&host=yoodo.zendesk.com&type=ws#$user$exp@yodoo"
vlesslink24="vless://$uuid@104.17.113.188:80?path=/vless&security=none&encryption=none&host=cdn.who.int.$domain&type=ws#$user$exp@Yes"
vlesslink27="vless://$uuid@cdn.opensignal.com:8080?path=/xvless&security=none&encryption=none&host=support.opensignal.com.$domain&type=xhttp#$user$exp@Maxis"
vlesslink30="vless://$uuid@$MYIP:443?path=/vless&security=tls&encryption=none&host=cdn.opensignal.com&type=ws&sni=cdn.opensignal.com#$user$exp@Uni5gWOW2"
vlesslink31="vless://$uuid@172.66.43.86:8880?path=/xvless&security=none&encryption=none&host=cdn.opensignal.com.$domain&type=xhttp#$user$exp@Maxis2"
#######CDN Config
vlesslink21="vless://$uuid@speedtest.net:443?path=/vless&security=tls&encryption=none&host=$cname&type=ws&sni=speedtest.net#$user$exp@MCDU"
vlesslink22="vless://$uuid@151.101.2.219:443?path=/vless&security=tls&encryption=none&host=$cname&type=ws&sni=151.101.2.219#$user$exp@MCDU2"
vlesslink28="vless://$uuid@speedtest.net:80?path=/vless&security=none&encryption=none&host=$cname&type=ws#$user$exp@MCDU3"
vlesslink23="vless://$uuid@api-gateway-global.viu.com.$domain:80?path=/vless&security=none&encryption=none&host=api-gateway-global.viu.com&type=ws#$user$exp@MaxTV"
vlesslink29="vless://$uuid@ookla.com:80?path=/vless&security=none&encryption=none&host=$cname2&type=ws#$user$exp@SBH2"
cat <<EOF >>"/var/www/html/vless/all/${user}.txt"
vless://$uuid@$domain:80?path=/vless&security=none&encryption=none&host=pmsc.pubgmobile.com&type=ws#$user$exp@Umo
vless://$uuid@$domain:443?path=/vless&security=tls&encryption=none&host=pmsc.pubgmobile.com&type=ws&sni=pmsc.pubgmobile.com#$user$exp@Umo
vless://$uuid@$MYIP:443?path=/vless&security=tls&encryption=none&host=pmsc.pubgmobile.com&type=ws&sni=pmsc.pubgmobile.com#$user$exp@Umo
vless://$uuid@yes.hate-me.eu.org:80?path=wss://$domain/vless&security=none&encryption=none&host=cdn.who.int&type=ws#$user$exp@Yes
vless://$uuid@yes.hate-me.eu.org:80?path=/vless&security=none&encryption=none&host=cdn.who.int.$domain&type=ws#$user$exp@Yes
vless://$uuid@104.18.203.232:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@Clcom
vless://$uuid@104.18.203.232:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@CLcom
vless://$uuid@104.18.203.232:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@Ydo_Tune
vless://$uuid@help.viu.com:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@MaxTV
vless://$uuid@api-faceid.maxis.com.my.$domain:443?path=/vless&security=tls&encryption=none&host=www.mosti.gov.my&type=ws&sni=www.mosti.gov.my#$user$exp@MaxExp
vless://$uuid@162.159.134.61:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@DG3mb
vless://$uuid@m.google.com.my.$domain:80?path=/vless&security=none&encryption=none&host=api.instagram.com&type=ws#$user$exp@DGsosial
vless://$uuid@api.useinsider.com:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@DGAPN
vless://$uuid@$domain:443?path=/vless&security=tls&encryption=none&host=sso.pokemon.com&type=ws&sni=sso.pokemon.com#$user$exp@DGPoke
vless://$uuid@104.17.10.12:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@Unifi
vless://$uuid@$domain:443?path=/vless&security=tls&encryption=none&host=esports.pubgmobile.com.esports.mobilelegends.com&type=ws&sni=esports.pubgmobile.com.esports.mobilelegends.com#$user$exp@YdoAddon
EOF
cat > /var/www/html/vless/vless-$user.txt << END
==========================
Vless WS (CDN) TLS
==========================
- name: Vless-$user
type: vless
server: ${domain}
port: 443
uuid: ${uuid}
cipher: auto
udp: true
tls: true
skip-cert-verify: true
servername: ${domain}
network: ws
ws-opts:
path: /vless
headers:
Host: ${domain}
==========================
Vless WS (CDN)
==========================
- name: Vless-$user
type: vless
server: ${domain}
port: 80
uuid: ${uuid}
cipher: auto
udp: true
tls: false
skip-cert-verify: false
network: ws
ws-opts:
path: /vless
headers:
Host: ${domain}
==========================
Vless gRPC (CDN)
==========================
- name: Vless-$user
server: $domain
port: 443
type: vless
uuid: $uuid
cipher: auto
network: grpc
tls: true
servername: $domain
skip-cert-verify: true
grpc-opts:
grpc-service-name: "vless-grpc"
==========================
Link Vless Account
==========================
Link TL   : vless://$uuid@$domain:443?path=/vless&security=tls&encryption=none&host=$domain&type=ws&sni=$domain#$user
==========================
Link NTLS : vless://$uuid@$domain:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user
==========================
Link gRPC : vless://$uuid@$domain:443?security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=$domain#$user
==========================
END
ISP=$(cat /usr/local/etc/xray/org)
CITY=$(cat /usr/local/etc/xray/city)
echo -e "${GB}[ INFO ]${NC} ${YB}Initiate Configuration Process...${NC}"
sleep 1
systemctl restart xray
sleep 1
clear
echo -e "${BB}┌─────────────────────────────────────────────────┐${NC}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}│${NC}             ───[ Vless Account ]───             ${BB}│${NC}    " | tee -a /user/log-vless-$user.txt
echo -e "${BB}└─────────────────────────────────────────────────┘${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Remarks       : ${user}" | tee -a /user/log-vless-$user.txt
echo -e "Domain        : ${domain}" | tee -a /user/log-vless-$user.txt
echo -e "IP/Host       : $MYIP" | tee -a /user/log-vless-$user.txt
echo -e "ISP           : $ISP" | tee -a /user/log-vless-$user.txt
echo -e "City          : $CITY" | tee -a /user/log-vless-$user.txt
echo -e "Wildcard      : (bug.com).${domain}" | tee -a /user/log-vless-$user.txt
echo -e "Port TLS      : 443" | tee -a /user/log-vless-$user.txt
echo -e "Port NTLS     : 80" | tee -a /user/log-vless-$user.txt
echo -e "Port gRPC     : 443" | tee -a /user/log-vless-$user.txt
echo -e "Alt Port TLS  : 2053, 2083, 2087, 2096, 8443" | tee -a /user/log-vless-$user.txt
echo -e "Alt Port NTLS : 8080, 8880, 2052, 2082, 2086, 2095" | tee -a /user/log-vless-$user.txt
echo -e "UUiD          : ${uuid}" | tee -a /user/log-vless-$user.txt
echo -e "Encryption    : none" | tee -a /user/log-vless-$user.txt
echo -e "Network       : Websocket, gRPC" | tee -a /user/log-vless-$user.txt
echo -e "Path WS       : /vless" | tee -a /user/log-vless-$user.txt
echo -e "Path XHTTP    : /xvless" | tee -a /user/log-vless-$user.txt
echo -e "ServiceName   : vless-grpc" | tee -a /user/log-vless-$user.txt
echo -e "Alpn          : h2, http/1.1" | tee -a /user/log-vless-$user.txt
echo -e "${BB}——————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link TLS      : ${vlesslink1}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}——————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link NTLS     : ${vlesslink2}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}——————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link gRPC     : ${vlesslink3}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}——————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}UMOBILE 1     ${NC}  : ${vlesslink25}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}UMOBILE 1Mbps ${NC}  : ${vlesslink4}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}UMOBILE New   ${NC}  : ${vlesslink26}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}UMO Openwrt   ${NC}  : ${vlesslink5}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${PLE}YES5g/4g 1${NC}     : ${vlesslink6}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${PLE}YES5g/4g 2${NC}     : ${vlesslink7}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${PLE}YES5g/4g EXP${NC}   : ${vlesslink24}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${BB}CELCOM Sedut   ${NC} : ${vlesslink8}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${BB}Celcom 3MBps${NC}    : ${vlesslink9}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${BB}Celcom 0 Basic${NC}  : ${vlesslink10}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}MAXIS NoSubs EXP${NC}: ${vlesslink12}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}DIGI Bypas 3MB${NC}  : ${vlesslink13}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}DG Sosial Unli  ${NC}: ${vlesslink14}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}Digi EXP  ${NC}      : ${vlesslink15}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}DG/Umo/DG 3/6mb${NC} : ${vlesslink11}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}Digi Pokemon${NC}    : ${vlesslink16}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}UNIFI Mobile${NC}    : ${vlesslink17}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}Yodoo Add on${NC}    : ${vlesslink18}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}UNI5gWOW${NC}        : ${vlesslink19}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}UNI5gWOW2${NC}       : ${vlesslink30}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}Yodoo Bypass 0GB${NC}: ${vlesslink20}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}4 IN 1${NC}          : ${vlesslink21}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}4 IN 1 Ver2${NC}     : ${vlesslink22}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}4 IN 1 Ver3${NC}     : ${vlesslink28}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}Maxis 1   ${NC}      : ${vlesslink27}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}Maxis 2${NC}         : ${vlesslink31}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}MAxis TV viu${NC}    : ${vlesslink23}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}MAxis SABAH 2${NC}   : ${vlesslink29}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Subs URL        : http://$domain:8000/vless/all/$user.txt" | tee -a /user/log-vless-$user.txt
echo -e "Format Clash    : http://$domain:8000/vless/vless-$user.txt" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Username      : $user" | tee -a /user/log-vless-$user.txt
echo -e "User ID       : $uuid" | tee -a /user/log-vless-$user.txt
echo -e "Server Name   : $domain" | tee -a /user/log-vless-$user.txt
echo -e "Created On    : $masa" | tee -a /user/log-vless-$user.txt
echo -e "Expired On    : $exp" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo " " | tee -a /user/log-vless-$user.txt
echo " " | tee -a /user/log-vless-$user.txt
echo " " | tee -a /user/log-vless-$user.txt
echo " "
echo " "
read -n 1 -s -r -p "Press any key to return to the menu"
clear
vless
