#!/bin/sh
# Avvio mailserver: rsyslog (log) + Dovecot (IMAP) + Postfix (SMTP, foreground).
service rsyslog start 2>/dev/null || true
postfix check 2>/dev/null || true
newaliases 2>/dev/null || true
dovecot
exec postfix start-fg
