#!/usr/bin/env bash
set -e

# Install some base packages useful on all machines
sudo bash -e <<SCRIPT
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
#apt-get -yq purge lxcfs unattended-upgrades
#apt-get upgrade -y
#apt-get install -y awscli jq unzip nano curl bash-completion apt-transport-https
#apt-get -yq autoremove snapd


locale-gen de_DE.UTF-8
SCRIPT
