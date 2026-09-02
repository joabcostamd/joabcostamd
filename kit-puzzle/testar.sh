#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
godot --headless --import >/dev/null 2>&1 || true
godot --headless -- --testes
