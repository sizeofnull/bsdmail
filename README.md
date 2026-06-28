# Email server setup script (FreeBSD)

This script installs an email server with all the features required in the
modern web.

## This script installs

- **Postfix** to send and receive mail.
- **Dovecot** to get mail to your email client (mutt, Thunderbird, etc.).
- Config files that link the two above securely with native PAM log-ins.
- **Spamassassin** to prevent spam and allow you to make custom filters.
- **OpenDKIM** to validate you so you can send to Gmail and other big sites.
- **Certbot** SSL certificates, if not already present.
- **fail2ban** to increase server security, with enabled modules for the above
  programs.
- (optionally) **a self-signed certificate** instead of OpenDKIM and Certbot. This allows to quickly set up an isolated mail server that collects email notifications from devices in the same local network(s) or serves as secure/private messaging system over VPN.

## Prerequisites for Installation

1. **FreeBSD** server
2. Set your domain before running:
   ```sh
   export MAIL_DOMAIN=example.com
   ```
3. DNS records that point at least your domain's `mail.` subdomain to your
   server's IP (IPv4 and IPv6). This is required on initial run for certbot to
   get an SSL certificate for your `mail.` subdomain.

## Running the script

```sh
git clone https://github.com/sizeofnull/bsdmail.git
chmod +x bsdmail.sh
export MAIL_DOMAIN=example.com
./bsdmail.sh
```

Services are enabled via `sysrc` and started with `service(8)`.

## Project layout

```
bsdmail.sh              Main entry point (orchestrates all modules)
lib/
  common.sh              Paths and shared helpers
  config.defaults.sh     User-editable options (selfsigned, ciphers, etc.)
  config.sh              Domain resolution
  install.sh             pkg installation
  firewall.sh            pf rules
  ssl.sh                 Certbot / self-signed certificates
  postfix.sh             Postfix main.cf and master.cf
  dovecot.sh             Dovecot and PAM
  opendkim.sh            DKIM keys and signing tables
  security.sh            SpamAssassin and fail2ban
  services.sh            sysrc and service restarts
  dns.sh                 DNS checks and record output
  finalize.sh            Postmaster user, cron, cert renewal hooks
```

To change install options (e.g. self-signed mode), edit `lib/config.defaults.sh`.

## Mandatory Finishing Touches

### Unblock your ports

While the script can add **pf** rules when `pf_enable=YES`, it is common practice
for VPS providers to block mail ports on their end by default. Open a help
ticket with your VPS provider asking them to open your mail ports.

If you use **pf**, ensure `/etc/pf.conf` includes the rules added under
`/usr/local/etc/bsdmail.pf.conf`, or add equivalent `pass` rules for ports
25, 80, 110, 465, 587, 993, and 995.

### DNS records

At the end of the script, you will be given some DNS records to add to your DNS
server/registrar's website. These are mostly for authenticating your emails as
non-spam. The 4 records are:

1. An MX record directing to `mail.yourdomain.tld`.
2. A TXT record for SPF (to reduce mail spoofing).
3. A TXT record for DMARC policies.
4. A TXT record with your public DKIM key. This record is long and **uniquely
   generated** while running `bsdmail.sh` and thus must be added after
   installation.

They will look something like this:

```
@	MX	10	mail.example.org
mail._domainkey.example.org    TXT     v=DKIM1; k=rsa; p=anextremelylongsequenceoflettersandnumbersgeneratedbyopendkim
_dmarc.example.org     TXT     v=DMARC1; p=reject; rua=mailto:dmarc@example.org; fo=1
example.org    TXT     v=spf1 mx a: -all
```

The script will create a file, `~/dns_bsdmail` that will list the records
for your convenience, and also prints them at the end of the script.

### Add a rDNS/PTR record as well!

Set a reverse DNS or PTR record to avoid getting spammed. You can do this at
your VPS provider, and should set it to `mail.yourdomain.tld`. Note that you
should set this for both IPv4 and IPv6.

## Making new users/mail accounts

Let's say we want to add a user foo and let him receive mail, run this:

```
pw useradd foo -m -s /usr/sbin/nologin
pw groupmod mail -m foo
passwd foo
```

Any user in the `mail` group will be able to receive mail.

## Installing with self-signed certificate, in "isolated" mode

This mode skips the setup of OpenDKIM and Certbot, and will instead create a self-signed cert that lasts 100 years.

Open `lib/config.defaults.sh` and change:

```
selfsigned="no" # yes no
```

to:

```
selfsigned="yes" # yes no
```

You can also set `use_cert_config="yes"` and fill in `country_name`,
`state_or_province_name`, and `organization_name` for automated certificate fields.

## Logging in from email clients (Thunderbird)

- SMTP server: `yourdomain.tld`
- SMTP port: 465
- IMAP server: `yourdomain.tld`
- IMAP port: 993

## Sites for Troubleshooting

Can't send or receive mail? Getting marked as spam?

- Check `/var/log/maillog` first for specific errors.
- [Check your DNS](https://intodns.com/)
- [Test your TXT records via mail](https://appmaildev.com/en/dkim)
- [Is your IP blacklisted?](https://mxtoolbox.com/blacklists.aspx)
- [mxtoolbox](https://mxtoolbox.com/SuperTool.aspx)

## FreeBSD paths reference

| Component   | Config / data                         |
|------------|----------------------------------------|
| Postfix    | `/usr/local/etc/postfix/`              |
| Dovecot    | `/usr/local/etc/dovecot/`              |
| OpenDKIM   | `/usr/local/etc/opendkim.conf`         |
| Let's Encrypt | `/usr/local/etc/letsencrypt/`       |
| fail2ban   | `/usr/local/etc/fail2ban/`             |
| Mail log   | `/var/log/maillog`                     |

Services: `postfix`, `dovecot`, `milter-opendkim`, `sa-spamd`, `fail2ban`.
