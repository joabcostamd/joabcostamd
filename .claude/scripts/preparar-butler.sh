#!/usr/bin/env bash
# Instala o butler (cliente de upload do itch.io). Sob demanda.
#   bash .claude/scripts/preparar-butler.sh
#
# ATENCAO: broth.itch.zone e BLOQUEADO pelo proxy de saida das sessoes na nuvem
# da Anthropic. Este script roda na maquina local do Joab e no GitHub Actions.
set -euo pipefail

DESTINO="${BUTLER_DESTINO:-$HOME/.local/opt/butler}"
BIN="$DESTINO/butler"
LINK="$HOME/.local/bin/butler"

if [ -x "$BIN" ]; then
  echo "butler ja instalado: $("$BIN" -V 2>&1 | head -1)"
else
  URL="https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default"
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  echo "baixando butler..."
  if ! curl -fL --retry 3 -o "$TMP/butler.zip" "$URL"; then
    echo "nao consegui baixar o butler." >&2
    echo "Na nuvem isso e esperado: broth.itch.zone esta bloqueado pelo proxy." >&2
    echo "Publique pelo workflow .github/workflows/publicar-itch.yml." >&2
    exit 4
  fi
  unzip -q -o "$TMP/butler.zip" -d "$DESTINO"
  chmod +x "$BIN"
fi

mkdir -p "$(dirname "$LINK")"
ln -sf "$BIN" "$LINK"
[ -w /usr/local/bin ] 2>/dev/null && ln -sf "$BIN" /usr/local/bin/butler
"$BIN" -V
