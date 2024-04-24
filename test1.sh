#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/UnityNodes/scripts/main/utils.sh)

spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  while ps -p "$pid" > /dev/null; do
    local temp=${spinstr#?}
    printf "################${spinstr:0:1}${temp}===100%%\r"
    local spinstr=${temp}${spinstr:0:1}
    sleep "$delay"
  done
  printf "\n"
}

clear
printLogo

echo ""
spinner $$ & # Используем $$ для получения PID текущего скрипта
printColor blue "Please enter the node moniker:"
read -r NODE_MONIKER

CHAIN_ID="lava-testnet-2"
BINARY_VERSION="v1.2.0"

source <(curl -s https://raw.githubusercontent.com/UnityNodes/scripts/main/dependencies.sh)

printColor blue "4. Building binaries"

export LAVA_BINARY=lavad

cd || return
rm -rf lava
git clone https://github.com/lavanet/lava
cd lava || return
git checkout v1.2.0
make install

make build
