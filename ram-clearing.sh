#!/bin/bash
clear
while true
do
RAM=$(free -m | awk 'NR==2{print $3}')
if [ $RAM -gt 350 ]
then
systemctl restart wireproxy
fi
sleep 60  # Check RAM every 60 seconds
done &>/dev/null &  # Redirect output to /dev/null
rm -f /root/ram-clearing.sh
clear
exit 1