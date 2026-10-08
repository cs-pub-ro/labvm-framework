#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Applies some Linux tweaks to speed up login

# Disable SSH reverse DNS querying
echo "UseDNS no" >> /etc/ssh/sshd_config
