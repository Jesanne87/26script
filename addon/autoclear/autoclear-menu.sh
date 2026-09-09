#!/bin/bash
# // Export Color & Information
export RED='\033[0;31m';
export GREEN='\033[0;32m';
export YELLOW='\033[0;33m';
export BLUE='\033[0;34m';
export PURPLE='\033[0;35m';
export CYAN='\033[0;36m';
export LIGHT='\033[0;37m';
export NC='\033[0m';
# // Export Banner Status Information
export ERROR="[${RED} ERROR ${NC}]";
export INFO="[${YELLOW} INFO ${NC}]";
export OKEY="[${GREEN} OKEY ${NC}]";
export PENDING="[${YELLOW} PENDING ${NC}]";
export SEND="[${YELLOW} SEND ${NC}]";
export RECEIVE="[${YELLOW} RECEIVE ${NC}]";
export RED_BG='\e[41m';
clear
# // Start
clear;
echo -e "${RED_BG}           AUTO Clear RAM Limit                 ${NC}";
echo ""
echo -e "${GREEN} 1${YELLOW})${NC}. Set RAM Limit for Autoclear service";
echo -e "${GREEN} 2${YELLOW})${NC}. Set CPU Limit for Autoclear service";
echo -e "${GREEN} 3${YELLOW})${NC}. Enable autoclear Service";
echo -e "${GREEN} 4${YELLOW})${NC}. Disable autoclear Service";
echo -e "${GREEN} 5${YELLOW})${NC}. Restart autoclear Service";
echo -e "${GREEN} 6${YELLOW})${NC}. Back To Main Menu";
echo "";
read -p "Please Choose one : " selection_mu;

node_name=ss;

case $selection_mu in
   1)
# Load the configuration
source /home/autoclear.conf  
read -p "RAM Limit for auto clear : " autoclear_bah

# Check if the input is valid
if [[ -z "$autoclear_bah" ]] || ! [[ "$autoclear_bah" =~ ^[0-9]+$ ]]; then
  clear;
  echo -e "${ERROR} Please input a valid Autoclear limit size"
  sleep 1.5
  autoclear-menu
fi
# Update the configuration
sed -i "0,/wire=${wire}/s//wire=${autoclear_bah}/" /home/autoclear.conf

# Restart the service
systemctl restart auto-clear-ram > /dev/null 2>&1;

# Provide feedback to the user
echo -e "${OKEY} Successfully Set Autoclear Limit To ${autoclear_bah} MB ";
sleep 2
autoclear-menu

# Check if the configuration is valid
if [[ -z "$wire" ]] || ! [[ "$wire" =~ ^[0-9]+$ ]]; then
  echo -e "${ERROR} Your Autoclear Config has an error"
  echo ""
  read -n 1 -r -s -p $"Press any key to continue ... "
  autoclear-menu
fi
;;
   2)
# Load the configuration
source /home/autoclear.conf  
read -p "CPU Limit for auto clear : " autoclear_bah

# Check if the input is valid
if [[ -z "$autoclear_bah" ]] || ! [[ "$autoclear_bah" =~ ^[0-9]+$ ]]; then
  clear;
  echo -e "${ERROR} Please input a valid Autoclear CPU limit "
  sleep 1.5
  autoclear-menu
fi
# Update the configuration
sed -i "0,/cpu_limit=${cpu_limit}/s//cpu_limit=${autoclear_bah}/" /home/autoclear.conf

# Restart the service
systemctl restart auto-clear-ram > /dev/null 2>&1;

# Provide feedback to the user
echo -e "${OKEY} Successfully Set Autoclear CPU Limit To ${autoclear_bah} ";
sleep 2
autoclear-menu

# Check if the configuration is valid
if [[ -z "$cpu_limit" ]] || ! [[ "$cpu_limit" =~ ^[0-9]+$ ]]; then
  echo -e "${ERROR} Your Autoclear Config has an error"
  echo ""
  read -n 1 -r -s -p $"Press any key to continue ... "
  autoclear-menu
fi
;;
    3)
        source /home/autoclear.conf
        if [[ $ENABLED == "" ]]; then
            clear;
            echo -e "${ERROR} Your autoclear Config have error";
            read -n 1 -r -s -p $"Press any key to continue ... "
            autoclear-menu
        fi
        sed -i "s/ENABLED=${ENABLED}/ENABLED=1/g" /home/autoclear.conf;
        systemctl restart auto-clear-ram > /dev/null 2>&1
        echo -e "${OKEY} Successfull Enabled autoclear"
        read -n 1 -r -s -p $"Press any key to continue ... "
        autoclear-menu
    ;;
    4)
        source /home/autoclear.conf
        if [[ $ENABLED == "" ]]; then
            clear;
            echo -e "${ERROR} Your autoclear Config have error"
            read -n 1 -r -s -p $"Press any key to continue ... "
            autoclear-menu
        fi
        sed -i "s/ENABLED=${ENABLED}/ENABLED=0/g" /home/autoclear.conf;
        systemctl restart auto-clear-ram > /dev/null 2>&1;
        echo -e "${OKEY} Successfull Disabled autoclear"
        read -n 1 -r -s -p $"Press any key to continue ... "
        autoclear-menu
    ;;
    5)
        systemctl restart auto-clear-ram > /dev/null 2>&1
        echo -e "${OKEY} Successfull Restarted autoclear Service"
        read -n 1 -r -s -p $"Press any key to continue ... "
        autoclear-menu
    ;;
    6)
      menu
    ;;
    *)
        echo -e "${ERROR} Your Input is Wrong";
        sleep 1;
        autoclear-menu;
    ;;
esac