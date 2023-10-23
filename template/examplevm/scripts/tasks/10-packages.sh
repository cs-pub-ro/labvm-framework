#!/bin/bash
# VM install initialization
[[ "$INSIDE_INSTALL_SCRIPT" == "1" ]] || { echo "Direct calls not supported!">&2; exit 5; }

# install some base dependencies
apt-get install --no-install-recommends -y \
	apt-transport-https ca-certificates curl wget software-properties-common \
	git unzip zsh vim

if [[ -n "$FULL_UPGRADE" ]]; then
	apt-get dist-upgrade -y
fi

