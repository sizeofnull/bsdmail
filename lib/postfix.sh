bsdmail_configure_postfix_main() {
	echo "Configuring Postfix's main.cf..."

	postconf -e "myhostname = $maildomain"
	postconf -e "mail_name = $domain"
	postconf -e "mydomain = $domain"
	postconf -e 'mydestination = $myhostname, $mydomain, mail, localhost.localdomain, localhost, localhost.$mydomain'

	postconf -e "smtpd_tls_key_file=$certdir/privkey.pem"
	postconf -e "smtpd_tls_cert_file=$certdir/fullchain.pem"

	if [ "$selfsigned" != "yes" ]; then
		postconf -e "smtp_tls_CAfile=$certdir/cert.pem"
	fi

	postconf -e 'smtpd_tls_security_level = may'
	postconf -e 'smtp_tls_security_level = may'
	postconf -e 'smtpd_tls_auth_only = yes'
	postconf -e 'smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1'
	postconf -e 'smtp_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1'
	postconf -e 'smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1'
	postconf -e 'smtp_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1'

	if [ "$allow_suboptimal_ciphers" = "no" ]; then
		postconf -e 'tls_preempt_cipherlist = yes'
		postconf -e 'smtpd_tls_exclude_ciphers = aNULL, LOW, EXP, MEDIUM, ADH, AECDH, MD5, DSS, ECDSA, CAMELLIA128, 3DES, CAMELLIA256, RSA+AES, eNULL'
	fi

	postconf -e 'smtpd_sasl_auth_enable = yes'
	postconf -e 'smtpd_sasl_type = dovecot'
	postconf -e 'smtpd_sasl_path = private/auth'

	postconf -e "smtpd_sender_login_maps = pcre:$postfix_dir/login_maps.pcre"
	postconf -e 'smtpd_sender_restrictions = reject_sender_login_mismatch, permit_sasl_authenticated, permit_mynetworks, reject_unknown_reverse_client_hostname, reject_unknown_sender_domain'
	postconf -e 'smtpd_recipient_restrictions = permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination, reject_unknown_recipient_domain'
	postconf -e 'smtpd_relay_restrictions = permit_sasl_authenticated, reject_unauth_destination'
	postconf -e 'smtpd_helo_required = yes'
	postconf -e 'smtpd_helo_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_invalid_helo_hostname, reject_non_fqdn_helo_hostname, reject_unknown_helo_hostname'

	postconf -e 'home_mailbox = Mail/Inbox/'
	postconf -e "header_checks = regexp:$postfix_dir/header_checks"

	echo "/^Received:.*/     IGNORE
/^X-Originating-IP:/    IGNORE" > "$postfix_dir/header_checks"

	echo "/^(.*)@$(sh -c "echo $domain | sed 's/\./\\\./'")$/   \${1}" > "$postfix_dir/login_maps.pcre"
}

bsdmail_configure_postfix_master() {
	echo "Configuring Postfix's master.cf..."

	sed_inplace '/^[[:space:]]*-o/d;/^[[:space:]]*submission/d;/^[[:space:]]*smtp/d' "$postfix_dir/master.cf"

	echo "smtp unix - - n - - smtp
smtp inet n - y - - smtpd
  -o content_filter=spamassassin
submission inet n       -       y       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_tls_auth_only=yes
  -o smtpd_enforce_tls=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o smtpd_sender_restrictions=reject_sender_login_mismatch
  -o smtpd_sender_login_maps=pcre:$postfix_dir/login_maps.pcre
  -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject_unauth_destination
smtps     inet  n       -       y       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
spamassassin unix -     n       n       -       -       pipe
  user=spamd argv=$prefix/bin/spamc -f -e $prefix/sbin/sendmail -oi -f \${sender} \${recipient}" >> "$postfix_dir/master.cf"
}

bsdmail_configure_postfix_milters() {
	echo 'Configuring Postfix with OpenDKIM settings...'

	postconf -e 'smtpd_sasl_security_options = noanonymous, noplaintext'
	postconf -e 'smtpd_sasl_tls_security_options = noanonymous'
	postconf -e "myhostname = $maildomain"
	postconf -e 'milter_default_action = accept'
	postconf -e 'milter_protocol = 6'
	postconf -e 'smtpd_milters = inet:localhost:12301'
	postconf -e 'non_smtpd_milters = inet:localhost:12301'
	postconf -e "mailbox_command = $prefix/libexec/dovecot/deliver"

	postconf -e 'smtpd_forbid_bare_newline = normalize'
	postconf -e 'smtpd_forbid_bare_newline_exclusions = $mynetworks'
}
