#!/bin/bash
[[ -n "$__MOD_PATH" ]] || { echo "Note: only usable as module (with @import)!" >&2; return 1; }
## VM provisioning scripts

# Runs all .sh scripts inside a directory ($1), sorted by name.
# It is recommended to prefix them with priority numbers (e.g. 01-init.sh)
function vm_run_scripts() {
	# tell the script it's inside our evaluation context
	local SCRIPTS_DIR="$1"
	local __INSIDE_VM_RUNNER=1 __SCRIPT_NAME=""
	local -a FIND_ARGS=(
		-mindepth 1 -maxdepth 1 -type f -iname '*.sh'	
	)
	# run installation scripts (in order)
	# Note: we use \0 as line separator (won't really have newlines inside
	# filenames, but it's not a bad thing to be comprehensive!)
	while IFS=  read -r -d $'\0' file; do
		__SCRIPT_NAME="$(basename "$file")"
		sh_log_info "> Running $__SCRIPT_NAME"
		source "$file"
	done < <(find "$SCRIPTS_DIR" '(' "${FIND_ARGS[@]}" ')' -print0 | sort -n -z)
}

