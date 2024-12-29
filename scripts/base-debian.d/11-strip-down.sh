#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Strips down the Ubuntu distribution / disk size reduction tweaks

# delete swap file
swapoff -a
sed -i '/^\/swap.img/d' /etc/fstab
rm -f /swap.img

# Note: if autoinstall kernel flavor is set to 'kvm' or 'virtual', these modules 
# won't bother us anymore!
# https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1960633
#pkg_install --no-install-recommends linux-image-virtual
#pkg_remove --purge linux-generic linux-firmware intel-microcode amd64-microcode || true

# remove some unnecessary packages
pkg_remove --purge snapd ufw apport ubuntu-advantage-tools || true

