#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## VM cleanup + sysprep routines

cloud-init clean --logs --machine-id
rm -rf /opt/vm-scripts/cloud-* /home/$VM_USER/.bash_history /root/.bash_history
rm -rf /var/lib/cloud/ /tmp/*
rm -rf /var/log/*/*
rm -f /var/log/* 2>/dev/null || true

pkg_cleanup || true

df -h

