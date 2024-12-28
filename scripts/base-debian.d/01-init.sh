#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Base image initialization script

# prepare package manager
@import 'debian/packages.sh'
pkg_init_update

# disable APT auto updates
cat << EOF > /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "0";
EOF

# disable TTY requirement for sudo
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

