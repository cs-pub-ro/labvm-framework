#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Installs / upgrades base packages

# always build up-to-date base VM image
pkg_upgrade_all

pkg_install wget curl jq rsync

