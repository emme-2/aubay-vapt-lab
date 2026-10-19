#!/usr/bin/env bash
# =====================================================================
#  Esegue una scansione VA (Nuclei dal nodo redteam) e aggiorna la
#  dashboard. Eseguito SUL SERVER.
#  Uso:  scan.sh [before|after]   (default: before)
# =====================================================================
set -euo pipefail

PHASE="${1:-before}"
case "$PHASE" in
  before) LABEL="Prima (baseline)";;
  after)  LABEL="Dopo remediation";;
  *) echo "Fase non valida: usa 'before' o 'after'"; exit 1;;
esac

DASH="/opt/vapt-lab/access/dashboard"
OUT="$DASH/results.json"
TARGETS=(http://web.corp.local http://proxy.corp.local http://juice.corp.local:3000)

echo ">> Scansione Nuclei [$PHASE] su ${#TARGETS[@]} target..."
UARGS=(); for t in "${TARGETS[@]}"; do UARGS+=(-u "$t"); done

# Nuclei gira dentro il nodo redteam (ha i template e vede le reti interne)
RAW=$(docker exec vapt-redteam nuclei "${UARGS[@]}" -silent -jsonl -duc 2>/dev/null || true)

# Conteggi per severità
counts=$(printf '%s\n' "$RAW" | jq -s '
  reduce .[] as $x ({critical:0,high:0,medium:0,low:0,info:0};
    .[$x.info.severity] = ((.[$x.info.severity] // 0) + 1))')

# Elenco rilevazioni (nome, severità, asset)
findings=$(printf '%s\n' "$RAW" | jq -s '[.[] | {
  name: .info.name,
  severity: .info.severity,
  host: (.host // ."matched-at" // .url)
}]')

run=$(jq -n --arg l "$LABEL" --argjson c "$counts" --argjson f "$findings" \
  '{label:$l, counts:$c, findings:$f}')

base='{"runs":{}}'; [ -f "$OUT" ] && base=$(cat "$OUT")
echo "$base" | jq --arg p "$PHASE" --argjson r "$run" --arg ts "$(date -Is)" \
  '.generated=$ts | .runs[$p]=$r' > "$OUT.tmp" && mv "$OUT.tmp" "$OUT"

tot=$(echo "$counts" | jq 'to_entries|map(.value)|add')
echo ">> Fatto. Rilevazioni totali [$PHASE]: ${tot:-0}"
echo ">> Dashboard aggiornata: apri  https://<IP>/dashboard/  (scheda '$PHASE')"
