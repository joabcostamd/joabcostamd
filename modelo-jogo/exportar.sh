#!/usr/bin/env bash
# Gera o executavel. Passa pelo portao antes — nao se exporta projeto vermelho.
#   ./exportar.sh              Linux, Windows e Web
#   ./exportar.sh Web          so um preset
#   ./exportar.sh --debug Web  build de depuracao
set -uo pipefail
cd "$(dirname "$0")"

GODOT="${GODOT_BIN:-}"
case "$GODOT" in *'$'*) GODOT="" ;; esac
[ -x "$GODOT" ] || GODOT="$(command -v godot 2>/dev/null || true)"
[ -x "$GODOT" ] || GODOT="$HOME/.local/bin/godot"
[ -x "$GODOT" ] || { echo "godot nao encontrado — rode .claude/scripts/preparar-ambiente.sh" >&2; exit 127; }

MODO="--export-release"
if [ "${1:-}" = "--debug" ]; then MODO="--export-debug"; shift; fi

VERSAO="$("$GODOT" --version | cut -d. -f1-3)"
TEMPLATES="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${VERSAO}.stable"
if [ ! -f "$TEMPLATES/linux_release.x86_64" ]; then
  echo "templates de export faltando em $TEMPLATES" >&2
  echo "rode: bash ../../.claude/scripts/preparar-export.sh" >&2
  exit 3
fi

echo "── portao antes de exportar ──"
if ! ./testar.sh >/tmp/pre-export.log 2>&1; then
  echo "projeto vermelho — nao vou exportar. Veja /tmp/pre-export.log" >&2
  tail -25 /tmp/pre-export.log >&2
  exit 1
fi
echo "verde."

PRESETS=("$@")
if [ ${#PRESETS[@]} -eq 0 ]; then PRESETS=("Linux" "Windows" "Web"); fi

FALHOU=0
for P in "${PRESETS[@]}"; do
  # o Godot NAO cria a pasta de destino sozinho — ele so falha
  ALVO="$(grep -A20 "name=\"$P\"" export_presets.cfg | grep -m1 '^export_path=' | cut -d'"' -f2)"
  [ -n "$ALVO" ] && mkdir -p "$(dirname "$ALVO")"

  echo "── exportando $P → $ALVO ──"
  if "$GODOT" --headless --path . $MODO "$P" >/tmp/export-$P.log 2>&1; then
    if [ -s "$ALVO" ]; then
      echo "   ok  $(du -h "$ALVO" | cut -f1)"
    else
      echo "   FALHOU: o Godot disse que deu certo mas o arquivo nao existe" >&2
      FALHOU=1
    fi
  else
    echo "   FALHOU (veja /tmp/export-$P.log)" >&2
    grep -i error /tmp/export-$P.log | head -5 >&2
    FALHOU=1
  fi
done

echo
[ $FALHOU -eq 0 ] && echo "EXPORT OK" || echo "EXPORT FALHOU"
exit $FALHOU
