bsdmail_setup_postmaster() {
	grep -q '^postmaster:' /etc/passwd || pw useradd postmaster -m -s /usr/sbin/nologin
	pw groupmod mail -m postmaster 2>/dev/null

	mkdir -p "$prefix/etc/periodic/weekly"
	cat <<'EOF' > "$prefix/etc/periodic/weekly/bsdmail-postmaster-clean"
#!/bin/sh
find /home/postmaster/Mail -type f -mtime +30 -name '*.mail*' -delete >/dev/null 2>&1
exit 0
EOF
	chmod 755 "$prefix/etc/periodic/weekly/bsdmail-postmaster-clean"
}

bsdmail_setup_cert_renewal() {
	mkdir -p "$letsencrypt_dir/renewal-hooks/deploy"
	cat <<EOF > "$letsencrypt_dir/renewal-hooks/deploy/bsdmail.sh"
#!/bin/sh
case "\$RENEWED_DOMAINS" in
	*$maildomain*) service postfix reload; service dovecot reload ;;
esac
EOF
	chmod 755 "$letsencrypt_dir/renewal-hooks/deploy/bsdmail.sh"
}

bsdmail_finalize() {
	bsdmail_setup_postmaster
	bsdmail_setup_cert_renewal
	bsdmail_save_dns_records "~/dns_bsdmail"
	bsdmail_print_dns_banner
}
