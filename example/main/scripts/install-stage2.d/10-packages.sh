#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# VM install initialization

# install some base dependencies
pkg_install --no-install-recommends \
	apt-transport-https ca-certificates curl wget software-properties-common \
	git unzip zsh vim

if [[ -n "$VM_FULL_UPGRADE" ]]; then
	pkg_upgrade_all
fi

