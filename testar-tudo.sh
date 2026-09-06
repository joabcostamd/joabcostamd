#!/usr/bin/env bash
# Roda o portao frio + a suite de TODOS os projetos Godot do repositorio.
#   ./testar-tudo.sh            verifica tudo
#   ./testar-tudo.sh picross    verifica so um
set -uo pipefail
cd "$(dirname "$0")"
RAIZ="$(pwd)"

GODOT="${GODOT_BIN:-}"
case "$GODOT" in *'$'*) GODOT="" ;; esac
[ -x "$GODOT" ] || GODOT="$(command -v godot 2>/dev/null || true)"
[ -x "$GODOT" ] || GODOT="$HOME/.local/bin/godot"
if [ ! -x "$GODOT" ]; then
  echo "godot nao encontrado — rodando o preparador..."
  bash .claude/scripts/preparar-ambiente.sh || exit 127
  GODOT="$HOME/.local/bin/godot"
fi
export GODOT_BIN="$GODOT"

ALVO="${1:-}"
if [ -n "$ALVO" ]; then
  PROJETOS="$ALVO"
else
  PROJETOS="$(find . -name project.godot -not -path './.git/*' -printf '%h\n' | sed 's|^\./||' | sort)"
fi

FALHOU=0
RESUMO=""
while read -r P; do
  [ -z "$P" ] && continue
  echo
  echo "════════ $P ════════"

  # o kit vem sempre da copia canonica — projeto nao fica com versao velha
  cp "$RAIZ/ferramentas/agent_verify.gd" "$P/agent_verify.gd"

  "$GODOT" --headless --path "$P" --import >/dev/null 2>&1
  "$GODOT" --headless --path "$P" --import >/dev/null 2>&1

  SAIDA="$("$GODOT" --headless --path "$P" -s res://agent_verify.gd 2>&1)"
  echo "$SAIDA" | sed -n '/===AGENT-VERIFY===/,/===FIM-AGENT-VERIFY===/p'
  if echo "$SAIDA" | grep -q '"status": "PASS"'; then
    ESTADO="portao OK"
  else
    ESTADO="PORTAO FALHOU"; FALHOU=1
  fi

  if [ -x "$P/testar.sh" ]; then
    if ( cd "$P" && ./testar.sh >/tmp/suite.log 2>&1 ); then
      ESTADO="$ESTADO · testes OK"
    else
      ESTADO="$ESTADO · TESTES FALHARAM"; FALHOU=1
      tail -30 /tmp/suite.log
    fi
  else
    ESTADO="$ESTADO · sem suite"
  fi
  RESUMO="$RESUMO\n  $P — $ESTADO"
done <<< "$PROJETOS"

echo
echo "════════ resumo ════════"
echo -e "$RESUMO"
echo
[ $FALHOU -eq 0 ] && echo "TUDO VERDE" || echo "HA FALHA ACIMA"
exit $FALHOU
