#!/bin/bash
# Install scripts entrypoint: sources all scripts in a directory

set -eo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/base.sh"

@import 'vmrunner'

if [[ -z "$1" ]]; then
	echo "Usage: install.sh [OPTIONS] SCRIPTS_DIR" >&2; exit 1
fi

vm_run_scripts "$@"

