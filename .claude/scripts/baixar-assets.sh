#!/usr/bin/env bash
# Traz um pacote de assets CC0 (Kenney e afins) para dentro de um jogo, ja
# configurado e catalogado.
#
#   .claude/scripts/baixar-assets.sh <slug-kenney|url-do-zip> <destino> [--pixel]
#
#   .claude/scripts/baixar-assets.sh pixel-platformer jogos/meu/assets/kenney --pixel
#   .claude/scripts/baixar-assets.sh https://exemplo/pack.zip jogos/meu/assets/x
#
# --pixel  liga filtro Nearest no projeto (pixel art nao pode ser borrada)
#
# ATENCAO: kenney.nl e BLOQUEADO pelo proxy das sessoes na nuvem da Anthropic.
# Aqui o caminho e o workflow .github/workflows/assets.yml, que roda num runner
# do GitHub (internet aberta) e commita o resultado — a nuvem le por git.
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"
FONTE="${1:-}"
DESTINO="${2:-}"
PIXEL=0
[ "${3:-}" = "--pixel" ] && PIXEL=1

if [ -z "$FONTE" ] || [ -z "$DESTINO" ]; then
  echo "uso: $0 <slug-kenney|url-do-zip> <destino> [--pixel]" >&2
  exit 2
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

case "$FONTE" in
  http*) URL="$FONTE" ;;
  *)
    PAGINA="https://kenney.nl/assets/$FONTE"
    echo "procurando o zip em $PAGINA"
    HTML="$(curl -fsSL --retry 3 "$PAGINA")" || {
      echo "nao consegui abrir $PAGINA" >&2
      echo "Se voce esta numa sessao na nuvem, kenney.nl esta bloqueado:" >&2
      echo "use o workflow assets.yml (Actions → Trazer assets)." >&2
      exit 4
    }
    URL="$(printf '%s' "$HTML" | grep -oE 'https://[^"]+\.zip' | head -1)"
    [ -z "$URL" ] && { echo "nenhum .zip encontrado em $PAGINA" >&2; exit 5; }
    ;;
esac

echo "baixando $URL"
curl -fL --retry 3 --progress-bar -o "$TMP/pack.zip" "$URL"

mkdir -p "$DESTINO"
unzip -q -o "$TMP/pack.zip" -d "$DESTINO"
# lixo que vem nos pacotes e nao serve para nada dentro do jogo
find "$DESTINO" -iname "*.html" -o -iname "Sample.png" -o -iname "Preview.png" | xargs -r rm -f
find "$DESTINO" -type d -empty -delete

echo "$(find "$DESTINO" -type f | wc -l) arquivos em $DESTINO"

# --- projeto Godot que recebeu os assets ---
PROJ="$DESTINO"
while [ "$PROJ" != "/" ] && [ ! -f "$PROJ/project.godot" ]; do PROJ="$(dirname "$PROJ")"; done

if [ -f "$PROJ/project.godot" ]; then
  if [ $PIXEL -eq 1 ] && ! grep -q 'default_texture_filter' "$PROJ/project.godot"; then
    printf '\n[rendering]\n\ntextures/canvas_textures/default_texture_filter=0\n' >> "$PROJ/project.godot"
    echo "filtro Nearest ligado — pixel art nao vai borrar"
  fi
  echo "LFS: confira se .gitattributes ja descomentou o bloco antes de commitar binario grande"
  python3 "$RAIZ/ferramentas/catalogo_assets.py" "$PROJ"
else
  echo "aviso: nao achei project.godot acima de $DESTINO — catalogo nao gerado" >&2
fi
