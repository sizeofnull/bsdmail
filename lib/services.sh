bsdmail_enable_services() {
	sysrc milteropendkim_enable="YES"
	sysrc postfix_enable="YES"
	sysrc dovecot_enable="YES"
	sysrc fail2ban_enable="YES"
}

bsdmail_restart_services() {
	for x in milter-opendkim dovecot postfix fail2ban; do
		service_restart "$x"
	done
}
