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

cat << EOF > "/etc/cloud/cloud.cfg.d/10-user.cfg"
#cloud-config
merge_how:
 - name: dict
   settings: [no_replace, recurse_list]

system_info:
  default_user:
    name: $VM_USER

users:
 - default
EOF

# copy cloud config for VM distro
CLOUD_TPL=cloud.debian.tpl
if lsb_release -d | grep -i Ubuntu &>/dev/null; then
	CLOUD_TPL=cloud.ubuntu.tpl
fi
cp -f "$SRC/etc/cloud/$CLOUD_TPL" "/etc/cloud/cloud.cfg"

