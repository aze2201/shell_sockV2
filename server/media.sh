# read session from client which set by Signalling function and remove characters
read session    
session=$(echo "$session" | tr "\r" " " | sed "s/ //g")

# if client sent session 
if [ ! -z "$session" ]; then
    echo "$(date)|INFO| Server got new session, id is $session" >> $LOG_PATH/shell_sock_$(date +"%Y%m%d")

    # search sessionid in map table and get sock file
    sock_file=$(grep "$session" "$TEMP/map.table" | cut -f2 -d"|")

    # fix sessionid for easy removal
    sock_file_4_delete=$(echo "$sock_file" | rev | cut -f1 -d"/" | rev)

    echo "$(date)|INFO| connect to this TCP to this sock file $sock_file " >> $LOG_PATH/shell_sock_$(date +"%Y%m%d")
    $socat_command - UNIX-CONNECT:"$sock_file"

    # Remove session information after exit
    sed -i "/$session/d" $TEMP/map.table
    sed -i "/$sock_file_4_delete/d" $TEMP/sock.db
    echo "$(date)|INFO| $sock_file and $session deleted" >> $LOG_PATH/shell_sock_$(date +"%Y%m%d")
fi
