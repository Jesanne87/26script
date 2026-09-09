#!/bin/bash
# fonts color
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
bold(){
    echo -e "\033[1m\033[01m$1\033[0m"
}

Green_font_prefix="\033[32m" 
Red_font_prefix="\033[31m" 
Green_background_prefix="\033[42;37m" 
Red_background_prefix="\033[41;37m" 
Font_color_suffix="\033[0m"

sudoCmd=""
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCmd="sudo"
fi
osRelease="debian"
osRelease2="ubuntu"
codename=$(grep VERSION_CODENAME /etc/os-release | cut -d '=' -f 2)
versionWgcf="2.2.11"
downloadFilenameWgcf="wgcf_${versionWgcf}_linux_amd64"
configWgcfBinPath="/usr/local/bin"
configWgcfConfigFolderPath="${HOME}/wireguard"
configWgcfAccountFilePath="${configWgcfConfigFolderPath}/wgcf-account.toml"
configWgcfProfileFilePath="${configWgcfConfigFolderPath}/wgcf-profile.conf"
configWARPPortFilePath="${configWgcfConfigFolderPath}/warp-port"
configWireGuardConfigFileFolder="/etc/wireguard"
configWireGuardConfigFilePath="/etc/wireguard/wgcf.conf"
configWireGuardDNSBackupFilePath="/etc/resolv_warp_bak.conf"
configWarpPort="40000"
cloudflare_Trace_URL='https://www.cloudflare.com/cdn-cgi/trace'

function checkWarpClientStatus(){
    
if [[ -f "${configWARPPortFilePath}" ]]; then
configWarpPort=$(cat ${configWARPPortFilePath})
fi
    
echo
green " ================================================== "
sleep 2s
isWarpClientBootSuccess=$(systemctl is-active warp-svc | grep -E "inactive")
if [[ -z "${isWarpClientBootSuccess}" ]]; then
green " Status display--WARP started successfully! "
echo
        
isWarpClientMode=$(curl -sx "socks5h://127.0.0.1:${configWarpPort}" ${cloudflare_Trace_URL} --connect-timeout 20 | grep warp | cut -d= -f2)
sleep 3s
case ${isWarpClientMode} in
on)
green " Status display--WARP SOCKS5 proxy has been started successfully, port number ${configWarpPort} ! "
;;
plus)
green " Status display--WARP+ SOCKS5 proxy has been started successfully, port number ${configWarpPort} ! "
;;
*)
green " Status display -- WARP SOCKS5 proxy failed to start ${Red_font_prefix}${Green_font_prefix}! "
;;
esac
        
green " ================================================== "
echo
echo "curl -x 'socks5h://127.0.0.1:${configWarpPort}' ${cloudflare_Trace_URL}"
echo
curl -x "socks5h://127.0.0.1:${configWarpPort}" ${cloudflare_Trace_URL}     
else
green " Status display -- WARP started ${Red_font_prefix} failed ${Green_font_prefix}! Please check the WARP operation log, find the error and restart WARP "
fi
green " ================================================== "
echo
}


# https://developers.cloudflare.com/warp-client/setting-up/linux

 echo
    green " =================================================="
    green " Prepare to install Cloudflare WARP Official client "
    green " Cloudflare WARP Official client only support Debian 10/11、Ubuntu 20.04/16.04、CentOS 8"
    green " =================================================="
    echo

    if [[ "${osRelease}" == "debian" || "${osRelease2}" == "ubuntu" ]]; then
        ${sudoCmd} apt-key del 835b8acb
        ${sudoCmd} apt-key del 8e5f9a5d

        ${sudoCmd} apt install -y gnupg
        ${sudoCmd} apt install -y apt-transport-https

        # Add cloudflare gpg key
        sudo mkdir -p --mode=0755 /usr/share/keyrings
        curl https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
        #curl https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

        # Add this repo to your apt repositories
if [[ "$codename" = "buster" ]]; then
     echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ buster main" | tee /etc/apt/sources.list.d/cloudflare-client.list
elif [[ "$codename" = "focal" ]]; then
      echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ focal main" | tee /etc/apt/sources.list.d/cloudflare-client.list
fi

        # install cloudflared

        ${sudoCmd} apt-get update
        ${sudoCmd} apt install -y cloudflare-warp
        ${sudoCmd} apt-get install cloudflared
    fi

clear
read -p "Generate a random WARP SOCKS5 port number? The default port is random. Enter N to set a fixed port number of 40000. Please enter [Y/n]:" isWarpPortInput
isWarpPortInput=${isWarpPortInput:-y}

if [[ $isWarpPortInput == [Nn] ]]; then
echo
else
configWarpPort="$(($RANDOM + 10000))"
fi
    
mkdir -p ${configWgcfConfigFolderPath}
echo "${configWarpPort}" > "${configWARPPortFilePath}"

${sudoCmd} systemctl enable warp-svc

yes | warp-cli register
echo
echo "warp-cli set-mode proxy"
warp-cli set-mode proxy
echo
echo "warp-cli --accept-tos set-proxy-port ${configWarpPort}"
warp-cli --accept-tos set-proxy-port ${configWarpPort}
echo
echo "warp-cli --accept-tos connect"
warp-cli --accept-tos connect
echo
#echo "warp-cli --accept-tos enable-always-on"    
#warp-cli --accept-tos enable-always-on

echo
checkWarpClientStatus

    # (crontab -l ; echo "10 6 * * 0,1,2,3,4,5,6 warp-cli disable-always-on ") | sort - | uniq - | crontab -
    # (crontab -l ; echo "11 6 * * 0,1,2,3,4,5,6 warp-cli disconnect ") | sort - | uniq - | crontab -
    (crontab -l ; echo "12 6 * * 1,4 systemctl restart warp-svc ") | sort - | uniq - | crontab -
    # (crontab -l ; echo "16 6 * * 0,1,2,3,4,5,6 warp-cli connect ") | sort - | uniq - | crontab -
    # (crontab -l ; echo "17 6 * * 0,1,2,3,4,5,6 warp-cli enable-always-on ") | sort - | uniq - | crontab -
    
    echo -e " ================================================== "
    echo -e "  Cloudflare official WARP Client installed successfully!"
    echo -e "  WARP SOCKS5 port number ${configWarpPort} "
    echo -e "  WARP Stop : warp-cli disconnect , Stop Always-On : warp-cli disable-always-on "
    echo -e "  WARP Start : warp-cli connect , Start Always-On (Stay connected to WARP) : warp-cli enable-always-on "
    echo -e "  WARP View log : journalctl -n 100 -u warp-svc"
    echo -e "  WARP View running status : warp-cli status"
    echo -e "  WARP View connection information : warp-cli warp-stats"
    echo -e "  WARP View setup information : warp-cli settings"
    echo -e "  WARP View account information : warp-cli account"
    echo -e " ================================================== "

    


