#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Kernel cmdline customizations

# append to previous cmdline (if any)
KERNEL_CMDLINE_APPEND=${KERNEL_CMDLINE_APPEND:-}
KERNEL_CMDLINE_APPEND+=" quiet"

vm_run_script "common-snippets.d/kernel-cmdline"

# and reboot!
vm_run_script "common-snippets.d/reboot"

