bsdmail_check_dns() {
	ipv4=$(host "$domain" | grep -m1 -Eo '([0-9]+\.){3}[0-9]+')
	[ -z "$ipv4" ] && echo "Please point your domain ($domain) to your server's ipv4 address." && exit 1

	ipv6=$(host "$domain" | grep "IPv6" | awk '{print $NF}')
	[ -z "$ipv6" ] && echo "Please point your domain ($domain) to your server's ipv6 address." && exit 1
}

bsdmail_dkim_public_value() {
	dkim_domain="$1"
	dkim_subdom="$2"

	tr -d '\n' <"$postfix_dir/dkim/$dkim_domain/$dkim_subdom.txt" |
		sed "s/k=rsa.* \"p=/k=rsa; p=/;s/\"\s*\"//;s/\"\s*).*//" |
		grep -o 'p=.*'
}

bsdmail_generate_dns_records() {
	pval="$(bsdmail_dkim_public_value "$domain" "$subdom")"

	dkimentry="$subdom._domainkey.$domain	TXT	v=DKIM1; k=rsa; $pval"
	dmarcentry="_dmarc.$domain	TXT	v=DMARC1; p=reject; rua=mailto:postmaster@$domain; fo=1"
	spfentry="$domain	TXT	v=spf1 mx a:$maildomain ip4:$ipv4 ip6:$ipv6 -all"
	mxentry="$domain	MX	10	$maildomain	300"

	printf '%s\n%s\n%s\n%s\n' "$dkimentry" "$dmarcentry" "$spfentry" "$mxentry"
}

bsdmail_save_dns_records() {
	outfile="$1"
	shift

	echo "NOTE: Elements in the entries might appear in a different order in your registrar's DNS settings." > "$outfile"
	bsdmail_generate_dns_records >> "$outfile"
}

bsdmail_print_dns_banner() {
	records="$(bsdmail_generate_dns_records)"

	printf "
            ,        ,
           /(        )\`
           \\ \\___   / |
           /- _  \`-/  '
          (/\\/ \\ \\   /\\
          / /   | \`    \\
          O O   ) /    |
          \`-^--'\`<     '
         (_.)  _  )   /
          \`.___/\`    /
            \`-----' /
 <----.     __ / __   \\
 <----|====O)))==) \\) /====
 <----'    \`--' \`.__,' \\
             |        |
              \\       /
         ______( (_  / \\______
       ,'  ,-----'   |        \\
       \`--{__________)        \\/


Add these DNS TXT records:

%s

The records have also been saved to ~/dns_bsdmail.

After adding them, check the README for account setup and login instructions.
\n" "$records"
}
