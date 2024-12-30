#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# Fully-featured VM preparation script
# Link all snippets to the appropriate stage dirs using their ordering info

SRC=$(sh_get_script_path)

declare -a _FIND_ARGS=(
	-mindepth 1 -maxdepth 1 -type f -iname '*.sh'	
)
declare FULL_SNIPPETS_DIR="$SRC/full-snippets.d" \
	STAGE1="install-stage1.d" STAGE2="install-stage2.d"

while IFS=  read -r -d $'\0' file; do
	declare -a _STAGES=
	declare _SCRIPT_NAME="$(basename "$file")" _N=""

	if [[ "$_SCRIPT_NAME" =~ ^([0-9]{2})[_\ -] ]]; then
		_N=$(( 10#${BASH_REMATCH[1]} ))
		if [[ "$_N" -lt 10 ]]; then
			# add to both stanges
			_STAGES=("$STAGE1" "$STAGE2")
		elif [[ "$_N" -lt 20 ]]; then
			# add to 1st stange
			_STAGES=("$STAGE1")
		else
			# last stange
			_STAGES=("$STAGE2")
		fi
	else
		sh_log_error " > DISABLED (invalid filename): $_SCRIPT_NAME"
		continue
	fi

	for stage in  "${_STAGES[@]}"; do
		sh_log_debug " > ln: $_SCRIPT_NAME -> $stage"
		ln -sf "$file" "$SRC/$stage/$_SCRIPT_NAME"
	done

done < <(find -L "$FULL_SNIPPETS_DIR" '(' "${_FIND_ARGS[@]}" ')' -print0 | sort -n -z)

