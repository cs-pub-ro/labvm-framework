#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Kernel cmdline customizations

# Blacklist floppy to prevent errors in dmesg
echo "blacklist floppy" > /etc/modprobe.d/blacklist-floppy.conf
update-initramfs -u

# Run the kernel-cmdline snippet to set defaults
vm_run_script "common-snippets.d/kernel-cmdline"

