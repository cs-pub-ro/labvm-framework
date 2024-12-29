#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# Modifies/replaces the kernel cmdline (in grub)
#
# No other dependencies.

# Default kernel cmdline with virtualization tweaks:
# console: also enable on first serial TTY
# no_timer_check: prevent kernel from probing for hardware timers
# edd=off: disable BIOS Enhanced Disk Drive Services (may cause problems on
#          some hypervisors)
KERNEL_CMDLINE_DEFAULT="console=tty0 console=ttyS0,115200n8 no_timer_check edd=off"

# compose new cmdline
KERNEL_CMDLINE_APPEND=${KERNEL_CMDLINE_APPEND:-}
KERNEL_CMDLINE_PREPEND=${KERNEL_CMDLINE_PREPEND:-}
KERNEL_CMDLINE_REPLACE=${KERNEL_CMDLINE_REPLACE:-$KERNEL_CMDLINE_DEFAULT}

_KERNEL_CMDLINE="${KERNEL_CMDLINE_PREPEND}${KERNEL_CMDLINE_REPLACE}${KERNEL_CMDLINE_APPEND}"

sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT='$_KERNEL_CMDLINE'|g" /etc/default/grub
update-grub

