#!/usr/bin/env bash
# A skill auditar-jogo precisa funcionar sozinha, fora deste repositorio.
# Este script planta a regua e o coletor dentro da pasta da skill.
# Canonico: AUDITORIA.md e ferramentas/auditar.sh da raiz. Nunca edite as copias.
set -euo pipefail
R="$(cd "$(dirname "$0")/.." && pwd)"
D="$R/.claude/skills/auditar-jogo"
mkdir -p "$D"
cp "$R/AUDITORIA.md"        "$D/AUDITORIA.md"
cp "$R/ferramentas/auditar.sh" "$D/auditar.sh"
chmod +x "$D/auditar.sh"
echo "plantado em $D: AUDITORIA.md, auditar.sh"
