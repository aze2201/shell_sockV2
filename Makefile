#include variables.env

# Colors
RED=\033[0;31m
YELLOW=\033[1;33m
NC=\033[0m # No Color

# systemd
SYSTEMD_INIT_PATH := /etc/systemd/system

# current
CURR_SHELL_SOCK := `pwd`
ROOT_SHELL_SOCK := /etc/shell_sock
SERV_SHELL_SOCK := $(ROOT_SHELL_SOCK)/server
CLNT_SHELL_SOCK := $(ROOT_SHELL_SOCK)/client

# Target server
SERV_CONF_SHELL_SOCK := $(SERV_SHELL_SOCK)/config
SERV_CERT_SHELL_SOCK := $(SERV_SHELL_SOCK)/certs

# Target client
CLNT_CONF_SHELL_SOCK := $(CLNT_SHELL_SOCK)/config
CLNT_CERT_SHELL_SOCK := $(CLNT_SHELL_SOCK)/certs

# Targets
.PHONY: server client help clean

server:
	@echo "${YELLOW}Installing server...${NC}"
	@if ! command -v socat >/dev/null; then \
		if command -v apt >/dev/null; then \
			sudo apt-get install socat; \
		else \
			sudo yum install socat; \
		fi; \
	fi
	
	@echo "${YELLOW}Configuring folders...${NC}"
	[ ! -d $(ROOT_SHELL_SOCK) ] && \
		(mkdir $(ROOT_SHELL_SOCK) && \
		mkdir -p $(SERV_CONF_SHELL_SOCK) && \
		mkdir -p $(SERV_CERT_SHELL_SOCK))
	   
	@echo "${YELLOW}Copying files to /etc/...${NC}"
	cp -r $(CURR_SHELL_SOCK)/server/config/server.conf $(SERV_CONF_SHELL_SOCK)/
	cp -r $(CURR_SHELL_SOCK)/server/config/shell_sock_server.service $(SYSTEMD_INIT_PATH)/shell_sock_server.service
	cp -r $(CURR_SHELL_SOCK)/server/shell_sock_server.sh $(ROOT_SHELL_SOCK)/
	cp -r $(CURR_SHELL_SOCK)/server/signalling.sh $(ROOT_SHELL_SOCK)/
	cp -r $(CURR_SHELL_SOCK)/server/media.sh $(ROOT_SHELL_SOCK)/
	chmod +x $(ROOT_SHELL_SOCK)/shell_sock_server.sh $(ROOT_SHELL_SOCK)/signalling.sh $(ROOT_SHELL_SOCK)/media.sh
	systemctl daemon-reload
	systemctl enable shell_sock_server.service
	@echo "${YELLOW}Server installation complete.${NC}"
	

client:
	@echo "${YELLOW}Installing client...${NC}"
	@if ! command -v socat >/dev/null; then \
		if command -v apt >/dev/null; then \
			sudo apt-get install socat; \
		else \
			sudo yum install socat; \
		fi; \
	fi
	
	@echo "${YELLOW}Configuring folders...${NC}"
	[ ! -d $(ROOT_SHELL_SOCK) ] && \
		(mkdir $(ROOT_SHELL_SOCK) && \
		mkdir -p $(CLNT_CONF_SHELL_SOCK) && \
		mkdir -p $(CLNT_CERT_SHELL_SOCK))
	
	@echo "${YELLOW}Copying files to /etc/...${NC}"
	cp -r $(CURR_SHELL_SOCK)/client/config/client.conf $(CLNT_CONF_SHELL_SOCK)/
	cp -r $(CURR_SHELL_SOCK)/client/config/shell_sock_client.service $(SYSTEMD_INIT_PATH)/shell_sock_client.service
	cp -r $(CURR_SHELL_SOCK)/client/shell_sock_client.sh $(ROOT_SHELL_SOCK)/
	cp -r $(CURR_SHELL_SOCK)/server/bash_media.sh $(ROOT_SHELL_SOCK)/
	chmod +x $(ROOT_SHELL_SOCK)/shell_sock_client.sh $(ROOT_SHELL_SOCK)/bash_media.sh
	systemctl daemon-reload
	systemctl enable shell_sock_client.service
	@echo "${YELLOW}Client installation complete.${NC}"
	
clean:
	@echo "${YELLOW}Cleaning up...${NC}"
	rm -rf $(ROOT_SHELL_SOCK)
	rm -rf $(SYSTEMD_INIT_PATH)/shell_sock_server.service
	rm -rf $(SYSTEMD_INIT_PATH)/shell_sock_client.service
	systemctl daemon-reload

help:
	@echo "${YELLOW}Available targets:${NC}"
	@echo "  ${RED}server:${NC}       Installs server software"
	@echo "  ${RED}client:${NC}       Installs agent on IoT device"
	@echo "  ${RED}clean:${NC}        Removes installed software"
	@echo "  ${RED}help:${NC}         Displays available targets and usage"
	@echo ""
	@echo "${YELLOW}To build:${NC}"
	@echo "  1. Generate certificates and sign with CA"
	@echo "  2. Copy key, public PEM, CA PEM chain to \e[92m/etc/shell_sock_server/server|client/certs folder\e[0m"
	@echo "  3. Configure keys absolute path and other parameters in \e[92m/etc/shell_sock/server/config/server.conf|client.conf\e[0m"
	@echo "  4. Start software using \e[92msystemctl start shell_sock_server.service\e[0m or \e[92msystemctl start shell_sock_client.service\e[0m"

# Default target
.DEFAULT_GOAL := help
