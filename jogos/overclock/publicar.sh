#!/usr/bin/env bash
# Sobe os builds para o itch.io. Exporta antes se precisar.
#   ITCH_ALVO=joabcostamd/meu-jogo ./publicar.sh
#   ./publicar.sh --so-conferir      mostra o que subiria, nao sobe
#
# Precisa de BUTLER_API_KEY no ambiente (itch.io → Settings → API keys).
set -uo pipefail
cd "$(dirname "$0")"

SO_CONFERIR=0
[ "${1:-}" = "--so-conferir" ] && SO_CONFERIR=1

ALVO="${ITCH_ALVO:-}"
if [ -z "$ALVO" ]; then
  echo "defina ITCH_ALVO=usuario/nome-do-jogo" >&2
  exit 2
fi

BUTLER="$(command -v butler 2>/dev/null || echo "$HOME/.local/bin/butler")"
if [ ! -x "$BUTLER" ] && [ $SO_CONFERIR -eq 0 ]; then
  echo "butler nao encontrado — rode: bash ../../.claude/scripts/preparar-butler.sh" >&2
  exit 127
fi
if [ -z "${BUTLER_API_KEY:-}" ] && [ $SO_CONFERIR -eq 0 ]; then
  echo "BUTLER_API_KEY nao definida" >&2
  exit 2
fi

# Versao: a tag do git se houver, senao a data + hash curto.
VERSAO="$(git describe --tags --exact-match 2>/dev/null || true)"
[ -z "$VERSAO" ] && VERSAO="$(date +%Y.%m.%d)-$(git rev-parse --short HEAD 2>/dev/null || echo local)"

# canal do itch  ←→  pasta do build
CANAIS="linux:build/linux windows:build/windows html5:build/web"

FALTA=0
for PAR in $CANAIS; do
  PASTA="${PAR#*:}"
  [ -d "$PASTA" ] && [ -n "$(ls -A "$PASTA" 2>/dev/null)" ] || FALTA=1
done
if [ $FALTA -eq 1 ]; then
  echo "build faltando — exportando primeiro"
  ./exportar.sh || exit 1
fi

echo "versao: $VERSAO"
FALHOU=0
for PAR in $CANAIS; do
  CANAL="${PAR%%:*}"; PASTA="${PAR#*:}"
  echo "── $PASTA → $ALVO:$CANAL ($(du -sh "$PASTA" | cut -f1))"
  if [ $SO_CONFERIR -eq 1 ]; then
    echo "   (so conferindo, nao subi)"
    continue
  fi
  "$BUTLER" push "$PASTA" "$ALVO:$CANAL" --userversion "$VERSAO" || FALHOU=1
done

echo
if [ $SO_CONFERIR -eq 1 ]; then
  echo "CONFERENCIA OK — rode sem --so-conferir para publicar"
elif [ $FALHOU -eq 0 ]; then
  echo "PUBLICADO: https://${ALVO%%/*}.itch.io/${ALVO#*/}"
  echo "Confira em maquina limpa antes de divulgar."
else
  echo "PUBLICACAO FALHOU"
fi
exit $FALHOU
