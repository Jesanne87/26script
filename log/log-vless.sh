#!/bin/bash

# ===============================

# Xray Multi-Protokol Log Viewer

# VLESS biru, VMESS merah

# ===============================

# === COLOR ===

NC='\e[0m'
RB='\e[31;1m'
GB='\e[32;1m'
YB='\e[33;1m'
BB='\e[34;1m'
WB='\e[37;1m'

CONFIG_FILE="/usr/local/etc/xray/config.json"

clear
NUMBER_OF_CLIENTS=$(grep -c -E "^#= |^#@ " "$CONFIG_FILE")

if [[ $NUMBER_OF_CLIENTS -eq 0 ]]; then
echo -e "${BB}┌────────────────────────────────────────────────────┐${NC}"
echo -e "${BB}│                  ${WB}Log All Xray Account${NC}              ${BB}│${NC}"
echo -e "${BB}└────────────────────────────────────────────────────┘${NC}"
echo -e "         ${YB}You have no existing clients!${NC}"
read -n1 -s -r -p "Press any key to go back to the menu"
menu
fi

clear
echo -e "${BB}┌────────────────────────────────────────────────────┐${NC}"
echo -e "${BB}│                  ${WB}Log All Xray Account${NC}              ${BB}│${NC}"
echo -e "${BB}└────────────────────────────────────────────────────┘${NC}"

# Sorting Option

echo -e "${YB}1. Sort by Name${NC}"
echo -e "${YB}2. Sort by Expiration Date${NC}"
read -rp "Choose sorting option (1/2) : " sort_option

case "$sort_option" in
1) sort_by="sort -k2,2" ;;  # by username
2) sort_by="sort -k3,3" ;;  # by expiry
*) sort_by="sort -k2,2" ;;
esac

# Optional Search

read -rp "Search username (press Enter to show all) : " keyword
clear
echo -e " ${BB}————————————————————————————————————————————————————${NC}"
echo -e " ${YB}No. Proto    User              Expired Date&Time ${NC}"
echo -e " ${BB}————————————————————————————————————————————————————${NC}"

# Arrays

users_list=()
expiry_list=()
protocol_list=()
protocol_display_list=()

# Load users

while read -r prefix username date time; do
expiry="${date} ${time}"

# Clean proto for logic
if [[ "$prefix" == "#=" ]]; then
    proto="[VLESS]"
    proto_display="${BB}[VLESS]${NC}"
else
    proto="[VMESS]"
    proto_display="${RB}[VMESS]${NC}"
fi

# Filter by keyword
if [[ -z "$keyword" || "$username" =~ $keyword ]]; then
    users_list+=("$username")
    expiry_list+=("$expiry")
    protocol_list+=("$proto")
    protocol_display_list+=("$proto_display")
fi

done < <(grep -E "^#= |^#@ " "$CONFIG_FILE" | eval "$sort_by")

# Display

for i in "${!users_list[@]}"; do
printf "%2d. %-12b %-15s %-20s\n" "$((i+1))" "${protocol_display_list[$i]}" "${users_list[$i]}" "${expiry_list[$i]}"
done

echo ""
echo -e "${YB}Tap enter to go back${NC}"
echo -e "${BB}————————————————————————————————————————————————————${NC}"
read -rp "Input User Number: " user_number

# Validation

if [[ -z "$user_number" || ! "$user_number" =~ ^[0-9]+$ || $user_number -lt 1 || $user_number -gt ${#users_list[@]} ]]; then
echo -e "${RB}Invalid input. Press any key to go back${NC}"
read -n1 -s -r
menu
fi

# Selected user

index=$((user_number-1))
username="${users_list[$index]}"
proto="${protocol_list[$index]}"

# Detect log file

if [[ "$proto" == "[VLESS]" ]]; then
log_file="/user/log-vless-$username.txt"
else
log_file="/user/log-vmess-$username.txt"
fi

clear
echo -e "${BB}┌─────────────────────────────────────────────────┐${NC}"
echo -e "${BB}│ Log for user: ${WB}$username${NC} ${proto_display_list[$index]}${BB}${NC}"
echo -e "${BB}└─────────────────────────────────────────────────┘${NC}"

if [[ -f "$log_file" ]]; then
cat "$log_file"
else
echo -e "${RB}No log file found for $username.${NC}"
fi

echo ""
read -n1 -s -r -p "Press any key to go back to the menu"
menu
