#!/usr/bin/env bash
# Roda a suíte de testes sem tela nenhuma. Serve na nuvem e na sua máquina.
set -e
cd "$(dirname "$0")"
godot --headless --import >/dev/null 2>&1 || true
godot --headless -- --testes
