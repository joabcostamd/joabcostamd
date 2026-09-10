#!/usr/bin/env bash
# Portao frio + suite de testes. Sai != 0 se qualquer um falhar.
set -uo pipefail
cd "$(dirname "$0")"
# Resolve o binario sem confiar em variavel de ambiente mal expandida.
GODOT="${GODOT_BIN:-}"
case "$GODOT" in *'$'*) GODOT="" ;; esac
[ -x "$GODOT" ] || GODOT="$(command -v godot 2>/dev/null || true)"
[ -x "$GODOT" ] || GODOT="$HOME/.local/bin/godot"
if [ ! -x "$GODOT" ]; then
  echo "godot nao encontrado. Rode: bash .claude/scripts/preparar-ambiente.sh" >&2
  exit 127
fi

echo "── importando recursos ──"
# Duas passadas de proposito: na primeira o cache de classes globais
# (.godot/global_script_class_cache.cfg) ainda nao existe, entao todo
# `class_name` some e os autoloads falham. A segunda ja enxerga tudo.
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true

echo "── portao frio (agent_verify) ──"
SAIDA_V="$("$GODOT" --headless --path . -s res://agent_verify.gd 2>&1)"
echo "$SAIDA_V" | sed -n '/===AGENT-VERIFY===/,/===FIM-AGENT-VERIFY===/p'
echo "$SAIDA_V" | grep -q '"status": "PASS"' && V=0 || V=1

echo
echo "── testes ──"
SAIDA_T="$("$GODOT" --headless --path . -s res://testes/executar.gd 2>&1)"
echo "$SAIDA_T" | sed -n '/===TESTES===/,/===FIM-TESTES===/p'
echo "$SAIDA_T" | grep -q '"status": "PASS"' && T=0 || T=1

echo
if [ $V -eq 0 ] && [ $T -eq 0 ]; then
  echo "TUDO VERDE"
  exit 0
fi
echo "FALHOU (portao=$V testes=$T)"
exit 1
