#!/usr/bin/env bash
# Deixa a sessão da nuvem pronta para trabalhar nos jogos Godot deste repo.
# Idempotente: se o Godot já estiver no lugar, sai na hora.
set -euo pipefail

VERSAO="4.7.2-stable"
DESTINO="$HOME/.local/bin"
BIN="$DESTINO/godot"

mkdir -p "$DESTINO"

if [ -x "$BIN" ] && "$BIN" --version >/dev/null 2>&1; then
  echo "godot $($BIN --version 2>/dev/null | head -1) já pronto"
  exit 0
fi

ARQUIVO="Godot_v${VERSAO}_linux.x86_64"
URL="https://github.com/godotengine/godot/releases/download/${VERSAO}/${ARQUIVO}.zip"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "baixando godot ${VERSAO}…"
for tentativa in 1 2 3; do
  if curl -sSL --fail -o "$TMP/godot.zip" "$URL"; then break; fi
  echo "  tentativa $tentativa falhou, repetindo…" >&2
  sleep $((tentativa * 3))
done

[ -s "$TMP/godot.zip" ] || { echo "não consegui baixar o godot" >&2; exit 1; }

unzip -q -o "$TMP/godot.zip" -d "$TMP"
mv "$TMP/${ARQUIVO}" "$BIN"
chmod +x "$BIN"

echo "godot $("$BIN" --version 2>/dev/null | head -1) instalado em $BIN"
