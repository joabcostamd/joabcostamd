#!/usr/bin/env bash
# Roda a suíte de todos os jogos do repo. Sem tela, do começo ao fim.
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"
cd "$(dirname "$0")/.."

command -v godot >/dev/null || { echo "godot não encontrado — rode scripts/preparar-nuvem.sh"; exit 1; }
echo "godot $(godot --version 2>/dev/null | head -1)"
echo

FALHAS=0
for projeto in */testar.sh; do
  jogo="$(dirname "$projeto")"
  printf '══ %s ══\n' "$jogo"
  if timeout 600 "./$projeto" >/tmp/saida-$$.txt 2>&1; then
    grep -E "OK —|PASSARAM" /tmp/saida-$$.txt || echo "  passou"
  else
    echo "  FALHOU:"
    tail -20 /tmp/saida-$$.txt | sed 's/^/  /'
    FALHAS=$((FALHAS + 1))
  fi
  echo
done
rm -f /tmp/saida-$$.txt

if [ "$FALHAS" -eq 0 ]; then echo "TUDO VERDE"; else echo "$FALHAS projeto(s) com falha"; fi
exit "$FALHAS"
