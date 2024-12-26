#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Applies some Linux tweaks to speed up login

# Disable SSH reverse DNS querying
if grep "^UseDNS yes" /etc/ssh/sshd_config; then
	sed "s/^UseDNS yes/UseDNS no/" /etc/ssh/sshd_config > /tmp/sshd_config
	mv /tmp/sshd_config /etc/ssh/sshd_config
else
	echo "UseDNS no" >> /etc/ssh/sshd_config
fi

