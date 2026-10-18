# Nodo RED TEAM — toolbox offensiva (Kali) con SSH per accesso via Guacamole.
FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive

# Toolbox: ricognizione, brute force, web, exploit
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nmap hydra sqlmap ffuf gobuster nikto nuclei metasploit-framework \
        dnsutils iputils-ping netcat-traditional curl wget \
        openssh-server ca-certificates procps less vim \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/sshd /opt/wordlists

# Trivy (scan immagini/filesystem)
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
    | sh -s -- -b /usr/local/bin || true

# Wordlist minime che garantiscono il successo del brute force in demo
COPY users.txt     /opt/wordlists/users.txt
COPY passwords.txt /opt/wordlists/passwords.txt

# SSH: nodo interno al lab, accesso via Guacamole con root
RUN echo "root:redteam" | chpasswd \
    && sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Pre-cache template Nuclei (best-effort)
RUN nuclei -update-templates >/dev/null 2>&1 || true

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-e"]
