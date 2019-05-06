#!/usr/bin/env bash

# git clone nodejs app
git clone https://github.com/dhpizza/nodejs-demo-app.git
# go to install dir and install packages
cd nodejs-demo-app
npm install
# move system d file to
mv -v contrib/hello.service /etc/systemd/system/hello.service
#enable sytsem unit file
sudo systemctl enable hello.service
