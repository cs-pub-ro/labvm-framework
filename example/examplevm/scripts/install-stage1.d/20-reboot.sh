#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Runs the reboot snippet

vm_run_script "common-snippets.d/reboot"

