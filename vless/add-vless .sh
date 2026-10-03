#!/bin/bash
# JsPhantom - Add VLESS Account V3.2.2
# Live-add VLESS WS + XHTTP via Xray HandlerService
# No Xray restart for normal account creation.
# One-time API setup is required when HandlerService/ReflectionService/tags are missing.

set -u

CONFIG_FILE="/usr/local/etc/xray/config.json"
XRAY_BIN="$(command -v xray || echo /usr/local/bin/xray)"
API_ADDR="127.0.0.1:10000"
GRPCURL="/usr/local/bin/grpcurl"
API_WS_TAG="vless-ws"
API_XHTTP_TAG="vless-xhttp"

NC='\e[0m'; DEFBOLD='\e[39;1m'; RB='\e[31;1m'; GB='\e[32;1m'; YB='\e[33;1m'; BB='\e[34;1m'; MB='\e[35;1m'; CB='\e[35;1m'; WB='\e[37;1m'; PLE='\033[0;35m'

CFG_BACKUP=""

fail() {
    echo -e "${RB}[ ERROR ]${NC} $*"
    exit 1
}

need_root() {
    [[ ${EUID:-0} -eq 0 ]] || fail "Script mesti dijalankan sebagai root."
}

check_base() {
    [[ -f "$CONFIG_FILE" ]] || fail "Config tidak dijumpai: $CONFIG_FILE"
    [[ -x "$XRAY_BIN" ]] || fail "Xray binary tidak dijumpai."
    command -v curl >/dev/null 2>&1 || fail "curl tidak dijumpai."
    command -v wget >/dev/null 2>&1 || fail "wget tidak dijumpai."
    command -v base64 >/dev/null 2>&1 || fail "base64 tidak dijumpai."
    command -v python3 >/dev/null 2>&1 || fail "python3 diperlukan untuk encode protobuf API."
}

install_grpcurl() {
    if command -v grpcurl >/dev/null 2>&1; then
        GRPCURL="$(command -v grpcurl)"
        return 0
    fi
    [[ -x "$GRPCURL" ]] && return 0

    echo -e "${YB}[ INFO ]${NC} grpcurl belum ada. Memasang grpcurl v1.9.4..."
    local arch url tmp deb
    arch="$(uname -m)"
    tmp="$(mktemp -d)"

    case "$arch" in
        x86_64|amd64)
            # v1.9.4 menyediakan Linux amd64 dalam format .deb/.rpm,
            # bukan linux_amd64.tar.gz.
            url="https://github.com/fullstorydev/grpcurl/releases/download/v1.9.4/grpcurl_1.9.4_linux_amd64.deb"
            deb="$tmp/grpcurl.deb"
            if ! curl -fL --retry 3 -sS "$url" -o "$deb"; then
                rm -rf "$tmp"
                fail "Gagal download grpcurl v1.9.4 (amd64)."
            fi
            if ! dpkg -i "$deb" >/tmp/jsphantom-grpcurl-dpkg.log 2>&1; then
                apt-get install -f -y >/tmp/jsphantom-grpcurl-apt.log 2>&1 || {
                    cat /tmp/jsphantom-grpcurl-dpkg.log
                    rm -rf "$tmp"
                    fail "Gagal memasang grpcurl v1.9.4."
                }
            fi
            rm -rf "$tmp"
            GRPCURL="$(command -v grpcurl || true)"
            [[ -x "$GRPCURL" ]] || GRPCURL="/usr/bin/grpcurl"
            [[ -x "$GRPCURL" ]] || fail "grpcurl berjaya dipasang tetapi binary tidak dijumpai."
            ;;
        aarch64|arm64)
            url="https://github.com/fullstorydev/grpcurl/releases/download/v1.9.4/grpcurl_1.9.4_linux_arm64.tar.gz"
            if ! curl -fL --retry 3 -sS "$url" -o "$tmp/grpcurl.tar.gz"; then
                rm -rf "$tmp"
                fail "Gagal download grpcurl v1.9.4 (arm64)."
            fi
            tar -xzf "$tmp/grpcurl.tar.gz" -C "$tmp" || {
                rm -rf "$tmp"
                fail "Gagal extract grpcurl."
            }
            install -m 0755 "$tmp/grpcurl" "$GRPCURL" || {
                rm -rf "$tmp"
                fail "Gagal install grpcurl."
            }
            rm -rf "$tmp"
            ;;
        *)
            rm -rf "$tmp"
            fail "Architecture $arch belum disokong untuk auto-install grpcurl."
            ;;
    esac
}

xray_test() {
    "$XRAY_BIN" run -test -config "$CONFIG_FILE" >/tmp/jsphantom-xray-test-v32.log 2>&1
    local rc=$?
    if [[ $rc -ne 0 ]]; then
        cat /tmp/jsphantom-xray-test-v32.log
        return 1
    fi
    return 0
}

api_config_ready() {
    grep -q '"HandlerService"' "$CONFIG_FILE" || return 1
    grep -q '"ReflectionService"' "$CONFIG_FILE" || return 1
    grep -q '"port": 10002,' "$CONFIG_FILE" || return 1
    grep -q '"tag": "vless-ws"' "$CONFIG_FILE" || return 1
    grep -q '"port": 10007,' "$CONFIG_FILE" || return 1
    grep -q '"tag": "vless-xhttp"' "$CONFIG_FILE" || return 1
    return 0
}

setup_api_once() {
    echo -e "${YB}[ SETUP ]${NC} API live-add belum lengkap. Buat backup dan aktifkan HandlerService + ReflectionService + tag inbound."
    CFG_BACKUP="${CONFIG_FILE}.bak-v32-$(date +%Y%m%d-%H%M%S)"
    cp -a "$CONFIG_FILE" "$CFG_BACKUP" || fail "Gagal backup config."

    # Enable HandlerService and ReflectionService once.
    if ! grep -q '"HandlerService"' "$CONFIG_FILE"; then
        sed -i '/"StatsService"/i\      "HandlerService",' "$CONFIG_FILE"
    fi
    if ! grep -q '"ReflectionService"' "$CONFIG_FILE"; then
        sed -i '/"StatsService"/i\      "ReflectionService",' "$CONFIG_FILE"
    fi

    # Give the two VLESS inbounds stable HandlerService tags.
    if ! grep -q '"tag": "vless-ws"' "$CONFIG_FILE"; then
        sed -i '/^[[:space:]]*"port": 10002,/a\      "tag": "vless-ws",' "$CONFIG_FILE"
    fi
    if ! grep -q '"tag": "vless-xhttp"' "$CONFIG_FILE"; then
        sed -i '/^[[:space:]]*"port": 10007,/a\      "tag": "vless-xhttp",' "$CONFIG_FILE"
    fi

    if ! xray_test; then
        cp -a "$CFG_BACKUP" "$CONFIG_FILE"
        fail "Config test gagal. Config asal dipulihkan: $CFG_BACKUP"
    fi

    echo -e "${YB}[ SETUP ]${NC} Restart Xray diperlukan SEKALI sahaja untuk mengaktifkan API/tag."
    systemctl restart xray
    sleep 2
    if ! systemctl is-active --quiet xray; then
        cp -a "$CFG_BACKUP" "$CONFIG_FILE"
        systemctl restart xray >/dev/null 2>&1 || true
        fail "Xray gagal aktif selepas setup API. Config asal dipulihkan."
    fi
    echo -e "${GB}[ OK ]${NC} API HandlerService + ReflectionService sudah aktif."
}

check_api_live() {
    "$GRPCURL" -plaintext -max-time 5 "$API_ADDR" list 2>/dev/null | grep -q 'xray.app.proxyman.command.HandlerService'
}

ensure_api() {
    install_grpcurl
    if ! api_config_ready; then
        setup_api_once
    fi
    if ! check_api_live; then
        echo -e "${YB}[ INFO ]${NC} API belum boleh diakses. Cuba restart Xray sekali untuk sync konfigurasi API..."
        CFG_BACKUP="${CONFIG_FILE}.bak-v32-retry-$(date +%Y%m%d-%H%M%S)"
        cp -a "$CONFIG_FILE" "$CFG_BACKUP"
        xray_test || fail "Config test gagal."
        systemctl restart xray
        sleep 2
    fi
    check_api_live || fail "HandlerService tidak boleh dicapai di $API_ADDR. Semak API inbound/routing."
}

# Build the serialized xray.common.serial.TypedMessage(AddUserOperation).
make_add_request() {
    local tag="$1" email="$2" uuid="$3" out="$4"
    TAG="$tag" EMAIL="$email" UUID="$uuid" OUT="$out" python3 - <<'PY'
import base64, json, os

def field_bytes(n, b):
    def varint(v):
        out=[]
        while v >= 0x80:
            out.append((v & 0x7f) | 0x80); v >>= 7
        out.append(v)
        return bytes(out)
    return bytes([(n << 3) | 2]) + varint(len(b)) + b

def s(n, value): return field_bytes(n, value.encode())
def msg(n, value): return field_bytes(n, value)
def typed(type_name, raw): return s(1, type_name) + msg(2, raw)

email=os.environ['EMAIL']; uuid=os.environ['UUID']; tag=os.environ['TAG']
account=s(1, uuid)
user=s(2, email) + msg(3, typed('xray.proxy.vless.Account', account))
operation=msg(1, user)
value=base64.b64encode(operation).decode()
req={"tag": tag, "operation": {"type": "xray.app.proxyman.command.AddUserOperation", "value": value}}
with open(os.environ['OUT'], 'w') as f: json.dump(req, f)
PY
}

make_remove_request() {
    local email="$1" out="$2"
    EMAIL="$email" OUT="$out" python3 - <<'PY'
import base64, json, os

def varint(v):
    out=[]
    while v >= 0x80:
        out.append((v & 0x7f) | 0x80); v >>= 7
    out.append(v)
    return bytes(out)

def f(n,b): return bytes([(n<<3)|2]) + varint(len(b)) + b
email=os.environ['EMAIL']
operation=f(1,email.encode())
req={"tag":"REPLACE_TAG","operation":{"type":"xray.app.proxyman.command.RemoveUserOperation","value":base64.b64encode(operation).decode()}}
with open(os.environ['OUT'],'w') as h: json.dump(req,h)
PY
}

api_add_user() {
    local tag="$1" email="$2" uuid="$3" req="$4"
    make_add_request "$tag" "$email" "$uuid" "$req"
    "$GRPCURL" -plaintext -max-time 10 -d @ "$API_ADDR" xray.app.proxyman.command.HandlerService/AlterInbound < "$req"
}

api_remove_user() {
    local tag="$1" email="$2" req="$3"
    make_remove_request "$email" "$req"
    sed -i "s/REPLACE_TAG/$tag/" "$req"
    "$GRPCURL" -plaintext -max-time 10 -d @ "$API_ADDR" xray.app.proxyman.command.HandlerService/AlterInbound < "$req" >/dev/null 2>&1 || true
}

# ---------- JsPhantom User Status V1 ----------
USER_STATUS_DIR="/etc/jsphantom/user-status"
USER_STATUS_TOKEN_DIR="$USER_STATUS_DIR/tokens"
USER_STATUS_BASE_URL=""
status_token=""
status_url=""

create_user_status_token() {
    mkdir -p "$USER_STATUS_TOKEN_DIR"
    chmod 700 "$USER_STATUS_DIR" "$USER_STATUS_TOKEN_DIR" 2>/dev/null || true

    # 48 hex chars (192-bit random token). Never expose UUID in status URL.
    while true; do
        status_token="$(python3 - <<'PYTOKEN'
import secrets
print(secrets.token_hex(24))
PYTOKEN
)"
        [[ ! -e "$USER_STATUS_TOKEN_DIR/$status_token.json" ]] && break
    done

    python3 - "$USER_STATUS_TOKEN_DIR/$status_token.json" "$user" "$exp" <<'PYMAP'
import json,os,sys,time
f,u,exp=sys.argv[1:]
data={"user":u,"expires":exp,"created_at":int(time.time())}
t=f+'.tmp'
with open(t,'w') as h: json.dump(data,h,indent=2)
os.chmod(t,0o600)
os.replace(t,f)
PYMAP
    status_url="${USER_STATUS_BASE_URL}/${status_token}/"
}

# ---------- Telegram notification ----------
TELEGRAM_CONF="/etc/jsphantom/telegram.conf"

send_telegram_account() {
    [[ -f "$TELEGRAM_CONF" ]] || return 0

    local BOT_TOKEN="" CHAT_ID=""
    # shellcheck disable=SC1090
    source "$TELEGRAM_CONF" 2>/dev/null || return 0
    [[ -n "${BOT_TOKEN:-}" && -n "${CHAT_ID:-}" ]] || return 0

    local quota_text ip_text message
    [[ "${ip_limit:-0}" == "0" ]] && ip_text="Unlimited" || ip_text="$ip_limit"
    [[ "${quota_gb:-0}" == "0" ]] && quota_text="Unlimited" || quota_text="${quota_gb} GB"

    message="🆕 VLESS ACCOUNT CREATED

Username    : $user
User ID     : $uuid
Server Name : $domain
Created On  : $masa
Expired On  : $exp
IP Limit    : $ip_text
Quota       : $quota_text
Status URL  : ${status_url:-Not installed}"

    curl -sS --connect-timeout 5 --max-time 10 \
        -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        --data-urlencode "chat_id=${CHAT_ID}" \
        --data-urlencode "text=${message}" >/dev/null 2>&1 || true
}

# ---------- original environment ----------
need_root
check_base
clear

MYIP="$(curl -sS ipv4.icanhazip.com | tr -d '[:space:]')"
domain="$(cat /usr/local/etc/xray/domain 2>/dev/null || true)"
cname="$(cat /home/cname 2>/dev/null || true)"
cname2="$(cat /home/cname2 2>/dev/null || true)"
masa="$(date '+%Y-%m-%d %T')"

[[ -n "$domain" ]] || fail "Domain tidak dijumpai."
USER_STATUS_BASE_URL="https://${domain}/status"

# Make sure live API is ready before changing the account.
ensure_api

while true; do
    clear
    echo -e "${BB}┌─────────────────────────────────────────────────┐${NC}"
    echo -e "${BB}│${NC}           ───[ Add Vless Account V3.2 ]───      ${BB}│${NC}"
    echo -e "${BB}└─────────────────────────────────────────────────┘${NC}"

    # Username
    while true; do
        read -rp "User: " -e user
        [[ "$user" =~ ^[a-zA-Z0-9_]+$ ]] || { echo -e "${RB}Username hanya A-Z a-z 0-9 _${NC}"; continue; }
        if grep -Eq "^#= ${user}([[:space:]]|$)" "$CONFIG_FILE"; then
            echo -e "${YB}User $user sudah wujud.${NC}"
            continue
        fi
        break
    done

    # UUID (Enter = auto-generate)
    read -rp "UUID : " -e id
    uuid="$id"
    [[ -n "$uuid" ]] || uuid="$(cat /proc/sys/kernel/random/uuid)"
    if [[ ! "$uuid" =~ ^[0-9a-fA-F-]{36}$ ]]; then
        echo -e "${RB}UUID tidak nampak seperti UUID yang sah.${NC}"
        sleep 1
        continue
    fi

    # Expired days
    while true; do
        read -rp "Expired (days): " -e masaaktif
        [[ "$masaaktif" =~ ^[0-9]+$ && "$masaaktif" -gt 0 ]] && break
        echo -e "${RB}Expired days tidak sah.${NC}"
    done

    # JsPhantom Account Control V1
    while true; do
        read -rp "IP Limit (0 = unlimited): " -e ip_limit
        [[ "$ip_limit" =~ ^[0-9]+$ ]] && break
        echo -e "${RB}IP limit tidak sah.${NC}"
    done
    while true; do
        read -rp "Quota GB (0 = unlimited): " -e quota_gb
        [[ "$quota_gb" =~ ^[0-9]+([.][0-9]+)?$ ]] && break
        echo -e "${RB}Quota tidak sah.${NC}"
    done

    # Final review/edit menu. Nothing has been written to Xray yet.
    while true; do
        exp="$(date -d "$masaaktif days" '+%Y-%m-%d %T')"
        clear
        echo -e "${BB}┌─────────────────────────────────────────────────┐${NC}"
        echo -e "${BB}│${NC}              ───[ Confirm Account ]───          ${BB}│${NC}"
        echo -e "${BB}└─────────────────────────────────────────────────┘${NC}"
        echo -e "Username : ${GB}${user}${NC}"
        echo -e "UUID     : ${GB}${uuid}${NC}"
        echo -e "Expired  : ${GB}${masaaktif} days${NC} (${exp})"
        echo -e "IP Limit : ${GB}${ip_limit}${NC} (0=unlimited)"
        echo -e "Quota    : ${GB}${quota_gb} GB${NC} (0=unlimited)"
        echo
        echo -e "${GB}[1]${NC} Confirm & Create"
        echo -e "${YB}[2]${NC} Edit Username"
        echo -e "${YB}[3]${NC} Edit UUID"
        echo -e "${YB}[4]${NC} Edit Expired"
        echo -e "${YB}[5]${NC} Edit IP Limit"
        echo -e "${YB}[6]${NC} Edit Quota"
        echo -e "${RB}[0]${NC} Cancel"
        echo
        read -rp "Select [0-6]: " confirm_choice

        case "$confirm_choice" in
            1)
                break 2
                ;;
            2)
                while true; do
                    read -rp "New Username: " -e new_user
                    [[ "$new_user" =~ ^[a-zA-Z0-9_]+$ ]] || { echo -e "${RB}Username hanya A-Z a-z 0-9 _${NC}"; continue; }
                    if grep -Eq "^#= ${new_user}([[:space:]]|$)" "$CONFIG_FILE"; then
                        echo -e "${YB}User $new_user sudah wujud.${NC}"
                        continue
                    fi
                    user="$new_user"
                    break
                done
                ;;
            3)
                read -rp "New UUID (Enter = auto): " -e new_uuid
                [[ -n "$new_uuid" ]] || new_uuid="$(cat /proc/sys/kernel/random/uuid)"
                if [[ "$new_uuid" =~ ^[0-9a-fA-F-]{36}$ ]]; then
                    uuid="$new_uuid"
                else
                    echo -e "${RB}UUID tidak sah. UUID lama dikekalkan.${NC}"
                    sleep 1
                fi
                ;;
            4)
                read -rp "New Expired (days): " -e new_days
                if [[ "$new_days" =~ ^[0-9]+$ && "$new_days" -gt 0 ]]; then
                    masaaktif="$new_days"
                else
                    echo -e "${RB}Expired days tidak sah. Nilai lama dikekalkan.${NC}"
                    sleep 1
                fi
                ;;
            5)
                while true; do
                    read -rp "New IP Limit (0 = unlimited): " -e new_ip
                    [[ "$new_ip" =~ ^[0-9]+$ ]] && { ip_limit="$new_ip"; break; }
                    echo -e "${RB}IP limit tidak sah.${NC}"
                done
                ;;
            6)
                while true; do
                    read -rp "New Quota GB (0 = unlimited): " -e new_quota
                    [[ "$new_quota" =~ ^[0-9]+([.][0-9]+)?$ ]] && { quota_gb="$new_quota"; break; }
                    echo -e "${RB}Quota tidak sah.${NC}"
                done
                ;;
            0)
                echo -e "${YB}Create account dibatalkan.${NC}"
                exit 0
                ;;
            *)
                echo -e "${RB}Pilihan tidak sah.${NC}"
                sleep 1
                ;;
        esac
    done
done

# Final expiry after confirmation/edit.
exp="$(date -d "$masaaktif days" '+%Y-%m-%d %T')"

# Backup BEFORE persistent config edit.
CFG_BACKUP="${CONFIG_FILE}.bak-add-vless-v32-$(date +%Y%m%d-%H%M%S)"
cp -a "$CONFIG_FILE" "$CFG_BACKUP" || fail "Gagal backup config."

# Persistent config: add the same VLESS client to WS and XHTTP inbounds.
if ! grep -q '^#vless$' "$CONFIG_FILE" || ! grep -q '^#xvless$' "$CONFIG_FILE"; then
    fail "Marker #vless / #xvless tidak lengkap dalam config."
fi

sed -i "/^#vless$/a\\#= ${user} ${exp}\\
},{\"id\": \"${uuid}\",\"email\": \"${user}\"" "$CONFIG_FILE"
sed -i "/^#xvless$/a\\#= ${user} ${exp}\\
},{\"id\": \"${uuid}\",\"email\": \"${user}\"" "$CONFIG_FILE"

# Validate persistent config BEFORE touching the live Xray instance.
if ! xray_test; then
    echo -e "${RB}[ ERROR ]${NC} Config test gagal. Rollback config."
    cp -a "$CFG_BACKUP" "$CONFIG_FILE"
    exit 1
fi

REQ_WS="$(mktemp)"
REQ_XHTTP="$(mktemp)"
trap 'rm -f "$REQ_WS" "$REQ_XHTTP"' EXIT

# Live-add: no systemctl restart here.
echo -e "${YB}[ LIVE ]${NC} Add user ke VLESS WS..."
if ! api_add_user "$API_WS_TAG" "$user" "$uuid" "$REQ_WS" >/tmp/jsphantom-v32-api-ws.log 2>&1; then
    cat /tmp/jsphantom-v32-api-ws.log
    cp -a "$CFG_BACKUP" "$CONFIG_FILE"
    fail "Live-add VLESS WS gagal. Config dipulihkan. Xray tidak direstart."
fi

echo -e "${YB}[ LIVE ]${NC} Add user ke VLESS XHTTP..."
if ! api_add_user "$API_XHTTP_TAG" "$user" "$uuid" "$REQ_XHTTP" >/tmp/jsphantom-v32-api-xhttp.log 2>&1; then
    cat /tmp/jsphantom-v32-api-xhttp.log
    api_remove_user "$API_WS_TAG" "$user" "$REQ_WS"
    cp -a "$CFG_BACKUP" "$CONFIG_FILE"
    fail "Live-add VLESS XHTTP gagal. Runtime + config dipulihkan. Xray tidak direstart."
fi

# Save JsPhantom Account Control policy after live-add succeeds.
POLICY_DIR="/etc/jsphantom/account-control/policies"
mkdir -p "$POLICY_DIR"
python3 -c 'import json,sys;f,u,ip,q=sys.argv[1:];json.dump({"user":u,"protocol":"vless","ip_limit":int(ip),"quota_bytes":int(float(q)*1073741824),"auto_lock":True,"ip_window_seconds":300},open(f,"w"),indent=2)' "$POLICY_DIR/${user}.json" "$user" "$ip_limit" "$quota_gb"

# Create private status URL token for this account.
create_user_status_token

# ---------- links: preserved from original script ----------
vlesslink1="vless://$uuid@$domain:443?path=/vless&security=tls&encryption=none&host=$domain&type=ws&sni=$domain#$user$exp"
vlesslink2="vless://$uuid@$domain:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp"
vlesslink3="vless://$uuid@$domain:443?security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=$domain#$user$exp"
vlesslink25="vless://$uuid@$domain:80?path=/vless&security=none&encryption=none&host=pmsc.pubgmobile.com&type=ws#$user$exp@Umo"
vlesslink26="vless://$uuid@172.66.40.170:80?path=/vless&security=none&encryption=none&host=cdn.opensignal.com.$domain&type=ws#$user$exp@Umo"
vlesslink4="vless://$uuid@biorecovery.com:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@Umo"
vlesslink5="vless://$uuid@$MYIP:443?path=/vless&security=tls&encryption=none&host=pmsc.pubgmobile.com&type=ws&sni=pmsc.pubgmobile.com#$user$exp@Umo"
vlesslink6="vless://$uuid@yes.hate-me.eu.org:80?path=wss://$domain/vless&security=none&encryption=none&host=cdn.who.int&type=ws#$user$exp@Yes"
vlesslink7="vless://$uuid@104.17.147.22:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@Yes"
vlesslink8="vless://$uuid@nga.celcomdigi.com.$domain:80?path=/vless&security=none&encryption=none&host=nga.celcomdigi.com&type=ws#$user$exp@Clcom"
vlesslink9="vless://$uuid@104.17.148.22:80?path=/vless&security=none&encryption=none&host=www.speedtest.net.$domain&type=ws#$user$exp@Clcom2"
vlesslink10="vless://$uuid@biruls1.u-pro.fun:80?path=/xvless&security=none&encryption=none&host=$domain&type=xhttp#$user$exp@Celcom"
vlesslink11="vless://$uuid@codecademy.com:80?path=/vless&security=none&encryption=none&host=silent-auth.u.com.my.$domain&type=ws#${user}${exp}2in1"
vlesslink12="vless://$uuid@api-faceid.maxis.com.my.$domain:443?path=/vless&security=tls&encryption=none&host=www.mosti.gov.my&type=ws&sni=www.mosti.gov.my#$user$exp@MaxExp"
vlesslink13="vless://$uuid@162.159.134.61:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@DG3mb"
vlesslink14="vless://$uuid@m.google.com.my.$domain:80?path=/vless&security=none&encryption=none&host=api.instagram.com&type=ws#$user$exp@DGsosial"
vlesslink15="vless://$uuid@104.18.20.212:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@DGexp"
vlesslink16="vless://$uuid@$domain:443?path=/vless&security=tls&encryption=none&host=sso.pokemon.com&type=ws&sni=sso.pokemon.com#$user$exp@DGPoke"
vlesslink17="vless://$uuid@104.17.10.12:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@Unifi"
vlesslink18="vless://$uuid@$MYIP:443?path=/vless&security=tls&encryption=none&host=esports.pubgmobile.com.esports.mobilelegends.com&type=ws&sni=esports.pubgmobile.com.esports.mobilelegends.com#$user$exp@YdoAddon"
vlesslink19="vless://$uuid@$MYIP:443?path=/vless&security=tls&encryption=none&host=www.opensignal.com&type=ws&sni=www.opensignal.com#$user$exp@Uni5gWOW"
vlesslink20="vless://$uuid@$domain:80?path=/vless&security=none&encryption=none&host=yoodo.zendesk.com&type=ws#$user$exp@yodoo"
vlesslink24="vless://$uuid@104.17.113.188:80?path=/vless&security=none&encryption=none&host=cdn.who.int.$domain&type=ws#$user$exp@Yes"
vlesslink27="vless://$uuid@cdn.opensignal.com:8080?path=/xvless&security=none&encryption=none&host=support.opensignal.com.$domain&type=xhttp#$user$exp@Maxis"
vlesslink30="vless://$uuid@$MYIP:443?path=/vless&security=tls&encryption=none&host=cdn.opensignal.com&type=ws&sni=cdn.opensignal.com#$user$exp@Uni5gWOW2"
vlesslink31="vless://$uuid@172.66.43.86:8880?path=/xvless&security=none&encryption=none&host=cdn.opensignal.com.$domain&type=xhttp#$user$exp@Maxis2"
vlesslink21="vless://$uuid@speedtest.net:443?path=/vless&security=tls&encryption=none&host=$cname&type=ws&sni=speedtest.net#$user$exp@MCDU"
vlesslink22="vless://$uuid@151.101.2.219:443?path=/vless&security=tls&encryption=none&host=$cname&type=ws&sni=151.101.2.219#$user$exp@MCDU2"
vlesslink28="vless://$uuid@speedtest.net:80?path=/vless&security=none&encryption=none&host=$cname&type=ws#$user$exp@MCDU3"
vlesslink23="vless://$uuid@api-gateway-global.viu.com.$domain:80?path=/vless&security=none&encryption=none&host=api-gateway-global.viu.com&type=ws#$user$exp@MaxTV"
vlesslink29="vless://$uuid@ookla.com:80?path=/vless&security=none&encryption=none&host=$cname2&type=ws#$user$exp@SBH2"

mkdir -p /var/www/html/vless/all /user
cat > "/var/www/html/vless/all/${user}.txt" <<EOF2
vless://$uuid@$domain:80?path=/vless&security=none&encryption=none&host=pmsc.pubgmobile.com&type=ws#$user$exp@Umo
vless://$uuid@$domain:443?path=/vless&security=tls&encryption=none&host=pmsc.pubgmobile.com&type=ws&sni=pmsc.pubgmobile.com#$user$exp@Umo
vless://$uuid@$MYIP:443?path=/vless&security=tls&encryption=none&host=pmsc.pubgmobile.com&type=ws&sni=pmsc.pubgmobile.com#$user$exp@Umo
vless://$uuid@yes.hate-me.eu.org:80?path=wss://$domain/vless&security=none&encryption=none&host=cdn.who.int&type=ws#$user$exp@Yes
vless://$uuid@yes.hate-me.eu.org:80?path=/vless&security=none&encryption=none&host=cdn.who.int.$domain&type=ws#$user$exp@Yes
vless://$uuid@104.18.203.232:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@Clcom
vless://$uuid@104.18.203.232:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@CLcom
vless://$uuid@104.18.203.232:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@Ydo_Tune
vless://$uuid@help.viu.com:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@MaxTV
vless://$uuid@api-faceid.maxis.com.my.$domain:443?path=/vless&security=tls&encryption=none&host=www.mosti.gov.my&type=ws&sni=www.mosti.gov.my#$user$exp@MaxExp
vless://$uuid@162.159.134.61:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@DG3mb
vless://$uuid@m.google.com.my.$domain:80?path=/vless&security=none&encryption=none&host=api.instagram.com&type=ws#$user$exp@DGsosial
vless://$uuid@api.useinsider.com:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@DGAPN
vless://$uuid@$domain:443?path=/vless&security=tls&encryption=none&host=sso.pokemon.com&type=ws&sni=sso.pokemon.com#$user$exp@DGPoke
vless://$uuid@104.17.10.12:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user$exp@Unifi
vless://$uuid@$domain:443?path=/vless&security=tls&encryption=none&host=esports.pubgmobile.com.esports.mobilelegends.com&type=ws&sni=esports.pubgmobile.com.esports.mobilelegends.com#$user$exp@YdoAddon
EOF2

cat > "/var/www/html/vless/vless-${user}.txt" <<EOF3
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
Link TL   : $vlesslink1
==========================
Link NTLS : $vlesslink2
==========================
Link gRPC : $vlesslink3
==========================
END
EOF3

ISP="$(cat /usr/local/etc/xray/org 2>/dev/null || true)"
CITY="$(cat /usr/local/etc/xray/city 2>/dev/null || true)"
LOGFILE="/user/log-vless-${user}.txt"

# Output restored to the original JsPhantom layout.
rm -f "$LOGFILE"
clear
echo -e "${BB}┌─────────────────────────────────────────────────┐${NC}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}│${NC}             ───[ Vless Account ]───             ${BB}│${NC}    " | tee -a /user/log-vless-$user.txt
echo -e "${BB}└─────────────────────────────────────────────────┘${NC}" | tee -a /user/log-vless-$user.txt
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
echo -e "UUiD          : ${uuid}" | tee -a /user/log-vless-$user.txt
echo -e "Encryption    : none" | tee -a /user/log-vless-$user.txt
echo -e "Network       : Websocket, gRPC" | tee -a /user/log-vless-$user.txt
echo -e "Path WS       : /vless" | tee -a /user/log-vless-$user.txt
echo -e "Path XHTTP    : /xvless" | tee -a /user/log-vless-$user.txt
echo -e "ServiceName   : vless-grpc" | tee -a /user/log-vless-$user.txt
echo -e "Alpn          : h2, http/1.1" | tee -a /user/log-vless-$user.txt
echo -e "${BB}——————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link TLS      : ${vlesslink1}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}——————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link NTLS     : ${vlesslink2}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}——————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link gRPC     : ${vlesslink3}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}——————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}UMOBILE 1     ${NC}  : ${vlesslink25}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}UMOBILE 1Mbps ${NC}  : ${vlesslink4}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}UMOBILE New   ${NC}  : ${vlesslink26}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}UMO Openwrt   ${NC}  : ${vlesslink5}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${PLE}YES5g/4g 1${NC}     : ${vlesslink6}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${PLE}YES5g/4g 2${NC}     : ${vlesslink7}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${PLE}YES5g/4g EXP${NC}   : ${vlesslink24}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${BB}CELCOM Sedut   ${NC} : ${vlesslink8}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${BB}Celcom 3MBps${NC}    : ${vlesslink9}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${BB}Celcom 0 Basic${NC}  : ${vlesslink10}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}MAXIS NoSubs EXP${NC}: ${vlesslink12}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}DIGI Bypas 3MB${NC}  : ${vlesslink13}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}DG Sosial Unli  ${NC}: ${vlesslink14}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}Digi EXP  ${NC}      : ${vlesslink15}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}DG/Umo/DG 3/6mb${NC} : ${vlesslink11}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}Digi Pokemon${NC}    : ${vlesslink16}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}UNIFI Mobile${NC}    : ${vlesslink17}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}Yodoo Add on${NC}    : ${vlesslink18}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}UNI5gWOW${NC}        : ${vlesslink19}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${YB}UNI5gWOW2${NC}       : ${vlesslink30}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}Yodoo Bypass 0GB${NC}: ${vlesslink20}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}4 IN 1${NC}          : ${vlesslink21}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}4 IN 1 Ver2${NC}     : ${vlesslink22}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}4 IN 1 Ver3${NC}     : ${vlesslink28}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}Maxis 1   ${NC}      : ${vlesslink27}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}Maxis 2${NC}         : ${vlesslink31}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}MAxis TV viu${NC}    : ${vlesslink23}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Link ${RB}MAxis SABAH 2${NC}   : ${vlesslink29}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Subs URL        : http://$domain:8000/vless/all/$user.txt" | tee -a /user/log-vless-$user.txt
echo -e "Format Clash    : http://$domain:8000/vless/vless-$user.txt" | tee -a /user/log-vless-$user.txt
echo -e "Status URL      : ${status_url}" | tee -a /user/log-vless-$user.txt
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo -e "Username      : $user" | tee -a /user/log-vless-$user.txt
echo -e "User ID       : $uuid" | tee -a /user/log-vless-$user.txt
echo -e "Server Name   : $domain" | tee -a /user/log-vless-$user.txt
echo -e "Created On    : $masa" | tee -a /user/log-vless-$user.txt
echo -e "Expired On    : $exp" | tee -a /user/log-vless-$user.txt

# Send account summary to Telegram if configured.
send_telegram_account
echo -e "${BB}———————————————————${NC}" | tee -a /user/log-vless-$user.txt
echo " " | tee -a /user/log-vless-$user.txt
echo " " | tee -a /user/log-vless-$user.txt
echo " " | tee -a /user/log-vless-$user.txt
echo " "
echo " "
read -n 1 -s -r -p "Press any key to return to the menu"
menu