#!/bin/bash
YB='\e[33;1m'
GB='\e[32;1m'
RB='\e[31;1m'
NC='\e[0m'  # Reset color

# Function to update expiration date (DNS or Fastly)
update_exp() {
    read -p "Enter Expiry Duration (Days): " days

    # Validate input (must be a positive number)
    if [[ ! "$days" =~ ^[0-9]+$ || "$days" -le 0 ]]; then
        echo -e "${RB}Error!! Invalid input. Please enter a positive number.${NC}"
        sleep 2
        return
    fi

    # Calculate expiration date
    exp_date=$(date -d "+$days days" +"%Y%m%d")

    # Determine whether it's for DNS or Fastly
    if [[ "$1" == "dns" ]]; then
        echo "$exp_date" > /home/exp
        echo -e "${GB}DNS Expiry Date Updated: $exp_date${NC}"
    else
        echo "$exp_date" > /home/exp2
        echo -e "${GB}Fastly Expiry Date Updated: $exp_date${NC}"
    fi
    sleep 2
}

# Function to update CDN domain
update_cdn() {
    read -p "Enter CDN Domain Name ($1): " domain

    # Validate input (must not be empty)
    if [[ -z "$domain" ]]; then
        echo -e "${RB}Error!! Invalid input. Please enter a valid domain name.${NC}"
        sleep 2
        return
    fi

    # Save to the correct file
    if [[ "$1" == "primary" ]]; then
        echo "$domain" > /home/cname
        echo -e "${GB}Primary CDN Updated: $domain${NC}"
    else
        echo "$domain" > /home/cname2
        echo -e "${GB}Secondary CDN Updated: $domain${NC}"
    fi
    sleep 2
}

# Menu function
update_menu() {
    while true; do
        clear
        echo -e "${YB}Update Options:${NC}"
        echo -e "1. ${YB}Update DNS Expiration${NC}"
        echo -e "2. ${YB}Update Fastly Expiration${NC}"
        echo -e "3. ${YB}Update Primary CDN${NC}"
        echo -e "4. ${YB}Update Secondary CDN${NC}"
        echo -e "5. ${YB}Back to Main Menu${NC}"
        read -p "Enter choice (1-5): " choice

        case $choice in
            1) update_exp "dns" ;;
            2) update_exp "fastly" ;;
            3) update_cdn "primary" ;;
            4) update_cdn "secondary" ;;
            5) menu ;;  # Assuming `menu` is a function in your script
            *) echo -e "${RB}Invalid choice! Please select 1-5.${NC}"; sleep 2 ;;
        esac
    done
}

# Run the menu
update_menu
