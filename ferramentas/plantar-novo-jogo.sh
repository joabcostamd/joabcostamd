#!/usr/bin/env bash
# A skill novo-jogo precisa funcionar de QUALQUER pasta, nas duas maquinas.
# Este script planta as copias em dois lugares:
#
#   1. .claude/skills/novo-jogo/        — escopo do projeto, viaja por git
#   2. ~/.claude/skills/novo-jogo/      — escopo do usuario, vale em qualquer pasta
#
# Canonico: planejamento-jogo-novo/. NUNCA edite as copias.
set -euo pipefail
R="$(cd "$(dirname "$0")/.." && pwd)"
ORIGEM="$R/planejamento-jogo-novo"
NO_REPO="$R/.claude/skills/novo-jogo"

plantar() {
  local D="$1"
  mkdir -p "$D"
  cp "$ORIGEM/BLOCOS.md"        "$D/BLOCOS.md"
  cp "$ORIGEM/PERGUNTAS.md"     "$D/PERGUNTAS.md"
  cp "$ORIGEM/portao-plano.py"  "$D/portao-plano.py"
  cp "$ORIGEM/novo-plano.py"    "$D/novo-plano.py"
  rm -rf "$D/modelos"
  cp -r "$ORIGEM/modelos"       "$D/modelos"
  chmod +x "$D/portao-plano.py" "$D/novo-plano.py"
  echo "plantado em $D"
}

plantar "$NO_REPO"

# escopo do usuario: e o que faz /novo-jogo funcionar fora deste repositorio
USUARIO="${CLAUDE_SKILLS_USUARIO:-$HOME/.claude/skills}/novo-jogo"
if [ "${1:-}" = "--so-repo" ]; then
  echo "pulando o escopo do usuario (--so-repo)"
else
  cp "$NO_REPO/SKILL.md" /tmp/novo-jogo-SKILL.md 2>/dev/null || true
  plantar "$USUARIO"
  cp "$NO_REPO/SKILL.md" "$USUARIO/SKILL.md"
  echo "a skill agora vale em qualquer pasta: $USUARIO"
fi
