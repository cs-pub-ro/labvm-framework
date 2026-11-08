#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# OpenStack had no Console ACL for shared projects, so children/students 
# will troll each other when (not if) they find out
# This contains several workarounds (prevent ctrl-alt-del, mainly).

if [[ -n "$VM_CONSOLE_SECURITY" ]]; then
	# disable reboot from OpenStack's console CtrlAltDel btn
	systemctl mask "ctrl-alt-del.target"
	# also disable force reboot on burst presses
	sed -i -E 's/^#?CtrlAltDelBurstAction=.*/CtrlAltDelBurstAction=none/' /etc/systemd/system.conf
fi
