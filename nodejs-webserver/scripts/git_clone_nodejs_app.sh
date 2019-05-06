#!/usr/bin/env bash



# git clone nodejs app
git clone https://github.com/dhpizza/nodejs-demo-app.git /home/ubuntu/sample-node-app/
# go to install dir and install packages
cd /home/ubuntu/sample-node-app/
npm install
sudo bash -ex <<SCRIPT
# move system d file to
cp -p /home/ubuntu/sample-node-app/contrib/hello.service /etc/systemd/system/hello.service
#enable sytsem unit file
systemctl enable hello.service
SCRIPT
