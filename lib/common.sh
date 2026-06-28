# Shared paths and helpers for bsdmail.

prefix="/usr/local"
etcdir="$prefix/etc"
postfix_dir="$etcdir/postfix"
dovecot_dir="$etcdir/dovecot"
opendkim_conf="$etcdir/opendkim.conf"
letsencrypt_dir="$etcdir/letsencrypt"
fail2ban_dir="$etcdir/fail2ban"
pam_dovecot="$etcdir/pam.d/dovecot"

install_core="postfix fail2ban certbot nginx dovecot dovecot-pigeonhole opendkim spamassassin bind-tools"

service_stop() {
	serv="$1"
	service "$serv" stop >/dev/null 2>&1
}

service_restart() {
	serv="$1"
	printf "Restarting %s..." "$serv"
	service "$serv" restart && printf " ...done\n"
}

sed_inplace() {
	sed -i '' "$@"
}

port80_listener() {
	sockstat -4 -l 2>/dev/null | grep -E '[:.]80[[:space:]]' ||
		netstat -an 2>/dev/null | grep -E '\.80[[:space:]]'
}
