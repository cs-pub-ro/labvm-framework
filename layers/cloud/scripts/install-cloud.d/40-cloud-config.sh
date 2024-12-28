#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Installs / upgrades cloud specific packages

SRC=$(sh_get_script_path)

# delete previous cloud-init generated files
rm -f /etc/cloud/cloud.cfg.d/99-installer.cfg
rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf
rm -f /etc/cloud/cloud-init.disabled
rm -f /etc/cloud/cloud.cfg.d/50-curtin-networking.cfg \
	/etc/cloud/cloud.cfg.d/curtin-preserve-sources.cfg \
	/etc/cloud/cloud.cfg.d/99-installer.cfg \
	/etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
rm -f /etc/cloud/ds-identify.cfg
rm -f /etc/netplan/50-cloud-init.yaml

# copy our custom cloud-init config
rsync -ai --chown="root:root" --exclude "*.tpl" \
	"$SRC/etc/" "/etc/"

# interpolate user inside cloud.cfg
sh_interpolate_vars "$(cat "$SRC/etc/cloud/cloud.cfg.tpl")" \
	VM_USER="$VM_USER" > "/etc/cloud/cloud.cfg"

