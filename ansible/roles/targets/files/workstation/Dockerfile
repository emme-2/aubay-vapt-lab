# Workstation Linux "vittima" — SSH con credenziali deboli (didattico).
FROM debian:12-slim

ARG USER1=user1
ARG PASS1=changeme1
ARG USER2=user2
ARG PASS2=changeme2

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends openssh-server sudo ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/sshd

# Utenti con password deboli (presenti nelle wordlist comuni, di proposito)
RUN useradd -m -s /bin/bash "${USER1}" && echo "${USER1}:${PASS1}" | chpasswd && usermod -aG sudo "${USER1}" \
    && useradd -m -s /bin/bash "${USER2}" && echo "${USER2}:${PASS2}" | chpasswd

# SSH debole di proposito: password auth sì, root login no
RUN sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-e"]
