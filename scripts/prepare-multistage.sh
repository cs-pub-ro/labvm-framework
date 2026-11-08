#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# Utility multi-stage provisioning script (shared by all layers & base images)
# Runs provisioning snippets from one or more prepare dirs (no symlinks),
# selecting them by their numeric prefix against a range spec.
#
# Config (env):
#   VM_PREPARE_RANGE  comma-separated numeric ranges to run, e.g. "1-19" or
#                     "1,20-99" (a snippet NN-name.sh runs if NN is in range)
#   VM_PREPARE_DIRS   colon-separated snippets dirs, PATH-style, e.g.
#                     "prepare.d:full-snippets.d" (relative to $VM_SCRIPTS_DIR
#                     or absolute). Missing dirs are skipped; on duplicate
#                     filenames, the FIRST dir listed wins (like $PATH).
#   VM_PREPARE_DIR    legacy single-dir var (used when VM_PREPARE_DIRS is unset)
#
# Snippets from all dirs form a single virtual dir: they run globally sorted by
# filename, so a "90-cleanup.sh" from the first dir still runs after a
# "25-docker.sh" from the last one.

declare -a _FIND_ARGS=(
	-mindepth 1 -maxdepth 1 -type f -iname '*.sh'	
)
# old dir names (kept working for backwards compatibility)
declare -a _LEGACY_DIRS=(install-stage1.d install-stage2.d)
declare RANGE="${VM_PREPARE_RANGE:-}"
declare DIRS="${VM_PREPARE_DIRS:-${VM_PREPARE_DIR:-prepare.d}}"

if [[ -z "$RANGE" ]]; then
	sh_log_info "SKIP prepare: no range given"
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

# gather snippets from all dirs (earlier dirs shadow later ones, like $PATH)
declare -A _SNIPPETS=()
IFS=':' read -r -a _DIRS <<< "$DIRS"
declare _DIR="" _SCRIPT_FILE="" _SCRIPT_NAME=""
for _DIR in "${_DIRS[@]}"; do
	[[ -z "$_DIR" ]] && continue
	[[ "$_DIR" == /* ]] || _DIR="$VM_SCRIPTS_DIR/$_DIR"
	if [[ ! -d "$_DIR" ]]; then
		sh_log_debug "SKIP prepare dir (missing): $_DIR"
		continue
	fi
	[[ ! " ${_LEGACY_DIRS[*]} " == *" $(basename "$_DIR") "* ]] || \
		sh_log_info "NOTE: legacy snippets dir (please rename it to prepare.d or choose a different convention): $(basename "$_DIR")"
	while IFS=  read -r -d $'\0' _SCRIPT_FILE; do
		_SCRIPT_NAME="$(basename "$_SCRIPT_FILE")"
		if [[ -v "_SNIPPETS[$_SCRIPT_NAME]" ]]; then
			sh_log_info " > Ignoring $_SCRIPT_NAME from $(basename "$_DIR")/ (shadowed by an earlier dir)"
			continue
		fi
		_SNIPPETS["$_SCRIPT_NAME"]="$_SCRIPT_FILE"
	done < <(find -L "$_DIR" '(' "${_FIND_ARGS[@]}" ')' -print0)
done

# run the (deduplicated) snippets, sorted by filename
if (( ${#_SNIPPETS[@]} == 0 )); then
	sh_log_info "SKIP prepare: no snippets found in: $DIRS"
	return 0
fi
while IFS=  read -r -d $'\0' _SCRIPT_NAME; do
	declare _N=""
	if [[ "$_SCRIPT_NAME" =~ ^([0-9]{2})[_\ -] ]]; then
		_N=$(( 10#${BASH_REMATCH[1]} ))
		if _prepare_in_range "$_N"; then
			sh_log_info "> Running $_SCRIPT_NAME"
			source "${_SNIPPETS[$_SCRIPT_NAME]}"
		fi
	else
		sh_log_error " > DISABLED (invalid filename): $_SCRIPT_NAME"
	fi
done < <(printf '%s\0' "${!_SNIPPETS[@]}" | sort -z)
