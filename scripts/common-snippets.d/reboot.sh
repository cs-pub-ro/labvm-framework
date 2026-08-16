#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# Use as the last script (e.g., 90-*) in stage 1 to gracefully reboot the VM.
#
# No other dependencies.

sh_log_info "Rebooting the system..."

# find the sshd systemd unit name
ssh_unit=$(systemctl list-unit-files --no-legend --no-pager \
	| awk '$1=="sshd.service"{print $1; exit} $1=="ssh.service"{print $1; exit}')
systemctl stop "$ssh_unit"

nohup shutdown -r now </dev/null >/dev/null 2>&1 &
sleep 3
exit 0

