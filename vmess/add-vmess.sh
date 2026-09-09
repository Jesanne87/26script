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
MYIP=$(curl -sS ipv4.icanhazip.com)
clear
domain=$(cat /usr/local/etc/xray/domain)
until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e "                 ${WB}Add Vmess Account${NC}                  "
echo -e "${BB}————————————————————————————————————————————————————${NC}"
read -rp "User: " -e user
CLIENT_EXISTS=$(grep -w $user /usr/local/etc/xray/config.json | wc -l)
if [[ ${CLIENT_EXISTS} == '1' ]]; then
clear
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e "                 ${WB}Add Vmess Account${NC}                  "
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e "${YB}A client with the specified name was already created, please choose another name.${NC}"
echo -e "${BB}————————————————————————————————————————————————————${NC}"
read -n 1 -s -r -p "Press any key to back on menu"
add-vmess
fi
done
read -p "UUID : " id
uuid=$id
if [[ $id == "" ]]; then
uuid=$(cat /proc/sys/kernel/random/uuid)
fi
masa="$(date +"%Y-%m-%d %T")"
read -p "Expired (days): " masaaktif
exp=`date -d "$masaaktif days" +"%Y-%m-%d %T"`
sed -i '/#vmess$/a\#@ '"$user $exp"'\
},{"id": "'""$uuid""'","alterId": '"0"',"email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#vmess-grpc$/a\#@gr '"$user $exp"'\
},{"id": "'""$uuid""'","alterId": '"0"',"email": "'""$user""'"' /usr/local/etc/xray/config.json
vlink1=`cat << EOF
{
"v": "2",
"ps": "$user",
"add": "$domain",
"port": "443",
"id": "$uuid",
"aid": "0",
"net": "ws",
"path": "/vmess",
"type": "none",
"host": "$domain",
"tls": "tls"
}
EOF`
vlink2=`cat << EOF
{
"v": "2",
"ps": "$user",
"add": "$domain",
"port": "80",
"id": "$uuid",
"aid": "0",
"net": "ws",
"path": "/vmess",
"type": "none",
"host": "$domain",
"tls": "none"
}
EOF`
vlink3=`cat << EOF
{
"v": "2",
"ps": "$user",
"add": "$domain",
"port": "443",
"id": "$uuid",
"aid": "0",
"net": "grpc",
"path": "vmess-grpc",
"type": "none",
"host": "$domain",
"tls": "tls"
}
EOF`
vlink4=`cat << EOF
{
"v": "2",
"ps": "$user",
"add": "zn4oa6cok9jkhgn6c-maxiscx.siteintercept.qualtrics.com",
"port": "80",
"id": "$uuid",
"aid": "0",
"net": "ws",
"path": "",
"type": "none",
"host": "zn4oa6cok9jkhgn6c-maxiscx.siteintercept.qualtrics.com.$domain",
"tls": "none"
}
EOF`
vlink5=`cat << EOF
{
"v": "2",
"ps": "$user",
"add": "$MYIP",
"port": "80",
"id": "$uuid",
"aid": "0",
"net": "ws",
"path": "/",
"type": "none",
"host": "opensignal.com",
"tls": "none"
}
EOF`
vlink6=`cat << EOF
{
"v": "2",
"ps": "$user",
"add": "104.18.7.178",
"port": "80",
"id": "$uuid",
"aid": "0",
"net": "ws",
"path": "/",
"type": "none",
"host": "app.speedtest.net.$domain",
"tls": "none"
}
EOF`
vlink7=`cat << EOF
{
"v": "2",
"ps": "$user",
"add": "162.159.140.229",
"port": "80",
"id": "$uuid",
"aid": "0",
"net": "ws",
"path": "GET /cdn-cgi/trace HTTP/1.1[crlf]Host: [host][crlf][crlf][split]CF-RAY / HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf][crlf]",
"type": "none",
"host": "strx-payload://shop.u.com.my/",
"tls": "none"
}
EOF`
vlink8=`cat << EOF
{
"v": "2",
"ps": "$user",
"add": "104.17.209.240",
"port": "80",
"id": "$uuid",
"aid": "0",
"net": "ws",
"path": "GET /cdn-cgi/trace HTTP/1.1[crlf]Host: [host][crlf][crlf][split]CF-RAY / HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf][crlf]",
"type": "none",
"host": "strx-payload://mgm.maxis.com.my/",
"tls": "none"
}
EOF`
vlink9=`cat << EOF
{
"v": "2",
"ps": "$user",
"add": "cdn.opensignal.com",
"port": "80",
"id": "$uuid",
"aid": "0",
"net": "ws",
"path": "GET /cdn-cgi/trace HTTP/1.1[crlf]Host: wap.u.com.my[crlf][crlf][split]STRX / HTTP/1.1[crlf]Host: [host][crlf]Upgrade: websocket[crlf]Sec-WebSocket-Key: K4vEMLAxh27PNePuLDwBAQ==[crlf]Connection: Upgrade[crlf]Sec-WebSocket-Version: 13[crlf][crlf]",
"type": "none",
"host": "strx-payload://$domain/",
"tls": "none"
}
EOF`
vlink10=`cat << EOF
{
"v": "2",
"ps": "$user",
"add": "mgm.maxis.com.my.siteintercept.qualtrics.com",
"port": "80",
"id": "$uuid",
"aid": "0",
"net": "ws",
"path": "GET /cdn-cgi/trace HTTP/1.1[crlf]Host: mgm.maxis.com.my[crlf][crlf][split]STRX / HTTP/1.1[crlf]Host: [host][crlf]Upgrade: websocket[crlf]Sec-WebSocket-Key: K4vEMLAxh27PNePuLDwBAQ==[crlf]Connection: Upgrade[crlf]Sec-WebSocket-Version: 13[crlf][crlf]",
"type": "none",
"host": "strx-payload://$domain/",
"tls": "none"
}
EOF`
vlink11=`cat << EOF
{
"v": "2",
"ps": "$user",
"add": "104.17.148.22",
"port": "80",
"id": "$uuid",
"aid": "0",
"net": "ws",
"path": "/",
"type": "none",
"host": "cdn.opensignal.com.$domain",
"tls": "none"
}
EOF`
vmesslink1="vmess://$(echo $vlink1 | base64 -w 0)"
vmesslink2="vmess://$(echo $vlink2 | base64 -w 0)"
vmesslink3="vmess://$(echo $vlink3 | base64 -w 0)"
vmesslink4="vmess://$(echo $vlink4 | base64 -w 0)"
vmesslink5="vmess://$(echo $vlink5 | base64 -w 0)"
vmesslink6="vmess://$(echo $vlink6 | base64 -w 0)"
vmesslink7="vmess://$(echo $vlink7 | base64 -w 0)"
vmesslink8="vmess://$(echo $vlink8 | base64 -w 0)"
vmesslink9="vmess://$(echo $vlink9 | base64 -w 0)"
vmesslink10="vmess://$(echo $vlink10 | base64 -w 0)"
vmesslink11="vmess://$(echo $vlink11 | base64 -w 0)"
cat > /var/www/html/vmess/vmess-$user.txt << END
==========================
Vmess WS (CDN) TLS
==========================
- name: Vmess-$user
type: vmess
server: ${domain}
port: 443
uuid: ${uuid}
alterId: 0
cipher: auto
udp: true
tls: true
skip-cert-verify: true
servername: ${domain}
network: ws
ws-opts:
path: /vmess
headers:
Host: ${domain}
==========================
Vmess WS (CDN)
==========================
- name: Vmess-$user
type: vmess
server: ${domain}
port: 80
uuid: ${uuid}
alterId: 0
cipher: auto
udp: true
tls: false
skip-cert-verify: false
servername: ${domain}
network: ws
ws-opts:
path: /vmess
headers:
Host: ${domain}
==========================
Vmess gRPC (CDN)
==========================
- name: Vmess-$user
server: $domain
port: 443
type: vmess
uuid: $uuid
alterId: 0
cipher: auto
network: grpc
tls: true
servername: $domain
skip-cert-verify: true
grpc-opts:
grpc-service-name: "vmess-grpc"
==========================
Vmess WS (MaxisNosub CDN)
==========================
- name: Vmess-$user
type: vmess
server: ${domain}
port: 80
uuid: ${uuid}
alterId: 0
cipher: auto
udp: true
tls: false
skip-cert-verify: false
servername: zn4oa6cok9jkhgn6c-maxiscx.siteintercept.qualtrics.com
network: ws
ws-opts:
path: 
headers:
Host: zn4oa6cok9jkhgn6c-maxiscx.siteintercept.qualtrics.com.${domain}
=========================
Vmess WS (UNI5gwow)
==========================
- name: Vmess-$user
type: vmess
server: 162.159.133.61
port: 80
uuid: ${uuid}
alterId: 0
cipher: auto
udp: true
tls: false
skip-cert-verify: false
servername: opensignal.com
network: ws
ws-opts:
path: ws://${domain}/
headers:
Host:
=========================
Vmess WS (UNI5gwow 2)
==========================
- name: Vmess-$user
type: vmess
server: 104.18.7.178
port: 80
uuid: ${uuid}
alterId: 0
cipher: auto
udp: true
tls: false
skip-cert-verify: false
servername: app.speedtest.net.$domain
network: ws
ws-opts:
path: /
headers:
Host:  
==========================
Link Vmess Account
==========================
Link TLS   : vmess://$(echo $vlink1 | base64 -w 0)
==========================
Link NTLS  : vmess://$(echo $vlink2 | base64 -w 0)
==========================
Link gRPC  : vmess://$(echo $vlink3 | base64 -w 0)
==========================
MaxisNoSub : vmess://$(echo $vlink4 | base64 -w 0)
==========================
UNI5gwow   : vmess://$(echo $vlink5 | base64 -w 0)
==========================
UNI5gwow 2 : vmess://$(echo $vlink6 | base64 -w 0)
==========================
Umobile    : vmess://$(echo $vlink7 | base64 -w 0)
==========================
Umobile 2  : vmess://$(echo $vlink9 | base64 -w 0)
==========================
Maxis      : vmess://$(echo $vlink8 | base64 -w 0)
==========================
Maxis 2    : vmess://$(echo $vlink10 | base64 -w 0)
==========================
Maxis Frezee/Bypass   : vmess://$(echo $vlink11 | base64 -w 0)
==========================
END
ISP=$(cat /usr/local/etc/xray/org)
CITY=$(cat /usr/local/etc/xray/city)
systemctl restart xray
clear
echo -e "————————————————————————————————————————————————————${NC}" | tee -a /user/log-vmess-$user.txt
echo -e "                   Vmess Account                    " | tee -a /user/log-vmess-$user.txt
echo -e "————————————————————————————————————————————————————${NC}" | tee -a /user/log-vmess-$user.txt
echo -e "Remarks       : $user" | tee -a /user/log-vmess-$user.txt
echo -e "ISP           : $ISP" | tee -a /user/log-vmess-$user.txt
echo -e "City          : $CITY" | tee -a /user/log-vmess-$user.txt
echo -e "Domain        : $domain" | tee -a /user/log-vmess-$user.txt
echo -e "IP/Host       : $MYIP" | tee -a /user/log-vmess-$user.txt
echo -e "Wildcard      : (bug.com).$domain" | tee -a /user/log-vmess-$user.txt
echo -e "Port TLS      : 443" | tee -a /user/log-vmess-$user.txt
echo -e "Port NTLS     : 80" | tee -a /user/log-vmess-$user.txt
echo -e "Port gRPC     : 443" | tee -a /user/log-vmess-$user.txt
echo -e "Alt Port TLS  : 2053, 2083, 2087, 2096, 8443" | tee -a /user/log-vmess-$user.txt
echo -e "Alt Port NTLS : 8080, 8880, 2052, 2082, 2086, 2095" | tee -a /user/log-vmess-$user.txt
echo -e "id            : $uuid" | tee -a /user/log-vmess-$user.txt
echo -e "AlterId       : 0" | tee -a /user/log-vmess-$user.txt
echo -e "Security      : auto" | tee -a /user/log-vmess-$user.txt
echo -e "Network       : Websocket" | tee -a /user/log-vmess-$user.txt
echo -e "Path          : /(multipath) • ubah suka-suka" | tee -a /user/log-vmess-$user.txt
echo -e "ServiceName   : vmess-grpc" | tee -a /user/log-vmess-$user.txt
echo -e "Alpn          : h2, http/1.1" | tee -a /user/log-vmess-$user.txt
echo -e "————————————————————————————————————————————————————${NC}" | tee -a /user/log-vmess-$user.txt
echo -e "Link TLS      : $vmesslink1" | tee -a /user/log-vmess-$user.txt
echo -e "————————————————————————————————————————————————————${NC}" | tee -a /user/log-vmess-$user.txt
echo -e "Link NTLS     : $vmesslink2" | tee -a /user/log-vmess-$user.txt
echo -e "————————————————————————————————————————————————————${NC}" | tee -a /user/log-vmess-$user.txt
echo -e "Link gRPC     : $vmesslink3" | tee -a /user/log-vmess-$user.txt
echo -e "————————————————————————————————————————————————————${NC}" | tee -a /user/log-vmess-$user.txt
echo -e "${RB}MaxisNoSub${NC}    : $vmesslink4" | tee -a /user/log-vmess-$user.txt
echo -e "————————————————————————————————————————————————————${NC}" | tee -a /user/log-vmess-$user.txt
echo -e "${YB}UNI5Gwow${NC}      : $vmesslink5" | tee -a /user/log-vmess-$user.txt
echo -e "————————————————————————————————————————————————————${NC}" | tee -a /user/log-vmess-$user.txt
echo -e "${YB}Yes/Uni5gwow 2${NC}: $vmesslink6" | tee -a /user/log-vmess-$user.txt
echo -e "————————————————————————————————————————————————————${NC}" | tee -a /user/log-vmess-$user.txt
echo -e "${YB}Umobile 1(ip)${NC} : $vmesslink7" | tee -a /user/log-vmess-$user.txt
echo -e "————————————————————————————————————————————————————${NC}" | tee -a /user/log-vmess-$user.txt
echo -e "${YB}Umobile 2(bug)${NC}: $vmesslink9" | tee -a /user/log-vmess-$user.txt
echo -e "————————————————————————————————————————————————————${NC}" | tee -a /user/log-vmess-$user.txt
echo -e "${RB}Maxis 1(ip) ${NC}  : $vmesslink8" | tee -a /user/log-vmess-$user.txt
echo -e "————————————————————————————————————————————————————${NC}" | tee -a /user/log-vmess-$user.txt
echo -e "${RB}Maxis 2(bug) ${NC} : $vmesslink10" | tee -a /user/log-vmess-$user.txt
echo -e "————————————————————————————————————————————————————${NC}" | tee -a /user/log-vmess-$user.txt
echo -e "${RB}Maxis Frezee/Bypass ${NC} : $vmesslink11" | tee -a /user/log-vmess-$user.txt
echo -e "————————————————————————————————————————————————————${NC}" | tee -a /user/log-vmess-$user.txt
echo -e "Format Clash  : http://$domain:8000/vmess/vmess-$user.txt" | tee -a /user/log-vmess-$user.txt
echo -e "————————————————————————————————————————————————————${NC}" | tee -a /user/log-vmess-$user.txt
echo -e "Username      : $user" | tee -a /user/log-vmess-$user.txt
echo -e "User ID       : $uuid" | tee -a /user/log-vmess-$user.txt
echo -e "Server Name   : $domain" | tee -a /user/log-vmess-$user.txt
echo -e "Created On    : $masa" | tee -a /user/log-vmess-$user.txt
echo -e "Expired On    : $exp" | tee -a /user/log-vmess-$user.txt
echo -e "————————————————————————————————————————————————————${NC}" | tee -a /user/log-vmess-$user.txt
echo " " | tee -a /user/log-vmess-$user.txt
echo " " | tee -a /user/log-vmess-$user.txt
echo " " | tee -a /user/log-vmess-$user.txt
read -n 1 -s -r -p "Press any key to back on menu"
clear
vmess
