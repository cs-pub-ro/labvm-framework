#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Installs / upgrades cloud specific packages

pkg_install cloud-init cloud-utils cloud-initramfs-growroot

