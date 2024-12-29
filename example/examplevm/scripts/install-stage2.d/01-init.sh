#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# VM install initialization

# prepare package manager
@import 'debian/packages.sh'
pkg_init_update

VM_FULL_UPGRADE=${VM_FULL_UPGRADE:-1}

