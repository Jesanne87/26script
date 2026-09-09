#!/bin/bash

_APISERVER=127.0.0.1:10000
_XRAY=/usr/local/bin/xray
INTERVAL=5     # ulang setiap 5 saat – boleh ubah

apidata () {
    for i in {1..10}; do
        RAW=$($_XRAY api statsquery --server=$_APISERVER "" 2>/dev/null)

        # Jika data ada ? parse dan hantar balik
        if [[ -n "$RAW" ]]; then
            echo "$RAW" | awk '{
                if (match($1, /"name":/)) {
                    f=1; gsub(/^"|link"|,$/, "", $2);
                    split($2, p,  ">>>");
                    printf "%s:%s->%s\t", p[1],p[2],p[4];
                } else if (match($1, /"value":/) && f){
                    f=0; gsub(/"/, "", $2); printf "%.0f\n", $2;
                } else if (match($0, /}/) && f) { f=0; print 0; }
            }'
            return
        fi
        
        sleep 1
    done

    echo ""   # jika masih gagal 10 kali
}

log_user_data() {
    local DATA="$1"
    local TODAY=$(date +"%Y-%m-%d")

    # Skip jika API kosong
    [[ -z "$DATA" ]] && return

    mkdir -p /user/bwlog
    mkdir -p /user/bwcounter

    echo "$DATA" | grep "^user" | while read -r line; do
        USER=$(echo "$line" | cut -d':' -f2 | cut -d'-' -f1)
        DIR=$(echo "$line" | cut -d'>' -f2 | cut -f1)
        VALUE=$(echo "$line" | awk '{print $2}')

        COUNTER="/user/bwcounter/${USER}-${DIR}.txt"
        LOG="/user/bwlog/${USER}.log"

        OLD=0
        [[ -f "$COUNTER" ]] && OLD=$(cat "$COUNTER")

        DELTA=$((VALUE - OLD))
        [[ $DELTA -lt 0 ]] && DELTA=$VALUE

        echo "$VALUE" > "$COUNTER"
        echo "$TODAY $DIR $DELTA" >> "$LOG"
    done
}

# ===== MAIN LOOP =====
while true; do
    DATA=$(apidata)
    log_user_data "$DATA"
    sleep $INTERVAL
done
