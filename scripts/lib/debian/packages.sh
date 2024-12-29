#!/bin/bash
# Abstracted package management routines for Debian-based distros (using APT)

# Global APT overrides
declare -g APT_ARGS=(-y)
declare -g APT_INSTALL_ARGS=()
declare -g APT_REMOVE_ARGS=()
[[ -n "$DEBUG" && "$DEBUG" -ge 1 ]] || APT_ARGS+=(-qq)

# use non-interactive environment for apt/dpkg tools
export DEBIAN_FRONTEND=noninteractive

# Initializes the package manager for unattended op. & updates its repos
function pkg_init_update() {
	apt-get "${APT_ARGS[@]}" update
}

function _apt_silence() {
	if [[ -n "$DEBUG" && "$DEBUG" -ge 1 ]]; then
		"$@"
	else
		"$@" >/dev/null
	fi
}

# Installs the requested package(s)
function pkg_install() {
	local -a _args=()
	# parse args
	while [[ $# -gt 0 ]]; do case "$1" in
		--) shift; break ;;  # the rest are packages
		-*) _args+=("$1") ;; # pass APT options
		*) break ;; # position arguments are packages
	esac; shift; done
	# make apt-get's post-install dpkg steps silent if DEBUG is disabled...
	_apt_silence apt-get "${APT_ARGS[@]}" install "${_args[@]}" \
		"${APT_INSTALL_ARGS[@]}" "$@"
}

# Removes the requested package(s)
function pkg_remove() {
	local -a _args=()
	# parse args
	while [[ $# -gt 0 ]]; do case "$1" in
		--) shift; break ;;  # the rest are packages
		-*) _args+=("$1") ;; # pass APT options
		*) break ;; # position arguments are packages
	esac; shift; done
	apt-get "${APT_ARGS[@]}" remove "${_args[@]}" \
		"${APT_REMOVE_ARGS[@]}" "$@"
}

# Upgrades all packages
function pkg_upgrade_all() {
    apt-get "${APT_ARGS[@]}" dist-upgrade
}

# Do a full cleanup of the packages & temp files
function pkg_cleanup() {
	apt-get "${APT_ARGS[@]}" autoremove
    apt-get "${APT_ARGS[@]}" clean
}

