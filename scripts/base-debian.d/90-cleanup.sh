#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## VM cleanup routines

apt-get -y -qq autoremove || true
apt-get -y -qq clean || true

df -h

