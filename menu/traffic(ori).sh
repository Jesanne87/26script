#!/bin/bash
export NC='\033[0m'
export YLW='\033[0;33m'
export CYA='\033[0;36m'

_APISERVER=127.0.0.1:10000
_XRAY=/usr/local/bin/xray
LOGDIR="/user/bwlog"

declare -A USERS_TOTAL

apidata () {
    $_XRAY api statsquery --server=$_APISERVER "" \
    | awk '{
        if (match($1, /"name":/)) {
            f=1; gsub(/^"|link"|,$/, "", $2);
            split($2, p, ">>>");
            printf "%s:%s->%s\t", p[1],p[2],p[4];
        }
        else if (match($1, /"value":/) && f){
            f=0; gsub(/"/,"",$2); printf "%.0f\n",$2;
        }
        else if (match($0,/}/) && f){ f=0; print 0; }
    }'
}

print_live() {
    local DATA="$1"
    local SORTED=$(echo "$DATA" | grep "^user" | sort )

    echo "$SORTED" | column -t | numfmt --field=2 --to=iec --suffix=B

    echo
    echo "$SORTED" | awk '
        /->up/ {up+=$2}
        /->down/ {down+=$2}
        END {
            printf "TOTAL\nUP\t%.0f\nDOWN\t%.0f\nTOTAL\t%.0f\n", up, down, up+down
        }' \
    | numfmt --field=2 --to=iec --suffix=B \
    | column -t
}

print_lifetime() {
    echo -e "${CYA}══════════════[ TOTAL LIFETIME USAGE ]══════════════${NC}\n"

    for FILE in "$LOGDIR"/*.log; do
        [[ -f "$FILE" ]] || continue
        USER=$(basename "$FILE" .log)

        UP=$(awk '/ up/ {s+=$3} END {printf "%.0f", s}' "$FILE")
        DOWN=$(awk '/ down/ {s+=$3} END {printf "%.0f", s}' "$FILE")
        TOTAL=$((UP+DOWN))

        USERS_TOTAL["$USER"]=$TOTAL

        echo -e "User: $USER"
        echo -e "   Up:\t\t$(numfmt --to=iec $UP)"
        echo -e "   Down:\t$(numfmt --to=iec $DOWN)"
        echo -e "   Total:\t$(numfmt --to=iec $TOTAL)\n"
    done

    echo -e "${CYA}══════════════════════════════════════════════${NC}\n"
}

print_top_usage() {
    echo -e "${CYA}══════════════[ TOP 10 USERS BY TOTAL USAGE ]══════════════${NC}\n"

    for U in "${!USERS_TOTAL[@]}"; do
        echo "$U ${USERS_TOTAL[$U]}"
    done | sort -k2 -nr | head -n 10 | awk '
    {
        usage=$2
        hum[1]="B"; hum[2]="KB"; hum[3]="MB"; hum[4]="GB"; hum[5]="TB";
        idx=1
        while (usage>=1024 && idx<5) {
            usage/=1024; idx++
        }
        printf "%-20s : %.2f %s\n", $1, usage, hum[idx]
    }'

    echo -e "${CYA}══════════════════════════════════════════════${NC}\n"
}

clear

echo -e "\n${CYA}═══════════════[ Xray Live Traffic ]═══════════════${NC}\n"
DATA=$(apidata)
print_live "$DATA"

print_lifetime
print_top_usage

read -n1 -r -p " Press any key to continue..."
menu
