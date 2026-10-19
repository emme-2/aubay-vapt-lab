#!/usr/bin/env bash
# =====================================================================
#  Crea in Guacamole le connessioni SSH ai nodi del lab (REST API).
#  Eseguito SUL SERVER. Idempotente: salta quelle già presenti.
#  Argomenti opzionali: $1 = utente Guacamole, $2 = password
#  (default guacadmin/guacadmin — se l'hai cambiata, passala).
# =====================================================================
set -euo pipefail

GUAC="https://127.0.0.1/guacamole"
GUSER="${1:-guacadmin}"
GPASS="${2:-guacadmin}"

echo "Autenticazione a Guacamole come '$GUSER'..."
RESP=$(curl -sk -X POST "$GUAC/api/tokens" \
  --data-urlencode "username=$GUSER" --data-urlencode "password=$GPASS")
TOKEN=$(echo "$RESP" | jq -r '.authToken // empty')
DS=$(echo "$RESP" | jq -r '.dataSource // "postgresql"')

if [ -z "$TOKEN" ]; then
  echo "ERRORE: login Guacamole fallito."
  echo "Se hai cambiato la password di guacadmin:  make seed-guac GUAC_PASS=latuapassword"
  exit 1
fi
echo "OK (dataSource=$DS)."

EXISTING=$(curl -sk "$GUAC/api/session/data/$DS/connections?token=$TOKEN" | jq -r '.[].name' 2>/dev/null || true)

create_conn() {
  local name="$1" host="$2" port="$3" user="$4" pass="$5"
  if printf '%s\n' "$EXISTING" | grep -qxF "$name"; then
    echo "  = '$name' già presente"
    return
  fi
  curl -sk -X POST "$GUAC/api/session/data/$DS/connections?token=$TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"parentIdentifier\":\"ROOT\",\"name\":\"$name\",\"protocol\":\"ssh\",\"parameters\":{\"hostname\":\"$host\",\"port\":\"$port\",\"username\":\"$user\",\"password\":\"$pass\"},\"attributes\":{}}" \
    >/dev/null && echo "  + '$name' creata"
}

create_vnc() {
  local name="$1" host="$2" port="$3" pass="$4"
  if printf '%s\n' "$EXISTING" | grep -qxF "$name"; then
    echo "  = '$name' già presente"
    return
  fi
  curl -sk -X POST "$GUAC/api/session/data/$DS/connections?token=$TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"parentIdentifier\":\"ROOT\",\"name\":\"$name\",\"protocol\":\"vnc\",\"parameters\":{\"hostname\":\"$host\",\"port\":\"$port\",\"password\":\"$pass\"},\"attributes\":{}}" \
    >/dev/null && echo "  + '$name' creata"
}

VNCPASS="${3:-demo}"   # password VNC del desktop (default: demo)

echo "Creo le connessioni..."
create_conn "redteam (Kali)" 172.20.30.10 22 root   redteam
create_conn "ws01 (jdoe)"    172.20.20.11 22 jdoe   Password1
create_conn "ws02 (mrossi)"  172.20.20.12 22 mrossi qwerty
create_vnc  "Desktop utente (walk-through)" 172.20.20.20 5900 "$VNCPASS"

echo "Fatto. Ricarica Guacamole nel browser: le connessioni sono nella home."
