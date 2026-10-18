#!/usr/bin/env bash
# =====================================================================
#  Verifica che i target rispondano sulle rispettive reti interne.
#  Usa un container usa-e-getta (netshoot) agganciato a ciascuna rete.
# =====================================================================
set -u
NET_DC=vapt_datacenter
NET_US=vapt_users
IMG=nicolaka/netshoot

run_dc() { docker run --rm --network "$NET_DC" "$IMG" "$@"; }
run_us() { docker run --rm --network "$NET_US" "$IMG" "$@"; }

echo "== DATACENTER (${NET_DC}) =="
run_dc curl -s -o /dev/null -w "  DVWA        web.corp.local      -> HTTP %{http_code}\n"  http://web.corp.local        || echo "  DVWA        -> non raggiungibile"
run_dc curl -s -o /dev/null -w "  Juice Shop  juice.corp.local    -> HTTP %{http_code}\n"  http://juice.corp.local:3000 || echo "  Juice Shop  -> non raggiungibile"
run_dc curl -s -o /dev/null -w "  Proxy       proxy.corp.local    -> HTTP %{http_code}\n"  http://proxy.corp.local      || echo "  Proxy       -> non raggiungibile"
run_dc bash -c 'printf "QUIT\r\n" | nc -w3 mail.corp.local 25 | head -1 | tr -d "\r" | sed "s/^/  Mail        mail.corp.local:25  -> /"' || echo "  Mail        -> non raggiungibile"

echo "== UTENTI (${NET_US}) =="
for ws in ws01 ws02; do
  run_us bash -c "nc -z -w3 ${ws}.corp.local 22 && echo '  ${ws}.corp.local:22    -> SSH aperto' || echo '  ${ws}.corp.local:22    -> chiuso'"
done

echo
echo "Suggerimento: la prima volta DVWA va inizializzato da /setup.php (login admin/password)."
