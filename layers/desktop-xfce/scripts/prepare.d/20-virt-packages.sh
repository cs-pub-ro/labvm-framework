#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Install paravirtualization packages

pkg_install --no-install-recommends open-vm-tools qemu-guest-agent

