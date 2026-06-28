bsdmail_dovecot_dh_path() {
	dh="$prefix/share/dovecot/dh.pem"
	[ ! -f "$dh" ] && dh="$dovecot_dir/dh.pem"
	[ ! -f "$dh" ] && openssl dhparam -out "$dovecot_dir/dh.pem" 4096 && dh="$dovecot_dir/dh.pem"
	echo "$dh"
}

bsdmail_configure_dovecot() {
	mv "$dovecot_dir/dovecot.conf" "$dovecot_dir/dovecot.backup.conf" 2>/dev/null

	echo "Creating Dovecot config..."

	dovecot_dh="$(bsdmail_dovecot_dh_path)"

	echo "# Dovecot config
ssl = required
ssl_cert = <$certdir/fullchain.pem
ssl_key = <$certdir/privkey.pem
ssl_min_protocol = TLSv1.2
ssl_cipher_list = 'EECDH+ECDSA+AESGCM:EECDH+aRSA+AESGCM:EECDH+ECDSA+SHA256:EECDH+aRSA+SHA256:EECDH+ECDSA+SHA384:EECDH+ECDSA+SHA256:EECDH+aRSA+SHA384:EDH+aRSA+AESGCM:EDH+aRSA+SHA256:EDH+aRSA:EECDH:!aNULL:!eNULL:!MEDIUM:!LOW:!3DES:!MD5:!EXP:!PSK:!SRP:!DSS:!RC4:!SEED'
ssl_prefer_server_ciphers = yes
ssl_dh = <$dovecot_dh
auth_mechanisms = plain login
auth_username_format = %n

protocols = \$protocols $allowed_protocols

userdb {
	driver = passwd
}
passdb {
	driver = pam
}

mail_location = $mailbox_format:~/Mail:INBOX=~/Mail/Inbox:LAYOUT=fs
namespace inbox {
	inbox = yes
	mailbox Drafts {
	special_use = \\Drafts
	auto = subscribe
}
	mailbox Junk {
	special_use = \\Junk
	auto = subscribe
	autoexpunge = 30d
}
	mailbox Sent {
	special_use = \\Sent
	auto = subscribe
}
	mailbox Trash {
	special_use = \\Trash
}
	mailbox Archive {
	special_use = \\Archive
}
}

service auth {
  unix_listener /var/spool/postfix/private/auth {
	mode = 0660
	user = postfix
	group = postfix
}
}

protocol lda {
  mail_plugins = \$mail_plugins sieve
}

protocol lmtp {
  mail_plugins = \$mail_plugins sieve
}

protocol pop3 {
  pop3_uidl_format = %08Xu%08Xv
  pop3_no_flag_updates = yes
}

plugin {
	sieve = ~/.dovecot.sieve
	sieve_default = $prefix/etc/dovecot/sieve/default.sieve
	sieve_dir = ~/.sieve
	sieve_global_dir = $prefix/etc/dovecot/sieve/
}
" > "$dovecot_dir/dovecot.conf"

	case "$(dovecot --version)" in
		1|2.1*|2.2*) sed_inplace '/^ssl_dh/d' "$dovecot_dir/dovecot.conf" ;;
	esac

	mkdir -p "$prefix/etc/dovecot/sieve"

	echo "require [\"fileinto\", \"mailbox\"];
if header :contains \"X-Spam-Flag\" \"YES\"
	{
		fileinto \"Junk\";
	}" > "$prefix/etc/dovecot/sieve/default.sieve"

	grep -q '^vmail:' /etc/passwd || pw useradd vmail -d /var/vmail -s /usr/sbin/nologin
	chown -R vmail:vmail "$prefix/etc/dovecot"
	sievec "$prefix/etc/dovecot/sieve/default.sieve"

	echo 'Preparing user authentication...'
	mkdir -p "$prefix/etc/pam.d"
	grep -q nullok "$pam_dovecot" 2>/dev/null ||
		cat <<'EOF' >> "$pam_dovecot"
auth    sufficient    pam_unix.so nullok
account required      pam_unix.so
EOF
}
