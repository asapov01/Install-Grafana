#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/UnityNodes/scripts/main/utils.sh)

spinner() {
  local delay=0.1
  local progress=0
  local width=20 # Ширина прогресс-бара
  local total_iterations=30 # Всего итераций (время анимации = total_iterations * delay)

  for ((i = 0; i < total_iterations; i++)); do
    printf "Progress: %3d%% [%-${width}s] %d%%\r" "$progress" "$(printf "%0.s#" $(seq 1 $((progress*width/100))))" "$progress"
    ((progress += 100 / total_iterations)) # Увеличиваем прогресс на 100 / total_iterations %
    sleep "$delay"
  done
  printf "\n"
}

clear
printLogo

echo ""
(spinner) & # Запускаем анимацию в фоновом режиме

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
