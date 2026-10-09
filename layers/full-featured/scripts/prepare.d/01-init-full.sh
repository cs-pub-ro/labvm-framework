#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Fully featured install initialization script

@import "systemd"

# prepare package manager
@import 'debian/packages.sh'
pkg_init_update

# configure DPKG to keep our config files (for pre-configured services)
cat << EOF > /etc/apt/apt.conf.d/30keep-provisioned-configs
Dpkg::Options {
	"--force-confdef";
	"--force-confold";
}
EOF

## Configuration variables (override them inside env or add a next script, 
## e.g. 02-overrides.sh)

# Default user
VM_USER=${VM_USER:-$(getent passwd 1000 | cut -d: -f1)}

# VM Features (set to 0/empty to disable)
# Check the individual install scripts for details
VM_LEGACY_IFNAMES=${VM_LEGACY_IFNAMES:-1}
VM_SYSTEM_TWEAKS=${VM_SYSTEM_TWEAKS:-1}
VM_INSTALL_TERM_TOOLS=${VM_INSTALL_TERM_TOOLS:-1}
VM_INSTALL_NET_TOOLS=${VM_INSTALL_NET_TOOLS:-1}
VM_INSTALL_DEV_TOOLS=${VM_INSTALL_DEV_TOOLS:-1}
VM_INSTALL_HACKING_TOOLS=${VM_INSTALL_HACKING_TOOLS:-1}
VM_INSTALL_DOCKER=${VM_INSTALL_DOCKER:-1}
VM_USER_TWEAKS=${VM_USER_TWEAKS:-1}
VM_USER_BASH_CONFIGS=${VM_USER_BASH_CONFIGS:-1}
VM_USER_ZSH_CONFIGS=${VM_USER_ZSH_CONFIGS:-0}

# source VM config environment
if [[ -f "/etc/vm-config/env.sh" ]]; then
	source "/etc/vm-config/env.sh"
fi

systemd_wait_for_boot

