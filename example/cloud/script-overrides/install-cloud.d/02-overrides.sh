#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Cloud install overrides

# set a hardcoded passwords & enable password auth (NOT RECOMMENDED!)
VM_PASSWORD="Test123"
VM_SSH_PASSWORD_AUTH=1
# we might as well turn on legacy algs for ssh ;)
VM_SSH_LEGACY_ALGS=1

