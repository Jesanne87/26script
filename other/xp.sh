#!/bin/bash
> /tmp/deleted_users.log

# Set Timezone
export TZ=Asia/Kuala_Lumpur

# Get Current Date & Time
now=$(date +"%Y-%m-%d %T")

# Telegram Bot Config
_TELEGRAM_TOKEN=$(cat /home/jsphantom/tele_token.txt)
_CHAT_ID=$(cat /home/jsphantom/tele_id.txt)

# Get Server IP & Domain
SERVER_IP=$(curl -sS ipv4.icanhazip.com)
DOMAIN=$(cat /usr/local/etc/xray/domain)

# Deletion counter
DELETED=0

send_telegram_message() {
    local user=$1
    local user_type=$2
    local exp=$3
    
    # Prevent duplicate notifications
    if grep -q "$user" "/tmp/deleted_users.log"; then
        return
    fi

    echo "$user" >> /tmp/deleted_users.log  
    
    MESSAGE="🚨 * User Deleted‼*
👥 * Username:* \`$user\`
🆔 * UUID:* \`$uuid\`
❌ * Type:* \`$user_type\`
📵 * Expired On:* \`$exp\`
🌍 * Server IP:* \`$SERVER_IP\`
🌐 * Domain:* \`$DOMAIN\`
⏰ * Time Deleted:* \`$now\`"

    curl -s -X POST "https://api.telegram.org/bot$_TELEGRAM_TOKEN/sendMessage" \
        -d chat_id="$_CHAT_ID" \
        -d text="$MESSAGE" \
        -d parse_mode="Markdown" > /dev/null 2>&1 &
}

delete_expired_users() {
    local prefix=$1
    local user_type=$2
    local paths=("${@:3}")
    local expiration_file="/usr/local/etc/xray/config.json"

    users=($(grep -oP "^$prefix \K\S+" "$expiration_file" | sort -u))

    for user in "${users[@]}"; do
        exp_lines=$(grep -w "^$prefix $user" "$expiration_file" | cut -d ' ' -f 3- | sort -u)

        latest_exp=""
        latest_ts=0
        latest_exp_updated=""
        latest_ts_updated=0

        while read -r exp; do
            [[ -z "$exp" ]] && continue

            if [[ ! "$exp" =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
                continue
            fi

            if [[ ! "$exp" =~ [0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
                exp="$exp 23:59:59"
            fi

            ts=$(date -d "$exp" +%s 2>/dev/null)
            [[ -z "$ts" ]] && continue

            # Track the latest expiration time
            if [[ "$ts" -gt "$latest_ts" ]]; then
                latest_exp="$exp"
                latest_ts=$ts
            fi

            # Track if the expiration was updated
            if [[ "$ts" -gt "$latest_ts_updated" ]]; then
                latest_exp_updated="$exp"
                latest_ts_updated=$ts
            fi
        done <<< "$exp_lines"

        [[ -z "$latest_exp" ]] && continue

        now_ts=$(date +%s)

        # If expiration date is updated or not expired, skip the user
        if [[ -n "$latest_ts_updated" && "$latest_ts_updated" -gt "$now_ts" ]]; then
            continue
        fi

        # === Ambil UUID sebelum delete ===
        uuid=$(grep -oP "(?<=\"id\": \")\S+(?=\",.*\"email\": \"$user\")" "$expiration_file" | head -n 1)

        # Delete Xray config entries
        sed -i "/^$prefix $user /,/^},{/d" "$expiration_file"
        sed -i "/^$prefix $user /d" "$expiration_file"

        if [[ "$prefix" == "#=" ]]; then
            sed -i "/^#gr $user /,/^},{/d" "$expiration_file"
            sed -i "/^#gr $user /d" "$expiration_file"
        fi

        # Only delete files if the user hasn't been extended or is expired
        if [[ "$latest_ts" -le "$now_ts" && "$latest_ts_updated" -eq "$latest_ts" ]]; then
            exp_count=$(echo "$exp_lines" | wc -l)
            if [[ "$exp_count" -eq 1 ]]; then
                for path in "${paths[@]}"; do
                    rm -f "$path/$user.txt"
                done
                rm -f "/user/log-vless-$user.txt"
                rm -f "/user/log-vmess-$user.txt"
                rm -f "/var/www/html/vless/all/$user.txt"
                rm -f "/var/www/html/vless/vless-$user.txt"
                rm -f "/var/www/html/vmess/vmess-$user.txt"
                rm -f "/user/bwcounter/$user-down.txt"
                rm -f "/user/bwcounter/$user-up.txt"
                rm -f "/user/bwlog/$user.log"
            fi
        fi

        # Hantar Telegram sekali UUID
        send_telegram_message "$user" "$user_type" "$latest_exp" "$uuid"

        # Increment global deletion counter
        ((DELETED++))
    done
}

# === Run For All User Types ===
delete_expired_users "#@" "vmess" "/var/www/html/vmess"
delete_expired_users "#@gr" "vmess"
delete_expired_users "#=" "vless" \
    "/var/www/html/vless/all" "/var/www/html/vless/umobile" "/var/www/html/vless/yes" \
    "/var/www/html/vless/celcom" "/var/www/html/vless/yodootune" "/var/www/html/vless/maxis" \
    "/var/www/html/vless/digi" "/var/www/html/vless/unifi" "/var/www/html/vless/beone"
delete_expired_users "#gr" "vless"
delete_expired_users "#&" "trojan" "/var/www/html/trojan"
delete_expired_users "#!" "shadowsocks" "/var/www/html/shadowsocks"
delete_expired_users "#%" "shadowsocks2022" "/var/www/html/shadowsocks2022"
delete_expired_users "#" "socks5" "/var/www/html/socks5"
delete_expired_users "#&@" "allxray" "/var/www/html/allxray"

# Restart Xray only if at least one user was deleted
if [[ $DELETED -gt 0 ]]; then
    systemctl restart xray > /dev/null 2>&1
fi