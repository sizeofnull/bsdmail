bsdmail_configure_pf() {
	[ "$(sysrc -n pf_enable 2>/dev/null)" != "YES" ] && return 0

	pf_rules="/usr/local/etc/bsdmail.pf.conf"
	grep -q 'bsdmail mail ports' "$pf_rules" 2>/dev/null && return 0

	cat <<'EOF' >> "$pf_rules"
# bsdmail mail ports
pass in quick proto tcp to port { 25, 80, 110, 465, 587, 993, 995 }
EOF

	grep -q 'bsdmail.pf.conf' /etc/pf.conf 2>/dev/null ||
		echo 'include "/usr/local/etc/bsdmail.pf.conf"' >> /etc/pf.conf

	pfctl -f /etc/pf.conf 2>/dev/null
}
