#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Fully featured install initialization script

@import "systemd"

# prepare package manager
@import 'debian/packages.sh'
pkg_init_update

# Default user
VM_USER=${VM_USER:-$(getent passwd 1000 | cut -d: -f1)}

# source VM config environment
if [[ -f "/etc/vm-config/env.sh" ]]; then
	source "/etc/vm-config/env.sh"
fi

systemd_wait_for_boot

