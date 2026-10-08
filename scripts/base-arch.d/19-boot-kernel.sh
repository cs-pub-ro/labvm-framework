#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Kernel cmdline customizations

# Blacklist floppy to prevent errors in dmesg
echo "blacklist floppy" > /etc/modprobe.d/blacklist-floppy.conf

# update-grub compatibility shim (common snippets use the Debian naming)
if ! command -v update-grub >/dev/null; then
	cat << EOF > /usr/local/bin/update-grub
#!/bin/bash
grub-mkconfig -o /boot/grub/grub.cfg
EOF
	chmod 0755 /usr/local/bin/update-grub
fi

# Run the kernel-cmdline snippet to set defaults
vm_run_script "common-snippets.d/kernel-cmdline"
