#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Installs some base packages (useful within scripts and debugging)

pkg_install --no-install-recommends \
	apt-transport-https software-properties-common ca-certificates gnupg \
	curl wget git unrar unzip lzma xz-utils moreutils expect lsof jq \
	vim less rsync moreutils

