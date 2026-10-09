#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Basic terminal tools

[[ "$VM_INSTALL_TERM_TOOLS" == "1" ]] || { sh_log_info " > Skipped!"; return 0; }

pkg_install --no-install-recommends \
	tree tmux vim-nox nano bash-completion zsh less zip git lsof \
	unrar p7zip moreutils expect mc htop iotop sysstat

