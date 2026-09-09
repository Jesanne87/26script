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

IPINFO_API_KEY="b6b5857f4f0812"
IPGEO_API_KEY="41a897436b4b478fa2070081e01cf1aa"
CACHE_FILE="/etc/xray/isp_cache.txt"
LASTSEEN_DB="/etc/xray/user_lastseen.db"

ONLINE_THRESHOLD_MINUTES=5

mkdir -p /etc/xray
touch "$CACHE_FILE"
touch "$LASTSEEN_DB"

echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e "         ${WB}Unique IP addresses for all users${NC}              "
echo -e "${BB}————————————————————————————————————————————————————${NC}"

# ========== LAST SEEN DATABASE FUNCTIONS ==========
save_last_seen() {
    local user="$1"
    local ts="$2"
    sed -i "/^$user=/d" "$LASTSEEN_DB"
    echo "$user=$ts" >> "$LASTSEEN_DB"
}

load_last_seen() {
    local user="$1"
    grep "^$user=" "$LASTSEEN_DB" | cut -d'=' -f2
}

# helper time parser
parse_line_epoch() {
    local line="$1"
    local ts=""

    ts=$(echo "$line" | grep -oP '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}' | head -n1)
    if [ -z "$ts" ]; then
        ts=$(echo "$line" | grep -oP '\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}' | head -n1)
    fi
    if [ -z "$ts" ]; then
        ts=$(echo "$line" | awk '{print $1" "$2}' | sed -n 's/^\([0-9]\{4\}[-/][0-9]\{2\}[-/][0-9]\{2\} [0-9:]\{8\}\).*$/\1/p' | head -n1)
    fi

    if [ -n "$ts" ]; then
        ts_for_date="${ts//T/ }"
        date -d "$ts_for_date" +%s 2>/dev/null || echo 0
    else
        echo 0
    fi
}

# get all users (#@ vless)
users=$(grep -oP '^#@\s*\K\w+' /usr/local/etc/xray/config.json | sort -u)

for user in $users; do

    ips=$(grep "email: $user" /var/log/xray/access.log | while read -r line; do
        ip=$(echo "$line" | awk '{print $4}' | sed -E 's/from tcp://g; s/tcp://g; s/\[//g; s/\]//g; s/:0$//; s/:[0-9]+$//')
        if ! [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$|^([0-9a-fA-F:]+)$ ]]; then
            ip=$(echo "$line" | awk '{print $3}' | sed -E 's/from tcp://g; s/tcp://g; s/\[//g; s/\]//g; s/:0$//; s/:[0-9]+$//')
        fi
        [ -n "$ip" ] && echo "$ip"
    done | sort -u)

    [ -z "$ips" ] && ip_count=0 || ip_count=$(echo "$ips" | wc -l)

    if [ "$ip_count" -gt 1 ]; then
        echo -e "User ${RB}$user${NC} is LOGGED in from multiple Devices!!"
        echo "User: $user" >> /home/multiple_ip_logins.log
        echo "$ips" >> /home/multiple_ip_logins.log
        echo "----------------------------------------" >> /home/multiple_ip_logins.log
    fi

    # ============= NEW LAST SEEN LOGIC WITH DATABASE =============
    last_line=$(grep "email: $user" /var/log/xray/access.log | tail -n 1)

    if [ -n "$last_line" ]; then
        last_epoch=$(parse_line_epoch "$last_line")
        if [ "$last_epoch" -gt 0 ]; then
            save_last_seen "$user" "$last_epoch"
        fi
    else
        last_epoch=$(load_last_seen "$user")
        last_epoch=${last_epoch:-0}
    fi

    now_epoch=$(date +%s)

    if [ "$last_epoch" -gt 0 ]; then
        delta_min=$(( (now_epoch - last_epoch) / 60 ))
    else
        delta_min=999999
    fi

    is_online=0
    if [ "$delta_min" -le "$ONLINE_THRESHOLD_MINUTES" ]; then
        is_online=1
    fi
    if [ "$ip_count" -gt 0 ] && [ "$delta_min" -le 60 ]; then
        is_online=1
    fi

    expiration_file="/usr/local/etc/xray/config.json"
    expired_date=$(grep -oP "#@ $user \K\d{4}-\d{2}-\d{2}( \d{2}:\d{2}:\d{2})?" "$expiration_file" | head -n1)
    expired_date=${expired_date:-Unknown}

    uuid=$(grep -oP "(?<=\"id\": \")\S+(?=\",.*\"email\": \"$user\")" "$expiration_file" | head -n 1)

    echo -e "${YB}User${NC} : ${GB}$user${NC}"
    [ -n "$uuid" ] && echo -e "UUID: ${GB}$uuid${NC}"

    if [ -n "$ips" ]; then
        for ip in $ips; do
            cache_line=$(grep -w "$ip" "$CACHE_FILE")
            if [ -z "$cache_line" ]; then
                response=$(curl -s --max-time 5 "https://ipinfo.io/${ip}?token=${IPINFO_API_KEY}")
                isp=$(echo "$response" | jq -r '.org // empty' | sed 's/^AS[0-9]* //')
                country=$(echo "$response" | jq -r '.country // empty')

                if [ -z "$isp" ] || [ -z "$country" ]; then
                    response=$(curl -s --max-time 5 "https://api.ipgeolocation.io/ipgeo?apiKey=${IPGEO_API_KEY}&ip=${ip}")
                    isp=$(echo "$response" | jq -r '.isp // "Unknown ISP"')
                    country=$(echo "$response" | jq -r '.country_name // "Unknown Country"')
                fi

                isp="${isp:-Unknown ISP}"
                country="${country:-Unknown Country}"
                echo "$ip|$isp|$country" >> "$CACHE_FILE"
            else
                IFS='|' read -r _ isp country <<< "$cache_line"
            fi

            echo -e "${ip}${NC} ---->> ${RB}${isp}${NC},${YB}${country}${NC}"
        done
    else
        echo -e "IPs: ${RB}None recorded${NC}"
    fi

    if [ "$is_online" -eq 1 ]; then
        echo -e "⚡ Status: ${GB}ONLINE${NC}"
        if [ "$delta_min" -lt 1 ]; then
            echo -e "⏰ Last activity: just now"
        elif [ "$delta_min" -lt 60 ]; then
            echo -e "⏰ Last activity: $delta_min minute(s) ago"
        else
            echo -e "⏰ Last activity: $(date -d "@$last_epoch" '+%Y-%m-%d %H:%M:%S')"
        fi
    else
        echo -e "⚠️ Status: ${RB}OFFLINE${NC}"
        if [ "$last_epoch" -gt 0 ]; then
            last_human=$(date -d "@$last_epoch" '+%Y-%m-%d %H:%M:%S')
            echo -e "⏰ Last seen: $last_human ($delta_min minute(s) ago)"
        else
            echo -e "⏰ Last seen: ${RB}Unknown${NC}"
        fi
    fi

    echo -e "Expiration Date: ${GB}$expired_date${NC}"
    echo -e "${BB}————————————————————————————————————————————————————${NC}"
done

echo ""
read -n 1 -s -r -p "Press any key to back on menu"
vmess
