#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Applies GRUB / bootloader tweaks for virtual environments

# Blacklist floppy to prevent errors in dmesg
echo "blacklist floppy" > /etc/modprobe.d/blacklist-floppy.conf
update-initramfs -u

# Custom kernel cmdline with tweaks:
# console: also enable on first serial TTY
# no_timer_check: prevent kernel from probing for hardware timers
# edd=off: disable BIOS Enhanced Disk Drive Services (may cause problems on
#          some hypervisors)
GRUB_CMDLINE_VIRT="console=tty0 console=ttyS0,115200n8 no_timer_check edd=off"
sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"$GRUB_CMDLINE_VIRT\"/g" /etc/default/grub
update-grub

