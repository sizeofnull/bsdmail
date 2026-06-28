#!/bin/sh

# BEFORE INSTALLING
#
# Have a FreeBSD server with a static IP and DNS records (usually A/AAAA)
# that point your domain name to it.
#
# AFTER INSTALLING
#
# More DNS records will be given to you to install. One of them will be
# different for every installation and is uniquely generated on your machine.

umask 0022

BSDMAIL_ROOT="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=lib/common.sh
. "$BSDMAIL_ROOT/lib/common.sh"
# shellcheck source=lib/config.sh
. "$BSDMAIL_ROOT/lib/config.sh"
# shellcheck source=lib/install.sh
. "$BSDMAIL_ROOT/lib/install.sh"
# shellcheck source=lib/firewall.sh
. "$BSDMAIL_ROOT/lib/firewall.sh"
# shellcheck source=lib/ssl.sh
. "$BSDMAIL_ROOT/lib/ssl.sh"
# shellcheck source=lib/postfix.sh
. "$BSDMAIL_ROOT/lib/postfix.sh"
# shellcheck source=lib/dovecot.sh
. "$BSDMAIL_ROOT/lib/dovecot.sh"
# shellcheck source=lib/opendkim.sh
. "$BSDMAIL_ROOT/lib/opendkim.sh"
# shellcheck source=lib/security.sh
. "$BSDMAIL_ROOT/lib/security.sh"
# shellcheck source=lib/services.sh
. "$BSDMAIL_ROOT/lib/services.sh"
# shellcheck source=lib/dns.sh
. "$BSDMAIL_ROOT/lib/dns.sh"
# shellcheck source=lib/finalize.sh
. "$BSDMAIL_ROOT/lib/finalize.sh"

bsdmail_load_config
bsdmail_check_dns
bsdmail_configure_pf
bsdmail_setup_ssl
bsdmail_verify_ssl
bsdmail_configure_postfix_main
bsdmail_configure_postfix_master
bsdmail_configure_dovecot
bsdmail_configure_opendkim
bsdmail_configure_postfix_milters
bsdmail_configure_security
bsdmail_enable_services
bsdmail_restart_services
bsdmail_finalize
