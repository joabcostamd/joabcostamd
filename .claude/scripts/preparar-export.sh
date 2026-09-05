#!/usr/bin/env bash
# Instala os templates de export do Godot (~1,2 GB). Sob demanda, NAO no hook de
# sessao: so faz sentido quando o pedido e gerar executavel.
#   bash .claude/scripts/preparar-export.sh
set -euo pipefail

GODOT_VERSAO="${GODOT_VERSAO:-4.7.2-stable}"
# o Godot procura em <versao com ponto>, ex.: 4.7.2.stable
PASTA_VERSAO="${GODOT_VERSAO%-stable}.stable"
DESTINO="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$PASTA_VERSAO"

if [ -f "$DESTINO/linux_release.x86_64" ]; then
  echo "templates $PASTA_VERSAO ja instalados em $DESTINO"
  exit 0
fi

URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSAO}/Godot_v${GODOT_VERSAO}_export_templates.tpz"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "baixando templates de export ($GODOT_VERSAO, ~1,2 GB)..."
curl -fL --retry 4 --retry-delay 2 --progress-bar -o "$TMP/tpl.tpz" "$URL"

echo "extraindo..."
unzip -q "$TMP/tpl.tpz" -d "$TMP"
mkdir -p "$DESTINO"
mv "$TMP"/templates/* "$DESTINO/"

echo "templates em $DESTINO"
ls "$DESTINO" | head -8
echo "... ($(ls "$DESTINO" | wc -l) arquivos)"
