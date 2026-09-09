#!/bin/bash

# ============================================================
#        NGINX + XRAY VPN OPTIMIZER MANAGER
#        Extreme Tuning + Memory Guard
#
#        For:
#        Xray / VLESS / VMess / Trojan / SS
#        WebSocket / gRPC / Cloudflare
#
#        Author : JsPhantom
# ============================================================

set -u

NGINX_CONF="/etc/nginx/nginx.conf"
BACKUP_ROOT="/root/nginx-backups"

GUARD="/usr/local/sbin/nginx-memory-guard"
GUARD_SERVICE="/etc/systemd/system/nginx-memory-guard.service"
GUARD_LOG="/var/log/nginx-memory-guard.log"
GUARD_STATE="/run/nginx-memory-guard.last"

THRESHOLD_MB=800
COOLDOWN=300
CHECK_INTERVAL=30

# ============================================================
# COLORS
# ============================================================

NC='\e[0m'
RB='\e[31;1m'
GB='\e[32;1m'
YB='\e[33;1m'
BB='\e[34;1m'
CB='\e[36;1m'
WB='\e[37;1m'
MB='\e[35;1m'

# ============================================================
# ROOT CHECK
# ============================================================

if [ "$(id -u)" != "0" ]; then
    echo -e "${RB}ERROR: Script mesti dijalankan sebagai root.${NC}"
    exit 1
fi

# ============================================================
# FUNCTIONS
# ============================================================

pause() {
    echo
    read -rp "Tekan ENTER untuk kembali ke menu..."
}

header() {
    clear
    echo -e "${GB}+------------------------------------------------------+${NC}"
    echo -e "${GB}¦${WB}          NGINX + XRAY VPN OPTIMIZER${GB}             ¦${NC}"
    echo -e "${GB}¦${CB}       Extreme Tuning + Memory Guard${GB}             ¦${NC}"
    echo -e "${GB}+------------------------------------------------------+${NC}"
    echo
}

check_nginx() {
    if ! command -v nginx >/dev/null 2>&1; then
        echo -e "${RB}Nginx tidak dijumpai.${NC}"
        echo "Sila install Nginx dahulu."
        return 1
    fi

    return 0
}

check_xray() {
    if ! command -v xray >/dev/null 2>&1; then
        echo -e "${YB}Xray tidak dijumpai.${NC}"
        echo "Nginx tuning masih boleh diteruskan."
        return 1
    fi

    return 0
}

# ============================================================
# BACKUP NGINX
# ============================================================

backup_nginx() {

    mkdir -p "$BACKUP_ROOT"

    local BACKUP_DIR

    BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"

    echo -e "${CB}Creating Nginx backup...${NC}"

    mkdir -p "$BACKUP_DIR"

    if cp -a /etc/nginx "$BACKUP_DIR/"; then
        echo -e "${GB}Backup berjaya:${NC}"
        echo "$BACKUP_DIR"
        echo "$BACKUP_DIR" > /run/nginx-last-backup
        return 0
    else
        echo -e "${RB}Backup gagal!${NC}"
        return 1
    fi
}

# ============================================================
# EXTREME OPTIMIZER
# ============================================================

optimize_nginx_xray() {

    header

    echo -e "${CB}[ NGINX + XRAY EXTREME OPTIMIZER ]${NC}"
    echo

    if ! check_nginx; then
        pause
        return
    fi

    echo -e "${GB}Nginx detected:${NC}"
    nginx -v 2>&1

    echo

    # --------------------------------------------------------
    # BACKUP
    # --------------------------------------------------------

    if ! backup_nginx; then
        pause
        return
    fi

    echo

    # --------------------------------------------------------
    # SYSTEMD NGINX
    # --------------------------------------------------------

    echo -e "${CB}[1/6] Configuring Nginx systemd limits...${NC}"

    mkdir -p /etc/systemd/system/nginx.service.d

    cat > /etc/systemd/system/nginx.service.d/override.conf <<'EOF'
[Service]
LimitNOFILE=65535
TasksMax=infinity
EOF

    # --------------------------------------------------------
    # SYSTEMD XRAY
    # --------------------------------------------------------

    echo -e "${CB}[2/6] Configuring Xray systemd limits...${NC}"

    mkdir -p /etc/systemd/system/xray.service.d

    cat > /etc/systemd/system/xray.service.d/override.conf <<'EOF'
[Service]
LimitNOFILE=65535
Restart=always
RestartSec=3
EOF

    # --------------------------------------------------------
    # SYSCTL
    # --------------------------------------------------------

    echo -e "${CB}[3/6] Applying kernel network tuning...${NC}"

    SYSCTL_CONF="/etc/sysctl.conf"
    SYSCTL_MARKER="# JsPhantom NGINX XRAY VPN TUNING"

    if [ ! -f "${SYSCTL_CONF}.bak" ]; then
        cp "$SYSCTL_CONF" "${SYSCTL_CONF}.bak"
    fi

    # Remove old tuning block if it exists
    sed -i "/^# VPS tuning added by script$/,/^net.ipv4.tcp_keepalive_probes = 5$/d" "$SYSCTL_CONF"
    sed -i "/^# JsPhantom NGINX XRAY VPN TUNING$/,/^net.ipv4.tcp_keepalive_probes = 5$/d" "$SYSCTL_CONF"

    cat >> "$SYSCTL_CONF" <<'EOF'

# JsPhantom NGINX XRAY VPN TUNING
fs.file-max = 2097152

net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535

net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 15

net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65535

net.ipv4.tcp_keepalive_time = 120
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5
EOF

    sysctl -p >/dev/null 2>&1 || true

    # --------------------------------------------------------
    # NGINX CONFIG
    # --------------------------------------------------------

    echo -e "${CB}[4/6] Rebuilding Nginx optimized configuration...${NC}"

    cat > "$NGINX_CONF" <<'EOF'
user www-data;

worker_processes auto;

pid /var/run/nginx.pid;

events {
    use epoll;
    worker_connections 8192;
    multi_accept on;
}

http {

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;

    keepalive_timeout 15;
    keepalive_requests 1000;

    reset_timedout_connection on;

    client_max_body_size 32M;

    client_header_buffer_size 4k;
    large_client_header_buffers 2 16k;

    types_hash_max_size 2048;

    server_tokens off;

    gzip on;
    gzip_vary on;
    gzip_comp_level 4;

    gzip_types
        text/plain
        text/css
        application/json
        application/javascript
        application/x-javascript
        text/xml;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log warn;

    include /etc/nginx/conf.d/*.conf;
}
EOF

    # --------------------------------------------------------
    # TEST
    # --------------------------------------------------------

    echo -e "${CB}[5/6] Testing Nginx configuration...${NC}"

    if ! nginx -t; then

        echo
        echo -e "${RB}Nginx configuration FAILED!${NC}"
        echo -e "${YB}Attempting automatic restore...${NC}"

        local LAST_BACKUP

        LAST_BACKUP=$(cat /run/nginx-last-backup 2>/dev/null || true)

        if [ -n "$LAST_BACKUP" ] && [ -d "$LAST_BACKUP/nginx" ]; then

            rm -rf /etc/nginx
            cp -a "$LAST_BACKUP/nginx" /etc/nginx

            if nginx -t; then
                echo -e "${GB}Original configuration restored.${NC}"
            else
                echo -e "${RB}WARNING: Restore configuration also failed!${NC}"
            fi
        fi

        pause
        return
    fi

    echo -e "${GB}Nginx configuration OK.${NC}"

    # --------------------------------------------------------
    # SYSTEMD
    # --------------------------------------------------------

    echo -e "${CB}[6/6] Restarting services...${NC}"

    systemctl daemon-reload

    systemctl restart nginx

    if systemctl list-unit-files | grep -q "^xray.service"; then
        systemctl restart xray
    fi

    sleep 2

    echo
    echo -e "${GB}==============================================${NC}"
    echo -e "${GB}       OPTIMIZATION COMPLETED${NC}"
    echo -e "${GB}==============================================${NC}"

    echo
    echo "Nginx : $(systemctl is-active nginx)"

    if systemctl list-unit-files | grep -q "^xray.service"; then
        echo "Xray  : $(systemctl is-active xray)"
    else
        echo "Xray  : Not installed"
    fi

    echo
    echo "Worker Connections : 8192"
    echo "Keepalive Requests : 2000"
    echo "Nginx LimitNOFILE  : 65535"
    echo "Xray LimitNOFILE   : 65535"

    echo
    echo -e "${GB}Backup:${NC}"
    cat /run/nginx-last-backup 2>/dev/null || echo "N/A"

    pause
}

# ============================================================
# MEMORY GUARD
# ============================================================

install_memory_guard() {

    header

    echo -e "${CB}[ NGINX MEMORY GUARD ]${NC}"
    echo

    if ! check_nginx; then
        pause
        return
    fi

    echo "Threshold : ${THRESHOLD_MB} MB"
    echo "Cooldown  : $((COOLDOWN / 60)) minutes"
    echo "Check     : ${CHECK_INTERVAL} seconds"
    echo

    # --------------------------------------------------------
    # CREATE GUARD
    # --------------------------------------------------------

    echo -e "${CB}Installing Memory Guard...${NC}"

    cat > "$GUARD" <<'EOF'
#!/bin/bash

THRESHOLD_KB=$((800 * 1024))
COOLDOWN=300

LOG="/var/log/nginx-memory-guard.log"
STATE="/run/nginx-memory-guard.last"

log() {
    echo "$(date '+%F %T') $*" >> "$LOG"
}

while true; do

    ACTIVE_PID=""
    ACTIVE_RSS=0
    SHUTTING_DOWN=0

    for pid in $(pgrep -x nginx 2>/dev/null); do

        [ -r "/proc/$pid/cmdline" ] || continue
        [ -r "/proc/$pid/status" ] || continue

        cmd=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)

        # Skip master process
        case "$cmd" in
            *"master process"*)
                continue
                ;;
        esac

        # Detect graceful shutdown worker
        if echo "$cmd" | grep -q "shutting down"; then
            SHUTTING_DOWN=1
            continue
        fi

        rss=$(awk '/VmRSS:/ {print $2}' \
            "/proc/$pid/status" 2>/dev/null || echo 0)

        if [ "$rss" -gt "$ACTIVE_RSS" ]; then
            ACTIVE_RSS=$rss
            ACTIVE_PID=$pid
        fi

    done

    # --------------------------------------------------------
    # OLD WORKER STILL SHUTTING DOWN
    # --------------------------------------------------------

    if [ "$SHUTTING_DOWN" -eq 1 ]; then
        sleep 30
        continue
    fi

    # --------------------------------------------------------
    # MEMORY CHECK
    # --------------------------------------------------------

    if [ -n "$ACTIVE_PID" ] &&
       [ "$ACTIVE_RSS" -ge "$THRESHOLD_KB" ]; then

        NOW=$(date +%s)
        LAST=0

        if [ -f "$STATE" ]; then
            LAST=$(cat "$STATE" 2>/dev/null || echo 0)
        fi

        ELAPSED=$((NOW - LAST))

        if [ "$ELAPSED" -ge "$COOLDOWN" ]; then

            MB=$((ACTIVE_RSS / 1024))

            log "Worker PID=$ACTIVE_PID RSS=${MB}MB exceeded threshold. Graceful reload."

            if nginx -t >/dev/null 2>&1; then

                systemctl reload nginx

                echo "$NOW" > "$STATE"

            else

                log "ERROR: nginx config test failed. Reload skipped."

            fi
        fi
    fi

    sleep 30

done
EOF

    chmod +x "$GUARD"

    # --------------------------------------------------------
    # SERVICE
    # --------------------------------------------------------

    cat > "$GUARD_SERVICE" <<'EOF'
[Unit]
Description=Nginx VPN Memory Guard
After=nginx.service
Requires=nginx.service

[Service]
Type=simple
ExecStart=/usr/local/sbin/nginx-memory-guard
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload

    systemctl enable nginx-memory-guard.service >/dev/null 2>&1

    systemctl restart nginx-memory-guard.service

    sleep 2

    echo
    echo -e "${GB}==============================================${NC}"
    echo -e "${GB}       MEMORY GUARD INSTALLED${NC}"
    echo -e "${GB}==============================================${NC}"

    echo
    echo "Status    : $(systemctl is-active nginx-memory-guard)"
    echo "Threshold : ${THRESHOLD_MB} MB"
    echo "Cooldown  : $((COOLDOWN / 60)) minutes"
    echo "Check     : ${CHECK_INTERVAL} seconds"
    echo "Log       : ${GUARD_LOG}"

    pause
}

# ============================================================
# INSTALL EVERYTHING
# ============================================================

install_all() {

    header

    echo -e "${MB}[ INSTALL ALL ]${NC}"
    echo
    echo "Ini akan install:"
    echo
    echo "  1. Nginx Extreme Tuning"
    echo "  2. Xray systemd tuning"
    echo "  3. Kernel network tuning"
    echo "  4. Nginx Memory Guard"
    echo
    echo -e "${YB}Backup Nginx akan dibuat dahulu.${NC}"
    echo

    read -rp "Teruskan? [y/N]: " confirm

    case "$confirm" in
        y|Y)
            ;;
        *)
            echo
            echo "Dibatalkan."
            sleep 1
            return
            ;;
    esac

    # Run optimizer
    optimize_nginx_xray

    # Install guard
    install_memory_guard

    header

    echo -e "${GB}+------------------------------------------------------+${NC}"
    echo -e "${GB}¦${WB}             INSTALLATION COMPLETE${GB}               ¦${NC}"
    echo -e "${GB}+------------------------------------------------------+${NC}"

    echo
    echo "Nginx:"
    echo "  Status : $(systemctl is-active nginx)"

    echo
    echo "Xray:"
    if systemctl list-unit-files | grep -q "^xray.service"; then
        echo "  Status : $(systemctl is-active xray)"
    else
        echo "  Status : Not installed"
    fi

    echo
    echo "Memory Guard:"
    echo "  Status : $(systemctl is-active nginx-memory-guard)"

    echo
    echo "Memory threshold : ${THRESHOLD_MB} MB"
    echo "Cooldown          : $((COOLDOWN / 60)) minutes"
    echo "Check interval    : ${CHECK_INTERVAL} seconds"

    echo
    echo "Backup:"
    cat /run/nginx-last-backup 2>/dev/null || echo "N/A"

    pause
}

# ============================================================
# STATUS
# ============================================================

show_status() {

    header

    echo -e "${CB}[ SYSTEM STATUS ]${NC}"
    echo

    echo "=============================================="
    echo "NGINX"
    echo "=============================================="

    if command -v nginx >/dev/null 2>&1; then
        nginx -v 2>&1
        echo "Status : $(systemctl is-active nginx)"

        PID=$(pidof nginx | awk '{print $1}')

        if [ -n "$PID" ] && [ -r "/proc/$PID/limits" ]; then
            echo
            echo "File Limit:"
            grep "open files" "/proc/$PID/limits"
        fi
    else
        echo "Nginx tidak dipasang."
    fi

    echo
    echo "=============================================="
    echo "XRAY"
    echo "=============================================="

    if command -v xray >/dev/null 2>&1; then

        xray version 2>/dev/null | head -1

        echo "Status : $(systemctl is-active xray)"

        PID=$(pidof xray | awk '{print $1}')

        if [ -n "$PID" ] && [ -r "/proc/$PID/limits" ]; then
            echo
            echo "File Limit:"
            grep "open files" "/proc/$PID/limits"
        fi

    else
        echo "Xray tidak dijumpai."
    fi

    echo
    echo "=============================================="
    echo "MEMORY GUARD"
    echo "=============================================="

    if [ -f "$GUARD_SERVICE" ]; then

        echo "Status : $(systemctl is-active nginx-memory-guard)"
        echo "Enabled: $(systemctl is-enabled nginx-memory-guard 2>/dev/null || true)"

        echo
        echo "Threshold : ${THRESHOLD_MB} MB"
        echo "Cooldown  : $((COOLDOWN / 60)) minutes"
        echo "Check     : ${CHECK_INTERVAL} seconds"

    else
        echo "Memory Guard belum dipasang."
    fi

    echo
    echo "=============================================="
    echo "CURRENT NGINX WORKERS"
    echo "=============================================="

    ps -o pid,etime,rss,vsz,stat,cmd -C nginx 2>/dev/null || true

    echo
    echo "=============================================="
    echo "CURRENT RAM"
    echo "=============================================="

    free -h

    echo
    echo "=============================================="
    echo "LOAD"
    echo "=============================================="

    uptime

    echo
    echo "=============================================="
    echo "RECENT MEMORY GUARD LOG"
    echo "=============================================="

    if [ -f "$GUARD_LOG" ]; then
        tail -10 "$GUARD_LOG"
    else
        echo "Belum ada log."
    fi

    pause
}

# ============================================================
# RESTORE NGINX
# ============================================================

restore_nginx() {

    header

    echo -e "${RB}[ RESTORE NGINX CONFIG ]${NC}"
    echo

    if [ ! -d "$BACKUP_ROOT" ]; then
        echo -e "${RB}Tiada backup dijumpai.${NC}"
        pause
        return
    fi

    echo "Backup yang tersedia:"
    echo

    ls -1dt "$BACKUP_ROOT"/* 2>/dev/null | head -10

    echo
    read -rp "Masukkan full path backup yang mahu restore: " RESTORE_DIR

    if [ ! -d "$RESTORE_DIR/nginx" ]; then
        echo
        echo -e "${RB}Backup tidak sah.${NC}"
        pause
        return
    fi

    echo
    echo -e "${YB}Backup akan dipasang sebagai /etc/nginx.${NC}"
    read -rp "Teruskan? [y/N]: " confirm

    case "$confirm" in
        y|Y)
            ;;
        *)
            echo "Dibatalkan."
            pause
            return
            ;;
    esac

    echo
    echo "Creating safety backup..."

    SAFETY="/root/nginx-restore-safety-$(date +%Y%m%d-%H%M%S)"

    mkdir -p "$SAFETY"

    cp -a /etc/nginx "$SAFETY/"

    echo
    echo "Restoring..."

    rm -rf /etc/nginx
    cp -a "$RESTORE_DIR/nginx" /etc/nginx

    echo
    echo "Testing configuration..."

    if nginx -t; then

        systemctl reload nginx

        echo
        echo -e "${GB}Restore berjaya.${NC}"

    else

        echo
        echo -e "${RB}Restore gagal. Safety backup sedang dipulihkan...${NC}"

        rm -rf /etc/nginx
        cp -a "$SAFETY/nginx" /etc/nginx

        nginx -t

        echo
        echo -e "${GB}Configuration asal dipulihkan.${NC}"

    fi

    pause
}

# ============================================================
# UNINSTALL MEMORY GUARD
# ============================================================

remove_memory_guard() {

    header

    echo -e "${RB}[ REMOVE MEMORY GUARD ]${NC}"
    echo

    if [ ! -f "$GUARD_SERVICE" ]; then
        echo "Memory Guard tidak dipasang."
        pause
        return
    fi

    echo "Ini akan remove:"
    echo
    echo "$GUARD"
    echo "$GUARD_SERVICE"
    echo
    read -rp "Teruskan? [y/N]: " confirm

    case "$confirm" in
        y|Y)
            ;;
        *)
            echo "Dibatalkan."
            pause
            return
            ;;
    esac

    systemctl disable --now nginx-memory-guard.service >/dev/null 2>&1 || true

    rm -f "$GUARD"
    rm -f "$GUARD_SERVICE"
    rm -f "$GUARD_STATE"

    systemctl daemon-reload

    echo
    echo -e "${GB}Memory Guard berjaya dibuang.${NC}"

    pause
}

# ============================================================
# MENU
# ============================================================

while true; do

    header

    echo -e "${GB}  [1]${NC} Nginx + Xray Extreme Optimizer"
    echo -e "${GB}  [2]${NC} Install Nginx Memory Guard"
    echo -e "${GB}  [3]${NC} Install Semua"
    echo -e "${CB}  [4]${NC} Check Status / RAM"
    echo -e "${YB}  [5]${NC} Restore Nginx Backup"
    echo -e "${RB}  [6]${NC} Remove Memory Guard"
    echo -e "${RB}  [0]${NC} Keluar"

    echo
    echo -e "${GB}------------------------------------------------------${NC}"
    echo

    read -rp "Pilih menu [0-6]: " MENU

    case "$MENU" in

        1)
            optimize_nginx_xray
            ;;

        2)
            install_memory_guard
            ;;

        3)
            install_all
            ;;

        4)
            show_status
            ;;

        5)
            restore_nginx
            ;;

        6)
            remove_memory_guard
            ;;

        0)
            clear
            echo "Keluar."
            exit 0
            ;;

        *)
            echo
            echo -e "${RB}Pilihan tidak sah.${NC}"
            sleep 1
            ;;

    esac

done
