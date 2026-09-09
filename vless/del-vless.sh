#!/bin/bash

# =========================================
# Delete Vless Account
# With Delete All Option
# =========================================

NC='\e[0m'
DEFBOLD='\e[39;1m'
RB='\e[31;1m'
GB='\e[32;1m'
YB='\e[33;1m'
BB='\e[34;1m'
MB='\e[35;1m'
CB='\e[35;1m'
WB='\e[37;1m'

CONFIG="/usr/local/etc/xray/config.json"

clear

# =========================================
# CHECK CONFIG
# =========================================

if [[ ! -f "$CONFIG" ]]; then
    echo -e "${RB}Xray config not found!${NC}"
    sleep 2
    exit 1
fi

# =========================================
# COUNT CLIENTS
# =========================================

NUMBER_OF_CLIENTS=$(grep -c -E "^#= " "$CONFIG")

if [[ "$NUMBER_OF_CLIENTS" == "0" ]]; then

    echo -e "${BB}————————————————————————————————————————————————————${NC}"
    echo -e "                 ${WB}Delete Vless Account${NC}"
    echo -e "${BB}————————————————————————————————————————————————————${NC}"
    echo -e "  ${YB}You have no existing clients!${NC}"
    echo -e "${BB}————————————————————————————————————————————————————${NC}"

    read -n 1 -s -r -p "Press any key to back on menu"

    if type vless &> /dev/null; then
        vless
    fi

    exit 0
fi

# =========================================
# DISPLAY MENU
# =========================================

clear

echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e "                 ${WB}Delete Vless Account${NC}"
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e " ${RB}0.${NC} ${RB}Delete ALL Users${NC}"
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e " ${YB}User                 Expired${NC}"
echo -e "${BB}————————————————————————————————————————————————————${NC}"

# =========================================
# GET USERS
# =========================================

users=$(grep -E "^#= " "$CONFIG" | cut -d ' ' -f 2-3 | sort | uniq)

declare -a userArray=($users)
declare -a nameArray=()
declare -a dateArray=()

i=1
name=""

for user in "${userArray[@]}"; do

    if [[ "$user" =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then

        dateArray+=("$user")

        printf " %2s. %-20s %s\n" "$i" "$name" "$user"

        nameArray+=("$name")
        name=""

        i=$((i+1))

    else

        if [[ -z "$name" ]]; then
            name="$user"
        else
            name="$name-$user"
        fi

    fi

done

# =========================================
# INPUT
# =========================================

echo ""
echo -e "${YB}Double tap enter to go back${NC}"
echo -e "${BB}————————————————————————————————————————————————————${NC}"

read -rp "Input Option Number : " option

# =========================================
# EMPTY OPTION
# =========================================

if [[ -z "$option" ]]; then

    echo -e "${RB}No option selected, please try again.${NC}"
    sleep 1

    if type vless &> /dev/null; then
        vless
    fi

    exit 0
fi

# =========================================
# DELETE ALL USERS
# =========================================

if [[ "$option" == "0" ]]; then

    clear

    echo -e "${BB}————————————————————————————————————————————————————${NC}"
    echo -e "              ${RB}DELETE ALL VLESS USERS${NC}"
    echo -e "${BB}————————————————————————————————————————————————————${NC}"
    echo ""
    echo -e "${RB}WARNING!${NC}"
    echo -e "${YB}This will permanently delete ALL VLESS accounts.${NC}"
    echo ""
    echo -e "${YB}Number of users: ${WB}${NUMBER_OF_CLIENTS}${NC}"
    echo ""
    echo -e "Type ${RB}YES${NC} to continue."
    echo -e "Anything else will cancel."
    echo ""

    read -rp "Confirmation : " confirm

    if [[ "$confirm" != "YES" ]]; then

        echo ""
        echo -e "${GB}Delete ALL cancelled.${NC}"
        sleep 2

        if type vless &> /dev/null; then
            vless
        fi

        exit 0
    fi

    # =====================================
    # BACKUP CONFIG
    # =====================================

    BACKUP="/usr/local/etc/xray/config.json.bak.$(date +%Y%m%d-%H%M%S)"

    cp -f "$CONFIG" "$BACKUP"

    # =====================================
    # DELETE VLESS USERS
    # =====================================

    sed -i '/^#= /,/^},{/d' "$CONFIG"

    # =====================================
    # DELETE GRPC USERS
    # =====================================

    sed -i '/^#gr /,/^},{/d' "$CONFIG"

    # =====================================
    # DELETE USER FILES
    # =====================================

    rm -f /var/www/html/vless/vless-*.txt
    rm -f /user/log-vless-*.txt

    # =====================================
    # TEST CONFIG
    # =====================================

    if xray run -test -config "$CONFIG" >/dev/null 2>&1; then

        systemctl restart xray

        clear

        echo -e "${BB}————————————————————————————————————————————————————${NC}"
        echo -e "          ${GB}ALL VLESS ACCOUNTS DELETED${NC}"
        echo -e "${BB}————————————————————————————————————————————————————${NC}"
        echo -e " ${YB}Deleted Users :${NC} ${NUMBER_OF_CLIENTS}"
        echo -e " ${YB}Backup Config :${NC} ${BACKUP}"
        echo -e " ${YB}Xray Status   :${NC} Restarted"
        echo -e "${BB}————————————————————————————————————————————————————${NC}"
        echo ""

    else

        # =================================
        # RESTORE IF CONFIG INVALID
        # =================================

        cp -f "$BACKUP" "$CONFIG"

        systemctl restart xray

        clear

        echo -e "${BB}————————————————————————————————————————————————————${NC}"
        echo -e "              ${RB}DELETE FAILED${NC}"
        echo -e "${BB}————————————————————————————————————————————————————${NC}"
        echo -e " ${YB}Original config restored.${NC}"
        echo -e " ${YB}Backup :${NC} ${BACKUP}"
        echo -e "${BB}————————————————————————————————————————————————————${NC}"
        echo ""

    fi

    read -n 1 -s -r -p "Press any key to back on menu"

    clear

    if type vless &> /dev/null; then
        vless
    fi

    exit 0
fi

# =========================================
# CHECK OPTION NUMBER
# =========================================

if ! [[ "$option" =~ ^[0-9]+$ ]]; then

    echo -e "${RB}Please enter a correct number.${NC}"
    sleep 1

    if type vless &> /dev/null; then
        vless
    fi

    exit 0
fi

# =========================================
# GET ARRAY INDEX
# =========================================

index=$((option-1))

user="${nameArray[$index]}"

# =========================================
# CHECK USER
# =========================================

if [[ -z "$user" ]]; then

    echo -e "${RB}Please enter a correct number.${NC}"
    sleep 1

    if type vless &> /dev/null; then
        vless
    fi

    exit 0
fi

# =========================================
# GET EXPIRY
# =========================================

exp=$(grep -wE "^#= $user" "$CONFIG" | cut -d ' ' -f 3 | sort | uniq)

# =========================================
# DELETE USER
# =========================================

sed -i "/^#= $user $exp/,/^},{/d" "$CONFIG"

sed -i "/^#gr $user $exp/,/^},{/d" "$CONFIG"

# =========================================
# DELETE FILES
# =========================================

rm -f "/var/www/html/vless/vless-$user.txt"
rm -f "/user/log-vless-$user.txt"

# =========================================
# TEST CONFIG
# =========================================

if xray run -test -config "$CONFIG" >/dev/null 2>&1; then

    systemctl restart xray

else

    echo -e "${RB}Xray config error!${NC}"
    sleep 2

    if type vless &> /dev/null; then
        vless
    fi

    exit 1
fi

# =========================================
# SUCCESS
# =========================================

clear

echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e "          ${GB}Vless Account Success Deleted${NC}"
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e " ${YB}Client Name :${NC} $user"
echo -e " ${YB}Expired On  :${NC} $exp"
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo ""

read -n 1 -s -r -p "Press any key to back on menu"

clear

if type vless &> /dev/null; then
    vless
fi