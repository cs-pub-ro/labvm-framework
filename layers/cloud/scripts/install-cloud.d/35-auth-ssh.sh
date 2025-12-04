#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## User & SSH password-based authentication options

# Change root/student account passwords, if requested
if [[ -n "$VM_PASSWORD" ]]; then
	echo "root:$VM_PASSWORD" | chpasswd
	echo "$VM_USER:$VM_PASSWORD" | chpasswd
	[[ -n "$VM_SSH_PASSWORD_AUTH" ]] || VM_SSH_PASSWORD_AUTH=1

elif [[ -n "$VM_CONSOLE_SECURITY" ]]; then
	# disable password login for the main accounts
	# cloud-init should be supplied with proper ssh authorized keys
	passwd -l "root"
	passwd -l "$VM_USER"
fi

# comment out these lines from the main sshd_config
sed -i "s/.*PasswordAuthentication.*/#PasswordAuthentication no/g" /etc/ssh/sshd_config
sed -i "s/.*PermitRootLogin.*/#PermitRootLogin no/g" /etc/ssh/sshd_config

# Note: sshd keeps the first option value found...
# cloud-init uses 50-* for its configs, so make these with lesser priority
if [[ "$VM_SSH_PASSWORD_AUTH" == "1" ]]; then
	# enable ssh password-based login
	echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/60-cloud-auth.conf
	echo "PermitRootLogin yes" >> /etc/ssh/sshd_config.d/60-cloud-auth.conf
else
	# disable ssh password & root login
	echo "PasswordAuthentication no" > /etc/ssh/sshd_config.d/60-cloud-auth.conf
	echo "PermitRootLogin no" >> /etc/ssh/sshd_config.d/60-cloud-auth.conf
fi

if [[ "$VM_SSH_LEGACY_ALGS" == "1" ]]; then
	( echo "HostkeyAlgorithms +ssh-rsa"; 
	  echo "PubkeyAcceptedAlgorithms +ssh-rsa" ) \
		> "/etc/ssh/sshd_config.d/30-legacy-algs.conf"
else
	rm -f "/etc/ssh/sshd_config.d/30-legacy-algs.conf"
fi

