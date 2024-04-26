#!/bin/bash

### Utils Unity Nodes
source <(curl -s https://raw.githubusercontent.com/UnityNodes/scripts/main/utils.sh)

### Function autoupgrade
CHAIN=$1
CHAIN_ID=$2
BLOCK=$3
VERSION=$4
BINARY=$5
PORT_RPC=$6

logo

echo -e "Node $(printBlue "$CHAIN") upgraded to version $(printBlue "$VERSION") on block height $(printBlue "$BLOCK")" && sleep 1

function AutoUpgrade() {
  local height

  until ((height >= BLOCK)); do
    if [ -z "$PORT_RPC" ]; then
      height=$($BINARY status 2>&1 | jq -r '.SyncInfo.latest_block_height // .sync_info.latest_block_height')
    else
      height=$($BINARY status --node="tcp://127.0.0.1:$PORT_RPC" 2>&1 | jq -r '.SyncInfo.latest_block_height // .sync_info.latest_block_height')
    fi

    echo -e "Current block height: $(printYellow "$height")"
    sleep 1
  done

  bash <(curl -s https://raw.githubusercontent.com/UnityNodes/scripts/main/${CHAIN,,}/upgrade/${VERSION}.sh)
  printBlue "Your node upgraded to version: $VERSION" && sleep 1
  $BINARY version --long | head

  ### Useful commands
  echo ""
  printLine
  printColor blue "Check your logs        >>> journalctl -u lavad -f --no-hostname -o cat "
  echo ""
  printColor blue "Check synchronization  >>> lavad status | jq | grep \"catching_up\" "
  echo ""
  printColor blue "Enjoy to Unity Nodes   >>> https://t.me/unitynodes "
  printLine
}

AutoUpgrade
