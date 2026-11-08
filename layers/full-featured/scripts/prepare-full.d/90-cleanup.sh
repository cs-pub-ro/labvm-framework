#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## VM cleanup

rm -rf /home/$VM_USER/.bash_history /root/.bash_history

pkg_cleanup || true

df -h

