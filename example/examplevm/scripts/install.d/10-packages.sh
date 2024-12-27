#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# VM install initialization

# install some base dependencies
apt-get install --no-install-recommends -y \
	apt-transport-https ca-certificates curl wget software-properties-common \
	git unzip zsh vim

if [[ -n "$FULL_UPGRADE" ]]; then
	apt-get dist-upgrade -y
fi

