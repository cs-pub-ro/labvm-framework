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

# disable ssh password authentication
rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf
sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication no/g" /etc/ssh/sshd_config

# update grub to replace kernel cmdline
GRUB_CMDLINE_VIRT="modprobe.blacklist=floppy console=ttyS0,115200n8 no_timer_check edd=off"
sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"$GRUB_CMDLINE_VIRT\"/g" /etc/default/grub
update-grub

# Cleanup the system
apt-get -y autoremove
apt-get -y clean
rm -rf /home/student/install*
cloud-init clean --logs --machine-id

