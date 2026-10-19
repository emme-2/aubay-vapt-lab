# Desktop grafico "postazione utente" — XFCE + browser, accesso VNC via Guacamole.
# Serve al walk-through visivo per personale non tecnico.
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      xvfb x11vnc dbus-x11 x11-xserver-utils \
      xfce4-session xfwm4 xfce4-panel xfdesktop4 xfce4-terminal \
      firefox-esr ca-certificates fonts-dejavu \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash demo \
    && mkdir -p /home/demo/.vnc \
    && chown -R demo:demo /home/demo

COPY start.html /home/demo/start.html
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && chown demo:demo /home/demo/start.html

USER demo
ENV HOME=/home/demo VNC_PASSWORD=demo VNC_GEOMETRY=1360x768
EXPOSE 5900
CMD ["/usr/local/bin/entrypoint.sh"]
