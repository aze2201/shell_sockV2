# shell_sock V2
## Server for Connecting to IoT Device PTY Terminal behind NAT

## Description
This project aims to share the local terminal with a cloud proxy using `x509` certificates. 
Unlike SSH, there's no need to manage individual device keys centrally for authentication in `.ssh/authorized_keys`. 
Instead, it allows to connect IoT via your own UNIX SOCK file. 
For instance, unlike `ssh -R 12345:0.0.0.0:12345 user@proxy`, all IoT devices connect to Proxy Linux machina with 2 port. Signalling and Media for `/bin/bash`
The x509-based certificate setup eliminates the need to manage SSH keys. All devices require certificates signed by the same CA used by the server.

![Flow](https://github.com/aze2201/shell_sock/blob/main/shell_sock.pndg)

## About socat
Socat is a flexible, multi-purpose relay tool. Its purpose is to establish a relationship between two data sources, where each data source can be a file, a Unix socket, UDP, TCP, or standard input.


## How to install 
### Depencecies:
 `socat` and `make` <br>


### Installing Server (proxy)
```
apt-get install socat make
git clone https://github.com/aze2201/shell_sock.git`
cd shell_sock
make server
```
  - Generate keys
```
openssl genrsa -out /etc/shell_sock/server/certs/server.key 4096
openssl req -new -key /etc/shell_sock/server/certs/server.key -out /etc/shell_sock/server/certs/server.csr
```
  - Send the CSR to a CA provider and get a signed PEM certificate to store in `/etc/shell_sock/server/certs/server.crt`.
  - Obtain the CA public key chain and store it in `/etc/shell_sock/server/certs/ca-cert.crt.`
  - Configure `/etc/shell_sock/client/server/server.conf` file
```
cat server.conf
# private key
KEY=/etc/shell_sock/server/certs/server.key

# SIGNED PUBLIC KEY X509
CERT=/etc/shell_sock/server/certs/server.crt

# CA public key chain
CA_CERT=/etc/shell_sock/server/certs/ca-chain.crt

# SERVER LISTEN PORT
PORT=22443

# MEDIA (/bin/bash) PORT
MEDIA_PORT=2222

# TEMP FOLDER
TEMP=/tmp/shell_sock

# LOG FOLDER
LOG_PATH=/var/log/shell_sock


```
  - Start server
```
systemctl start shell_sock_server
```

Or you can export variables in conf file and start sh scrript manually from any directory
```
set -a
source /etc/shell_sock/server/config/*.conf
set +a
./shell_sock_server.sh
```


Help
```
/etc/shell_sock/shell_sock_server.sh 
Loading configuration...
Configurations are loaded !

ERROR: Some of arguments are not specified !! 

To share accept terminal PTY requires certificates wich is signed by any CA
Generate private key: root@shell_sock:~\# openssl genrsa -out certs/server.key 4096
Generate CSR key:     root@shell_sock:~\# openssl req -new -key certs/server.key -out certs/server.csr
Send CSR file to CA and obtain signed PEM or CRT file and store certs folder (x509)
Get CA public key chain

  {-k|--key     }  private key   -- Set prvate key     or   root@shell_sock:~# export KEY=
  {-c|--cert    }  public key    -- Set public key     or   root@shell_sock:~# export CERT=
  {-C|--ca-cert }  CA file       -- Set CA public key  or   root@shell_sock:~# export CA_CERT=
  {-p|--port    }  PORT          -- Set listen port    or   root@shell_sock:~# export PORT=
  {-t|--temp    }  TEMP          -- Set TEMP folder    or   root@shell_sock:~# export TEMP=
  {-l|--log     }  LOG_PATH      -- Set LOG folder     or   root@shell_sock:~# export LOG_PATH=
  {-d|--debug   }


```







### Installing client
```
apt-get install socat make
git clone https://github.com/aze2201/shell_sock.git`
cd shell_sock
make client
```

  - Generate keys
```
openssl genrsa -out /etc/shell_sock/client/certs/iot.key 4096
openssl req -new -key /etc/shell_sock/client/certs/iot.key -out /etc/shell_sock/client/certs/iot.csr
```
-  Send the CSR to a CA provider and get a signed PEM certificate to store in  `/etc/shell_sock/client/certs/iot.crt`.
-  Obtain the CA public key chain and store it in `/etc/shell_sock/client/certs/ca-cert.crt`.
-  Configure `/etc/shell_sock/client/config/client.conf` file
  
```
cat client.conf
# private key
KEY=

# SIGNED PUBLIC KEY X509
CERT=

# CA public key chain
CA_CERT=

# SERVER IP address or DOMAIN
# please not that, domain name should match with certificate DNS information
SERVER=

# SERVER PORT FOR SIGNALLING
PORT=22443

# SERVER PORT FOR /bin/bash MEDIA
MEDIA_PORT=2222

# LOGGING
LOG_PATH=/var/log/shell_sock
  
# TEMP DIR
TEMP=/tmp/shell_sock
```



  - Start Client
```
systemctl start shell_sock_server
```

Or you can export variables in conf file and start sh scrript manually from any directory
```
set -a
source /etc/shell_sock/client/config/*.conf
set +a
./shell_sock_client.sh
```


Help
```
/etc/shell_sock/shell_sock_client.sh 
Loading configuration
Configurations are loaded

ERROR: Some of arguments are not specified !! 

To share terminal to server requires certificates wich is signed by any CA
Generate private key: root@shell_sock:~\# openssl genrsa -out certs/server.key 4096
Generate CSR key:     root@shell_sock:~\# openssl req -new -key certs/server.key -out certs/server.csr
Send CSR file to CA and obtain signed PEM or CRT file and store certs folder (x509)
Get CA public key chain

  {-k|--key        }  private key  -- Set prvate key       or   root@shell_sock:~# export KEY=
  {-c|--cert       }  public key   -- Set public key       or   root@shell_sock:~# export CERT=
  {-C|--ca-cert    }  CA file      -- Set CA public key    or   root@shell_sock:~# export CA_CERT=
  {-p|--port       }  PORT         -- Set listen port      or   root@shell_sock:~# export PORT=
  {-s|--server     }  SERVER       -- Set server ip|domain or   root@shell_sock:~# export SERVER=
  {-m|--media-port }  MEDIA_PORT   -- Set port for bash    or   root@shell_sock:~# export MEDIA_PORT=
  {-t|--temp-dir   }  TEMP         -- Set tmp dir          or   root@shell_sock:~# export TEMP=
  {-l|--log        }  LOG_PATH     -- Set LOG directory    or   root@shell_sock:~# export LOG_PATH=
  {-d|--debug      }  DEBUG leve from 1 to 3
```


# Connect to device
Now you have a pattern wich port is which device. If you know port (you can get from hostname or serial, etc).
Use that port to connect your device.

```
$ ssh -t root@proxy "socat UNIX-LISTEN:/tmp/shell_sock/<hostname>/<random or user>.sock -",raw,echo=0
```

# BUG report
[BUG](https://github.com/aze2201/shell_sock/issues)

# My contacts
[Linkedin](https://www.linkedin.com/in/fariz-muradov-b100a268/)

# Buy ne a coffe if usefull. So, I can add more fetures
[buymeacoffee](https://www.buymeacoffee.com/2kfAp0elyz)



### Examples:
Proxy status
```
systemctl status shell_sock_server.service 
* shell_sock_server.service - SHELL over SOCK
     Loaded: loaded (/etc/systemd/system/shell_sock_server.service; enabled; vendor preset: enabled)
     Active: active (running) since Sat 2024-01-06 22:01:27 CET; 1h 12min ago
   Main PID: 3422108 (shell_sock_serv)
      Tasks: 9 (limit: 11958)
     Memory: 8.0M
        CPU: 25.867s
     CGroup: /system.slice/shell_sock_server.service
             |-3422108 /bin/bash /etc/shell_sock/shell_sock_server.sh
             |-3422113 /bin/bash /etc/shell_sock/shell_sock_server.sh
             |-3422114 /usr/bin/socat openssl-listen:2222,fork,cert=/etc/shell_sock/server/certs/server.crt,key=/etc/shell_sock/server/certs/server.key,cafile=/etc/shell_sock/server/certs/>
             |-3422115 /usr/bin/socat openssl-listen:22444,fork,cert=/etc/shell_sock/server/certs/server.crt,key=/etc/shell_sock/server/certs/server.key,cafile=/etc/shell_sock/server/certs>
             |-3422118 /usr/bin/socat openssl-listen:22444,fork,cert=/etc/shell_sock/server/certs/server.crt,key=/etc/shell_sock/server/certs/server.key,cafile=/etc/shell_sock/server/certs>
             |-3422120 /usr/bin/socat openssl-listen:22444,fork,cert=/etc/shell_sock/server/certs/server.crt,key=/etc/shell_sock/server/certs/server.key,cafile=/etc/shell_sock/server/certs>
             |-3422121 sh -c "\n     {\n         \$THIS_PATH/signalling.sh\n     }"
             |-3422122 /bin/bash /etc/shell_sock/signalling.sh
             `-3440883 sleep 2s

Jan 06 22:01:27 proxy systemd[1]: Started SHELL over SOCK.
Jan 06 22:01:27 proxy shell_sock_server.sh[3422111]: Loading configuration...
Jan 06 22:01:27 proxy shell_sock_server.sh[3422111]: Configurations are loaded !
Jan 06 22:01:27 proxy shell_sock_server.sh[3422108]: /usr/bin/socat
Jan 06 22:01:27 proxy shell_sock_server.sh[3422108]: SIGNALLING SERVER START 0.0.0.0:22444
Jan 06 22:01:27 proxy shell_sock_server.sh[3422108]: SIGNALLING SERVER START 0.0.0.0:2222
```

Agent status
```
● shell_sock_client.service - SHELL over SOCK
   Loaded: loaded (/etc/systemd/system/shell_sock_client.service; enabled; vendor preset: enabled)
   Active: active (running) since Sat 2024-01-06 22:01:40 CET; 1h 13min ago
 Main PID: 14734 (shell_sock_clie)
    Tasks: 6 (limit: 999)
   Memory: 1.9M
   CGroup: /system.slice/shell_sock_client.service
           ├─12467 sleep 10s
           ├─14734 /bin/bash /etc/shell_sock/shell_sock_client.sh
           ├─14753 /bin/bash /etc/shell_sock/shell_sock_client.sh
           ├─14763 cat /var/run/shell_sock/shell_sock.fifo -
           ├─14764 /usr/bin/socat - OPENSSL:proxy:22444,cafile=/etc/shell_sock/client/certs/ca-cert.crt,key=/etc/shell_sock/client/certs/client.key,cert=/etc/shell_sock/cl
           └─14765 /bin/bash /etc/shell_sock/shell_sock_client.sh
```
