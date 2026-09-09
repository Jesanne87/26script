#!/bin/bash

# ============================================================
#              TELEGRAM BOT MANAGER
# ============================================================
# Functions:
# 1. Setup Bot Token + Chat ID
# 2. Check Xray Traffic via Telegram /check
# 3. Multiple Login Detection
# 4. ISP / Country Cache
# 5. Start / Stop / Restart / Status
# 6. Enable Bot on Boot
#
# Main files:
# /home/jsphantom/tele_token.txt
# /home/jsphantom/tele_id.txt
# /etc/xray/isp_cache.txt
# /usr/local/sbin/telegram-xray-bot
# /etc/systemd/system/telegram-xray-bot.service
# ============================================================

# ---------------- COLORS ----------------

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'

# ---------------- PATH ----------------

BOT_TOKEN_FILE="/home/jsphantom/tele_token.txt"
CHAT_ID_FILE="/home/jsphantom/tele_id.txt"

BOT_SCRIPT="/usr/local/sbin/telegram-xray-bot"
SERVICE_FILE="/etc/systemd/system/telegram-xray-bot.service"

CACHE_FILE="/etc/xray/isp_cache.txt"

XRAY="/usr/local/bin/xray"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
XRAY_LOG="/var/log/xray/access.log"

API_SERVER="127.0.0.1:10000"

# ---------------- CHECK ROOT ----------------

check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}Please run this script as root.${NC}"
        exit 1
    fi
}

# ---------------- INSTALL DEPENDENCIES ----------------

install_dependencies() {

    clear

    echo -e "${BLUE}============================================${NC}"
    echo -e "        ${YELLOW}Checking Dependencies${NC}"
    echo -e "${BLUE}============================================${NC}"

    command -v curl >/dev/null 2>&1 || {
        echo -e "${YELLOW}Installing curl...${NC}"
        apt-get update -qq
        apt-get install -y curl >/dev/null 2>&1
    }

    command -v jq >/dev/null 2>&1 || {
        echo -e "${YELLOW}Installing jq...${NC}"
        apt-get update -qq
        apt-get install -y jq >/dev/null 2>&1
    }

    command -v numfmt >/dev/null 2>&1 || {
        echo -e "${YELLOW}Installing coreutils...${NC}"
        apt-get update -qq
        apt-get install -y coreutils >/dev/null 2>&1
    }

    mkdir -p /home/jsphantom
    mkdir -p /etc/xray

    touch "$CACHE_FILE"

    chmod 600 "$BOT_TOKEN_FILE" 2>/dev/null
    chmod 600 "$CHAT_ID_FILE" 2>/dev/null
}

# ============================================================
#                    BOT CREDENTIALS
# ============================================================

setup_bot() {

    clear

    echo -e "${BLUE}╭════════════════════════════════════════════╮${NC}"
    echo -e "${BLUE}│        ${YELLOW}•••── BOT NOTIFICATION ──•••        ${BLUE}│${NC}"
    echo -e "${BLUE}╰════════════════════════════════════════════╯${NC}"
    echo

    OLD_TOKEN=""
    OLD_CHAT=""

    [ -f "$BOT_TOKEN_FILE" ] && OLD_TOKEN=$(cat "$BOT_TOKEN_FILE")
    [ -f "$CHAT_ID_FILE" ] && OLD_CHAT=$(cat "$CHAT_ID_FILE")

    if [ -n "$OLD_TOKEN" ]; then
        echo -e "${GREEN}Bot Token already configured.${NC}"
        echo -e "${GREEN}Chat ID already configured.${NC}"
        echo
        echo "1. Keep existing data"
        echo "2. Change Bot Token / Chat ID"
        echo

        read -rp "Select [1-2]: " choice

        case "$choice" in
            1)
                return
                ;;
            2)
                ;;
            *)
                echo -e "${RED}Invalid option.${NC}"
                sleep 1
                return
                ;;
        esac
    fi

    clear

    echo -e "${BLUE}============================================${NC}"
    echo -e "       ${YELLOW}Setup Bot Notification${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo

    read -rp "API Bot Token : " api
    echo
    read -rp "Chat ID       : " itd

    if [ -z "$api" ] || [ -z "$itd" ]; then
        echo
        echo -e "${RED}Token atau Chat ID tidak boleh kosong.${NC}"
        sleep 2
        return
    fi

    clear

    echo -e "${CYAN}"
    echo "Information"
    echo "================================"
    echo "API Bot : $api"
    echo "Chat ID : $itd"
    echo "================================"
    echo -e "${NC}"

    read -rp "Data betul? [y/n]: " confirmation

    case "$confirmation" in

        y|Y)

            mkdir -p /home/jsphantom

            printf '%s\n' "$api" > "$BOT_TOKEN_FILE"
            printf '%s\n' "$itd" > "$CHAT_ID_FILE"

            chmod 600 "$BOT_TOKEN_FILE"
            chmod 600 "$CHAT_ID_FILE"

            echo
            echo -e "${GREEN}Bot notification berjaya disimpan.${NC}"

            # Test Telegram
            echo
            echo -e "${YELLOW}Testing Telegram Bot...${NC}"

            response=$(curl -s --max-time 10 \
                -X POST \
                "https://api.telegram.org/bot${api}/sendMessage" \
                -d "chat_id=${itd}" \
                --data-urlencode "text=✅ Telegram Bot connected successfully.")

            if echo "$response" | grep -q '"ok":true'; then
                echo -e "${GREEN}Telegram connection OK.${NC}"
            else
                echo -e "${RED}Telegram connection FAILED.${NC}"
                echo "$response"
            fi

            sleep 2

            # Restart bot if installed
            if [ -f "$SERVICE_FILE" ]; then
                systemctl daemon-reload
                systemctl restart telegram-xray-bot.service 2>/dev/null
            fi

            ;;

        *)
            echo
            echo -e "${YELLOW}Setup dibatalkan.${NC}"
            sleep 1
            ;;
    esac
}

# ============================================================
#                    READ BOT DATA
# ============================================================

get_bot_data() {

    if [ ! -s "$BOT_TOKEN_FILE" ] || [ ! -s "$CHAT_ID_FILE" ]; then
        return 1
    fi

    TELEGRAM_TOKEN=$(cat "$BOT_TOKEN_FILE")
    CHAT_ID=$(cat "$CHAT_ID_FILE")

    [ -n "$TELEGRAM_TOKEN" ] && [ -n "$CHAT_ID" ]
}

# ============================================================
#                    SEND TELEGRAM
# ============================================================

send_message() {

    local message="$1"

    get_bot_data || return 1

    curl -s --max-time 10 \
        -X POST \
        "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        --data-urlencode "text=${message}" \
        -d "parse_mode=Markdown" \
        >/dev/null 2>&1
}

# ============================================================
#                    SERVER INFORMATION
# ============================================================

get_server_info() {

    MYIP=$(curl -sS --max-time 5 ipv4.icanhazip.com 2>/dev/null)

    if [ -f "/usr/local/etc/xray/domain" ]; then
        DOMAIN=$(cat /usr/local/etc/xray/domain)
    else
        DOMAIN=$(hostname)
    fi

    MYIP=${MYIP:-Unknown}
    DOMAIN=${DOMAIN:-Unknown}
}

# ============================================================
#                    XRAY TRAFFIC
# ============================================================

get_xray_stats() {

    if [ ! -x "$XRAY" ]; then
        echo "Xray binary not found."
        return
    fi

    json_output=$(
        "$XRAY" api statsquery \
        --server="$API_SERVER" 2>/dev/null
    )

    if [ -z "$json_output" ]; then
        echo "Unable to read Xray API."
        return
    fi

    echo "$json_output" |
    jq -r '
    .stat[]? |
    [.name, .value] |
    @tsv
    ' 2>/dev/null |
    while IFS=$'\t' read -r name value; do

        [ -z "$name" ] && continue

        clean=$(echo "$name" | sed 's/^user>>>//')

        echo "$clean $value"
    done
}

# ============================================================
#                  FORMAT TRAFFIC
# ============================================================

format_xray_traffic() {

    if [ ! -x "$XRAY" ]; then
        echo "Xray not found."
        return
    fi

    json_output=$(
        "$XRAY" api statsquery \
        --server="$API_SERVER" 2>/dev/null
    )

    if [ -z "$json_output" ]; then
        echo "Unable to read Xray API."
        return
    fi

    echo "$json_output" |
    jq -r '
    .stat[]? |
    [.name, .value] |
    @tsv
    ' 2>/dev/null |
    awk -F'\t' '
    BEGIN {
        printf "USER\t\t\tUPLOAD\t\tDOWNLOAD\tTOTAL\n"
        printf "------------------------------------------------------------\n"
    }

    {
        name=$1
        value=$2

        split(name,p,">>>")

        user=p[2]
        direction=p[3]

        if (user == "")
            next

        if (direction == "uplink") {
            up[user]+=value
        }

        if (direction == "downlink") {
            down[user]+=value
        }
    }

    END {

        totalup=0
        totaldown=0

        for (u in up) {

            total=up[u]+down[u]

            printf "%-20s %12s %12s %12s\n",
            u,
            human(up[u]),
            human(down[u]),
            human(total)

            totalup+=up[u]
            totaldown+=down[u]
        }

        printf "\n------------------------------------------------------------\n"

        printf "TOTAL UPLOAD   : %s\n", human(totalup)
        printf "TOTAL DOWNLOAD : %s\n", human(totaldown)
        printf "TOTAL          : %s\n", human(totalup+totaldown)
    }

    function human(n) {

        if (n >= 1099511627776)
            return sprintf("%.2f TB", n/1099511627776)

        if (n >= 1073741824)
            return sprintf("%.2f GB", n/1073741824)

        if (n >= 1048576)
            return sprintf("%.2f MB", n/1048576)

        if (n >= 1024)
            return sprintf("%.2f KB", n/1024)

        return sprintf("%.0f B", n)
    }
    '
}

# ============================================================
#                    TELEGRAM /check
# ============================================================

telegram_check() {

    get_bot_data || return

    get_server_info

    TRAFFIC=$(format_xray_traffic)

    MESSAGE="*Server:* \`${DOMAIN}\`
*Server IP:* \`${MYIP}\`

---------------[ Xray Traffic ]---------------

\`\`\`
${TRAFFIC}
\`\`\`
"

    send_message "$MESSAGE"
}

# ============================================================
#                    ISP CACHE
# ============================================================

get_ip_info() {

    local ip="$1"

    local cache_line
    cache_line=$(grep -E "^${ip}\|" "$CACHE_FILE" 2>/dev/null | head -n1)

    if [ -n "$cache_line" ]; then

        IFS='|' read -r _ ISP COUNTRY <<< "$cache_line"

        echo "$ISP|$COUNTRY"
        return
    fi

    local response
    local isp
    local country

    response=$(curl -s --max-time 5 \
        "https://ipinfo.io/${ip}")

    isp=$(echo "$response" |
        jq -r '.org // empty' 2>/dev/null |
        sed 's/^AS[0-9]* //')

    country=$(echo "$response" |
        jq -r '.country // empty' 2>/dev/null)

    if [ -z "$isp" ] || [ -z "$country" ]; then

        isp="Unknown ISP"
        country="Unknown Country"
    fi

    echo "$ip|$isp|$country" >> "$CACHE_FILE"

    echo "$isp|$country"
}

# ============================================================
#                    GET XRAY USERS
# ============================================================

get_xray_users() {

    [ -f "$XRAY_CONFIG" ] || return

    grep -oP '^(#=|#@)\s*\K\w+' "$XRAY_CONFIG" |
        sort -u
}

# ============================================================
#                    MULTIPLE LOGIN
# ============================================================

check_multiple_login() {

    [ -f "$XRAY_LOG" ] || return
    [ -f "$XRAY_CONFIG" ] || return

    get_bot_data || return

    get_server_info

    USERS=$(get_xray_users)

    for user in $USERS; do

        ips=$(
            grep "email: $user" "$XRAY_LOG" 2>/dev/null |
            awk '
            {
                for(i=1;i<=NF;i++) {

                    if ($i ~ /from/) {

                        x=$(i+1)

                        gsub(/tcp:\/\//,"",x)
                        gsub(/\[/,"",x)
                        gsub(/\]/,"",x)

                        sub(/:[0-9]+$/,"",x)

                        print x
                    }
                }
            }
            ' |
            grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' |
            sort -u
        )

        ip_count=$(echo "$ips" | grep -c .)

        # Only notify if more than one IP
        [ "$ip_count" -le 1 ] && continue

        MESSAGE="🚨 *Multiple Login Detected* ‼️

💻 *Server:* \`${DOMAIN}\`
🌍 *Server IP:* \`${MYIP}\`
👥 *User:* \`${user}\`

🔑 *Logged in from multiple devices:*"

        # UUID
        UUID=$(grep -oP \
            "(?<=\"id\": \")\S+(?=\",.*\"email\": \"$user\")" \
            "$XRAY_CONFIG" |
            head -n1)

        if [ -n "$UUID" ]; then
            MESSAGE+="

🆔 *UUID:* \`${UUID}\`"
        fi

        MESSAGE+="

"

        for ip in $ips; do

            INFO=$(get_ip_info "$ip")

            IFS='|' read -r ISP COUNTRY <<< "$INFO"

            MESSAGE+="${ip} ➡️ ${ISP}, ${COUNTRY}
"
        done

        # Last login
        LAST_LOG=$(grep "email: $user" "$XRAY_LOG" 2>/dev/null |
            tail -n1)

        if [ -n "$LAST_LOG" ]; then

            LAST_LOGIN=$(echo "$LAST_LOG" |
                awk '{split($2,t,"."); print $1" "t[1]}')

            MESSAGE+="
🟢 *Status:* ONLINE
⏰ *Last Online:* \`${LAST_LOGIN}\`"
        fi

        # Expiration
        EXPIRED_DATE=$(
            grep -oP \
            "#= $user \K\d{4}-\d{2}-\d{2}( \d{2}:\d{2}:\d{2})?" \
            "$XRAY_CONFIG" |
            head -n1
        )

        EXPIRED_DATE=${EXPIRED_DATE:-Unknown}

        MESSAGE+="
⏳ *Expiration Date:* \`${EXPIRED_DATE}\`"

        send_message "$MESSAGE"

    done
}

# ============================================================
#                    TELEGRAM COMMAND LOOP
# ============================================================

telegram_command_loop() {

    get_bot_data || return

    OFFSET=0

    while true; do

        RESPONSE=$(
            curl -s --max-time 20 \
            "https://api.telegram.org/bot${TELEGRAM_TOKEN}/getUpdates?offset=${OFFSET}&timeout=15"
        )

        [ -z "$RESPONSE" ] && sleep 2 && continue

        UPDATES=$(echo "$RESPONSE" |
            jq -c '.result[]?' 2>/dev/null)

        while IFS= read -r UPDATE; do

            [ -z "$UPDATE" ] && continue

            UPDATE_ID=$(echo "$UPDATE" |
                jq -r '.update_id // empty')

            MSG_TEXT=$(echo "$UPDATE" |
                jq -r '.message.text // empty')

            MSG_CHAT=$(echo "$UPDATE" |
                jq -r '.message.chat.id // empty')

            if [ "$MSG_CHAT" = "$CHAT_ID" ]; then

                case "$MSG_TEXT" in

                    /check)

                        telegram_check
                        ;;

                esac

            fi

            if [ -n "$UPDATE_ID" ]; then
                OFFSET=$((UPDATE_ID + 1))
            fi

        done <<< "$UPDATES"

        sleep 1

    done
}

# ============================================================
#                    BOT DAEMON
# ============================================================

bot_daemon() {

    get_bot_data || {
        exit 1
    }

    mkdir -p /etc/xray
    touch "$CACHE_FILE"

    # Start Telegram command loop in background
    telegram_command_loop &

    TELEGRAM_PID=$!

    # Multiple login check
    # Run every 60 seconds
    while true; do

        check_multiple_login

        sleep 60

        # If Telegram loop somehow dies, restart it
        if ! kill -0 "$TELEGRAM_PID" 2>/dev/null; then

            telegram_command_loop &
            TELEGRAM_PID=$!

        fi

    done
}

# ============================================================
#                    CREATE BOT SERVICE
# ============================================================

install_bot_service() {

    clear

    echo -e "${BLUE}============================================${NC}"
    echo -e "          ${YELLOW}Installing Telegram Bot${NC}"
    echo -e "${BLUE}============================================${NC}"

    install_dependencies

    # Copy this script as daemon
    cp "$0" "$BOT_SCRIPT"

    chmod 755 "$BOT_SCRIPT"

    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Telegram Xray Bot
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$BOT_SCRIPT --daemon
Restart=always
RestartSec=5

User=root

NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload

    systemctl enable telegram-xray-bot.service >/dev/null 2>&1

    echo
    echo -e "${GREEN}Telegram Bot service installed.${NC}"

    if [ ! -s "$BOT_TOKEN_FILE" ] || [ ! -s "$CHAT_ID_FILE" ]; then

        echo
        echo -e "${YELLOW}Bot Token / Chat ID belum diset.${NC}"
        echo -e "${YELLOW}Sila pilih menu Setup Bot dahulu.${NC}"

    else

        systemctl restart telegram-xray-bot.service

        echo
        echo -e "${GREEN}Telegram Bot started.${NC}"
    fi

    sleep 2
}

# ============================================================
#                    START SERVICE
# ============================================================

start_bot() {

    if [ ! -f "$SERVICE_FILE" ]; then
        install_bot_service
        return
    fi

    systemctl daemon-reload
    systemctl enable telegram-xray-bot.service >/dev/null 2>&1
    systemctl start telegram-xray-bot.service

    echo
    echo -e "${GREEN}Telegram Bot started.${NC}"

    sleep 2
}

# ============================================================
#                    STOP SERVICE
# ============================================================

stop_bot() {

    systemctl stop telegram-xray-bot.service 2>/dev/null
    systemctl disable telegram-xray-bot.service 2>/dev/null

    echo
    echo -e "${RED}Telegram Bot stopped.${NC}"

    sleep 2
}

# ============================================================
#                    RESTART SERVICE
# ============================================================

restart_bot() {

    systemctl daemon-reload
    systemctl restart telegram-xray-bot.service

    echo
    echo -e "${GREEN}Telegram Bot restarted.${NC}"

    sleep 2
}

# ============================================================
#                    BOT STATUS
# ============================================================

bot_status() {

    clear

    echo -e "${BLUE}============================================${NC}"
    echo -e "             ${YELLOW}BOT STATUS${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo

    if systemctl is-active --quiet telegram-xray-bot.service; then
        echo -e "Service : ${GREEN}RUNNING${NC}"
    else
        echo -e "Service : ${RED}STOPPED${NC}"
    fi

    echo

    if [ -s "$BOT_TOKEN_FILE" ]; then
        echo -e "Bot Token : ${GREEN}Configured${NC}"
    else
        echo -e "Bot Token : ${RED}Not configured${NC}"
    fi

    if [ -s "$CHAT_ID_FILE" ]; then
        echo -e "Chat ID   : ${GREEN}Configured${NC}"
    else
        echo -e "Chat ID   : ${RED}Not configured${NC}"
    fi

    echo

    systemctl --no-pager status telegram-xray-bot.service

    echo
    read -rp "Press ENTER to continue..."
}

# ============================================================
#                    VIEW LOG
# ============================================================

bot_log() {

    clear

    echo -e "${BLUE}============================================${NC}"
    echo -e "             ${YELLOW}BOT LOG${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo

    journalctl \
        -u telegram-xray-bot.service \
        -n 100 \
        --no-pager

    echo
    read -rp "Press ENTER to continue..."
}

# ============================================================
#                    TEST TELEGRAM
# ============================================================

test_bot() {

    clear

    echo -e "${BLUE}============================================${NC}"
    echo -e "          ${YELLOW}TEST TELEGRAM BOT${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo

    get_bot_data || {
        echo -e "${RED}Bot Token / Chat ID belum diset.${NC}"
        sleep 2
        return
    }

    get_server_info

    MESSAGE="✅ *Telegram Bot Test*

💻 Server: \`${DOMAIN}\`
🌍 IP: \`${MYIP}\`

Telegram Bot is working."

    if send_message "$MESSAGE"; then
        echo -e "${GREEN}Test message sent.${NC}"
    else
        echo -e "${RED}Failed to send message.${NC}"
    fi

    sleep 2
}

# ============================================================
#                    REMOVE BOT
# ============================================================

remove_bot() {

    clear

    echo -e "${RED}============================================${NC}"
    echo -e "             ${YELLOW}REMOVE BOT${NC}"
    echo -e "${RED}============================================${NC}"
    echo

    read -rp "Remove Telegram Bot? [y/n]: " confirm

    case "$confirm" in

        y|Y)

            systemctl stop telegram-xray-bot.service 2>/dev/null
            systemctl disable telegram-xray-bot.service 2>/dev/null

            rm -f "$SERVICE_FILE"
            rm -f "$BOT_SCRIPT"

            systemctl daemon-reload

            echo
            echo -e "${GREEN}Bot service removed.${NC}"

            echo
            read -rp "Remove Token + Chat ID juga? [y/n]: " remove_data

            case "$remove_data" in
                y|Y)
                    rm -f "$BOT_TOKEN_FILE"
                    rm -f "$CHAT_ID_FILE"
                    echo -e "${GREEN}Bot credentials removed.${NC}"
                    ;;
            esac

            ;;

        *)
            echo -e "${YELLOW}Cancelled.${NC}"
            ;;
    esac

    sleep 2
}

# ============================================================
#                    BOT MENU
# ============================================================

bot_menu() {

    while true; do

        clear

        echo -e "${BLUE}╭════════════════════════════════════════════╮${NC}"
        echo -e "${BLUE}│       ${YELLOW}•••───[ TELEGRAM BOT ]───•••       ${BLUE}│${NC}"
        echo -e "${BLUE}╰════════════════════════════════════════════╯${NC}"
        echo

        if systemctl is-active --quiet telegram-xray-bot.service; then
            echo -e "        Status : ${GREEN}RUNNING${NC}"
        else
            echo -e "        Status : ${RED}STOPPED${NC}"
        fi

        echo
        echo -e " ${GREEN}[01]${NC} Setup / Change Bot"
        echo -e " ${GREEN}[02]${NC} Install Bot Service"
        echo -e " ${GREEN}[03]${NC} Start Bot"
        echo -e " ${GREEN}[04]${NC} Stop Bot"
        echo -e " ${GREEN}[05]${NC} Restart Bot"
        echo -e " ${GREEN}[06]${NC} Bot Status"
        echo -e " ${GREEN}[07]${NC} Test Telegram"
        echo -e " ${GREEN}[08]${NC} View Bot Log"
        echo -e " ${GREEN}[09]${NC} Remove Bot"
        echo -e " ${GREEN}[10]${NC} Exit"
        echo
        echo -e "${BLUE}════════════════════════════════════════════${NC}"

        read -rp " Select menu [1-10]: " opt

        case "$opt" in

            01|1)
                setup_bot
                ;;

            02|2)
                install_bot_service
                ;;

            03|3)
                start_bot
                ;;

            04|4)
                stop_bot
                ;;

            05|5)
                restart_bot
                ;;

            06|6)
                bot_status
                ;;

            07|7)
                test_bot
                ;;

            08|8)
                bot_log
                ;;

            09|9)
                remove_bot
                ;;

            10|0)
                clear
                exit 0
                ;;

            *)
                echo -e "${RED}Invalid option.${NC}"
                sleep 1
                ;;

        esac

    done
}

# ============================================================
#                    DAEMON MODE
# ============================================================

if [ "$1" = "--daemon" ]; then
    bot_daemon
    exit 0
fi

# ============================================================
#                    MAIN
# ============================================================

check_root
install_dependencies
bot_menu
