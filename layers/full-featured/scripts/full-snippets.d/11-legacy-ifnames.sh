#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# Configures the kernel for legacy interface names (e.g., eth0)
# This is recommended for better portability among other hypervisors (VMware,
# VirtualBox, Qemu etc.)

[[ "$VM_LEGACY_IFNAMES" == "1" ]] || { sh_log_info " > Skipped!"; return 0; }

# append to previous cmdline (if any)
KERNEL_CMDLINE_APPEND=${KERNEL_CMDLINE_APPEND:-}
KERNEL_CMDLINE_APPEND+=" net.ifnames=0 biosdevname=0"

# use a standard interfaces with eth0
if [[ -f /etc/network/interfaces ]]; then
	cat << EOF > "/etc/network/interfaces"
# interfaces(5) file used by ifup(8) and ifdown(8)
auto lo

auto eth0
iface eth0 inet dhcp

# Include files from /etc/network/interfaces.d:
source /etc/network/interfaces.d/*
EOF
fi

# modify Ubuntu's netplan configuration (if used) for eth0
NETPLAN_CONFIG="/etc/netplan/50-cloud-init.yaml"
if [[ -f "$NETPLAN_CONFIG" ]]; then
	cat << EOF > "$NETPLAN_CONFIG"
network:
  ethernets:
    eth0:
      dhcp4: true
    version: 2
EOF
fi

# bootloader will be configured in 19-kernel-cmdline

