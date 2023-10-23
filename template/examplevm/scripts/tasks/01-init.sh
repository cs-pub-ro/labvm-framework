#!/bin/bash
# VM install initialization

[[ "$INSIDE_INSTALL_SCRIPT" == "1" ]] || { echo "Direct calls not supported!">&2; exit 5; }

# prevent prompts from `dpkg`
export DEBIAN_FRONTEND=noninteractive

# update the repos
apt-get update

