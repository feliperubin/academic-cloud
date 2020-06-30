#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Installs Loki Log Aggregator


# Ignore user already existing

FILE="$1"
reject_old_samples="false"
set +e
sudo useradd --no-create-home --shell /usr/sbin/nologin loki
sudo mkdir /etc/loki && sudo chown loki:loki /etc/loki
set -e

sudo apt-get update
sudo apt-get install -y zip
if [ "$FILE" == "" ]; then
# Workaround on the failed to resolv
LINK="https://github.com/grafana/loki/releases/download/v1.5.0/loki-linux-amd64.zip"
MAX_TRIES=3
promdl=$(wget -L "$LINK")
while [ "$?" -ne "0" ] && [ "$MAX_TRIES" -gt 0 ]; do
  echo "Download Failed, retrying..."
  sleep 1
  promdl=$(wget -L "$LINK")
  MAX_TRIES=$(($MAX_TRIES-1))
done
FILE="loki-linux-amd64.zip"
fi

unzip "$FILE"
rm "$FILE"
chmod a+x "loki-linux-amd64"
mv loki-linux-amd64 /usr/local/bin/loki
sudo chown loki:loki /usr/local/bin/loki

cat > /etc/loki/loki.yaml << EOF
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    address: 0.0.0.0
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s
  max_transfer_retries: 0

schema_config:
  configs:
    - from: 2018-04-15
      store: boltdb
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 168h

storage_config:
  boltdb:
    directory: /etc/loki/index

  filesystem:
    directory: /etc/loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: $reject_old_samples
  reject_old_samples_max_age: 168h

chunk_store_config:
  max_look_back_period: 0s

EOF
# limits_config:
#   enforce_metric_name: false
#   reject_old_samples: true
#   reject_old_samples_max_age: 168h

sudo chown -R loki:loki /etc/loki

cat > /etc/systemd/system/loki.service << EOF
[Unit]
Description=Loki Logging Aggregation
Wants=network-online.target
After=network-online.target

[Service]
User=loki
Group=loki
Type=simple
ExecStart=/usr/local/bin/loki \
-config.file=/etc/loki/loki.yaml
ExecReload=/bin/kill -HUP \$MAINPID
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable loki
sudo systemctl start loki
echo 'Loki Started on port 3100, config file /etc/loki/loki.yaml'
touch /.loki.stamp
