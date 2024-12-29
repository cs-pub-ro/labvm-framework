#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Networking tools installation snippet

[[ "$VM_INSTALL_NET_TOOLS" == "1" ]] || { sh_log_info " > Skipped!"; return 0; }

pkg_install --no-install-recommends \
	traceroute net-tools iputils-ping whois telnet dnsutils host finger \
	ftp ncftp nmap tcpdump dsniff rsync ethtool lynx elinks asciinema \
	s-nail mailutils sharutils iptables-persistent \
	smbclient cifs-utils ldap-utils netcat-openbsd socat

# Note: tshark has X11/WireShark as dependency, so just skip it!

