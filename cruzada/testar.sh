#!/usr/bin/env bash
# Suíte do CRUZADA. Hoje cobre a maquete de direção de arte; cresce com o jogo.
set -e
cd "$(dirname "$0")"

GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "MODO DEGRADADO — Godot não encontrado no PATH; rodando só os validadores"
  python3 ferramentas/medir_layout.py
  python3 ferramentas/validar_contraste.py
  exit 0
fi

echo "── capturas da maquete (8 temas × 3 modos) ──"
"$GODOT" --headless --import >/dev/null 2>&1 || true
# Captura exige display: em --headless o renderizador é nulo e não desenha nada.
if command -v xvfb-run >/dev/null 2>&1; then
  xvfb-run -a "$GODOT" --resolution 1280x720 res://maquete/capturas.tscn
else
  echo "CAPTURAS — puladas — xvfb ausente"
fi

echo
echo "── alvos de toque em todos os tamanhos ──"
python3 ferramentas/medir_layout.py

echo
echo "── contraste WCAG AA em todos os temas ──"
python3 ferramentas/validar_contraste.py
