#!/usr/bin/env bash
# Prepara a sessao na nuvem: deixa `godot` disponivel como binario headless.
# Idempotente: roda em toda sessao, so baixa se faltar.
set -euo pipefail

GODOT_VERSAO="${GODOT_VERSAO:-4.7.2-stable}"
DESTINO="${GODOT_DESTINO:-$HOME/.local/opt/godot}"
BIN="$DESTINO/godot"
LINK="$HOME/.local/bin/godot"

if [ -x "$BIN" ] && "$BIN" --version 2>/dev/null | grep -q "${GODOT_VERSAO%-stable}"; then
  echo "godot $GODOT_VERSAO ja instalado em $BIN"
else
  ARQ="Godot_v${GODOT_VERSAO}_linux.x86_64"
  URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSAO}/${ARQ}.zip"
  TMP="$(mktemp -d)"
  echo "baixando godot $GODOT_VERSAO ..."
  curl -fsSL --retry 4 --retry-delay 2 -o "$TMP/godot.zip" "$URL"
  unzip -q -o "$TMP/godot.zip" -d "$TMP"
  mkdir -p "$DESTINO"
  mv "$TMP/$ARQ" "$BIN"
  chmod +x "$BIN"
  rm -rf "$TMP"
  echo "godot instalado em $BIN"
fi

mkdir -p "$(dirname "$LINK")"
ln -sf "$BIN" "$LINK"
# /usr/local/bin ja esta no PATH de qualquer shell — evita depender de export.
if [ -w /usr/local/bin ] 2>/dev/null; then
  ln -sf "$BIN" /usr/local/bin/godot
elif command -v sudo >/dev/null 2>&1; then
  sudo ln -sf "$BIN" /usr/local/bin/godot 2>/dev/null || true
fi

# Godot headless ainda quer um HOME de configuracao gravavel.
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
mkdir -p "$XDG_DATA_HOME/godot"

"$BIN" --version
