#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Installs Promtail Log agent for Loki


LOKI_IP="$1"
FILE="$2"
HNAME="$(echo $HOSTNAME)"
sudo apt-get install -y zip
if [ "$FILE" == "" ]; then

# Workaround on the failed to resolv
LINK="https://github.com/grafana/loki/releases/download/v1.5.0/promtail-linux-amd64.zip"
MAX_TRIES=3
promdl=$(wget -L "$LINK")
while [ "$?" -ne "0" ] && [ "$MAX_TRIES" -gt 0 ]; do
  echo "Download Failed, retrying..."
  sleep 1
  promdl=$(wget -L "$LINK")  
  MAX_TRIES=$(($MAX_TRIES-1))
done
FILE="$PWD/promtail-linux-amd64.zip"
fi

unzip "$FILE"
rm -rf      "$FILE"
mv promtail-* /usr/local/bin/promtail
chmod a+x /usr/local/bin/promtail


# Configuration
if [ ! -d /etc/promtail ]; then
	mkdir /etc/promtail
fi

cat > /etc/promtail/promtail.yaml << EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0
clients:
  - url: http://$LOKI_IP:3100/loki/api/v1/push
positions:
  filename: /var/log/positions.yaml
scrape_configs:
    - job_name: system
      pipeline_stages:
      static_configs:
      - targets:
         - localhost
        labels:
         job: varlogs
         host: "$HNAME"
         agent: promtail
         __path__: /var/log/**/*.log
    - job_name: journal
      journal:
        max_age: 12h
        labels:
          job: systemd-journal
      relabel_configs:
        - source_labels: ['__journal__systemd_unit']
          target_label: 'unit'
EOF

cat > /etc/systemd/system/promtail.service << EOF
[Unit]
Description=Promtail Loki Agent

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/promtail \
-config.file=/etc/promtail/promtail.yaml
Restart=always
RestartSec=10
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable promtail
sudo systemctl start promtail
echo 'Promtail port 9080, config /etc/promtail/promtail.yaml'
touch /.promtail.stamp
