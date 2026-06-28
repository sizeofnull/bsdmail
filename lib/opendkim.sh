bsdmail_opendkim_generate_keys() {
	dkim_domain="$1"
	dkim_subdom="$2"

	mkdir -p "$postfix_dir/dkim/$dkim_domain"
	opendkim-genkey -D "$postfix_dir/dkim/$dkim_domain" -d "$dkim_domain" -s "$dkim_subdom"
	chgrp -R opendkim "$postfix_dir/dkim"/*
	chmod -R g+r "$postfix_dir/dkim"/*
}

bsdmail_opendkim_register_domain() {
	dkim_domain="$1"
	dkim_subdom="$2"

	echo "$dkim_subdom._domainkey.$dkim_domain $dkim_domain:$dkim_subdom:$postfix_dir/dkim/$dkim_domain/$dkim_subdom.private" >> "$postfix_dir/dkim/keytable"
	echo "*@$dkim_domain $dkim_subdom._domainkey.$dkim_domain" >> "$postfix_dir/dkim/signingtable"
}

bsdmail_configure_opendkim() {
	echo 'Generating OpenDKIM keys...'
	bsdmail_opendkim_generate_keys "$domain" "$subdom"

	echo 'Configuring OpenDKIM...'
	grep -q "$domain" "$postfix_dir/dkim/keytable" 2>/dev/null ||
		bsdmail_opendkim_register_domain "$domain" "$subdom"

	grep -q '127.0.0.1' "$postfix_dir/dkim/trustedhosts" 2>/dev/null ||
		echo '127.0.0.1
10.1.0.0/16' >> "$postfix_dir/dkim/trustedhosts"

	grep -q '^KeyTable' "$opendkim_conf" 2>/dev/null || cat <<EOF >> "$opendkim_conf"
KeyTable file:$postfix_dir/dkim/keytable
SigningTable refile:$postfix_dir/dkim/signingtable
InternalHosts refile:$postfix_dir/dkim/trustedhosts
EOF

	sed_inplace '/^#Canonicalization/s/simple/relaxed\/simple/' "$opendkim_conf"
	sed_inplace '/^#Canonicalization/s/^#//' "$opendkim_conf"
	sed_inplace '/^Socket/s/^/#/' "$opendkim_conf"
	grep -q '^Socket[[:space:]]*inet:12301@localhost' "$opendkim_conf" || echo 'Socket inet:12301@localhost' >> "$opendkim_conf"
	grep -q '^PidFile' "$opendkim_conf" || echo 'PidFile /var/run/opendkim/opendkim.pid' >> "$opendkim_conf"

	mkdir -p /var/run/opendkim
	chown opendkim:opendkim /var/run/opendkim
}
