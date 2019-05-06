#!/usr/bin/env bash

# Do installation of nodejs here

sudo bash -e <<SCRIPT
apt-get install -y curl
curl -sL https://deb.nodesource.com/setup_8.x | sudo bash -
apt-get install -y nodejs
SCRIPT
