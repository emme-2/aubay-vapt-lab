# Desktop grafico "postazione utente" — XFCE + browser + client mail (walk-through).
# Server grafico: TigerVNC (X + VNC integrati, robusto headless non-root).
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      tigervnc-standalone-server tigervnc-common x11-utils \
      dbus-x11 \
      xfce4-session xfwm4 xfce4-panel xfdesktop4 xfce4-terminal thunar \
      firefox-esr thunderbird ca-certificates fonts-dejavu \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /tmp/.X11-unix /tmp/.ICE-unix \
    && chmod 1777 /tmp/.X11-unix /tmp/.ICE-unix

RUN useradd -m -s /bin/bash demo \
    && mkdir -p /home/demo/.vnc /home/demo/Desktop \
    && chown -R demo:demo /home/demo

COPY start.html /home/demo/start.html
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# Profilo Thunderbird preconfigurato sulla casella del lab
COPY thunderbird/profiles.ini /home/demo/.thunderbird/profiles.ini
COPY thunderbird/prefs.js      /home/demo/.thunderbird/demo.default/prefs.js
# Icona cliccabile sul desktop (apertura manuale, non autostart)
COPY thunderbird/mail.desktop  /home/demo/Desktop/mail.desktop

RUN chmod +x /usr/local/bin/entrypoint.sh /home/demo/Desktop/mail.desktop \
    && chown -R demo:demo /home/demo/start.html /home/demo/.thunderbird /home/demo/Desktop

USER demo
ENV HOME=/home/demo VNC_PASSWORD=demo VNC_GEOMETRY=1360x768
EXPOSE 5900
CMD ["/usr/local/bin/entrypoint.sh"]
