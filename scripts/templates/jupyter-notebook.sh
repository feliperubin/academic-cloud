#!/bin/bash
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Simple Jupyter-Notebook Installer
DEFAULT_USER=$(ls /home | head -n 1)
# Set the default workstation as a folder int he users' home directory
# Create the directory if it does not exist
JUPYTER_WORKSPACE="/home/$DEFAULT_USER/jupyter"
if [ ! -d "$JUPYTER_WORKSPACE" ]; then mkdir -p "$JUPYTER_WORKSPACE"; fi

# Install Jupyter along with some common libraries
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-dev

sudo pip3 install --upgrade pip

# Install pandas (without SSL)
sudo -H pip3 install --trusted-host pypi.org --trusted-host files.pythonhosted.org pandas
sudo -H pip3 install -vU setuptools
sudo -H pip3 install numpy
sudo -H pip3 install matplotlib
sudo -H pip3 install jupyter

# Check sysvinit with: pidogg /sbin/init
cat > /etc/systemd/system/jupyter.service <<EOF
[Unit]
Description=Jupyter-Notebook
[Service]
Environment=PATH="$JUPYTER_WORKSPACE"
Type=simple
PIDFile=/run/jupyter.pid
ExecStart=/usr/local/bin/jupyter-notebook \
--ip=0.0.0.0 --port=80 \
--allow-root --no-browser --NotebookApp.token='' --NotebookApp.password=''
User=root
Group=root
Restart=always
RestartSec=10
# there's probably a better way to do this part

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable jupyter
sudo systemctl daemon-reload
sudo systemctl start jupyter
exit 0
