#!/bin/bash
# =========================================
# Xray-Core Switcher v2.1
# Edition : Stable Edition (No Re-Download Official)
# Author  : Jesanne87 + ChatGPT Patch
# =========================================

NC='\e[0m'; GB='\e[32;1m'; YB='\e[33;1m'; RB='\e[31;1m'
XRAY_BIN="/usr/local/bin/xray"

BACKUP_DIR="/backup"; mkdir -p "$BACKUP_DIR"
OFFICIAL_BACKUP="$BACKUP_DIR/xray.official.backup"

# ------------------ Check current installed version ------------------
if [[ -x $XRAY_BIN ]]; then
    CURRENT_VER=$($XRAY_BIN version 2>/dev/null | head -n1 | awk '{print $2}')
else
    CURRENT_VER="Not Installed"
fi

# ------------------ FUNCTIONS ------------------

# Install official Xray (one time)
install_official_once() {
    echo -e "${GB}[INFO]${NC} Installing official Xray from XTLS..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

    if [[ ! -f "$XRAY_BIN" ]]; then
        echo -e "${RB}[ERROR]${NC} Official install failed!"
        return 1
    fi

    echo -e "${GB}[INFO]${NC} Backing up official Xray binary..."
    cp "$XRAY_BIN" "$OFFICIAL_BACKUP"

    echo -e "${GB}[SUCCESS]${NC} Official Xray installed and backed up."
}

# Apply official version from backup
apply_official_backup() {
    if [[ ! -f "$OFFICIAL_BACKUP" ]]; then
        echo -e "${YB}[WARN]${NC} No official backup found. Installing now..."
        install_official_once
    fi

    echo -e "${GB}[INFO]${NC} Applying official Xray from backup..."
    systemctl stop xray 2>/dev/null

    # Backup current xray (modded)
    if [[ -f "$XRAY_BIN" ]]; then
        mv "$XRAY_BIN" "$BACKUP_DIR/xray_backup_$(date +%s)"
    fi

    cp "$OFFICIAL_BACKUP" "$XRAY_BIN"
    chmod +x "$XRAY_BIN"

    systemctl restart xray
    echo -e "${GB}[SUCCESS]${NC} Applied Official Xray!"
    $XRAY_BIN version
}

# Apply MOD or ZIP version
apply_version() {
    local ver_name="$1"
    local url="$2"
    local is_zip="$3"

    echo -e "${GB}[INFO]${NC} Stopping Xray service..."
    systemctl stop xray 2>/dev/null

    tmpdir=$(mktemp -d)
    tmpfile="$tmpdir/xray_tmp.zip"

    echo -e "${GB}[INFO]${NC} Downloading $ver_name..."
    wget -q -O "$tmpfile" "$url"

    if [[ "$is_zip" == "yes" ]]; then
        echo -e "${GB}[INFO]${NC} Extracting ZIP..."
        unzip -o "$tmpfile" -d "$tmpdir" >/dev/null 2>&1

        XRAY_FILE=$(find "$tmpdir" -type f -perm /111 -iname "*xray*" ! -iname "*.json" ! -iname "*.md" | head -n1)

        if [[ -f "$XRAY_FILE" ]]; then
            [[ -f $XRAY_BIN ]] && mv "$XRAY_BIN" "$BACKUP_DIR/xray_backup_$(date +%s)"
            mv "$XRAY_FILE" "$XRAY_BIN"
            chmod +x "$XRAY_BIN"
            echo -e "${GB}[INFO]${NC} Xray binary updated."
        else
            echo -e "${RB}[ERROR]${NC} Xray binary not found in ZIP!"
            rm -rf "$tmpdir"; return 1
        fi
    else
        [[ -f $XRAY_BIN ]] && mv "$XRAY_BIN" "$BACKUP_DIR/xray_backup_$(date +%s)"
        mv "$tmpfile" "$XRAY_BIN"
        chmod +x "$XRAY_BIN"
    fi

    rm -rf "$tmpdir"

    echo -e "${GB}[INFO]${NC} Restarting Xray..."
    systemctl restart xray
    sleep 1
    echo -e "${GB}[SUCCESS]${NC} Applied $ver_name!"
    $XRAY_BIN version
}

# ------------------ MENU ------------------

clear
echo -e "${GB}╭════════════════════════════════════════════╮${NC}"
echo -e "${GB}│${NC}          ${YB}Xray-core Switcher Menu${NC}           ${GB}│${NC}"
echo -e "${GB}├────────────────────────────────────────────┤${NC}"
echo -e "${GB}│${NC} Current Xray version: ${GB}${CURRENT_VER}${NC}"
echo -e "${GB}╰════════════════════════════════════════════╯${NC}"
echo -e "${GB}╭════════════════════════════════════════════╮${NC}"
echo -e "${GB}│${NC} ${YB}1.${NC} Xray-core MOD ${GB}v1.7.2-1                   ${NC}"
echo -e "${GB}│${NC} ${YB}2.${NC} Xray-core MOD ${GB}v1.7.5.1                   ${NC}"
echo -e "${GB}│${NC} ${YB}3.${NC} Xray-core MOD ${GB}v25.3.31                   ${NC}"
echo -e "${GB}│${NC} ${YB}4.${NC} Official Xray (Restore from Backup)     ${NC}"
echo -e "${GB}│${NC} ${YB}5.${NC} Check current version                  ${NC}"
echo -e "${GB}│${NC} ${YB}0.${NC} Exit                                    ${NC}"
echo -e "${GB}╰════════════════════════════════════════════╯${NC}"
echo ""
read -rp "Select option [0-5]: " choice
echo ""

case $choice in
    1)
        apply_version "Xray v1.7.2-1" \
        "https://github.com/Jesanne87/xray_custom/releases/download/v1.7.2-1/Xray-linux-64-v1.7.2-1" \
        "no"
        ;;
    2)
        apply_version "Xray v1.7.5.1" \
        "https://github.com/Jesanne87/xray_custom/releases/download/v1.7.5.1/Xray-linux-64-v1.7.5.1" \
        "no"
        ;;
    3)
        apply_version "Xray v25.3.31" \
        "https://github.com/Jesanne87/xray_custom/releases/download/v25.3.31/Xray-linux-64-v25.3.31.zip" \
        "yes"
        ;;
    4)
        apply_official_backup
        ;;
    5)
        if [[ -x $XRAY_BIN ]]; then
            echo -e "${GB}[INFO]${NC} Current Xray version:"
            $XRAY_BIN version | head -n1
        else
            echo -e "${RB}[INFO]${NC} Xray not installed."
        fi
        ;;
    0)
        exit 0
        ;;
    *)
        echo -e "${RB}[ERROR]${NC} Invalid option."
        ;;
esac

echo ""
read -rp "Press Enter to return to menu..."
$0
