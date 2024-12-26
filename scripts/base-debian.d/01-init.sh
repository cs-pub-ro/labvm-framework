#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Base install initialization script

# disable APT auto updates
cat << EOF > /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "0";
EOF

# prepare package manager
export DEBIAN_FRONTEND=noninteractive
apt-get -y -qq upgrade

# disable TTY requirement for sudo
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

