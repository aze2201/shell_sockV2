# shell_sock 
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
Client: `socat` and `make` <br>

Server: `socat`, `nc` and `make`

### Installing Server (proxy)
```
apt-get install socat nc make
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
# private key
KEY=/etc/shell_sock/server/certs/server.key

# SIGNED PUBLIC KEY X509
CERT=/etc/shell_sock/server/certs/server.crt

# CA public key chain
CA_CERT=/etc/shell_sock/server/certs/ca-chain.crt

# SERVER LISTEN PORT
PORT=22444

# MEDIA (/bin/bash) PORT
MEDIA_PORT=2222

# TEMP FOLDER
TEMP=/tmp/shell_sock

# LOG FOLDER


```
  - Start server
```
systemctl start shell_sock_server
```

Or you can export variables in conf file and start sh scrript manually from any directory
```
$ export KEY=/etc/shell_sock/server/certs/iot.key
$ export CERT=/etc/shell_sock/server/certs/iot.crt
$ export CA_CERT=/etc/shell_sock/server/certs/ca-cert.crt
$ export PORT=123457
$ ./shell_sock_client.sh
```

or
```
./shell_sock_server.sh --cert certs/server.crt -k certs/server.key -C certs/ca-ca.crt -p 123457
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
KEY=/etc/shell_sock/client/certs/iot.key

# SIGNED PUBLIC KEY X509
CERT=/etc/shell_sock/client/certs/iot.crt

# CA public key chain
CA_CERT=/etc/shell_sock/client/certs/ca-cert.crt

# SERVER IP address or DOMAIN
# please not that, domain name should match with certificate DNS information
SERVER=<domainname>

# SERVER PORT
PORT=123457

# Local PORT
LPORT=4446
```
Help
```
./shell_sock_server.sh --help
Loading configuration
Configurations are loaded

To share accept terminal PTY requires certificates wich is signed by any CA
Generate private key: root@shell_sock:~\# openssl genrsa -out certs/server.key 4096
Generate CSR key:     root@shell_sock:~\# openssl req -new -key certs/server.key -out certs/server.csr
Send CSR file to CA and obtain signed PEM or CRT file and store certs folder (x509)
Get CA public key chain

  {-k|--key     }  private key   -- Set prvate key     or   root@shell_sock:~# export KEY=
  {-c|--cert    }  public key    -- Set public key     or   root@shell_sock:~# export CERT=
  {-C|--ca-cert }  CA file       -- Set CA public key  or   root@shell_sock:~# export CA_CERT=
  {-p|--port    }  PORT          -- Set listen port    or   root@shell_sock:~# export PORT=


```
  - Start Client
```
systemctl start shell_sock_server
```

Or you can export variables in conf file and start sh scrript manually from any directory
```
$ export KEY=/etc/shell_sock/client/certs/iot.key
$ export CERT=/etc/shell_sock/client/certs/iot.crt
$ export CA_CERT=/etc/shell_sock/client/certs/ca-cert.crt
$ export SERVER=<domainname>
$ export PORT=123457
$ export LPORT=4446
$ ./shell_sock_client.sh
```

or
```
./shell_sock_client.sh --cert certs/iot.crt -k certs/iot.key -C certs/ca-ca.crt -p 123457 -s <domain> --local-port 4444
```
Help
```
./shell_sock_client.sh --help
Loading configuration
Configurations are loaded

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
  {-l|--local-port }  LPORT        -- Set port in remote   or   root@shell_sock:~# export LPORT=
```


# Connect to device
Now you have a pattern wich port is which device. If you know port (you can get from hostname or serial, etc).
Use that port to connect your device.

```
$ ssh -t root@proxy "socat tcp-listen:4446 -",raw,echo=0
```
# BUG report
[BUG](https://github.com/aze2201/shell_sock/issues)

# My contacts
[Linkedin](https://www.linkedin.com/in/fariz-muradov-b100a268/)

# Buy ne a coffe if usefull. So, I can add more fetures
[buymeacoffee](https://www.buymeacoffee.com/2kfAp0elyz)



### Examples:
Proxy Server
```
systemctl status  shell_sock_server.service 
* shell_sock_server.service - SHELL over SOCK
     Loaded: loaded (/etc/systemd/system/shell_sock_server.service; enabled; vendor preset: enabled)
     Active: active (running) since Sun 2023-12-24 20:56:23 CET; 6s ago
   Main PID: 39534 (shell_sock_serv)
      Tasks: 3 (limit: 11958)
     Memory: 3.3M
        CPU: 86ms
     CGroup: /system.slice/shell_sock_server.service
             |-39534 /bin/bash /etc/shell_sock/shell_sock_server.sh
             |-39538 socat openssl-listen:123457,fork,cert=/etc/shell_sock/server/certs/server.crt,key=/etc/shell_sock/server/certs/s>
             `-39557 socat openssl-listen:123457,fork,cert=/etc/shell_sock/server/certs/server.crt,key=/etc/shell_sock/server/certs/s>

Dec 24 20:56:23 proxy shell_sock_server.sh[39536]: SHLVL=1
Dec 24 20:56:23 proxy shell_sock_server.sh[39536]: KEY=/etc/shell_sock/server/certs/server.key
Dec 24 20:56:23 proxy shell_sock_server.sh[39536]: JOURNAL_STREAM=9:651432
Dec 24 20:56:23 proxy shell_sock_server.sh[39536]: PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Dec 24 20:56:23 proxy shell_sock_server.sh[39536]: _=/usr/bin/printenv
Dec 24 20:56:23 proxy shell_sock_server.sh[39534]: SERVER START 0.0.0.0:123457
```

Agent start
```
systemctl status shell_sock_client
● shell_sock_client.service - SHELL over SOCK
   Loaded: loaded (/etc/systemd/system/shell_sock_client.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2023-12-24 20:29:41 CET; 1h 48min ago
 Main PID: 14054 (shell_sock_clie)
    Tasks: 6 (limit: 999)
   Memory: 88.0M
   CGroup: /system.slice/shell_sock_client.service
           ├─14054 /bin/bash /etc/shell_sock/shell_sock_client.sh
           ├─15614 socat OPENSSL:<domainname>:123457,cafile=/etc/she…
           ├─15615 socat OPENSSL:<domainname>:123457,cafile=/etc/she…
           ├─15616 sh -c echo $LPORT; /bin/bash
           ├─15617 /bin/bash
           └─15784 systemctl status shell_sock_client

Dec 24 20:58:33 IoTHost shell_sock_client.sh[14054]: Will attempt again…me
```
