#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
UNDERLINE='\033[4m' # 下划线
NC='\033[0m'        # No Color

function logerr() {
	echo -e "[${RED}ERR${NC}] $1"
}

function loginfo() {
	echo -e "[INFO] $1"
}

if [[ -z $DEPLOY_DOMAIN ]]; then
	echo
	logerr "env:DEPLOY_DOMAIN is not set"
	echo
	exit 1
fi

download_url_naive=""
download_url_hysteria=""

# https://gitee.com/xxoommd/magic/releases/download/v0.1/naive-darwin-amd64
# https://github.com/xxoommd/ultimate_collection/releases/download/latest/naive-darwin-amd64

os_arch=$(uname -m)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	if [[ $os_arch != "x86_64" ]]; then
		logerr "Unsuppored arch: ${YELLOW}${os_arch}"${NC}
		exit 1
	fi

	download_url_naive="https://github.com/xxoommd/ultimate_collection/releases/download/latest/naive-linux-amd64"
	download_url_hysteria="https://github.com/xxoommd/ultimate_collection/releases/download/latest/hysteria-linux-amd64-avx"
elif [[ "$OSTYPE" == "darwin"* ]]; then
	if [[ $os_arch == "x86_64" ]]; then
		download_url_naive="https://github.com/xxoommd/ultimate_collection/releases/download/latest/naive-darwin-amd64"
		download_url_hysteria="https://github.com/xxoommd/ultimate_collection/releases/download/latest/hysteria-darwin-amd64-avx"
	elif [[ $os_arch == "arm64" ]]; then
		download_url_naive="https://github.com/xxoommd/ultimate_collection/releases/download/latest/naive-darwin-arm64"
		download_url_hysteria="https://github.com/xxoommd/ultimate_collection/releases/download/latest/hysteria-darwin-arm64"
	else
		logerr "Unsuppored arch: ${YELLOW}${os_arch}"${NC}
		exit 1
	fi
elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
	if [[ $os_arch == "x86_64" ]]; then
		download_url_naive="https://github.com/xxoommd/ultimate_collection/releases/download/latest/naive-windows-amd64.exe"
		download_url_hysteria="https://github.com/xxoommd/ultimate_collection/releases/download/latest/hysteria-windows-amd64-avx.exe"
	else
		logerr "Unsuppored arch: ${YELLOW}${os_arch}"${NC}
		exit 1
	fi
else
	logerr "Unsupported OS: ${YELLOW}$OSTYPE${NC} arch: {YELLOW}$os_arch${NC}"
	exit 1
fi

if [ -z "$download_url_naive" ] || [ -z "$download_url_hysteria" ]; then
	logerr "Download URL is null. Naive:$download_url_naive Hysteria:$download_url_hysteria"
	exit 1
fi

function download_bin() {
	curl -o ./naive -L $download_url_naive && curl -o ./hysteria -L $download_url_hysteria && chmod +x ./naive ./hysteria
}

HYSTERIA_CONFIG="./hysteria-config.yaml"
NAIVE_CONFIG="./naive-config.json"

function gen_hysteria_config() {

	cat >$HYSTERIA_CONFIG <<EOF
server: $DEPLOY_DOMAIN:8443 
auth: fuckyouall 
bandwidth: 
  up: 100 mbps
  down: 1000 mbps
socks5:
  listen: 127.0.0.1:1080 
http:
  listen: 127.0.0.1:8080 
EOF
}

function gen_naive_config() {

	echo -e "[INFO] Generate ${GREEN}${NAIVE_CONFIG}${NC} ..."
	cat >${NAIVE_CONFIG} <<EOF
{
  "listen": "http://127.0.0.1:8081",
  "proxy": "quic://xxoommd:fuckyouall@$DEPLOY_DOMAIN"
}
EOF
	echo -e "[INFO] Generate Done\n"
}

function main() {
	if download_bin; then
		if gen_hysteria_config; then
			if gen_naive_config; then
				loginfo "ALL SUCCESS. Use: ./naive $NAIVE_CONFIG AND ./hysteria -c $HYSTERIA_CONFIG"
				exit 0
			fi
		fi
	else
		echo
		logerr "Download binary fail."
		echo
		exit 1
	fi
}

main $@
