#!/bin/bash
# Avvio desktop: TigerVNC (X+VNC) + XFCE + Firefox. Log attivi.
# SecurityTypes None: il desktop è interno alla rete Docker, dietro Guacamole
# e firewall, mai esposto. Nessuna password VNC da gestire.
set -x
export HOME=/home/demo
export DISPLAY=:0
GEO="${VNC_GEOMETRY:-1360x768}"

# Server X + VNC integrato (TigerVNC) in background, su tutte le interfacce
Xtigervnc :0 -geometry "$GEO" -depth 24 -rfbport 5900 -localhost no \
  -SecurityTypes None -AlwaysShared -desktop lab &
XPID=$!

# Attendi che il display sia pronto
for i in $(seq 1 40); do
  xdpyinfo -display :0 >/dev/null 2>&1 && break
  sleep 0.5
done

# Sessione desktop XFCE
dbus-launch --exit-with-session xfce4-session &

# Browser sulla pagina di lancio (ritardato)
( sleep 4; firefox-esr file:///home/demo/start.html ) &

# Il container resta vivo finché vive il server X/VNC
wait "$XPID"
