#!/bin/bash

export session="$1"

$socat_command  system:'echo "$session";TERM=xterm-256color /bin/bash',pty,stderr,setsid,sigint,sane OPENSSL:$SERVER:$MEDIA_PORT,cafile=$CA_CERT,key=$KEY,cert=$CERT,verify=4
