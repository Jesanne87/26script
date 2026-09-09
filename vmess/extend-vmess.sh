#!/bin/bash
# === COLOR ===
NC='\e[0m'
DEFBOLD='\e[39;1m'
RB='\e[31;1m'
GB='\e[32;1m'
YB='\e[33;1m'
BB='\e[34;1m'
MB='\e[35;1m'
CB='\e[36;1m'
WB='\e[37;1m'

CONFIG_FILE="/usr/local/etc/xray/config.json"

clear
NUMBER_OF_CLIENTS=$(grep -c -E "^#@ " "$CONFIG_FILE")
if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
    echo -e "${BB}————————————————————————————————————————————————————${NC}"
    echo -e "                ${WB}Extend Vmess Account${NC}          "
    echo -e "${BB}————————————————————————————————————————————————————${NC}"
    echo -e "  ${YB}You have no existing clients!${NC}"
    echo -e "${BB}————————————————————————————————————————————————————${NC}"
    echo ""
    read -n 1 -s -r -p "Press any key to back on menu"
    vmess
fi

clear
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e "                ${WB}Extend Vmess Account${NC}          "
echo -e "${BB}————————————————————————————————————————————————————${NC}"

# === Sort Options ===
echo -e "${YB}1. Sort by Name${NC}"
echo -e "${YB}2. Sort by Expiration Date${NC}"
echo -e "${BB}————————————————————————————————————————————————————${NC}"
read -rp "Choose sorting option (1/2) : " sort_option

case "$sort_option" in
    1) sort_by="sort -k1,1" ;;  # Sort by Name
    2) sort_by="sort -k2,2" ;;  # Sort by Expiration Date
    *) sort_by="sort -k1,1" ;;  # Default to Name
esac
clear

# === Optional Search Filter ===
read -rp "Search username (press Enter to show all) : " keyword
clear
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e " ${YB}User                  Expired${NC}  "
echo -e "${BB}————————————————————————————————————————————————————${NC}"

# === Build, filter & sort user list ===
user_list=$(grep -E "^#@ " "$CONFIG_FILE" | awk '{print $2, $3, $4}' | eval "$sort_by")

users=()
dates=()
index=1

while read -r line; do
    username=$(echo "$line" | awk '{print $1}')
    date_part=$(echo "$line" | awk '{print $2}')
    time_part=$(echo "$line" | awk '{print $3}')
    expire_date="$date_part"
    [[ -n "$time_part" ]] && expire_date="$date_part $time_part"

    if [[ -z "$keyword" || "$username" =~ $keyword ]]; then
        users+=("$username")
        dates+=("$expire_date")
        printf "%2d. %-20s %-20s\n" "$index" "$username" "$expire_date"
        index=$((index + 1))
    fi
done <<< "$user_list"

if [ ${#users[@]} -eq 0 ]; then
    echo -e "${RB}No matching user found.${NC}"
    echo ""
    read -n 1 -s -r -p "Press any key to back on menu"
    clear
    vmess
fi

echo ""
echo -e "${YB}Double tap enter to go back${NC}"
echo -e "${BB}————————————————————————————————————————————————————${NC}"
read -rp "Input Option Number : " option

if [ -z "$option" ]; then
    echo -e "\e[1;31mNo option selected, please try again.\e[0m"
    sleep 1
    vmess
fi

user=${users[$((option-1))]}
old_exp=${dates[$((option-1))]}

if [ -z "$user" ]; then
    echo -e "\e[1;31mPlease enter a correct number\e[0m"
    sleep 1
    vmess
fi

read -p "Extend Expired Days : " masaaktif
if [ -z "$masaaktif" ]; then
    echo -e "\e[1;31mNo days entered, please try again.\e[0m"
    sleep 1
    vmess
fi

# === Determine current time if missing ===
old_date=$(echo "$old_exp" | awk '{print $1}')
old_time=$(echo "$old_exp" | awk '{print $2}')

if [ -z "$old_time" ]; then
    old_time=$(date +%T)
fi

new_date=$(date -d "$old_date +$masaaktif days" +"%Y-%m-%d")
new_exp="$new_date $old_time"

# === Update config ===
sed -i "/#@ $user/c\#@ $user $new_exp" "$CONFIG_FILE"
sed -i "/#@gr $user/c\#@gr $user $new_exp" "$CONFIG_FILE"
systemctl restart xray

# === Fetch UUID ===
uuid=$(grep -oP "(?<=\"id\": \")\S+(?=\",.*\"email\": \"$user\")" "$CONFIG_FILE" | head -n 1)

# === Fetch Domain ===
if [[ -f /usr/local/etc/xray/domain ]]; then
    domain=$(cat /usr/local/etc/xray/domain)
else
    domain="Not Detected"
fi

clear
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e "           ${WB}Vmess Account Success Extended${NC}           "
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e " ${YB}Client Name      :${NC} $user"
echo -e " ${YB}Old Expiry       :${NC} $old_exp"
echo -e " ${YB}New Expiry       :${NC} $new_exp"
echo -e " ${YB}UUID             :${NC} $uuid"
echo -e " ${YB}Domain Server    :${NC} $domain"
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo ""
echo -e "${GB}[ INFO ]${NC} ${YB}Executing Backup Procedure...${NC}"
autobackup
echo -e "${GB}[ INFO ]${NC} ${YB}Backup Completed Successfully...${NC}"
echo " "
read -n 1 -s -r -p "Press any key to back on menu"
clear
vmess
