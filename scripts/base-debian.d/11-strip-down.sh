#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Strips down the Ubuntu distribution / disk size reduction tweaks

# delete swap file
swapoff -a
sed -i '/^\/swap.img/d' /etc/fstab
rm -f /swap.img

# remove linux-firmware and the generic kernel
apt-get -y purge -qq linux-generic linux-firmware || true
# remove some unnecessary packages
apt-get -y purge -qq snapd ufw apport ubuntu-advantage-tools || true

