#!/bin/bash

### Utils Unity Nodes
source <(curl -s https://raw.githubusercontent.com/UnityNodes/scripts/main/utils.sh)

clear
printLogo() {
    logo="

     __  __            _    __                     _   __              __              
    / / / /   ____    (_)  / /_   __  __          / | / /  ____   ____/ /  ___    _____
   / / / /   / __ \  / /  / __/  / / / /         /  |/ /  / __ \ / __  /  / _ \  / ___/
  / /_/ /   / / / / / /  / /_   / /_/ /         / /|  /  / /_/ // /_/ /  /  __/ (__  ) 
  \____/   /_/ /_/ /_/   \__/   \__, /         /_/ |_/   \____/ \__,_/   \___/ /____/  
                               /____/                                                  

"

    # Выводим логотип с задержкой 0.05 секунды между строками
    IFS=$'\n'
    for line in $logo; do
        echo "$line"
        sleep 0.067
    done
}

printLogo
echo "_______________________________________________________________________________________"



echo ""
echo -e "\e[30;47m Please enter the node moniker:\e[0m"
echo -en ">>> "
read -r NODE_MONIKER



### Chain ID, Binary Version Node
CHAIN_ID="lava-testnet-2"
BINARY_VERSION="v1.2.0"

### Install Dependencies
source <(curl -s https://raw.githubusercontent.com/UnityNodes/scripts/main/dependencies.sh)

### Bulding binaries
echo ""
printColor blue "[4/6] Building binaries"

export LAVA_BINARY=lavad

cd || return
rm -rf lava
git clone https://github.com/lavanet/lava
cd lava || return
git checkout v1.2.0
make install

make build

lavad config keyring-backend test
lavad config chain-id $CHAIN_ID
lavad init "$NODE_MONIKER" --chain-id $CHAIN_ID

### Seed and peers
SEEDS="3a445bfdbe2d0c8ee82461633aa3af31bc2b4dc0@testnet2-seed-node.lavanet.xyz:26656,e593c7a9ca61f5616119d6beb5bd8ef5dd28d62d@testnet2-seed-node2.lavanet.xyz:26656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.lava/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.lava/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.lava/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.lava/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.lava/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.025ulava"|g' $HOME/.lava/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.lava/config/config.toml

sed -i \
  -e 's/timeout_commit = ".*"/timeout_commit = "30s"/g' \
  -e 's/timeout_propose = ".*"/timeout_propose = "1s"/g' \
  -e 's/timeout_precommit = ".*"/timeout_precommit = "1s"/g' \
  -e 's/timeout_precommit_delta = ".*"/timeout_precommit_delta = "500ms"/g' \
  -e 's/timeout_prevote = ".*"/timeout_prevote = "1s"/g' \
  -e 's/timeout_prevote_delta = ".*"/timeout_prevote_delta = "500ms"/g' \
  -e 's/timeout_propose_delta = ".*"/timeout_propose_delta = "500ms"/g' \
  -e 's/skip_timeout_commit = ".*"/skip_timeout_commit = false/g' \
  -e 's/seeds = ".*"/seeds = "3a445bfdbe2d0c8ee82461633aa3af31bc2b4dc0@testnet2-seed-node.lavanet.xyz:26656,e593c7a9ca61f5616119d6beb5bd8ef5dd28d62d@testnet2-seed-node2.lavanet.xyz:26656"/g' \
  $HOME/.lava/config/config.toml

sed -i -e 's/broadcast-mode = ".*"/broadcast-mode = "sync"/g' $HOME/.lava/config/config.toml

### Downoload genesis and addrbook
curl -s https://raw.githubusercontent.com/lavanet/lava-config/main/testnet-2/genesis_json/genesis.json -o $HOME/.lava/config/genesis.json
curl -Ls https://snapshots.aknodes.net/snapshots/lava/addrbook.json -o $HOME/.lava/config/addrbook.json

### Create service
sudo tee /etc/systemd/system/lavad.service > /dev/null << EOF
[Unit]
Description=Lava Network Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which lavad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

### Downoload snapshot
echo ""
printColor blue "[5/6] Downloading snapshot for fast synchronization" 

lavad tendermint unsafe-reset-all --home $HOME/.lava --keep-addr-book 
curl https://snapshots.aknodes.net/snapshots/lava/snapshot-lava.AKNodes.lz4 | lz4 -dc - | tar -xf - -C $HOME/.lava

### Start service and run node
echo ""
printColor blue "[6/6] Start service and run node"

sudo systemctl daemon-reload
sudo systemctl enable lavad
sudo systemctl start lavad

### Useful commands
echo ""
printLine
printColor blue "Check your logs        >>> journalctl -u lavad -f --no-hostname -o cat "
echo ""
printColor blue "Check synchronization  >>> lavad status | jq | grep \"catching_up\" "
echo ""
printColor blue "Enjoy to Unity Nodes   >>> https://t.me/unitynodes "
printLine
