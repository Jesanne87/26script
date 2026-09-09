#!/bin/bash
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
MYIP=$(curl -sS ipv4.icanhazip.com)
domain=$(cat /usr/local/etc/xray/domain)
user=trial-`echo $RANDOM | head -c4`
uuid=$(cat /proc/sys/kernel/random/uuid)
masaaktif=1
echo ""
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`
sed -i '/#vless$/a\#= '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#vless-grpc$/a\#gr '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/config.json
vlesslink1="vless://$uuid@$domain:443?path=/vless&security=tls&encryption=none&host=$domain&type=ws&sni=$domain#$user$exp"
vlesslink2="vless://$uuid@$domain:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp"
vlesslink3="vless://$uuid@$domain:443?security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=$domain#$user$exp"
vlesslink4="vless://$uuid@$domain:443?path=/vless&security=tls&encryption=none&host=pmsc.pubgmobile.com&type=ws&sni=pmsc.pubgmobile.com#$user$exp@Umo"
vlesslink5="vless://$uuid@$MYIP:443?path=/vless&security=tls&encryption=none&host=pmsc.pubgmobile.com&type=ws&sni=pmsc.pubgmobile.com#$user$exp@Umo"
vlesslink6="vless://$uuid@yes.hate-me.eu.org:80?path=wss://$domain/vless&security=none&encryption=none&host=cdn.who.int&type=ws#$user$exp@Yes"
vlesslink7="vless://$uuid@yes.hate-me.eu.org:80?path=/vless&security=none&encryption=none&host=cdn.who.int.$domain&type=ws#$user$exp@Yes"
vlesslink8="vless://$uuid@104.18.203.232:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@Clcom"
vlesslink9="vless://$uuid@104.18.203.232:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@Clcom"
vlesslink10="vless://$uuid@104.18.203.232:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@Ydo_Tune"
vlesslink11="vless://$uuid@help.viu.com:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$expMaxTV"
vlesslink12="vless://$uuid@api-faceid.maxis.com.my.$domain:443?path=/vless&security=tls&encryption=none&host=www.mosti.gov.my&type=ws&sni=www.mosti.gov.my#$user$exp@MaxExp"
vlesslink13="vless://$uuid@162.159.134.61:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@DG3mb"
vlesslink14="vless://$uuid@m.google.com.my.$domain:80?path=/vless&security=none&encryption=none&host=api.instagram.com&type=ws#$user$exp@DGsosial"
vlesslink15="vless://$uuid@api.useinsider.com:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@DGAPN"
vlesslink16="vless://$uuid@$domain:443?path=/vless&security=tls&encryption=none&host=sso.pokemon.com&type=ws&sni=sso.pokemon.com#$user$exp@DGPoke"
vlesslink17="vless://$uuid@104.17.10.12:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@Unifi"
vlesslink18="vless://$uuid@$domain:443?path=/vless&security=tls&encryption=none&host=esports.pubgmobile.com.esports.mobilelegends.com&type=ws&sni=esports.pubgmobile.com.esports.mobilelegends.com#$user$exp@YdoAddon"
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
systemctl restart xray
clear
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-vless-$user.txt
echo -e "                 Trial Vless Account                " | tee -a /user/log-vless-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-vless-$user.txt
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
echo -e "id            : ${uuid}" | tee -a /user/log-vless-$user.txt
echo -e "Encryption    : none" | tee -a /user/log-vless-$user.txt
echo -e "Network       : Websocket" | tee -a /user/log-vless-$user.txt
echo -e "Path          : /vless" | tee -a /user/log-vless-$user.txt
echo -e "ServiceName   : vless-grpc" | tee -a /user/log-vless-$user.txt
echo -e "Alpn          : h2, http/1.1" | tee -a /user/log-vless-$user.txt
echo -e "——————————————" | tee -a /user/log-vless-$user.txt
echo -e "Link TLS      : ${vlesslink1}" | tee -a /user/log-vless-$user.txt
echo -e "——————————————" | tee -a /user/log-vless-$user.txt
echo -e "Link NTLS     : ${vlesslink2}" | tee -a /user/log-vless-$user.txt
echo -e "——————————————" | tee -a /user/log-vless-$user.txt
echo -e "Link gRPC     : ${vlesslink3}" | tee -a /user/log-vless-$user.txt
echo -e "——————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}UMOBILE NEW   ${NC}  : ${vlesslink4}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}UMO Openwrt   ${NC}  : ${vlesslink5}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${PLE}YES5g/4g 1${NC}      : ${vlesslink6}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${PLE}YES5g/4g 2${NC}      : ${vlesslink7}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${BB}CELCOM No Subs${NC}  : ${vlesslink8}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${BB}Celcom 3MBps${NC}    : ${vlesslink9}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${BB}Yodo${NC}/${RB}Tune ${NC}${GB}3Mbps${NC} : ${vlesslink10}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}MAXISTV${NC}         : ${vlesslink11}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}MAXIS NoSubs EXP${NC}: ${vlesslink12}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}DIGI Bypas 3MB${NC}  : ${vlesslink13}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}DG Sosial Unli  ${NC}: ${vlesslink14}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}Digi APN hos  ${NC}  : ${vlesslink15}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}Digi Pokemon${NC}    : ${vlesslink16}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}UNIFI Mobile${NC}    : ${vlesslink17}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}Yodoo Add on${NC}    : ${vlesslink18}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Format Clash  : http://$domain:8000/vless/vless-$user.txt" | tee -a /user/log-vless-$user.txt
echo -e "——————————————" | tee -a /user/log-vless-$user.txt
echo -e "Expired On    : $exp" | tee -a /user/log-vless-$user.txt
echo -e "——————————————" | tee -a /user/log-vless-$user.txt
echo " " | tee -a /user/log-vless-$user.txt
echo " " | tee -a /user/log-vless-$user.txt
echo " " | tee -a /user/log-vless-$user.txt
read -n 1 -s -r -p "Press any key to back on menu"
clear
vless
