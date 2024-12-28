#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Cloud install initialization script

@import "systemd"

# prepare package manager
export DEBIAN_FRONTEND=noninteractive
apt-get -y -qq update

## Configuration variables (override them inside env or add a next script, 
## e.g. 02-overrides.sh)

# Default user
VM_USER=${VM_USER:-$(getent passwd 1000 | cut -d: -f1)}
# Enable legacy ssh-rsa public key algorithms
VM_SSH_LEGACY_ALGS=${VM_SSH_LEGACY_ALGS:-0}
# Set a hardcoded root + main user passwords
VM_PASSWORD=${VM_PASSWORD:-}
# Disable SSH password auth (defaults to 1 if VM_PASSWORD is not set, 0 otherwise)
VM_SSH_PASSWORD_AUTH=${VM_SSH_PASSWORD_AUTH:-}

# source VM config environment
if [[ -f "/etc/vm-config/env.sh" ]]; then
	source "/etc/vm-config/env.sh"
fi

systemd_wait_for_boot

