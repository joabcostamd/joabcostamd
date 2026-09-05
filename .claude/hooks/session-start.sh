#!/usr/bin/env bash
# SessionStart: deixa a sessao da nuvem pronta para Godot sem ninguem pedir.
# Nao pode falhar a sessao — qualquer erro vira aviso.
set -uo pipefail
RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"

if bash "$RAIZ/.claude/scripts/preparar-ambiente.sh" >/tmp/preparar-godot.log 2>&1; then
  VER="$("$HOME/.local/bin/godot" --version 2>/dev/null | head -1)"
  echo "Godot pronto: $VER  (binario em ~/.local/bin/godot)"
else
  echo "Godot NAO pode ser preparado. Veja /tmp/preparar-godot.log"
fi

echo "Jogo novo em um comando: .claude/scripts/novo-jogo.sh <slug> \"Nome\""
