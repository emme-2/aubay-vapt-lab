# Mailserver didattico: Postfix permissivo (enumerazione SMTP, banner leak).
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends postfix rsyslog ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY main.cf /etc/postfix/main.cf

EXPOSE 25
CMD ["sh", "-c", "postfix check 2>/dev/null; newaliases 2>/dev/null; service rsyslog start 2>/dev/null; exec postfix start-fg"]
