#!/bin/bash
NC='\e[0m'
DEFBOLD='\e[39;1m'
RB='\e[31;1m'
GB='\e[32;1m'
YB='\e[33;1m'
BB='\e[34;1m'
MB='\e[35;1m'
CB='\e[35;1m'
WB='\e[37;1m'
clear
NUMBER_OF_CLIENTS=$(grep -c -E "^#@ " "/usr/local/etc/xray/config.json")
if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e "                 ${WB}Delete vmess Account${NC}               "
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e "  ${YB}You have no existing clients!${NC}"
echo -e "${BB}————————————————————————————————————————————————————${NC}"
read -n 1 -s -r -p "Press any key to back on menu"
vmess
fi
clear
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e "                 Delete vmess Account               "
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e " ${YB}User  Expired${NC}  "
echo -e "${BB}————————————————————————————————————————————————————${NC}"
users=$(grep -E "^#@ " "/usr/local/etc/xray/config.json" | cut -d ' ' -f 2-3 | sort | uniq)
declare -a userArray=($users)
declare -a nameArray=()
declare -a dateArray=()
i=1
name=""
for user in "${userArray[@]}"; do
    if [[ $user =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
        dateArray+=($user)
        echo "$i. $name $user"
        nameArray+=($name)
        name=""
        i=$((i+1))
    else
        if [[ -z $name ]]; then
            name=$user
        else
            name="$name-$user"
        fi
    fi
done
# rest of your script...
echo ""
echo -e "${YB}Double tap enter to go back${NC}"
echo -e "${BB}————————————————————————————————————————————————————${NC}"
read -rp "Input Option Number : " option

# Check if the option is empty
if [ -z "$option" ]; then
    echo -e "\e[1;31mNo option selected, please try again.\e[0m"
    sleep 1
    if type vmess &> /dev/null; then
        vmess
    else
        echo "vmess function/command not found"
    fi
else
    user=${nameArray[$((option-1))]}
    if [ -z $user ]; then
        echo -e "\e[1;31mPlease enter a correct number\e[0m"
        sleep 1
        if type vmess &> /dev/null; then
            vmess
        else
            echo "vmess function/command not found"
        fi
    else
        exp=$(grep -wE "^#@ $user" "/usr/local/etc/xray/config.json" | cut -d ' ' -f 3 | sort | uniq)
        sed -i "/^#@ $user $exp/,/^},{/d" /usr/local/etc/xray/config.json
        sed -i "/^#@gr $user $exp/,/^},{/d" /usr/local/etc/xray/config.json
        rm -rf /var/www/html/vmess/vmess-$user.txt
        rm -rf /user/log-vmess-$user.txt
        systemctl restart xray
        clear
        echo -e "${BB}————————————————————————————————————————————————————${NC}"
        echo -e "            ${WB}vmess Account Success Deleted${NC}           "
        echo -e "${BB}————————————————————————————————————————————————————${NC}"
        echo -e " ${YB}Client Name :${NC} $user"
        echo -e " ${YB}Expired On  :${NC} $exp"
        echo -e "${BB}————————————————————————————————————————————————————${NC}"
        echo ""
        read -n 1 -s -r -p "Press any key to back on menu"
        clear
        if type vmess &> /dev/null; then
            vmess
        else
            echo "vmess function/command not found"
        fi
    fi
fi

