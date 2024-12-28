#!/bin/bash
[[ -n "$__MOD_PATH" ]] || { echo "Note: only usable as module (with @import)!" >&2; return 1; }
## VM provisioning scripts

# default base path
VM_SCRIPTS_DIR=${VM_SCRIPTS_DIR:-/opt/vm-scripts}

# Runs all .sh scripts inside a directory ($1), sorted by name.
# It is recommended to prefix them with priority numbers (e.g. 01-init.sh)
function vm_run_scripts() {
	# tell the script it's inside our evaluation context
	local SCRIPTS_DIR="" OPTIONAL=""
	local __INSIDE_VM_RUNNER=1 __SCRIPT_NAME=""
	local -a FIND_ARGS=(
		-mindepth 1 -maxdepth 1 -type f -iname '*.sh'	
	)
	while [[ $# -gt 1 ]]; do case "$1" in
		--opt|--optional) OPTIONAL=1 ;;
		-*) sh_log_error "vm_run_scripts: invalid option: $1"; return 1 ;;
		*) break; ;;
	esac; shift; done
	SCRIPTS_DIR="$(vm_resolve_script "$1")"

	if [[ -z "$SCRIPTS_DIR" || ! -d "$SCRIPTS_DIR" ]]; then
		[[ -z "$OPTIONAL" ]] || return 0
		sh_log_error "vm_run_scripts: invalid scripts directory: '$SCRIPTS_DIR'"
		return 1
	fi

	# run installation scripts (in order)
	# Note: we use \0 as line separator (won't really have newlines inside
	# filenames, but it's not a bad thing to be comprehensive!)
	while IFS=  read -r -d $'\0' file; do
		__SCRIPT_NAME="$(basename "$file")"
		sh_log_info "> Running $__SCRIPT_NAME"
		source "$file"
	done < <(find "$SCRIPTS_DIR" '(' "${FIND_ARGS[@]}" ')' -print0 | sort -n -z)
}

# Executes a single script
# (useful for its optionality check)
function vm_run_script() {
	local SCRIPT_FILE="" OPTIONAL=""
	local __INSIDE_VM_RUNNER=1 __SCRIPT_NAME=""
	while [[ $# -gt 1 ]]; do case "$1" in
		--opt|--optional) OPTIONAL=1 ;;
		-*) sh_log_error "vm_run_scripts: invalid option: $1"; return 1 ;;
		*) break; ;;
	esac; shift; done
	SCRIPT_FILE="$(vm_resolve_script "$1")"

	if [[ -z "$SCRIPT_FILE" || ! -f "$SCRIPT_FILE" ]]; then
		[[ -z "$OPTIONAL" ]] || return 0
		sh_log_error "vm_run_script: invalid script file: '$SCRIPT_FILE'"
		return 1
	fi

	source "$SCRIPT_FILE"
}

# resolves the path to a vm-scripts dir/file
function vm_resolve_script() {
	local FILE="$1"
	if [[ "$FILE" == /* ]]; then
		true  # absolute path, continue!
	else
		FILE="$VM_SCRIPTS_DIR/$FILE"
	fi
	echo -n "$FILE"
}

