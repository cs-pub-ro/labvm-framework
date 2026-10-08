#!/bin/bash
# Abstracted package management routines for Arch-based distros (using pacman)

# Global pacman overrides
declare -g PACMAN_ARGS=(--noconfirm)
[[ -n "$DEBUG" && "$DEBUG" -ge 1 ]] || PACMAN_ARGS+=(--noprogressbar)

# Initializes the package manager for unattended op. & updates its repos
function pkg_init_update() {
	pacman "${PACMAN_ARGS[@]}" -Sy
}

# Installs the requested package(s)
function pkg_install() {
	pacman "${PACMAN_ARGS[@]}" -S "$@"
}

# Removes the requested package(s)
function pkg_remove() {
	pacman "${PACMAN_ARGS[@]}" -Rns "$@"
}

# Upgrades all packages
function pkg_upgrade_all() {
	pacman --noconfirm -Syu
}

# Do a full cleanup of the packages & temp files
function pkg_cleanup() {
	pacman "${PACMAN_ARGS[@]}" -Scc
}
