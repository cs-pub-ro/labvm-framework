#!/bin/sh
# Base provisioning script

set -e
export DEBIAN_FRONTEND=noninteractive

# remove some useless packages like snapd and ubuntu scripts
apt-get -y purge -qq linux-generic linux-firmware || true
apt-get -y purge -qq snapd ufw apport ubuntu-advantage-tools || true

apt-get -y -qq update
apt-get -y -qq upgrade

apt-get -y install wget curl

sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

# delete swap file
swapoff -a
sed -i '/^\/swap.img/d' /etc/fstab
rm -f /swap.img

# disable auto updates
cat << EOF > /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "0";
EOF

if grep "^UseDNS yes" /etc/ssh/sshd_config; then
	sed "s/^UseDNS yes/UseDNS no/" /etc/ssh/sshd_config > /tmp/sshd_config
	mv /tmp/sshd_config /etc/ssh/sshd_config
else
	echo "UseDNS no" >> /etc/ssh/sshd_config
fi

