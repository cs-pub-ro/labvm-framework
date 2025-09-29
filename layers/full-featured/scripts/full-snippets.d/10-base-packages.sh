#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Installs some base packages (useful within scripts and debugging)

pkg_install --no-install-recommends \
	apt-transport-https ca-certificates gnupg lsb-release \
	curl wget git unrar unzip lzma xz-utils moreutils expect lsof jq \
	vim less rsync moreutils

if lsb_release -d | grep -i Ubuntu &>/dev/null; then
	pkg_install --no-install-recommends software-properties-common 
	VM_IS_UBUNTU=1
fi

