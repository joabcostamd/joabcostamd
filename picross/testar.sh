#!/usr/bin/env bash
# Suíte completa: dados (Python) + núcleo do jogo (Godot headless).
set -e
cd "$(dirname "$0")"
echo "── auditoria dos puzzles ──"
python3 ferramentas/testar_solucionador.py
python3 ferramentas/validar_bloco.py | tail -2
echo
echo "── núcleo do jogo ──"
godot --headless --import >/dev/null 2>&1 || true
godot --headless res://cenas/testes.tscn
echo
echo "── fluxo das telas ──"
godot --headless res://cenas/fluxo.tscn
