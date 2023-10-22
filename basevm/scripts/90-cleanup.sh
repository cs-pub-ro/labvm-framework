#!/bin/sh
# Base VM cleanup script

set -e
export DEBIAN_FRONTEND=noninteractive

apt-get -y autoremove
apt-get -y clean

df -h

