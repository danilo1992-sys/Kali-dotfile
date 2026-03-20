echo "  "

#!/bin/bash

interface=$(/usr/sbin/ifconfig | grep tun_htb | awk '{print $1}' | tr -d ":")

if [ "$interface" = "tun_htb" ]; then
  echo "󰆧  $(/usr/sbin/ifconfig tun_htb | grep "inet " | awk '{print $2}')"
else
  echo "󰆧  Disconect"
fi
