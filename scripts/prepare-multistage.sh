#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# Utility multi-stage provisioning script (shared by all layers & base images)
# Runs provisioning snippets directly from a single prepare dir (no symlinks),
# selecting them by their numeric prefix against a range spec.
#
# Config (env):
#   VM_PREPARE_RANGE  comma-separated numeric ranges to run, e.g. "1-19" or
#                     "1,20-99" (a snippet NN-name.sh runs if NN is in range)
#   VM_PREPARE_DIR    snippets dir to run from (default: <scripts>/prepare.d)

declare -a _FIND_ARGS=(
	-mindepth 1 -maxdepth 1 -type f -iname '*.sh'	
)
declare RANGE="${VM_PREPARE_RANGE:-}"
declare _SNIPPETS_DIR="${VM_PREPARE_DIR:-prepare.d}"
[[ "$_SNIPPETS_DIR" == /* ]] || _SNIPPETS_DIR="$VM_SCRIPTS_DIR/$_SNIPPETS_DIR"

if [[ -z "$RANGE" ]]; then
	sh_log_info "SKIP prepare: no range given"
	return 0
fi
if [[ ! -d "$_SNIPPETS_DIR" ]]; then
	sh_log_info "SKIP prepare: no snippets dir: $_SNIPPETS_DIR"
	return 0
fi

# checks whether a numeric prefix is covered by the RANGE spec
function _prepare_in_range() {
	local n="$1" part lo hi
	local IFS=','
	for part in $RANGE; do
		if [[ "$part" == *-* ]]; then
			lo="${part%-*}"; hi="${part#*-}"
			(( n >= 10#$lo && n <= 10#$hi )) && return 0
		elif (( n == 10#$part )); then
			return 0
		fi
	done
	return 1
}

while IFS=  read -r -d $'\0' file; do
	declare _SCRIPT_NAME="$(basename "$file")" _N=""
	if [[ "$_SCRIPT_NAME" =~ ^([0-9]{2})[_\ -] ]]; then
		_N=$(( 10#${BASH_REMATCH[1]} ))
		if _prepare_in_range "$_N"; then
			sh_log_info "> Running $_SCRIPT_NAME"
			source "$file"
		fi
	else
		sh_log_error " > DISABLED (invalid filename): $_SCRIPT_NAME"
	fi
done < <(find -L "$_SNIPPETS_DIR" '(' "${_FIND_ARGS[@]}" ')' -print0 | sort -n -z)
