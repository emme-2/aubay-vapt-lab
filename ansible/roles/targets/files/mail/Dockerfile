# Mailserver didattico: Postfix (SMTP, debolezze volute) + Dovecot (IMAP) con
# caselle precaricate per il walk-through.
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       postfix dovecot-imapd rsyslog ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY main.cf /etc/postfix/main.cf
COPY dovecot.conf /etc/dovecot/dovecot.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Caselle di posta (utenti di sistema, auth IMAP via PAM)
RUN useradd -m -s /usr/sbin/nologin jdoe   && echo "jdoe:Password1"  | chpasswd \
 && useradd -m -s /usr/sbin/nologin mrossi && echo "mrossi:qwerty"   | chpasswd

# Precarica i messaggi nella Maildir di jdoe
COPY seed/jdoe/ /tmp/seed-jdoe/
RUN set -e; \
    mkdir -p /home/jdoe/Maildir/new /home/jdoe/Maildir/cur /home/jdoe/Maildir/tmp; \
    i=1; for f in /tmp/seed-jdoe/*.eml; do \
      cp "$f" "/home/jdoe/Maildir/new/$(date +%s).M${i}.mailsrv"; i=$((i+1)); \
    done; \
    chown -R jdoe:jdoe /home/jdoe/Maildir; \
    rm -rf /tmp/seed-jdoe

EXPOSE 25 143
CMD ["/usr/local/bin/entrypoint.sh"]
