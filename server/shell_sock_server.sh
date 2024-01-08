#!/bin/bash

## Author: Fariz Muradov

export THIS_PATH=$(dirname "$0")
export _PID="/var/run/shell_sock"
export socat_command=$(command -v socat)

# read config file if exist
[ -f /etc/shell_sock/server/config/*.conf ] &&
     (  
         echo "Loading configuration..."
         set -a
         source /etc/shell_sock/server/config/*.conf
         set +a
         echo "Configurations are loaded !"
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
       echo "To share accept terminal PTY requires certificates wich is signed by any CA"
       echo "Generate private key: root@shell_sock:~\# openssl genrsa -out certs/server.key 4096"
       echo "Generate CSR key:     root@shell_sock:~\# openssl req -new -key certs/server.key -out certs/server.csr"
       echo "Send CSR file to CA and obtain signed PEM or CRT file and store certs folder (x509)"
       echo "Get CA public key chain"
       echo ""
       echo "  {-k|--key     }  private key   -- Set prvate key     or   root@shell_sock:~# export KEY="
       echo "  {-c|--cert    }  public key    -- Set public key     or   root@shell_sock:~# export CERT="
       echo "  {-C|--ca-cert }  CA file       -- Set CA public key  or   root@shell_sock:~# export CA_CERT="
       echo "  {-p|--port    }  PORT          -- Set listen port    or   root@shell_sock:~# export PORT="
       echo "  {-t|--temp    }  TEMP          -- Set TEMP folder    or   root@shell_sock:~# export TEMP="
       echo "  {-l|--log     }  LOG_PATH      -- Set LOG folder     or   root@shell_sock:~# export LOG_PATH="
       echo "  {-d|--debug   }  DEBUG leve from 1 to 3"
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
                   [ $# = 0 ] && error "No tcp listen port specified for signalling"
                   export PORT="$1"
                   shift;;
				   
               (-m|--media-port)
                   shift
                   [ $# = 0 ] && error "No tcp listen port specified for media"
                   export MEDIA_PORT="$1"
                   shift;;
				   
               (-t|--temp)
                   shift
                   [ $# = 0 ] && error "No temporary path specified"
                   export TEMP="$1"
                   shift;;
				   
               (-l|--log)
                   shift
                   [ $# = 0 ] && error "No Log path specified"
                   export LOG_PATH="$1"
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

$([ ! -z $KEY ] && [ ! -z $CERT ] && [ ! -z $CA_CERT ] && [ ! -z $PORT ] && [ ! -z $MEDIA_PORT ] && [ ! -z $LOG_PATH ] && [ ! -z $TEMP ] ) && no_args=1 || no_args=0
[[ "$no_args" -ne "1" ]] && { echo "";echo "ERROR: Some of arguments are not specified !! "; help; exit 1; }


# Initialize env
initialize() {
   # create necessary folder if not exist
   [ ! -d $TEMP ]     && mkdir $TEMP
   [ ! -d $LOG_PATH ] && mkdir $LOG_PATH
   [ ! -d $_PID ]     && mkdir $_PID
   
   # empty sessions
   echo "dummy" > $TEMP/sock.db
   echo "dummy|dummy" > $TEMP/map.table
}



# SIGNALING
function signalling() {
     $socat_command openssl-listen:$PORT,fork,cert=$CERT,key=$KEY,cafile=$CA_CERT,verify=4 system:'
     {
         $THIS_PATH/signalling.sh
     }'
}





# Media exchange with client /bin/bash
media() {
    $socat_command openssl-listen:$MEDIA_PORT,fork,cert=$CERT,key=$KEY,cafile=$CA_CERT,verify=4 system:'
    { 
       $THIS_PATH/media.sh
    }'
}


main () {
  # inialize environment
  initialize
  
  echo "SIGNALLING SERVER START 0.0.0.0:$PORT"
  echo "SIGNALLING SERVER START 0.0.0.0:$MEDIA_PORT"
  
  # start signalling server
  signalling &
  [ $? -eq 0 ] && echo $! > $_PID/signalling.pid || 
    (
      echo "$(date)|ERROR|Signalling server not started. Maybe try with bash -x <script>"	
      exit 1
     )
  
   # Start Media script
   media
}

main
