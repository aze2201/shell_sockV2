#!/bin/bash

# get hostname from client and remove characters
read hostn
hostn=$(echo $hostn | tr "\r" " " | sed "s/ //g");

# create hostname Folder if not exist
[ ! -d "$TEMP/$hostn" ] && mkdir "$TEMP/$hostn"

# Logging
echo "$(date)|INFO| $hostn folder is creating" >> "$LOG_PATH/shell_sock_$(date +"%Y%m%d")"

# start loop to keep connection
while true; do
 sock_file=$(find "${TEMP}/${hostn}" -type s -name "*.sock" $(printf "! -name %s " $(cat "$TEMP/sock.db" | rev | cut -f1 -d"/" | rev)))
 if [ ! -z "$sock_file" ]; then
 
  # if sock file exists then store it as session
  echo "$sock_file" >> "$TEMP/sock.db"
  
  # generate random number
  session_id=$(openssl rand -base64 7 | base64)
  
  # send to client to initialize /bin/bash and map to newest sock file.
  echo $session_id
  echo "$session_id|$sock_file" >> "$TEMP/map.table"
  echo "$(date)|INFO| New session information set up. SessionID is $session_id" >> "$LOG_PATH/shell_sock_$(date +"%Y%m%d")"
 fi
 sleep 2s
done
