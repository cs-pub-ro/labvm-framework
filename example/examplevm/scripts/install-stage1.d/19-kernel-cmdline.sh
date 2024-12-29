#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Kernel cmdline customizations

KERNEL_CMDLINE_APPEND=" quiet"

vm_run_script "common-snippets.d/kernel-cmdline"

