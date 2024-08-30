## QUICK START

1. Set variable: `DEPLOY_DOMAIN`

```shell
export DEPLOY_DOMAIN=xxx.xxx
```

2. Start

#### server

- Github:

```shell
bash <(curl -fsSL https://raw.githubusercontent.com/xxoommd/magic/main/quick_server.sh)
```

- Gitea:

```shell
DOWNLOAD_SRC=gitee bash <(curl -fsSL https://gitee.com/xxoommd/magic/raw/main/quick_server.sh)
```

#### client

- Github:

```shell
TAG=latest bash <(curl -fsSL https://raw.githubusercontent.com/xxoommd/magic/main/quick_client.sh)
```

- Gitea:

```shell
TAG=latest bash <(curl -fsSL https://gitee.com/xxoommd/magic/raw/main/quick_client.sh)
```
