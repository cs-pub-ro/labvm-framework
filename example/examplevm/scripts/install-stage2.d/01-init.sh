#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# VM install initialization

# prevent prompts from `dpkg`
export DEBIAN_FRONTEND=noninteractive

# update the repos
apt-get update

