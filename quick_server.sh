#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
UNDERLINE='\033[4m' # 下划线
NC='\033[0m'        # No Color

# 仅root用户执行
if [ "$(id -u)" -eq 0 ]; then
  echo "当前用户是 root"
else
  echo -e "${RED}[Err]${NC}当前用户不是 root"
  exit 1
fi

# 验证域名格式是否合法
function is_valid_domain() {
  local str="$1"

  # 使用正则表达式匹配合法域名格式
  if [[ $str =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$ ]]; then
    return 0 # 合法返回0
  else
    return 1 # 不合法返回1
  fi
}

echo -e "\n[INFO] Validate DOMAN: ${BLUE}${DEPLOY_DOMAIN}${NC} ..."

if [[ -z $DEPLOY_DOMAIN ]]; then
  echo
  echo "[${RED}Err${NC}] DEPLOY_DOMAIN is not set"
  echo
  exit 1
fi

if is_valid_domain "$DEPLOY_DOMAIN"; then
  echo -e "[INFO] ${BLUE}${UNDERLINE}$DEPLOY_DOMAIN${NC} is a valid domain.\n"
else
  echo -e "[${RED}ERR${NC}] ${BLUE}${UNDERLINE}$DEPLOY_DOMAIN${NC} is not a valid domain. Abort."
  exit 1
fi

TAG=${TAG:-"latest"}

echo -e "[INFO] Using TAG: ${YELLOW}${TAG}${NC}"

caddy_download_url=""
hysteria_download_url=""

if [ "$DOWNLOAD_SRC" = "gitee" ]; then
  echo -e "[INFO] Download from ${YELLOW}Gitee${NC} ..."
  caddy_download_url="https://gitee.com/xxoommd/magic/releases/download/${TAG}/caddy-linux-amd64"
  hysteria_download_url="https://gitee.com/xxoommd/magic/releases/download/${TAG}/hysteria-linxu-amd64-avx"
else
  echo -e "[INFO] Download from ${YELLOW}Github${NC} ..."
  caddy_download_url="https://github.com/xxoommd/magic/releases/download/${TAG}/caddy-linux-amd64"
  hysteria_download_url="https://github.com/xxoommd/magic/releases/download/${TAG}/hysteria-linxu-amd64-avx"
fi

# 设置工作目录
WORKING_DIR="/root/.local/magic"
if [ ! -d "${WORKING_DIR}" ]; then
  mkdir -p "${WORKING_DIR}"
fi

CADDY_STORAGE="${WORKING_DIR}/caddy"
CERT_DIR="$CADDY_STORAGE/certificates/acme-v02.api.letsencrypt.org-directory/$DEPLOY_DOMAIN"
CRT_FILE="$CERT_DIR/$DEPLOY_DOMAIN.crt"
KEY_FILE="$CERT_DIR/$DEPLOY_DOMAIN.key"
HY_CONFIG_FILE="${WORKING_DIR}/hy-config.yaml"
CADDY_CONFIG_FILE="${WORKING_DIR}/Caddyfile"

echo -e "[INFO] Download ${GREEN}hysteria${NC} and ${GREEN}caddy${NC} ..."
curl -L -o /usr/local/bin/hysteria $hysteria_download_url &&
  curl -L -o /usr/local/bin/caddy $caddy_download_url &&
  chmod +x /usr/local/bin/hysteria /usr/local/bin/caddy
echo -e "[INFO] Download Done\n"

# Generating all config files...
echo -e "[INFO] Generate ${GREEN}${CADDY_CONFIG_FILE}${NC} ..."
cat >${CADDY_CONFIG_FILE} <<EOF
{
	storage file_system $CADDY_STORAGE
}

:443, ${DEPLOY_DOMAIN}
tls xxoommd@${DEPLOY_DOMAIN}
	route {
		forward_proxy {
		basic_auth xxoommd fuckyouall
		hide_ip
		hide_via
		probe_resistance
		# upstream socks5://127.0.0.1:40000
	}
		respond "hello ${DEPLOY_DOMAIN}@naive!"
}
EOF
echo -e "[INFO] Generate Done\n"

echo -e "[INFO] Generate ${GREEN}${HY_CONFIG_FILE}${NC} ..."
cat >${HY_CONFIG_FILE} <<EOF
listen: :8443
tls:
  cert: $CRT_FILE
  key: $KEY_FILE
auth:
  type: password
  password: fuckyouall
masquerade:
  type: string
  string:
    content: 'hello ${DEPLOY_DOMAIN}@hysteria2'
    headers:
      content-type: text/plain
      custom-stuff: ice cream so good
    statusCode: 200
disableUDP: false
EOF
echo -e "[INFO] Generate Done\n"

echo -e "[INFO] Generate ${GREEN}hysteria.service${NC} ..."
cat >/etc/systemd/system/hysteria.service <<EOF
[Unit]
Description=Hysteria Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/hysteria server --config /${HY_CONFIG_FILE}
WorkingDirectory=${WORKING_DIR}
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF
echo -e "[INFO] Generate Done\n"

echo -e "[INFO] Generating caddy.service${NC} ..."
cat >/etc/systemd/system/caddy.service <<EOF
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
User=root
ExecStart=/usr/local/bin/caddy run --environ --config ${CADDY_CONFIG_FILE}
ExecReload=/usr/local/bin/caddy reload --config ${CADDY_CONFIG_FILE}
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
echo -e "[INFO] Generate Done\n"

echo -e "[INFO] Handling ${GREEN}system daemons${NC} ..."
systemctl daemon-reload && systemctl enable caddy && systemctl enable hysteria
echo -e "[INFO] Generate Done\n"

echo -e "All ready!!!"
echo -e "  Note: Run ${GREEN}caddy${NC} first to gain certificates. Wait a few seconds then start ${GREEN}hysteria${NC}."
echo -e "  E.g: ${GREEN}systemctl start caddy && sleep 10 && systemctl start hysteria${NC}\n"
