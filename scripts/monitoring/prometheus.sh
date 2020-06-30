#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Installs and configures prometheus to listen to targets

while [ $# -gt 0 ]; do
  case "$1" in
    --time) shift; COLLECTD_TIME="$1"; shift;;
    --targets) shift; COLLECTD_TARGETS="$1"; shift;;
    --append) shift; COLLECTD_APPEND="$1"; shift;;
    --remove) shift; COLLECTD_REMOVE="$1"; shift;;
    *) echo "Unknown Parameter $1, exiting..."; exit 1;;
  esac
done

if [ -z "$COLLECTD_TIME" ]; then COLLECTD_TIME="60s";fi
if [ -z "$COLLECTD_TARGETS" ]; then echo "No Targets specified, exiting...";exit 1;fi


# put the list in the correct format
TARGET_LIST=""
IFS=','
for i in $COLLECTD_TARGETS; do
  TARGET_LIST="$TARGET_LIST,'$i'"
done

# Remove first comma ','
TARGET_LIST="$(echo "$TARGET_LIST" | cut -c 2-)"
TARGET_LIST="$TARGET_LIST'"
# Ignore user already existing
set +e
sudo useradd --no-create-home --shell /usr/sbin/nologin prometheus
sudo mkdir /etc/prometheus && sudo chown prometheus:prometheus /etc/prometheus
sudo mkdir /var/lib/prometheus && sudo chown prometheus:prometheus /var/lib/prometheus
set -e

# # Workaround on the failed to resolv
# LINK="https://github.com/prometheus/prometheus/releases/download/v2.2.1/prometheus-2.2.1.linux-amd64.tar.gz"
LINK="https://github.com/prometheus/prometheus/releases/download/v2.18.1/prometheus-2.18.1.linux-amd64.tar.gz"
MAX_TRIES=3
promdl=$(wget -Lnc "$LINK")
while [ "$?" -ne "0" ] && [ "$MAX_TRIES" -gt 0 ]; do
  echo "Download Failed, retrying..."
  sleep 1
  promdl=$(wget -Lnc "$LINK")
  MAX_TRIES=$(($MAX_TRIES-1))
done


tar xfz prometheus-*.tar.gz

sudo cp prometheus-*/prometheus /usr/local/bin/
sudo cp prometheus-*/promtool  /usr/local/bin/
sudo cp -r prometheus-*/consoles /etc/prometheus
sudo cp -r prometheus-*/console_libraries /etc/prometheus

sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries

sudo rm -rf prometheus*

cat > /etc/prometheus/prometheus.yaml << EOF
global:
  scrape_interval:     $COLLECTD_TIME
  evaluation_interval: $COLLECTD_TIME

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
 
  - job_name: 'collectd'
    static_configs:
      - targets: [$TARGET_LIST]
EOF

sudo chown prometheus:prometheus /etc/prometheus/prometheus.yaml

cat > /etc/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus Monitoring
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
--config.file /etc/prometheus/prometheus.yaml \
--storage.tsdb.path /var/lib/prometheus/ \
--web.console.templates=/etc/prometheus/consoles \
--web.console.libraries=/etc/prometheus/console_libraries
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

echo 'Prometheus port 9090, config /etc/prometheus/prometheus.yaml'

touch /.prometheus.stamp



# cat prometheus.yaml | awk 'x==2 {print $3}/collectd/,/targets/'
# JOB_NAME="collectd"
# cat prometheus.yaml | awk 'x==1 {print $3}/job_name/ {x=1}' | 

# Section corresponding to job_name 
# JOB_SECTION=$(cat prometheus.yaml | awk "/$JOB_NAME/,/targets/")












