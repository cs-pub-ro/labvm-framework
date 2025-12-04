#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Cloud VM preparation script.
## Called to dynamically select / enable the scripts to use for provisioning.

SRC=$(sh_get_script_path)

if [[ -n "$VM_CLOUD_TESTING" ]]; then
	# disable (remove) all scripts during `cloud_test` goal
	rm -f "$SRC/install-cloud.d/"*.sh
fi

# Alternative way of enabling snippets (not preferred as makes task ordering
# difficult to understand)
#ln -sf "$SRC/common-snippets.d/ssh-authorized-keys.sh" "$SRC/install-cloud.d/32-ssh-authorized-keys.sh"

