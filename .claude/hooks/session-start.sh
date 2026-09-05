#!/usr/bin/env bash
# Prepara a sessão da nuvem: instala o Godot e deixa o PATH pronto.
set -euo pipefail

# Na máquina local o Godot já está instalado — não mexe em nada.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

RAIZ="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

"$RAIZ/scripts/preparar-nuvem.sh" || {
  echo "aviso: não consegui preparar o Godot; os testes headless vão falhar" >&2
}

# Deixa o godot no PATH pelo resto da sessão.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$CLAUDE_ENV_FILE"
fi

# Gera o índice de API do Godot (usado por scripts/api.py contra alucinação).
if [ ! -f "$HOME/.cache/godot-api/extension_api.json" ]; then
  "$RAIZ/scripts/api.py" --tem Node2D position >/dev/null 2>&1 || true
fi
