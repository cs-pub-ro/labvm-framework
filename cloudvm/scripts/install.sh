#!/bin/bash
# Install script for cloud-init
# Everything should run as root
set -e
#set -x

export SRC="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

echo "Waiting for the VM to fully boot..."
while [ "$(systemctl is-system-running 2>/dev/null)" != "running" ] && \
	[ "$(systemctl is-system-running 2>/dev/null)" != "degraded" ]; do sleep 2; done

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y cloud-init cloud-utils cloud-initramfs-growroot
# copy the cloud-init config
rsync -ai --chown="root:root" "$SRC/etc/" "/etc/"

rm -f /etc/cloud/cloud.cfg.d/99-installer.cfg

# disable ssh password login
sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication no/g" /etc/ssh/sshd_config

# Cleanup the system
rm -rf /home/student/install*

