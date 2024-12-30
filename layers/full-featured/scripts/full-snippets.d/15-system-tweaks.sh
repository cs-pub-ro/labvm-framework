#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# Various system tweaks (MOTD, prever IPv4 in DNS, cloud init cleanup)

[[ "$VM_SYSTEM_TWEAKS" == "1" ]] || { sh_log_info " > Skipped!"; return 0; }

# remove MOTD snippets, disable SSH DNS lookup
sed -i 's/^ENABLED.*/ENABLED=0/' /etc/default/motd-news
sed -i 's/^UseDNS.*/UseDNS no/' /etc/ssh/sshd_config

sh_log_debug "$(echo "Current update-motd.d snippets: "; ls -lh /etc/update-motd.d/)"
chmod -x /etc/update-motd.d/10-help-text
chmod -x /etc/update-motd.d/50-motd-news
chmod -x /etc/update-motd.d/91-release-upgrade
chmod -x /etc/update-motd.d/92-unattended-upgrades

# disable ubuntu advantage leftovers
# https://askubuntu.com/questions/1452519/what-are-the-services-apt-news-and-esm-cache-and-how-do-i-disable-them
systemctl mask apt-news.service
systemctl mask esm-cache.service
dpkg-divert --rename --divert /etc/apt/apt.conf.d/20apt-esm-hook.conf.disabled \
	--add /etc/apt/apt.conf.d/20apt-esm-hook.conf

# tell GAI that we prefer ipv4, thanks
GAI_PREFER_IPV4="precedence ::ffff:0:0/96  100"
gai_file="/etc/gai.conf"
if ! grep "^$GAI_PREFER_IPV4" "$gai_file"; then
	echo "$GAI_PREFER_IPV4" >> "$gai_file"
fi

# disable password authentication (enabled by cloud-init :/ )
rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf

