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

TAG=${TAG:-latest}

github_download_url_prefix="https://gitee.com/xxoommd/magic/releases/download"
gitee_download_url_prefix="https://github.com/xxoommd/ultimate_collection/releases/download"

naive_bin_name=""
hysteria_bin_name=""

os_arch=$(uname -m)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	if [[ $os_arch != "x86_64" ]]; then
		logerr "Unsuppored arch: ${YELLOW}${os_arch}"${NC}
		exit 1
	fi

	naive_bin_name="naive-linux-amd64"
	hysteria_bin_name="hysteria-linux-amd64"
elif [[ "$OSTYPE" == "darwin"* ]]; then
	if [[ $os_arch == "x86_64" ]]; then
		naive_bin_name="naive-darwin-amd64"
		hysteria_bin_name="hysteria-darwin-amd64"
	elif [[ $os_arch == "arm64" ]]; then
		naive_bin_name="naive-darwin-arm64"
		hysteria_bin_name="hysteria-darwin-arm64"
	else
		logerr "Unsuppored arch: ${YELLOW}${os_arch}"${NC}
		exit 1
	fi
elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
	if [[ $os_arch == "x86_64" ]]; then
		naive_bin_name="naive-windows-amd64.exe"
		hysteria_bin_name="hysteria-windows-amd64-avx.exe"
	else
		logerr "Unsuppored arch: ${YELLOW}${os_arch}"${NC}
		exit 1
	fi
else
	logerr "Unsupported OS: ${YELLOW}$OSTYPE${NC} arch: {YELLOW}$os_arch${NC}"
	exit 1
fi

if [ -z "$naive_bin_name" ] || [ -z "$hysteria_bin_name" ]; then
	logerr "Download URL is null. Naive:$naive_bin_name Hysteria:$hysteria_bin_name"
	exit 1
fi

function download_bin() {
	download_url_naive="${gitee_download_url_prefix}/${TAG}/${naive_bin_name}"
	download_url_hysteria="${gitee_download_url_prefix}/${TAG}/${hysteria_bin_name}"

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
  listen: 127.0.0.1:21089
http:
  listen: 127.0.0.1:28080
EOF
}

function gen_naive_config() {

	echo -e "[INFO] Generate ${GREEN}${NAIVE_CONFIG}${NC} ..."
	cat >${NAIVE_CONFIG} <<EOF
{
  "listen": "http://127.0.0.1:28081",
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
