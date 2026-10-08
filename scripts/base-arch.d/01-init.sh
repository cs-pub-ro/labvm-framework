#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Base image initialization script

# prepare package manager
@import 'arch/packages.sh'
pkg_init_update

# disable TTY requirement for sudo
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
