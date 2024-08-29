#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
UNDERLINE='\033[4m' # 下划线
NC='\033[0m'        # No Color

BIN_PATH="./bin"

function check_golang() {
  echo
  echo "[INFO] Checking golang..."
  if command -v go >/dev/null 2>&1; then
    GO_VER="$(go version)"
    echo "[INFO] Go is installed: " $GO_VER
    echo
  else
    echo "[INFO] Go is not installed. Start installing..."
    install_go

    if [[ $? != 0 ]]; then
      echo -e "[${RED}Err${NC}] Install ${YELLLOW}golang${NC} fail"
      exit 1
    fi
  fi
}

function install_go() {
  go_ver=$(curl -s https://go.dev/VERSION?m=text | grep go)
  echo "[INFO] Downloading ${go_ver}..."
  curl -s -L -o /tmp/$go_ver.linux-amd64.tar.gz https://go.dev/dl/${go_ver}.linux-amd64.tar.gz &&
    sudo tar -xf /tmp/go*.linux-amd64.tar.gz -C /usr/local/ &&
    rm /tmp/go*.linux-amd64.tar.gz &&
    echo 'export GOROOT=/usr/local/go' >>~/.profile &&
    echo 'export PATH=$GOROOT/bin:$PATH' >>~/.profile &&
    echo 'export GO111MODULE=on' >>~/.profile &&
    source ~/.profile && echo -e "[INFO] Install golang success:" && go version && echo
}

function build_caddy() {
  export GOOS=$1
  export GOARCH=$2
  export OUTPUT="caddy-${GOOS}-${GOARCH}"
  if [[ "$GOOS" == "windows" ]]; then
    export OUTPUT=$OUTPUT.exe
  fi
  cmd="~/go/bin/xcaddy build --output $BIN_PATH/${OUTPUT} --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive > /dev/null 2>&1"
  echo -e "- Building ${GREEN}${OUTPUT}${NC}: ${YELLOW}${cmd}${NC}"
  eval ${cmd}
}

function update_caddy() {
  go env -w GO111MODULE=on &&
    go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest &&
    build_caddy "linux" "amd64" &&
    # build_caddy "darwin" "arm64" &&
    # build_caddy "darwin" "amd64" &&
    # build_caddy "windows" "amd64" &&
    chmod +x $BIN_PATH/* && ls -lhF $BIN_PATH/caddy*
}

function download_naive() {
  NAIVE_VERSION=$1
  OS=$2
  ARCH=$3
  OS_N=$4
  ARCH_N=$5
  SUFFIX=${6:-tar.xz}

  target_name="naive-${OS}-${ARCH}.${SUFFIX}"
  download_url="https://github.com/klzgrad/naiveproxy/releases/download/${NAIVE_VERSION}/naiveproxy-${NAIVE_VERSION}-${OS_N}-${ARCH_N}.${SUFFIX}"
  download_cmd="curl -s -L -o /tmp/${target_name} $download_url"
  decompress_cmd="tar -xf /tmp/${target_name} -C /tmp"
  mv_cmd="mv /tmp/naiveproxy-${NAIVE_VERSION}-${OS_N}-${ARCH_N}/naive $BIN_PATH/naive-${OS}-${ARCH}"

  if [[ "$SUFFIX" == "zip" ]]; then
    decompress_cmd="unzip -q -o -d /tmp /tmp/${target_name}"
    mv_cmd="mv /tmp/naiveproxy-${NAIVE_VERSION}-${OS_N}-${ARCH_N}/naive.exe $BIN_PATH/naive-${OS}-${ARCH}.exe"
  fi

  echo -e "- Downloading: ${target_name} ... ${YELLOW}$download_cmd${NC}"

  eval $download_cmd && eval $decompress_cmd && eval $mv_cmd
  rm -rf /tmp/naive*
}

function update_naive() {
  rm -rf /tmp/naive*
  NAIVE_VERSION="v128.0.6613.40-1"
  download_naive $NAIVE_VERSION "linux" "amd64" "linux" "x64" &&
    download_naive $NAIVE_VERSION "darwin" "amd64" "mac" "x64" &&
    download_naive $NAIVE_VERSION "darwin" "arm64" "mac" "arm64" &&
    download_naive $NAIVE_VERSION "windows" "amd64" "win" "x64" "zip" &&
    echo &&
    chmod +x $BIN_PATH/naive* && ls -lhF $BIN_PATH/naive*
}

function update_hysteria() {
  curl -s -L -o $BIN_PATH/hysteria-linxu-amd64-avx https://download.hysteria.network/app/latest/hysteria-linux-amd64-avx &&
    curl -s -L -o $BIN_PATH/hysteria-darwin-amd64-avx https://download.hysteria.network/app/latest/hysteria-darwin-amd64-avx &&
    curl -s -L -o $BIN_PATH/hysteria-darwin-amd64 https://download.hysteria.network/app/latest/hysteria-darwin-amd64 &&
    curl -s -L -o $BIN_PATH/hysteria-darwin-arm64 https://download.hysteria.network/app/latest/hysteria-darwin-arm64 &&
    curl -s -L -o $BIN_PATH/hysteria-windows-amd64-avx.exe https://download.hysteria.network/app/latest/hysteria-windows-amd64-avx.exe &&
    echo &&
    chmod +x $BIN_PATH/* && ls -lhF $BIN_PATH/hy*
}

function main() {
  source ~/.profile

  up_caddy=false
  up_hy=false
  up_naive=false

  if [[ $# -eq 0 ]]; then
    up_caddy=true
    up_hy=true
  fi

  while [[ $# -gt 0 ]]; do
    case $1 in
    caddy)
      up_caddy=true
      ;;
    hysteria | hy)
      up_hy=true
      ;;
    naive)
      up_naive=true
      ;;
    all)
      up_caddy=true
      up_hy=true
      ;;
    *)
      echo -e "\n[${RED}Err${NC}] Invalid arg: $1\n"
      exit 0
      ;;
    esac
    shift
  done

  [ ! -d "$BIN_PATH" ] && mkdir -p $BIN_PATH # 创建./bin目录

  if ! check_golang; then
    echo -e "[${RED}Err${NC}] Check ${YELLLOW}golang${NC} success"
    exit 1
  fi

  if [ "$up_caddy" = true ]; then
    echo
    echo -e "[INFO] Updating ${GREEN}caddy${NC} ..."
    if update_caddy; then
      echo -e "[INFO] Updating ${GREEN}caddy${NC} success"
    else
      echo -e "[INFO] Updating ${GREEN}caddy${NC} fail"
      exit 1
    fi
    echo
  fi

  if [ "$up_hy" = true ]; then
    echo -e "[INFO] Updating ${GREEN}hysteria2${NC} ..."
    if update_hysteria; then
      echo -e "[INFO] Updating ${GREEN}hysteria2${NC} success"
    else
      echo -e "[Err] Updating ${GREEN}hysteria2${NC} fail"
      exit 1
    fi
    echo
  fi

  if [ "$up_naive" = true ]; then
    echo -e "[INFO] Updating ${GREEN}naive${NC} ..."
    if ! update_naive; then
      echo -e "[${RED}ERR${NC}] Update naive fail"
    fi
    echo
  fi
}

main $@
