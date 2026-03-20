echo "  "

#!/bin/bash

target=$(cat $1 /home/danilo/.config/bin/target.txt)

if [ $target ]; then
  echo "  $target"
else
  echo "  No Target "
fi
