#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Upgrades the provided noVNC

# Install it on control1
pushd /tmp
LINK="https://github.com/novnc/noVNC/archive/v1.1.0.tar.gz"
MAX_TRIES=3
promdl=$(wget -L "$LINK" -O v1.1.0.tar.gz)
while [ "$?" -ne "0" ] && [ "$MAX_TRIES" -gt 0 ]; do
  echo "Download Failed, retrying..."
  sleep 1
  promdl=$(wget -L "$LINK")
  MAX_TRIES=$(($MAX_TRIES-1))
done
# /usr/share/pyshared/horizon/dashboards/nova/instances/templates/instances/_detail_vnc.html
tar xfz v1.1.0.tar.gz
rm -rf /usr/share/novnc
mv /tmp/noVNC-1.1.0 /usr/share/novnc
mv /usr/share/novnc/vnc_lite.html /usr/share/novnc/vnc_auto.html
# service nova-compute restart
systemctl restart nova-novncproxy
service apache2 restart
popd
touch /.novnc.upgrade.stamp
