#!/bin/bash
# Avvio desktop: Xvfb + XFCE + Firefox + x11vnc.
set -e
export HOME=/home/demo
export DISPLAY=:0
GEO="${VNC_GEOMETRY:-1360x768}"
PASS="${VNC_PASSWORD:-demo}"

# Server X virtuale
Xvfb :0 -screen 0 "${GEO}x24" >/dev/null 2>&1 &
sleep 2

# Sessione desktop XFCE
dbus-launch xfce4-session >/dev/null 2>&1 &
sleep 3

# Browser aperto sulla pagina di lancio della demo
firefox-esr file:///home/demo/start.html >/dev/null 2>&1 &

# Server VNC (porta 5900) con password
mkdir -p "$HOME/.vnc"
x11vnc -storepasswd "$PASS" "$HOME/.vnc/passwd" >/dev/null 2>&1
exec x11vnc -display :0 -rfbauth "$HOME/.vnc/passwd" -rfbport 5900 \
     -forever -shared -noxdamage -repeat >/dev/null 2>&1
