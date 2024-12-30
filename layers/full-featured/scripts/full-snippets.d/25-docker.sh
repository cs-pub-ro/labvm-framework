#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Docker installation snippet

[[ "$VM_INSTALL_DOCKER" == "1" ]] || { sh_log_info " > Skipped!"; return 0; }

# container tools
pkg_install bridge-utils

# add the official docker repos
install -m 0755 -d /etc/apt/keyrings
[[ -f "/etc/apt/keyrings/docker.gpg" ]] || \
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
pkg_init_update
pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# MTU fix for OpenStack VMs
cat << EOF > /etc/docker/daemon.json
{
  "mtu": 1450,
  "features": {"buildkit": true}
}
EOF

# docker without sudo for the main VM user
usermod -aG docker "$VM_USER" || true

# enable docker by default
systemctl enable docker
systemctl restart docker

