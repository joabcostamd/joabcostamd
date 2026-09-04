#!/usr/bin/env bash
# Recria o repositório game-placard a partir deste, de forma determinística.
#
# O PLACARD nasceu dentro do repositório de perfil do Joab, ao lado de outros
# três projetos. Este script extrai só o que é dele — com o histórico junto, não
# como um "commit inicial" sem memória — e monta a raiz do repositório próprio.
#
#     ferramentas/migrar.sh [destino]
#
# Depois:
#     cd <destino>
#     git remote add origin git@github.com:joabcostamd/game-placard.git
#     git push -u origin main
set -euo pipefail

ORIGEM="$(cd "$(dirname "$0")/../.." && pwd)"
DESTINO="${1:-/tmp/game-placard}"
RAMO="${RAMO:-claude/balatro-card-game-prompt-sorsgt}"

command -v git-filter-repo >/dev/null 2>&1 || {
    echo "Falta git-filter-repo:  pip install git-filter-repo"; exit 1; }

rm -rf "$DESTINO"
git clone --quiet --single-branch --branch "$RAMO" "$ORIGEM" "$DESTINO"
cd "$DESTINO"

# Fica só o que é do jogo. O README da raiz é a PÁGINA DE PERFIL do Joab e não
# vem junto — o repositório do jogo precisa de porta própria.
git filter-repo --force \
    --path cruzada --path cruzada-pesquisa --path PROMPT-JOGO-DE-CARTAS.md \
    --path .claude --path .gitignore --path .mcp.json

git branch -m main

# A raiz do repositório novo: os arquivos que moram em cruzada/ aqui porque
# aqui eles dividiriam a raiz com outros três projetos.
git mv cruzada/PORTA-DO-REPO.md README.md
git mv cruzada/CLAUDE.md CLAUDE.md
git mv cruzada/setup.sh setup.sh
# O migrar.sh não vem: ele migra DAQUI para lá, e lá não tem de onde migrar.
git rm -q cruzada/ferramentas/migrar.sh
git add -A

git -c user.email="joabcosta_md@hotmail.com" -c user.name="Joab Costa" \
    commit -q -m "Dá ao repositório do jogo o próprio chão

O PLACARD morava dentro do repositório de perfil, ao lado de outros três
projetos. Aqui ele tem casa própria: README que é a porta do jogo e não a
página do dono, CLAUDE.md com as convenções, setup.sh que prepara uma máquina
limpa e .mcp.json apontando para o servidor MCP Godot.

O histórico veio junto, filtrado para as pastas do jogo."

echo
echo "Pronto em $DESTINO — $(git rev-list --count HEAD) commits."
echo "Confira antes de empurrar:  cd $DESTINO/cruzada && ./testar.sh"
