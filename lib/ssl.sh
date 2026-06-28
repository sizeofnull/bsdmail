bsdmail_write_cert_config() {
	[ "$use_cert_config" != "yes" ] && return 0

	echo "[req]
	default_bit = 4096
	distinguished_name = req_distinguished_name
	prompt = no

	[req_distinguished_name]
	countryName             = $country_name
	stateOrProvinceName     = $state_or_province_name
	organizationName        = $organization_name
	commonName              = $common_name " > "$certdir/certconfig.conf"
}

bsdmail_setup_selfsigned_cert() {
	rm -f "$certdir/privkey.pem" "$certdir/csr.pem" "$certdir/fullchain.pem"

	echo "Generating a 4096 rsa key and a self-signed certificate that lasts 100 years"
	mkdir -p "$certdir"
	openssl genrsa -out "$certdir/privkey.pem" 4096

	if [ "$use_cert_config" = "yes" ]; then
		openssl req -new -key "$certdir/privkey.pem" -out "$certdir/csr.pem" -config "$certdir/certconfig.conf"
	else
		openssl req -new -key "$certdir/privkey.pem" -out "$certdir/csr.pem"
	fi

	openssl req -x509 -days 36500 -key "$certdir/privkey.pem" -in "$certdir/csr.pem" -out "$certdir/fullchain.pem"
}

bsdmail_install_certbot_cert() {
	[ ! -d "$certdir" ] &&
		possiblecert="$(certbot certificates 2>/dev/null | grep "Domains:.* \(\*\.$domain\|$maildomain\)\( \|$\)" -A 2 | awk '/Certificate Path/ {print $3}' | head -n1)" &&
		certdir="${possiblecert%/*}"

	[ -d "$certdir" ] && return 0

	certdir="$letsencrypt_dir/live/$maildomain"

	case "$(port80_listener)" in
	*nginx*)
		pkg install -y py311-certbot-nginx 2>/dev/null || pkg install -y py313-certbot-nginx
		certbot -d "$maildomain" certonly --nginx --register-unsafely-without-email --agree-tos
		;;
	*apache*|*httpd*)
		pkg install -y py311-certbot 2>/dev/null || pkg install -y py313-certbot
		certbot -d "$maildomain" certonly --webroot -w /usr/local/www/apache24/data --register-unsafely-without-email --agree-tos 2>/dev/null ||
			certbot -d "$maildomain" certonly --standalone --register-unsafely-without-email --agree-tos
		;;
	*)
		pkg install -y py311-certbot 2>/dev/null || pkg install -y py313-certbot
		certbot -d "$maildomain" certonly --standalone --register-unsafely-without-email --agree-tos
		;;
	esac
}

bsdmail_setup_ssl() {
	bsdmail_write_cert_config

	if [ "$selfsigned" = "yes" ]; then
		bsdmail_setup_selfsigned_cert
	else
		bsdmail_install_certbot_cert
	fi
}

bsdmail_verify_ssl() {
	[ ! -f "$certdir/fullchain.pem" ] && echo "Error locating or installing SSL certificate." && exit 1
	[ ! -f "$certdir/privkey.pem" ] && echo "Error locating or installing SSL certificate." && exit 1

	if [ "$selfsigned" != "yes" ]; then
		[ ! -f "$certdir/cert.pem" ] && echo "Error locating or installing SSL certificate." && exit 1
	fi

	[ ! -d "$certdir" ] && echo "Error locating or installing SSL certificate." && exit 1
}
