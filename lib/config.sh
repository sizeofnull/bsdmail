# Domain and runtime configuration.

bsdmail_resolve_domain() {
	if [ -n "$MAIL_DOMAIN" ]; then
		domain="$MAIL_DOMAIN"
	else
		domain="$(hostname -f | awk -F. 'NF>1 {print $(NF-1)"."$NF}')"
	fi

	[ -z "$domain" ] && echo "Set MAIL_DOMAIN or create /etc/mailname with your domain." && exit 1

	subdom="${MAIL_SUBDOM:-mail}"
	maildomain="$subdom.$domain"
	certdir="$letsencrypt_dir/live/$maildomain"
	common_name="$(hostname -f)"
}

bsdmail_load_config() {
	# shellcheck source=lib/config.defaults.sh
	. "$BSDMAIL_ROOT/lib/config.defaults.sh"
	bsdmail_resolve_domain
}
