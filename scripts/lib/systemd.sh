#!/bin/bash
[[ -n "$__MOD_PATH" ]] || { echo "Note: only usable as module (with @import)!" >&2; return 1; }
# Systemd-based distro utilities


# Wait until system state is either running (all services OK) or degraded (some
# failed to start, but otherwise system has finished booting)
function systemd_wait_for_boot() {
	sh_log_info "Waiting for the VM to fully boot..."
	while [ "$(systemctl is-system-running 2>/dev/null)" != "running" ] && \
		[ "$(systemctl is-system-running 2>/dev/null)" != "degraded" ]; do sleep 2; done
}

# Installs and enabled a service file (service name defaults to svc file's name)
# Usage: systemd_install_service SERVICE_FILE [SERVICE_NAME]
function systemd_install_service() {
	local SERVICE_FILE="$1"
	local SERVICE_NAME="$2"
	[[ -n "$SERVICE_NAME" ]] || SERVICE_NAME=$(basename "$SERVICE_FILE")
	SERVICE_NAME=${SERVICE_NAME%.service}
	install -m0644 "$SERVICE_FILE" "/etc/systemd/system/$SERVICE_NAME.service"
	systemctl daemon-reload
	systemctl enable "$SERVICE_NAME"
}

# Returns whether a systemd service is installed & enabled.
function systemd_is_enabled() {
	systemctl is-enabled "$1" &>/dev/null
}

