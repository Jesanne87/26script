#!/bin/bash
GB='\e[32;1m'
NC='\e[0m'
BB='\e[34;1m'
WB='\e[37;1m'
YB='\e[33;1m'
while true; do
	unset choice
	n=21
	clear
	echo ""

echo -e "     ${WB}----- [ ${YB}WARP PANEL By ${YB}JsPhantom ${WB}] -----${NC}               "

		echo ""
		echo "[01] WARP Cli Stop"
		echo "[02] WARP Cli Start"
		echo "[03] WARP Cli View log"
		echo "[04] WARP Cli View running status"
		echo "[05] WARP Cli View connection information"
    echo "[06] WARP Cli View setup information"
    echo "[07] WARP Cli View account information"
    echo "[08] WARP Cli Install"
    echo "[09] WARP Cli Uninstall"
    echo "[10] WARP Cli Unregister"
    echo "[11] WARP Cli Register"
    echo "[12] WARP Cli Change License Key"
    echo "[13] WARP WireProxy Install"
    echo "[14] WARP WireProxy UnInstall"
    echo "[15] WARP WireProxy Status"
    echo "[16] WARP WireProxy Change License Key"
    echo "[17] WARP WireProxy Turn on/off"
    echo "[18] WARP Add Custom Geosite"    
    echo "[19] WARP Add Custom Domain"
    echo "[20] WARP Add Bypass Basic Domain"
    echo "[21] WARP Delete ALL Domain"
		echo ""
		echo "[x] Back"
		echo ""
	until [[ $choice -ge 1 ]] && [[ $choice -le $n ]] || [[ $choice == "x" ]]; do
		read -p "Choose option : " choice
		if [[ $choice -lt 1 ]] || [[ $choice -gt $n ]]; then
			[[ $choice != "x" ]] && echo "[ERROR] Invalid choice."
      sleep 1
      menu
		fi
	done
	case $choice in
		1)
			clear
			warp-cli disconnect
      echo ""
      read -n 1 -r -s -p $"Press any key to continue ... "
			;;
		2)
			clear
			warp-cli connect
      echo ""
      read -n 1 -r -s -p $"Press any key to continue ... "
			;;
		3)
			clear
			journalctl -n 100 -u warp-svc
      echo ""
      read -n 1 -r -s -p $"Press any key to continue ... "
			;;
		4)
			clear
			warp-cli status
      echo ""
			read -n 1 -r -s -p $"Press any key to continue ... "
			;;
		5)
			clear
      warp-cli tunnel stats
      echo ""
      read -n 1 -r -s -p $"Press any key to continue ... "
			;;
		6)
			clear
			warp-cli settings
      echo ""
			read -n 1 -r -s -p $"Press any key to continue ... "
			;;
   	7)
			clear
			warp-cli registration show
      echo ""
			read -n 1 -r -s -p $"Press any key to continue ... "
			;;
    8)
			echo -e "${GB}[ INFO ]${NC} ${YB}Setup WARP${NC}"
      #wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh
      wget https://raw.githubusercontent.com/Jesanne87/combo/main/warp.sh && chmod +x warp.sh && ./warp.sh
      rm -f /root/warp.sh
      echo -e "${GB}[ INFO ]${NC} ${YB}Successfully Installed WARP${NC}"
      echo ""
			read -n 1 -r -s -p $"Press any key to continue ... " 
      ;;
    9)
			clear
			sudo apt remove cloudflare-warp
      echo ""
      echo -e "${GB}[ INFO ]${NC} ${YB}Successfully Uninstalled WARP${NC}"
      echo ""
			read -n 1 -r -s -p $"Press any key to continue ... " 
      ;;  
    10)
			clear
			warp-cli registration delete
      echo ""
			read -n 1 -r -s -p $"Press any key to continue ... " 
      ;;
    11)
			clear
			warp-cli registration new
      echo ""
			read -n 1 -r -s -p $"Press any key to continue ... " 
      ;;  
    12)
			clear
      read -p "License Key : " key
      license=$key
			warp-cli set-license $key
      ;;
    13)
      clear
			echo -e "${GB}[ INFO ]${NC} ${YB}Setup WARP WireProxy${NC}"
      wget https://raw.githubusercontent.com/Jesanne87/combo/main/warp-proxy.sh && chmod +x warp-proxy.sh && ./warp-proxy.sh
      rm -f /root/warp-proxy.sh
      while true
      do
      RAM=$(free -m | awk 'NR==2{print $3}')
      if [ $RAM -gt 350 ]
      then
        systemctl restart wireproxy
      fi
      sleep 60  # Check RAM every 60 seconds
      done &>/dev/null &  # Redirect output to /dev/null
      echo -e "${GB}[ INFO ]${NC} ${YB}Successfully Installed WARP WireProxy${NC}"
      echo ""
			read -n 1 -r -s -p $"Press any key to continue ... " 
      ;;
    14)
			clear
			warp u
      echo ""
      echo -e "${GB}[ INFO ]${NC} ${YB}Successfully Uninstalled WARP WireProxy${NC}"
      echo ""
			read -n 1 -r -s -p $"Press any key to continue ... " 
      ;;
	  15)
			clear
      warp
      echo ""
      read -n 1 -r -s -p $"Press any key to continue ... "
			;;
	  16)
			clear
      warp a
      echo ""
      echo -e "${GB}[ INFO ]${NC} ${YB}Successfully Done${NC}"
      read -n 1 -r -s -p $"Press any key to continue ... "
			;;
 		17)
			clear
			warp y
      echo ""
			read -n 1 -r -s -p $"Press any key to continue ... "
			;;
    18)
			clear
      read -p "Nama Geosite : " geosite
      namageosite=$geosite
      sed -i "/#add-domain/a\        \"geosite:$namageosite\"," /usr/local/etc/xray/config.json
      systemctl restart xray.service
      echo -e "${GB}[ INFO ]${NC} ${YB}Successfully Added New Custom Geosite${NC}"
      echo ""
      read -n 1 -r -s -p $"Press any key to continue ... "
      ;;    
    19)
			clear
      read -p "Nama Domain : " domain
      namadomain=$domain
      sed -i "/#add-domain/a\        \"domain:$namadomain\"," /usr/local/etc/xray/config.json
      systemctl restart xray.service
      echo -e "${GB}[ INFO ]${NC} ${YB}Successfully Added New Custom Domain${NC}"
      echo ""
      read -n 1 -r -s -p $"Press any key to continue ... "
      ;;
    20)
			clear
      sed -i '/#add-domain/{n;:a;N;/\n\s*]/!ba;s/.*\n\s*//}' /usr/local/etc/xray/config.json
      sed -i '/#add-domain/a\        \"geosite:netflix"' /usr/local/etc/xray/config.json
      sed -i '/#add-domain/a\        \"geosite:openai",' /usr/local/etc/xray/config.json 
      sed -i '/#add-domain/a\        \"domain:astro.com.my",' /usr/local/etc/xray/config.json
      sed -i '/#add-domain/a\        \"domain:api.ott-nav.com",' /usr/local/etc/xray/config.json
      sed -i '/#add-domain/a\        \"domain:linearjitp-playback.astro.com.my",' /usr/local/etc/xray/config.json
      sed -i '/#add-domain/a\        \"domain:app.ott-nav.com",' /usr/local/etc/xray/config.json
      sed -i '/#add-domain/a\        \"domain:jepstoreiptv.atullijai.workers.dev",' /usr/local/etc/xray/config.json
      sed -i '/#add-domain/a\        \"domain:live-xtra-sg1.global.ssl.fastly.net",' /usr/local/etc/xray/config.json
      sed -i '/#add-domain/a\        \"domain:debrid.it",' /usr/local/etc/xray/config.json
      sed -i '/#add-domain/a\        \"domain:alldebrid.com",' /usr/local/etc/xray/config.json
      sed -i '/#add-domain/a\        \"domain:reddit.com",' /usr/local/etc/xray/config.json
      sed -i '/#add-domain/a\        \"domain:imgur.com",' /usr/local/etc/xray/config.json
      sed -i '/#add-domain/a\        \"domain:facebook.com",' /usr/local/etc/xray/config.json
      sed -i '/#add-domain/a\        \"domain:fextralife.com",' /usr/local/etc/xray/config.json
      sed -i '/#add-domain/a\        \"domain:alpha66.space",' /usr/local/etc/xray/config.json
      sed -i '/#add-domain/a\        \"domain:astrogo.astro.com.my",' /usr/local/etc/xray/config.json  
      sed -i '/#add-domain/a\        \"domain:hoyolab.com",' /usr/local/etc/xray/config.json
      sed -i '/#add-domain/a\        \"domain:playtv.unifi.com.my",' /usr/local/etc/xray/config.json
      sed -i '/#add-domain/a\        \"domain:api.strem.io",' /usr/local/etc/xray/config.json
      sed -i '/#add-domain/a\        \"domain:api.onesignal.com",' /usr/local/etc/xray/config.json       
      systemctl restart xray.service
      echo -e "${GB}[ INFO ]${NC} ${YB}Successfully Added Bypass Basic Domain${NC}"
      echo ""
      read -n 1 -r -s -p $"Press any key to continue ... "
      ;;
    21)
			clear
      sed -i '/#add-domain/{n;:a;N;/\n\s*]/!ba;s/.*\n\s*//}' /usr/local/etc/xray/config.json
      sed -i '/#add-domain/a\        \"domain:example.com\"' /usr/local/etc/xray/config.json
      systemctl restart xray.service
      echo -e "${GB}[ INFO ]${NC} ${YB}Successfully Remove All Domain${NC}"
      echo ""
      read -n 1 -r -s -p $"Press any key to continue ... "
      ;;
   	x)
			break
			;;
		esac
	done   
warp-menu  