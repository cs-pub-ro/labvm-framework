#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Configure desktop manager for autologin

sed -i "s/^#*\s*autologin-user=.*/autologin-user=$VM_USER/g" /etc/lightdm/lightdm.conf

