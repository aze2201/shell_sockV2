#!/bin/bash

## Author: Fariz Muradov

export THIS_PATH=$(dirname "$0")
export socat_command=$(command -v socat)

export _PID="/var/run/shell_sock"
export _SHELL_FIFO="$_PID/shell_sock.fifo"


# read config file if exist
[ -f /etc/shell_sock/client/config/*.conf ] &&
     (  
         echo "Loading configuration"
         set -a
         source /etc/shell_sock/client/config/*.conf
         set +a
         echo "Configurations are loaded"
     )



usage()
{
    exec 1>2   # Send standard output to standard error
    help
    exit 1
}

error()
{
    echo "$arg0: $*" >&2
    exit 1
}


help()
{
    echo
    echo "To share terminal to server requires certificates wich is signed by any CA"
    echo "Generate private key: root@shell_sock:~\# openssl genrsa -out certs/server.key 4096"
    echo "Generate CSR key:     root@shell_sock:~\# openssl req -new -key certs/server.key -out certs/server.csr"
    echo "Send CSR file to CA and obtain signed PEM or CRT file and store certs folder (x509)"
    echo "Get CA public key chain"
    echo ""
    echo "  {-k|--key        }  private key  -- Set prvate key       or   root@shell_sock:~# export KEY="
    echo "  {-c|--cert       }  public key   -- Set public key       or   root@shell_sock:~# export CERT="
    echo "  {-C|--ca-cert    }  CA file      -- Set CA public key    or   root@shell_sock:~# export CA_CERT="
    echo "  {-p|--port       }  PORT         -- Set listen port      or   root@shell_sock:~# export PORT="
    echo "  {-s|--server     }  SERVER       -- Set server ip|domain or   root@shell_sock:~# export SERVER="
    echo "  {-m|--media-port }  MEDIA_PORT   -- Set port for bash    or   root@shell_sock:~# export MEDIA_PORT="
    echo "  {-t|--temp-dir   }  TEMP         -- Set tmp dir          or   root@shell_sock:~# export TEMP="
    echo "  {-l|--log        }  LOG_PATH     -- Set LOG directory    or   root@shell_sock:~# export LOG_PATH="
    echo "  {-d|--debug      }  DEBUG leve from 1 to 3"
    echo ""               
    exit 0
}

# input arguments
no_args="0"
while test $# -gt 0
     do
          case "$1" in
              (-k|--key)
                  shift
                  [ $# = 0 ] && error "No private key specified"
                  export KEY="$1";
                  shift;;
				  
              (-c|--cert)
                  shift
                  [ $# = 0 ] && error "No public key specified"
                  export CERT="$1"
                  shift;;
				  
              (-C|--ca-cert)
                  shift
                  [ $# = 0 ] && error "No ca public key specified"
                  export CA_CERT="$1"
                  shift;;
				  
              (-p|--port)
                  shift
                  [ $# = 0 ] && error "No tcp server port specified"
                  export PORT="$1"
                  shift;;
				  
              (-m|--media-port)
                  shift
                  [ $# = 0 ] && error "No tcp server port specified"
                  export MEDIA_PORT="$1"
                  shift;;		
				  
              (-s|--server)
                  shift
                  [ $# = 0 ] && error "No tcp server specified"
                  export SERVER="$1"
                  shift;;

              (-l|--log)
                  shift
                  [ $# = 0 ] && error "No Log path specified"
                  export LOG_PATH="$1"
                  shift;;
				  
              (-t|--temp-dir)
                  shift
                  [ $# = 0 ] && error "No temporary path specified"
                  export TEMP="$1"
                  shift;;
				  
              (-d|--debug)
                   shift
                   if [ $# -ne 0 ]; then
                       socat_command=$(command -v socat)
                       _DEBUG="$1"
                       debug_option=""
                       for ((i = 0; i < _DEBUG; i++)); do
                           debug_option+=" -d"
                       done
                       export socat_command="$socat_command$debug_option"
                   fi
                  shift;;
				  
              (-h|--help)
                  help;;
              (*) help;;
          esac

done

$([ ! -z $KEY ] && [ ! -z $CERT ] && [ ! -z $CA_CERT ] && [ ! -z $PORT ] && [ ! -z $SERVER ] && [ ! -z $MEDIA_PORT ] && [ ! -z $LOG_PATH ] && [ ! -z $TEMP ] ) && no_args=1 || no_args=0
[[ "$no_args" -ne "1" ]] && { echo "";echo "ERROR: Some of arguments are not specified !! "; help; exit 1; }



# Initialize env
initialize() {
   # create necessary folder if not exist
   [ ! -d $TEMP ]     && mkdir $TEMP
   [ ! -d $LOG_PATH ] && mkdir $LOG_PATH
   [ ! -d $_PID ]     && mkdir $_PID
   
   # Re-create FIFO file
   rm -rf $_SHELL_FIFO && mkfifo $_SHELL_FIFO
}

# CONNECT to signalling
function signalling() {
   echo $(hostname) > $_SHELL_FIFO
   cat $_SHELL_FIFO -| $socat_command - OPENSSL:$SERVER:$PORT,cafile=$CA_CERT,key=$KEY,cert=$CERT,verify=4 | while read line; 
   do
          # Log   
          echo "$(date)| Message from $SERVER:$PORT is $line"       >> "$LOG_PATH/shell_sock_$(date +"%Y%m%d")"
      
	  # if message is Session ID then, connect local bash to remote 
	  if [ "$line" != "$(hostname)" ]; then
	        # Log
		echo "bin/bash-ing with session $line to $SERVER:$PORT" >> "$LOG_PATH/shell_sock_$(date +"%Y%m%d")"
        
		# connect bash in background
		$THIS_PATH/bash_media.sh "$line" &
		media_connect_pid=$!
		echo $media_connect_pid > $_PID/media.pid
      fi
   done
}


main() {
   # Initialize env
   initialize

   # change FIFO descriptor to unusual
   exec 3<> $_SHELL_FIFO
   
   # start connection
   echo "..Startging to connect to: $SERVER:$PORT"
   signalling &
   
   # get signalling pid and save it.
   _c_pid=$!
   echo $_c_pid > $_PID/signalling.pid
   
   # control loop
   while true; do
   
      # check connection is ESTABLISHED to server.
      lsof -i :$PORT| grep ESTABLISHED > /dev/null   
      # EXIT if not running. Let systemd restart it
      if [ $? -ne 0 ]; then 
        kill -9 $_c_pid 
		media_pid=$(lsof -i :$MEDIA_PORT | grep ESTABLISHED| grep -v PID |awk '{print $2}')
		[ -! z $media_pid ] && kill -9 $media_pid
        break
      fi
      
      # wait
      sleep 10s
   done
   # handover to systemd to restart
   exit 1
}
main
