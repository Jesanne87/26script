#!/bin/bash

# ==========================================================
# TELEGRAM BACKUP MANAGER
# BACKUP + RESTORE
# ==========================================================

CONFIG="/etc/telegram-backup.conf"
SCRIPT="/usr/bin/telegram-backup"

SERVICE="/etc/systemd/system/telegram-backup.service"
TIMER="/etc/systemd/system/telegram-backup.timer"

BACKUP_DIR="/root/backup"
RESTORE_DIR="/root/telegram-restore"

LAST_FILE="/etc/telegram-backup-last.txt"

# ==========================================================
# COLOR
# ==========================================================

NC='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'

# ==========================================================
# ROOT
# ==========================================================

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Sila jalankan sebagai root.${NC}"
    exit 1
fi

# ==========================================================
# CONFIG
# ==========================================================

create_config() {

    if [ ! -f "$CONFIG" ]; then

        cat > "$CONFIG" <<EOF
BOT_TOKEN=""
CHAT_ID=""
BACKUP_PASS="jsphantom"
BACKUP_TIME="03:00"
EOF

        chmod 600 "$CONFIG"
    fi

    source "$CONFIG"
}

create_config

# ==========================================================
# DEPENDENCY
# ==========================================================

install_dependency() {

    NEED=0

    command -v curl >/dev/null 2>&1 || NEED=1
    command -v 7z >/dev/null 2>&1 || NEED=1
    command -v rsync >/dev/null 2>&1 || NEED=1

    if [ "$NEED" -eq 1 ]; then

        echo
        echo -e "${CYAN}Installing dependency...${NC}"

        apt-get update -y >/dev/null 2>&1

        command -v curl >/dev/null 2>&1 || \
            apt-get install -y curl >/dev/null 2>&1

        command -v 7z >/dev/null 2>&1 || \
            apt-get install -y p7zip-full >/dev/null 2>&1

        command -v rsync >/dev/null 2>&1 || \
            apt-get install -y rsync >/dev/null 2>&1

    fi
}

install_dependency

# ==========================================================
# SAVE CONFIG
# ==========================================================

save_config() {

    cat > "$CONFIG" <<EOF
BOT_TOKEN="$BOT_TOKEN"
CHAT_ID="$CHAT_ID"
BACKUP_PASS="$BACKUP_PASS"
BACKUP_TIME="$BACKUP_TIME"
EOF

    chmod 600 "$CONFIG"
}

# ==========================================================
# DOMAIN
# ==========================================================

get_domain() {

    if [ -f /usr/local/etc/xray/domain ]; then
        DOMAIN=$(cat /usr/local/etc/xray/domain 2>/dev/null)
    fi

    [ -z "$DOMAIN" ] && DOMAIN=$(hostname)

    NAME="$DOMAIN"
}

# ==========================================================
# IP
# ==========================================================

get_ip() {

    MYIP=$(curl -4 -s --max-time 10 icanhazip.com 2>/dev/null)

    [ -z "$MYIP" ] && MYIP="Unknown"
}

# ==========================================================
# TELEGRAM TEST
# ==========================================================

test_telegram() {

    source "$CONFIG"

    if [ -z "$BOT_TOKEN" ]; then
        echo
        echo -e "${RED}Bot Token belum diset.${NC}"
        read -rp "Tekan Enter..."
        return
    fi

    if [ -z "$CHAT_ID" ]; then
        echo
        echo -e "${RED}Chat ID belum diset.${NC}"
        read -rp "Tekan Enter..."
        return
    fi

    echo
    echo -e "${CYAN}Menghantar test message...${NC}"

    RESULT=$(curl -s \
        --max-time 15 \
        -X POST \
        "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="$CHAT_ID" \
        --data-urlencode \
        text="Telegram Backup Manager

Test berjaya.

Server : $(hostname)
Date : $(date '+%Y-%m-%d %H:%M:%S')")

    if echo "$RESULT" | grep -q '"ok":true'; then

        echo
        echo -e "${GREEN}✓ Telegram OK.${NC}"

    else

        echo
        echo -e "${RED}✗ Telegram gagal.${NC}"
        echo
        echo "$RESULT"

    fi

    read -rp "Tekan Enter..."
}

# ==========================================================
# BACKUP
# ==========================================================

run_backup() {

    source "$CONFIG"

    if [ -z "$BOT_TOKEN" ]; then
        echo "Bot Token belum diset."
        return 1
    fi

    if [ -z "$CHAT_ID" ]; then
        echo "Chat ID belum diset."
        return 1
    fi

    if [ -z "$BACKUP_PASS" ]; then
        echo "Password backup belum diset."
        return 1
    fi

    get_domain
    get_ip

    DATE_NOW=$(date +"%Y-%m-%d %H:%M:%S")

    ARCHIVE="${NAME}-$(date +%Y%m%d-%H%M%S).7z"

    mkdir -p "$BACKUP_DIR"

    echo
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${WHITE}             TELEGRAM BACKUP${NC}"
    echo -e "${CYAN}==========================================${NC}"
    echo
    echo "Server : $DOMAIN"
    echo "IP     : $MYIP"
    echo

    # ======================================================
    # CLEAN OLD TEMP
    # ======================================================

    rm -rf "$BACKUP_DIR"
    rm -f "/root/$ARCHIVE"

    mkdir -p "$BACKUP_DIR"

    # ======================================================
    # PREPARE HTML
    # ======================================================

    echo -e "${YELLOW}[1/4] Menyediakan fail...${NC}"

    if [ -d /var/www/html ]; then

        mkdir -p "$BACKUP_DIR/html"

        rsync -a \
            /var/www/html/ \
            "$BACKUP_DIR/html/" \
            >/dev/null 2>&1

    fi

    # ======================================================
    # PREPARE USER
    # ======================================================

    if [ -d /user ]; then

        mkdir -p "$BACKUP_DIR/user"

        rsync -a \
            --exclude='bwcounter/' \
            --exclude='bwlog/' \
            /user/ \
            "$BACKUP_DIR/user/" \
            >/dev/null 2>&1

    fi

    # ======================================================
    # PREPARE XRAY
    # ======================================================

    if [ -d /usr/local/etc/xray ]; then

        mkdir -p "$BACKUP_DIR/xray"

        rsync -a \
            /usr/local/etc/xray/ \
            "$BACKUP_DIR/xray/" \
            >/dev/null 2>&1

    fi

    # ======================================================
    # COMPRESS
    # ======================================================

    echo -e "${YELLOW}[2/4] Compress + encrypt...${NC}"

    7z a \
        -t7z \
        -mx=1 \
        -p"$BACKUP_PASS" \
        -mhe=on \
        "/root/$ARCHIVE" \
        "$BACKUP_DIR" \
        >/dev/null 2>&1

    if [ ! -f "/root/$ARCHIVE" ]; then

        echo
        echo -e "${RED}Backup gagal dibuat.${NC}"

        return 1

    fi

    SIZE_MB=$(du -m "/root/$ARCHIVE" | awk '{print $1}')

    echo
    echo "File : $ARCHIVE"
    echo "Size : ${SIZE_MB}MB"
    echo

    # ======================================================
    # SIZE CHECK
    # ======================================================

    if [ "$SIZE_MB" -gt 49 ]; then

        echo -e "${RED}Backup melebihi 49MB.${NC}"

        curl -s \
            --max-time 15 \
            -X POST \
            "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
            -d chat_id="$CHAT_ID" \
            --data-urlencode \
            text="Backup gagal

Server : $DOMAIN
IP : $MYIP

Saiz backup ${SIZE_MB}MB melebihi had Telegram."

        rm -f "/root/$ARCHIVE"
        rm -rf "$BACKUP_DIR"

        return 1
    fi

    # ======================================================
    # UPLOAD
    # ======================================================

    echo -e "${YELLOW}[3/4] Upload ke Telegram...${NC}"

    RESULT=$(curl -s \
        --max-time 300 \
        -F chat_id="$CHAT_ID" \
        -F document=@"/root/$ARCHIVE" \
        "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument")

    # ======================================================
    # CHECK UPLOAD
    # ======================================================

    if ! echo "$RESULT" | grep -q '"ok":true'; then

        echo
        echo -e "${RED}Upload Telegram gagal.${NC}"
        echo
        echo "$RESULT"

        curl -s \
            --max-time 15 \
            -X POST \
            "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
            -d chat_id="$CHAT_ID" \
            --data-urlencode \
            text="Upload backup gagal

Server : $DOMAIN
IP : $MYIP
File : $ARCHIVE
Size : ${SIZE_MB}MB" \
            >/dev/null

        rm -f "/root/$ARCHIVE"
        rm -rf "$BACKUP_DIR"

        return 1
    fi

    # ======================================================
    # GET FILE ID
    # ======================================================

    FILE_ID=$(echo "$RESULT" | \
        sed -n 's/.*"document":{"file_name".*"file_id":"\([^"]*\)".*/\1/p')

    # ======================================================
    # SAVE LAST FILE ID
    # ======================================================

    if [ -n "$FILE_ID" ]; then

        cat > "$LAST_FILE" <<EOF
FILE_NAME="$ARCHIVE"
FILE_ID="$FILE_ID"
DATE="$DATE_NOW"
SIZE="${SIZE_MB}MB"
EOF

        chmod 600 "$LAST_FILE"

    fi

    # ======================================================
    # NOTIFICATION
    # ======================================================

    echo -e "${YELLOW}[4/4] Backup berjaya.${NC}"

    if [ -n "$FILE_ID" ]; then

curl -s \
    --max-time 15 \
    -X POST \
    "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d parse_mode="Markdown" \
    --data-urlencode \
    text="✅ *Backup Selesai*

*🖥️ Server:* $DOMAIN
*🌐 IP:* $MYIP
*📅 Date:* $DATE_NOW
*📁 File:* $ARCHIVE
*📦 Size:* ${SIZE_MB}MB

*File ID:*
\`$FILE_ID\`" \
    >/dev/null

    else

        curl -s \
            --max-time 15 \
            -X POST \
            "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
            -d chat_id="$CHAT_ID" \
            --data-urlencode \
        text="Backup Selesai✅ 

🖥️ Server : $DOMAIN
🌐 IP : $MYIP
📅 Date : $DATE_NOW
📁 File : $ARCHIVE
📦 Size : ${SIZE_MB}MB" \
            >/dev/null

    fi

    # ======================================================
    # CLEANUP
    # ======================================================

    rm -f "/root/$ARCHIVE" >/dev/null 2>&1
    rm -rf "$BACKUP_DIR" >/dev/null 2>&1

    echo
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN} Backup selesai${NC}"
    echo -e "${GREEN} Fail temporary telah dipadam${NC}"
    echo -e "${GREEN}==========================================${NC}"
}

# ==========================================================
# DOWNLOAD TELEGRAM FILE
# ==========================================================

download_telegram_file() {

    FILE_ID="$1"
    OUTPUT="$2"

    source "$CONFIG"

    echo
    echo -e "${YELLOW}[1/4] Mendapatkan Telegram file path...${NC}"

    RESPONSE=$(curl -s \
        --max-time 30 \
        "https://api.telegram.org/bot${BOT_TOKEN}/getFile?file_id=${FILE_ID}")

    if ! echo "$RESPONSE" | grep -q '"ok":true'; then

        echo
        echo -e "${RED}File ID tidak sah atau Telegram gagal.${NC}"
        echo
        echo "$RESPONSE"

        return 1
    fi

    FILE_PATH=$(echo "$RESPONSE" | \
        sed -n 's/.*"file_path":"\([^"]*\)".*/\1/p')

    if [ -z "$FILE_PATH" ]; then

        echo -e "${RED}File path Telegram tidak dijumpai.${NC}"

        return 1
    fi

    echo -e "${YELLOW}[2/4] Download backup...${NC}"

    curl -L \
        --fail \
        --max-time 600 \
        -o "$OUTPUT" \
        "https://api.telegram.org/file/bot${BOT_TOKEN}/${FILE_PATH}"

    if [ ! -s "$OUTPUT" ]; then

        echo
        echo -e "${RED}Download gagal.${NC}"

        rm -f "$OUTPUT"

        return 1
    fi

    return 0
}

# ==========================================================
# RESTORE BACKUP
# ==========================================================

restore_backup() {

    source "$CONFIG"

    if [ -z "$BOT_TOKEN" ]; then
        echo
        echo -e "${RED}Bot Token belum diset.${NC}"
        read -rp "Tekan Enter..."
        return
    fi

    if [ -z "$CHAT_ID" ]; then
        echo
        echo -e "${RED}Chat ID belum diset.${NC}"
        read -rp "Tekan Enter..."
        return
    fi

    if [ -z "$BACKUP_PASS" ]; then
        echo
        echo -e "${RED}Password backup belum diset.${NC}"
        read -rp "Tekan Enter..."
        return
    fi

    echo
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${WHITE}             RESTORE BACKUP${NC}"
    echo -e "${CYAN}==========================================${NC}"
    echo

    # ======================================================
    # LAST BACKUP
    # ======================================================

    if [ -f "$LAST_FILE" ]; then

        source "$LAST_FILE"

        echo "Backup terakhir:"
        echo
        echo "File : $FILE_NAME"
        echo "Date : $DATE"
        echo "Size : $SIZE"
        echo

    fi

    read -rp "Masukkan File ID Telegram: " INPUT_FILE_ID

    if [ -z "$INPUT_FILE_ID" ]; then

        echo
        echo -e "${RED}File ID kosong.${NC}"

        read -rp "Tekan Enter..."
        return
    fi

    # ======================================================
    # RESTORE TYPE
    # ======================================================

    echo
    echo "Pilih apa yang mahu restore:"
    echo
    echo " 1. /var/www/html"
    echo " 2. /user"
    echo " 3. /usr/local/etc/xray"
    echo " 4. SEMUA"
    echo " 0. Batal"
    echo

    read -rp "Pilih [0-4]: " RESTORE_OPTION

    case "$RESTORE_OPTION" in

        1)
            RESTORE_HTML=1
            ;;

        2)
            RESTORE_USER=1
            ;;

        3)
            RESTORE_XRAY=1
            ;;

        4)
            RESTORE_HTML=1
            RESTORE_USER=1
            RESTORE_XRAY=1
            ;;

        0)
            return
            ;;

        *)
            echo
            echo -e "${RED}Pilihan tidak sah.${NC}"
            read -rp "Tekan Enter..."
            return
            ;;

    esac

    # ======================================================
    # CONFIRM
    # ======================================================

    echo
    echo -e "${YELLOW}AMARAN:${NC}"
    echo
    echo "Restore akan overwrite fail sedia ada."
    echo

    [ "$RESTORE_HTML" = "1" ] && \
        echo " - /var/www/html"

    [ "$RESTORE_USER" = "1" ] && \
        echo " - /user"

    [ "$RESTORE_XRAY" = "1" ] && \
        echo " - /usr/local/etc/xray"

    echo

    read -rp "Teruskan restore? [y/N]: " CONFIRM

    case "$CONFIRM" in
        y|Y)
            ;;
        *)
            echo "Restore dibatalkan."
            read -rp "Tekan Enter..."
            return
            ;;
    esac

    # ======================================================
    # PREPARE
    # ======================================================

    rm -rf "$RESTORE_DIR"
    mkdir -p "$RESTORE_DIR"

    ARCHIVE="$RESTORE_DIR/backup.7z"

    # ======================================================
    # DOWNLOAD
    # ======================================================

    if ! download_telegram_file "$INPUT_FILE_ID" "$ARCHIVE"; then

        rm -rf "$RESTORE_DIR"

        read -rp "Tekan Enter..."
        return
    fi

    # ======================================================
    # EXTRACT
    # ======================================================

    echo
    echo -e "${YELLOW}[3/4] Decrypt + extract backup...${NC}"

    if ! 7z x \
        -p"$BACKUP_PASS" \
        -y \
        "$ARCHIVE" \
        -o"$RESTORE_DIR/extracted" \
        >/dev/null 2>&1; then

        echo
        echo -e "${RED}Extract gagal.${NC}"
        echo -e "${YELLOW}Pastikan password backup betul.${NC}"

        rm -rf "$RESTORE_DIR"

        read -rp "Tekan Enter..."
        return
    fi

    # ======================================================
    # FIND ROOT
    # ======================================================

    EXTRACT_ROOT="$RESTORE_DIR/extracted/backup"

    if [ ! -d "$EXTRACT_ROOT" ]; then

        EXTRACT_ROOT=$(find "$RESTORE_DIR/extracted" \
            -maxdepth 2 \
            -type d \
            -name backup \
            | head -1)

    fi

    if [ -z "$EXTRACT_ROOT" ] || [ ! -d "$EXTRACT_ROOT" ]; then

        echo
        echo -e "${RED}Struktur backup tidak dikenali.${NC}"

        rm -rf "$RESTORE_DIR"

        read -rp "Tekan Enter..."
        return
    fi

    # ======================================================
    # RESTORE HTML
    # ======================================================

    if [ "$RESTORE_HTML" = "1" ]; then

        if [ -d "$EXTRACT_ROOT/html" ]; then

            echo
            echo "Restore /var/www/html..."

            mkdir -p /var/www/html

            rsync -a \
                "$EXTRACT_ROOT/html/" \
                /var/www/html/

        fi
    fi

    # ======================================================
    # RESTORE USER
    # ======================================================

    if [ "$RESTORE_USER" = "1" ]; then

        if [ -d "$EXTRACT_ROOT/user" ]; then

            echo
            echo "Restore /user..."

            mkdir -p /user

            rsync -a \
                "$EXTRACT_ROOT/user/" \
                /user/

        fi
    fi

    # ======================================================
    # RESTORE XRAY
    # ======================================================

    if [ "$RESTORE_XRAY" = "1" ]; then

        if [ -d "$EXTRACT_ROOT/xray" ]; then

            echo
            echo "Restore /usr/local/etc/xray..."

            mkdir -p /usr/local/etc/xray

            rsync -a \
                "$EXTRACT_ROOT/xray/" \
                /usr/local/etc/xray/

        fi
    fi

    # ======================================================
    # PERMISSION
    # ======================================================

    echo
    echo -e "${YELLOW}[4/4] Menyelesaikan restore...${NC}"

    if [ "$RESTORE_HTML" = "1" ]; then

        if id www-data >/dev/null 2>&1; then
            chown -R www-data:www-data /var/www/html \
                >/dev/null 2>&1 || true
        fi

    fi

    # ======================================================
    # RESTART SERVICES
    # ======================================================

    if [ "$RESTORE_XRAY" = "1" ]; then

        systemctl restart xray \
            >/dev/null 2>&1 || true

    fi

    if [ "$RESTORE_HTML" = "1" ]; then

        systemctl restart nginx \
            >/dev/null 2>&1 || true

    fi

    # ======================================================
    # CLEAN
    # ======================================================

    rm -rf "$RESTORE_DIR"

    echo
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN} RESTORE BERJAYA${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo

    [ "$RESTORE_HTML" = "1" ] && \
        echo "✓ /var/www/html"

    [ "$RESTORE_USER" = "1" ] && \
        echo "✓ /user"

    [ "$RESTORE_XRAY" = "1" ] && \
        echo "✓ /usr/local/etc/xray"

    echo

    read -rp "Tekan Enter..."
}

# ==========================================================
# SET BOT TOKEN
# ==========================================================

set_bot_token() {

    source "$CONFIG"

    echo
    echo -e "${CYAN}Masukkan Bot Token Telegram${NC}"
    echo

    read -rsp "Bot Token: " NEW_TOKEN
    echo

    if [ -z "$NEW_TOKEN" ]; then

        echo -e "${RED}Token kosong.${NC}"

        read -rp "Tekan Enter..."
        return

    fi

    BOT_TOKEN="$NEW_TOKEN"

    save_config

    echo
    echo -e "${GREEN}✓ Bot Token disimpan.${NC}"
    echo

    read -rp "Tekan Enter..."
}

# ==========================================================
# SET CHAT ID
# ==========================================================

set_chat_id() {

    source "$CONFIG"

    echo
    echo -e "${CYAN}Masukkan Chat ID Telegram${NC}"
    echo

    read -rp "Chat ID: " NEW_CHAT_ID

    if [ -z "$NEW_CHAT_ID" ]; then

        echo -e "${RED}Chat ID kosong.${NC}"

        read -rp "Tekan Enter..."
        return

    fi

    CHAT_ID="$NEW_CHAT_ID"

    save_config

    echo
    echo -e "${GREEN}✓ Chat ID disimpan.${NC}"
    echo

    read -rp "Tekan Enter..."
}

# ==========================================================
# SET PASSWORD
# ==========================================================

set_backup_password() {

    source "$CONFIG"

    echo
    echo -e "${CYAN}Tetapkan password archive 7z${NC}"
    echo

    read -rsp "Password baru: " NEW_PASS
    echo

    if [ -z "$NEW_PASS" ]; then

        echo -e "${RED}Password tidak boleh kosong.${NC}"

        read -rp "Tekan Enter..."
        return

    fi

    read -rsp "Ulang password: " CONFIRM_PASS
    echo

    if [ "$NEW_PASS" != "$CONFIRM_PASS" ]; then

        echo
        echo -e "${RED}Password tidak sama.${NC}"

        read -rp "Tekan Enter..."
        return

    fi

    BACKUP_PASS="$NEW_PASS"

    save_config

    echo
    echo -e "${GREEN}✓ Password backup berjaya ditukar.${NC}"
    echo

    read -rp "Tekan Enter..."
}

# ==========================================================
# SYSTEMD
# ==========================================================

create_systemd() {

    cat > "$SERVICE" <<EOF
[Unit]
Description=Telegram Xray Backup
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/telegram-backup backup
EOF

    cat > "$TIMER" <<EOF
[Unit]
Description=Daily Telegram Xray Backup

[Timer]
OnCalendar=*-*-* ${BACKUP_TIME}:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
    systemctl daemon-reload
}

# ==========================================================
# ENABLE AUTO
# ==========================================================

enable_auto_backup() {

    source "$CONFIG"

    echo
    echo "Tetapkan waktu backup harian."
    echo
    echo "Contoh:"
    echo "03:00"
    echo "12:00"
    echo "23:30"
    echo

    read -rp "Waktu [$BACKUP_TIME]: " NEW_TIME

    [ -z "$NEW_TIME" ] && NEW_TIME="$BACKUP_TIME"

    if ! [[ "$NEW_TIME" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]; then

        echo
        echo -e "${RED}Format waktu tidak sah.${NC}"

        read -rp "Tekan Enter..."
        return

    fi

    BACKUP_TIME="$NEW_TIME"

    save_config
    create_systemd

    systemctl enable --now telegram-backup.timer \
        >/dev/null 2>&1

    echo
    echo -e "${GREEN}✓ Auto backup diaktifkan.${NC}"
    echo
    echo "Backup setiap hari : $BACKUP_TIME"
    echo

    systemctl list-timers \
        telegram-backup.timer \
        --no-pager

    read -rp "Tekan Enter..."
}

# ==========================================================
# DISABLE AUTO
# ==========================================================

disable_auto_backup() {

    systemctl disable --now telegram-backup.timer \
        >/dev/null 2>&1 || true

    echo
    echo -e "${GREEN}✓ Auto backup dimatikan.${NC}"
    echo

    read -rp "Tekan Enter..."
}

# ==========================================================
# STATUS
# ==========================================================

show_status() {

    source "$CONFIG"

    get_domain

    echo
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${WHITE}           BACKUP STATUS${NC}"
    echo -e "${CYAN}==========================================${NC}"
    echo

    echo "Domain      : $DOMAIN"

    if [ -n "$BOT_TOKEN" ]; then
        echo "Bot Token   : ${BOT_TOKEN:0:10}********"
    else
        echo "Bot Token   : Belum diset"
    fi

    echo "Chat ID     : ${CHAT_ID:-Belum diset}"

    if [ -n "$BACKUP_PASS" ]; then
        echo "7z Password : ********"
    else
        echo "7z Password : Belum diset"
    fi

    echo "Backup Time : ${BACKUP_TIME:-03:00}"

    echo

    if systemctl is-enabled telegram-backup.timer \
        >/dev/null 2>&1; then

        echo -e "Auto Backup : ${GREEN}AKTIF${NC}"
        echo

        systemctl list-timers \
            telegram-backup.timer \
            --no-pager

    else

        echo -e "Auto Backup : ${RED}TIDAK AKTIF${NC}"

    fi

    echo

    if [ -f "$LAST_FILE" ]; then

        echo -e "${CYAN}Backup terakhir:${NC}"
        echo

        source "$LAST_FILE"

        echo "File     : $FILE_NAME"
        echo "Date     : $DATE"
        echo "Size     : $SIZE"
        echo "File ID  : $FILE_ID"

    else

        echo "Belum ada rekod backup."

    fi

    echo

    read -rp "Tekan Enter..."
}

# ==========================================================
# LOG
# ==========================================================

show_log() {

    echo
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${WHITE}             BACKUP LOG${NC}"
    echo -e "${CYAN}==========================================${NC}"
    echo

    journalctl \
        -u telegram-backup.service \
        -n 50 \
        --no-pager 2>/dev/null || \
        echo "Tiada log."

    echo

    read -rp "Tekan Enter..."
}

# ==========================================================
# BACKUP NOW
# ==========================================================

backup_now() {

    run_backup

    echo

    read -rp "Tekan Enter..."
}

# ==========================================================
# MAIN MENU
# ==========================================================

menu() {

    while true; do

        clear

        source "$CONFIG"

        echo -e "${CYAN}==============================================${NC}"
        echo -e "${WHITE}          TELEGRAM BACKUP MANAGER${NC}"
        echo -e "${CYAN}==============================================${NC}"
        echo

        if [ -n "$BOT_TOKEN" ]; then
            BOT_STATUS="${GREEN}Configured${NC}"
        else
            BOT_STATUS="${RED}Not Set${NC}"
        fi

        if [ -n "$CHAT_ID" ]; then
            CHAT_STATUS="${GREEN}${CHAT_ID}${NC}"
        else
            CHAT_STATUS="${RED}Not Set${NC}"
        fi

        echo -e " Bot Token : $BOT_STATUS"
        echo -e " Chat ID   : $CHAT_STATUS"
        echo -e " 7z Pass   : ${GREEN}Configured${NC}"
        echo -e " Auto Time : ${YELLOW}${BACKUP_TIME:-03:00}${NC}"

        echo
        echo -e "${CYAN}----------------------------------------------${NC}"
        echo

        echo " 1. Set / Edit Bot Token"
        echo " 2. Set / Edit Chat ID"
        echo " 3. Set / Edit Backup Password"
        echo " 4. Test Telegram"
        echo
        echo " 5. Backup Sekarang"
        echo " 6. Restore Backup"
        echo
        echo " 7. Aktifkan Auto Backup Harian"
        echo " 8. Matikan Auto Backup"
        echo
        echo " 9. Lihat Status"
        echo "10. Lihat Log Backup"
        echo
        echo " 0. Keluar"

        echo
        echo -e "${CYAN}----------------------------------------------${NC}"

        read -rp "Pilih [0-10]: " OPTION

        case "$OPTION" in

            1)
                set_bot_token
                ;;

            2)
                set_chat_id
                ;;

            3)
                set_backup_password
                ;;

            4)
                test_telegram
                ;;

            5)
                backup_now
                ;;

            6)
                restore_backup
                ;;

            7)
                enable_auto_backup
                ;;

            8)
                disable_auto_backup
                ;;

            9)
                show_status
                ;;

            10)
                show_log
                ;;

            0)
                clear
                exit 0
                ;;

            *)
                echo
                echo -e "${RED}Pilihan tidak sah.${NC}"
                sleep 1
                ;;

        esac

    done
}

# ==========================================================
# SYSTEMD BACKUP MODE
# ==========================================================

if [ "${1:-}" = "backup" ]; then

    run_backup

    exit $?

fi

# ==========================================================
# START MENU
# ==========================================================

menu
