#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# Creates a master SSH authorized_keys and populates it with user provided keys.
#
# May be used on multiple layers (public keys are normalized, as you can see).
# The VM_AUTHORIZED_KEYS environment var. is passed by default with the generic 
# packer provisioning script.
#
# No other dependencies.

SSH_MASTER_AUTHKEYS=/etc/ssh/authorized_keys

SRC=$(sh_get_script_path)
_SSH_AUTHKEYS_FROM="$VM_AUTHORIZED_KEYS"

sh_log_debug "ssh-authorized-keys: VM_AUTHORIZED_KEYS=$VM_AUTHORIZED_KEYS"
if [[ -n "$VM_AUTHORIZED_KEYS" ]]; then
	[[ -f "$_SSH_AUTHKEYS_FROM" ]] || _SSH_AUTHKEYS_FROM="$SRC/$VM_AUTHORIZED_KEYS"
	[[ -f "$_SSH_AUTHKEYS_FROM" ]] || _SSH_AUTHKEYS_FROM="/opt/vm-scripts/$VM_AUTHORIZED_KEYS"
fi

if [[ -n "$_SSH_AUTHKEYS_FROM" && -f "$_SSH_AUTHKEYS_FROM" ]]; then
	cat "$_SSH_AUTHKEYS_FROM" >> "$SSH_MASTER_AUTHKEYS"
	sh_log_info "ssh-authorized-keys: installed from '$_SSH_AUTHKEYS_FROM'"
	# sanitize + anonymize keys (remove comments etc.)
	sed '/^\s\+$/d; /^#/d;
		s/^\(\S\+\)\s\+\(\S\+\).*$/\1 \2/' "$SSH_MASTER_AUTHKEYS" > "$SSH_MASTER_AUTHKEYS.new"
	sort < "$SSH_MASTER_AUTHKEYS.new" | uniq > "$SSH_MASTER_AUTHKEYS"
else
	sh_log_info "ssh-authorized-keys: no VM_AUTHORIZED_KEYS present! skipping..."
fi

if [[ -f "$SSH_MASTER_AUTHKEYS" ]]; then
	chown root:root "$SSH_MASTER_AUTHKEYS"
	chmod 644 "$SSH_MASTER_AUTHKEYS"

	cat <<EOF >"/etc/ssh/sshd_config.d/10-authorized.conf"
AuthorizedKeysFile .ssh/authorized_keys $SSH_MASTER_AUTHKEYS
EOF
	systemctl reload ssh
	sh_log_info "ssh-authorized-keys: master keys configured!"
fi

