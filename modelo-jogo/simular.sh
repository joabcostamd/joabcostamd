#!/usr/bin/env bash
# Monte Carlo determinístico das regras do jogo.
#   ./simular.sh                 2000 partidas nas fases 1, 3, 5 e 10
#   ./simular.sh 500 1 2 3       500 partidas nas fases 1, 2 e 3
set -uo pipefail
cd "$(dirname "$0")"
GODOT="${GODOT_BIN:-}"
case "$GODOT" in *'$'*) GODOT="" ;; esac
[ -x "$GODOT" ] || GODOT="$(command -v godot 2>/dev/null || true)"
[ -x "$GODOT" ] || GODOT="$HOME/.local/bin/godot"
[ -x "$GODOT" ] || { echo "godot nao encontrado — rode .claude/scripts/preparar-ambiente.sh" >&2; exit 127; }
exec "$GODOT" --headless --path . -s res://simulador/rodar.gd -- "$@"
