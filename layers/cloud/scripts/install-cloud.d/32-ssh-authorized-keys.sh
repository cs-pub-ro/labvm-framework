#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Runs the ssh-authorized-keys snippet

vm_run_script "common-snippets.d/ssh-authorized-keys"

