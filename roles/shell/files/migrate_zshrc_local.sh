#!/usr/bin/env bash
# Sposta in .zshrc.local le personalizzazioni presenti in .zshrc
# dopo il blocco gestito da Ansible (o, in assenza di marker, dopo PROMPT=).
set -euo pipefail

ZSHRC="${1:?}"
LOCAL="${2:?}"
MARKER_END='# <<< ansible-managed <<<'

[[ -f "$ZSHRC" ]] || exit 0

touch "$LOCAL"

if grep -qF "$MARKER_END" "$ZSHRC"; then
  EXTRA="$(awk -v m="$MARKER_END" '
    $0 == m { p = 1; next }
    p {
      if ($0 ~ /source[[:space:]].*\.zshrc\.local/) next
      if ($0 ~ /^# Override locali/) next
      print
    }
  ' "$ZSHRC")"
else
  # Compatibilità con .zshrc precedenti (senza marker)
  EXTRA="$(awk '
    /^PROMPT=/ { p = 1; next }
    p {
      if ($0 ~ /source[[:space:]].*\.zshrc\.local/) next
      if ($0 ~ /^# Override locali/) next
      print
    }
  ' "$ZSHRC")"
fi

# Solo whitespace → nulla da migrare
[[ -z "${EXTRA//[[:space:]]/}" ]] && exit 0

appended=0
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" ]] && continue
  if ! grep -qxF -- "$line" "$LOCAL"; then
    if [[ "$appended" -eq 0 ]]; then
      {
        echo ""
        echo "# Migrated from .zshrc by Ansible"
      } >> "$LOCAL"
      appended=1
    fi
    printf '%s\n' "$line" >> "$LOCAL"
  fi
done <<< "$EXTRA"

if [[ "$appended" -eq 1 ]]; then
  echo "MIGRATED"
fi
