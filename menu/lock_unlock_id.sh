#!/bin/bash
# ----------------------------------------------------------------------
#  Xray Multi-Tool Script (VLESS + VMESS Auto Detect)
#  Author : JsPhantom  •  https://github.com/Jesanne87
# ----------------------------------------------------------------------

# === COLOR SETTINGS ===
NC='\e[0m'
YB='\e[33;1m'
RB='\e[31;1m'
GB='\e[32;1m'
BB='\e[34;1m'
WB='\e[37;1m'

CONFIG_FILE="/usr/local/etc/xray/config.json"
USER_BACKUP_DIR="/usr/local/etc/xray/user_backups"

mkdir -p "$USER_BACKUP_DIR"

clear
NUMBER_OF_CLIENTS=$(grep -c -E "^#= |^#@ " "$CONFIG_FILE")
if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
    echo -e "${BB}————————————————————————————————————————————————————${NC}"
    echo -e "            ${WB}VLESS + VMESS Account${NC}"
    echo -e "${BB}————————————————————————————————————————————————————${NC}"
    echo -e "  ${YB}You have no existing clients!${NC}"
    echo -e "${BB}————————————————————————————————————————————————————${NC}"
    echo ""
    read -n 1 -s -r -p "Press any key to back on menu"
    exit
fi

clear
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e "            ${WB} VLESS + VMESS Account${NC}"
echo -e "${BB}————————————————————————————————————————————————————${NC}"

read -rp "Search username (press Enter to show all) : " keyword

echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e " ${YB}No.  Proto   User            Expired             Status${NC}"
echo -e "${BB}————————————————————————————————————————————————————${NC}"

user_list=$(grep -E "^#= |^#@ " "$CONFIG_FILE" | sort -k2,2)

users=()
dates=()
protocols=()
statuses=()
index=1

while read -r line; do
    prefix=$(echo "$line" | awk '{print $1}')
    username=$(echo "$line" | awk '{print $2}')
    date_part=$(echo "$line" | awk '{print $3}')
    time_part=$(echo "$line" | awk '{print $4}')
    expire_date="$date_part"
    [[ -n "$time_part" ]] && expire_date="$date_part $time_part"

    if [[ "$prefix" == "#=" ]]; then
        protocol="VLESS"
    else
        protocol="VMESS"
    fi

    user_uuid=$(awk "/^$prefix $username / {getline; if (\$0 ~ /\"id\":/) print \$0}" "$CONFIG_FILE" | grep -oE '"id":\s*"[^"]+"' | cut -d'"' -f4)

    backup_uuid_file="$USER_BACKUP_DIR/${protocol}_${username}.uuid"

    if [[ -f "$backup_uuid_file" ]]; then
        backup_uuid=$(cat "$backup_uuid_file")
    else
        backup_uuid=""
    fi

    if [[ "$user_uuid" != "$backup_uuid" && -n "$backup_uuid" ]]; then
        status="\e[31;1m[Locked]\e[0m"
    else
        status="\e[32;1m[Unlocked]\e[0m"
    fi

    if [[ -z "$keyword" || "$username" =~ $keyword ]]; then
        users+=("$username")
        dates+=("$expire_date")
        protocols+=("$protocol")
        statuses+=("$status")

        printf "%s. %-6s %-15s %-20s %b\n" "$index" "$protocol" "$username" "$expire_date" "$status"
        index=$((index + 1))
    fi
done <<< "$user_list"

if [ ${#users[@]} -eq 0 ]; then
    echo -e "${RB}No matching user found.${NC}"
    echo ""
    read -n 1 -s -r -p "Press any key to back on menu"
    exit
fi

echo ""
echo -e "${YB}Double tap enter to go back${NC}"
echo -e "${BB}————————————————————————————————————————————————————${NC}"
read -rp "Input Option Number : " option

if [ -z "$option" ]; then
    echo -e "${RB}No option selected, please try again.${NC}"
    sleep 1
    menu
fi

user=${users[$((option-1))]}
old_exp=${dates[$((option-1))]}
protocol=${protocols[$((option-1))]}
status=${statuses[$((option-1))]}
prefix="#="
[[ "$protocol" == "VMESS" ]] && prefix="#@"

if [ -z "$user" ]; then
    echo -e "${RB}Please enter a correct number${NC}"
    sleep 1
    menu
fi

echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e "    ${YB}Selected User: ${NC} $user"
echo -e "    ${YB}Protocol: ${NC} $protocol"
echo -e "    ${YB}Expired Date: ${NC} $old_exp"
echo -e "    ${YB}Status: ${NC} $status"
echo -e "${BB}————————————————————————————————————————————————————${NC}"

# === Toggle Lock/Unlock ===
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e "    ${YB}1. Lock User${NC}"
echo -e "    ${YB}2. Unlock User${NC}"
echo -e "${BB}————————————————————————————————————————————————————${NC}"
read -rp "Select option [1/2] to Lock or Unlock: " lock_option

backup_uuid_file="$USER_BACKUP_DIR/${protocol}_${user}.uuid"

if [[ "$lock_option" == "1" ]]; then
    original_uuid=$(awk "/^$prefix $user / {getline; if (\$0 ~ /\"id\":/) print \$0}" "$CONFIG_FILE" | grep -oE '"id":\s*"[^"]+"' | cut -d'"' -f4)

    if [[ -n "$original_uuid" && ! -f "$backup_uuid_file" ]]; then
        echo "$original_uuid" > "$backup_uuid_file"
    fi

    new_uuid=$(cat /proc/sys/kernel/random/uuid)

    sed -i -E "/^$prefix $user /{n;s/\"id\":\s*\"[^\"]+\"/\"id\": \"$new_uuid\"/}" "$CONFIG_FILE"

    echo -e "${RB}User $user ($protocol) has been Locked. New UUID set.${NC}"

elif [[ "$lock_option" == "2" ]]; then
    if [[ -f "$backup_uuid_file" ]]; then
        original_uuid=$(cat "$backup_uuid_file")
        sed -i -E "/^$prefix $user /{n;s/\"id\":\s*\"[^\"]+\"/\"id\": \"$original_uuid\"/}" "$CONFIG_FILE"
        rm -f "$backup_uuid_file"
        echo -e "${GB}User $user ($protocol) has been Unlocked. Original UUID restored.${NC}"
    else
        echo -e "${RB}Original UUID not found for $user! Keeping the modified UUID.${NC}"
    fi
else
    echo -e "${RB}Invalid option, please try again.${NC}"
    sleep 1
    exit
fi

systemctl restart xray > /dev/null 2>&1
sleep 1
menu
