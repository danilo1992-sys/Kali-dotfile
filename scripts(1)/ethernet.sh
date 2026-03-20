echo "  "
#!/bin/bash

if ip link show eth0 &>/dev/null; then
  IP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
  echo "󰈀   ${IP}"
else
  echo "󰈀   Disconect"
fi
