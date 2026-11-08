#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# VM install initialization

sh_log_info "Test environment vars:"
sh_log_info "VM_EXAMPLE=$VM_EXAMPLE"
sh_log_info "VM_TEST=$VM_TEST"

# install some base dependencies
pkg_install --no-install-recommends \
	apt-transport-https ca-certificates curl wget git unzip zsh vim

if [[ -n "$VM_FULL_UPGRADE" ]]; then
	pkg_upgrade_all
fi

