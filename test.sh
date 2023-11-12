#!/bin/bash 


function logo() {
    bash <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)
}

function printGreen {
    echo -e "\e[1m\e[32m${1}\e[0m"
}

function printDelimiter {
  echo "==========================================="
}

function full() { 
printGreen "Оновлюємо сервер"
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install wget

printGreen "Встановлення node-exporter"
cd $HOME && \
wget https://github.com/prometheus/node_exporter/releases/download/v1.2.0/node_exporter-1.2.0.linux-amd64.tar.gz && \
tar xvf node_exporter-1.2.0.linux-amd64.tar.gz && \
rm node_exporter-1.2.0.linux-amd64.tar.gz && \
sudo mv node_exporter-1.2.0.linux-amd64 node_exporter && \
chmod +x $HOME/node_exporter/node_exporter && \
mv $HOME/node_exporter/node_exporter /usr/bin && \
rm -Rvf $HOME/node_exporter/

sudo tee /etc/systemd/system/exporterd.service > /dev/null <<EOF
[Unit]
Description=node_exporter
After=network-online.target
[Service]
User=$USER
ExecStart=/usr/bin/node_exporter
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload && \
sudo systemctl enable exporterd && \
sudo systemctl restart exporterd

printGreen "Встановлюємо Prometheus"
wget https://github.com/prometheus/prometheus/releases/download/v2.28.1/prometheus-2.28.1.linux-amd64.tar.gz && \
tar xvf prometheus-2.28.1.linux-amd64.tar.gz && \
rm prometheus-2.28.1.linux-amd64.tar.gz && \
mv prometheus-2.28.1.linux-amd64 prometheus

chmod +x $HOME/prometheus/prometheus
udo tee /etc/systemd/system/prometheusd.service > /dev/null <<EOF
[Unit]
Description=prometheus
After=network-online.target
[Service]
User=$USER
ExecStart=$HOME/prometheus/prometheus \
--config.file="$HOME/prometheus/prometheus.yml"
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

wget -O $HOME/prometheus/prometheus.yml https://raw.githubusercontent.com/asapov01/Install-Grafana/main/prometheus.yml && \

sudo systemctl daemon-reload && \
sudo systemctl enable prometheusd && \

printGreen "Встановлюємо Grafana"
sudo apt-get install -y adduser libfontconfig1 && \
wget https://dl.grafana.com/oss/release/grafana_8.0.6_amd64.deb && \
sudo dpkg -i grafana_8.0.6_amd64.deb

sudo systemctl daemon-reload && \
sudo systemctl enable grafana-server && \
echo ""
printGreen "Встановлено Node-Exporter, Prometheus, Grafana"
echo ""
printGreen "Додайте IP та впишіть назву сервера, для відображення серверів в Grafana"
read -p "Введіть IP: " ip
    read -p "Введіть назву для відображення в Grafana: " label

    echo "    - targets: ['$ip:9100']" >> prometheus.yml
    echo "      labels:" >> prometheus.yml
    echo "        label: \"$label\"" >> prometheus.yml

    while true; do
        read -p "Бажаєте додати ще сервер для моніторингу? [Y/N]: " yn
        case $yn in
            [Yy]* )
                read -p "Введіть IP: " ip
                read -p "Введіть назву для відображення в Grafana: " label

                echo "    - targets: ['$ip:9100']" >> prometheus.yml
                echo "      labels:" >> prometheus.yml
                echo "        label: \"$label\"" >> prometheus.yml;;
            [Nn]* ) break;;
            * ) echo "Будь ласка, введіть Y або N.";;
        esac
    done
printGreen "Тепер перейдіть до гайду, та створіть дашборд в Grafana"
}

function node_exporter() {
printGreen "Встановлюємо Node Exporter"
sudo apt-get update && sudo apt-get upgrade -y
cd $HOME && \
wget https://github.com/prometheus/node_exporter/releases/download/v1.2.0/node_exporter-1.2.0.linux-amd64.tar.gz && \
tar xvf node_exporter-1.2.0.linux-amd64.tar.gz && \
rm node_exporter-1.2.0.linux-amd64.tar.gz && \
sudo mv node_exporter-1.2.0.linux-amd64 node_exporter && \
chmod +x $HOME/node_exporter/node_exporter && \
mv $HOME/node_exporter/node_exporter /usr/bin && \
rm -Rvf $HOME/node_exporter/

sudo tee /etc/systemd/system/exporterd.service > /dev/null <<EOF
[Unit]
Description=node_exporter
After=network-online.target
[Service]
User=$USER
ExecStart=/usr/bin/node_exporter
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload && \
sudo systemctl enable exporterd && \
sudo systemctl restart exporterd

echo ""
printDelimiter
echo "Перевірити журнал логів node exporter - sudo journalctl -u exporterd -f"
printDelimiter
}

clear
logo
printGreen "Оберіть,що саме ви плануєте встановити на ваш сервер:"
echo "[1] Node exporter + Prometheus + Grafana"
echo "[2] Node exporter"
echo ""
read -p "$(echo 'Ваш вибір: ')" answer

if [ "$answer" = "1" ]; then
  full
elif [ "$answer" = "2" ]; then
  node_exporter
fi
