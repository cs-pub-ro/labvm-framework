#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# Use as the last script (e.g., 90-*) in stage 1 to gracefully reboot the VM.
#
# No other dependencies.

sh_log_info "Rebooting the system..."

systemctl stop sshd.service
nohup shutdown -r now </dev/null >/dev/null 2>&1 &
sleep 3
exit 0

