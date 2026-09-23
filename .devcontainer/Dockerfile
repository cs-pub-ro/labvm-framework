# labvm-framework dev image: packer + qemu + deps on Debian
FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
	ca-certificates curl gpg \
	make git openssh-client sudo \
	# qemu userland (x86_64 + aarch64 guests) + tooling
	qemu-system-x86 qemu-system-arm qemu-utils \
	# framework build/test helpers
	whois genisoimage zerofree uuid-runtime rsync \
&& \
	# Packer from HashiCorp's APT repo (Debian trixie)
	curl -fsSL https://apt.releases.hashicorp.com/gpg \
		| gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
&& echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg arch=amd64,arm64] https://apt.releases.hashicorp.com trixie main" \
	> /etc/apt/sources.list.d/hashicorp.list \
&& apt-get update \
&& apt-get install -y --no-install-recommends packer \
&& rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
