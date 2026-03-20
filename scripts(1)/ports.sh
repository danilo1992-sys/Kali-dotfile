echo "  "

#!/bin/bash

port =$(cat $1 $HOME/.config/bin/ports.txt)

if [ $port ] 
  echo " $port" 
else 
  echo " No Port"
fi 
