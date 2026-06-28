bsdmail_configure_fail2ban() {
	[ -f "$fail2ban_dir/jail.d/bsdmail.local" ] && return 0

	mkdir -p "$fail2ban_dir/jail.d"
	echo "[postfix]
enabled = true
[postfix-sasl]
enabled = true
[sieve]
enabled = true
[dovecot]
enabled = true" > "$fail2ban_dir/jail.d/bsdmail.local"

	if [ -f "$fail2ban_dir/jail.conf" ]; then
		sed_inplace "s|^backend = auto$|backend = polling|" "$fail2ban_dir/jail.conf"
	fi
}

bsdmail_configure_spamassassin() {
	sa-update 2>/dev/null
	sysrc spamd_enable="YES"
	service_restart sa-spamd

	(
		crontab -l 2>/dev/null
		echo "0 1 * * * $prefix/bin/sa-update && service sa-spamd restart"
	) | crontab -
}

bsdmail_configure_security() {
	bsdmail_configure_fail2ban
	bsdmail_configure_spamassassin
}
