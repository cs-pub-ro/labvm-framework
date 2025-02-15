#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# Various system tweaks (MOTD, prever IPv4 in DNS, cloud init cleanup)

[[ "$VM_SYSTEM_TWEAKS" == "1" ]] || { sh_log_info " > Skipped!"; return 0; }

# disable SSH DNS lookup
sed -i 's/^UseDNS.*/UseDNS no/' /etc/ssh/sshd_config

# remove MOTD snippets
[[ -n "${DISABLE_MOTD_SNIPPETS[*]}" ]] || \
	DISABLE_MOTD_SNIPPETS=(10-help-text 50-motd-news 91-release-upgrade 
		92-unattended-upgrades)
sh_log_debug "$(echo "Current update-motd.d snippets: "; ls -lh /etc/update-motd.d/)"
if [[ -f /etc/default/motd-news ]]; then
	sed -i 's/^ENABLED.*/ENABLED=0/' /etc/default/motd-news
fi
for motd_snippet in "${DISABLE_MOTD_SNIPPETS[@]}"; do
	if [[ -f "/etc/update-motd.d/$motd_snippet" ]]; then
		chmod -x "/etc/update-motd.d/$motd_snippet"; fi
done

# disable ubuntu advantage leftovers
# https://askubuntu.com/questions/1452519/what-are-the-services-apt-news-and-esm-cache-and-how-do-i-disable-them
! systemd_is_enabled apt-news || systemctl mask apt-news.service
! systemd_is_enabled esm-cache || systemctl mask esm-cache.service
if [[ -f /etc/apt/apt.conf.d/20apt-esm-hook.conf ]]; then
	dpkg-divert --rename --divert /etc/apt/apt.conf.d/20apt-esm-hook.conf.disabled \
		--add /etc/apt/apt.conf.d/20apt-esm-hook.conf
fi

# tell GAI that we prefer ipv4, thanks
GAI_PREFER_IPV4="precedence ::ffff:0:0/96  100"
gai_file="/etc/gai.conf"
if ! grep "^$GAI_PREFER_IPV4" "$gai_file"; then
	echo "$GAI_PREFER_IPV4" >> "$gai_file"
fi

# disable password authentication (enabled by cloud-init :/ )
rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf

