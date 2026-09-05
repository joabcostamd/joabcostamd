#!/usr/bin/env bash
# Cria um jogo novo a partir de modelo-jogo/ — pronto, verde e testado.
#
#   .claude/scripts/novo-jogo.sh <slug> "Nome do Jogo"
#
# Ex.: .claude/scripts/novo-jogo.sh corrida-neon "Corrida Neon"
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"
SLUG="${1:-}"
NOME="${2:-}"

if [ -z "$SLUG" ]; then
  echo "uso: $0 <slug> [\"Nome do Jogo\"]" >&2
  exit 2
fi
if ! [[ "$SLUG" =~ ^[a-z0-9-]+$ ]]; then
  echo "slug so aceita minusculas, numeros e hifen: $SLUG" >&2
  exit 2
fi
[ -z "$NOME" ] && NOME="$SLUG"

DESTINO="$RAIZ/jogos/$SLUG"
if [ -e "$DESTINO" ]; then
  echo "ja existe: $DESTINO" >&2
  exit 1
fi

mkdir -p "$RAIZ/jogos"
cp -r "$RAIZ/modelo-jogo" "$DESTINO"
rm -rf "$DESTINO/.godot" "$DESTINO/.verify"

# kit de verificacao sempre vem da copia canonica
cp "$RAIZ/ferramentas/agent_verify.gd" "$DESTINO/agent_verify.gd"
cp "$RAIZ/ferramentas/gitattributes-godot" "$DESTINO/.gitattributes"

sed -i "s|^config/name=.*|config/name=\"$NOME\"|" "$DESTINO/project.godot"

HOJE="$(date +%Y-%m-%d)"
cat > "$DESTINO/CONCEITO.md" <<CONC
# $NOME — conceito

Data: $HOJE

## O jogo em uma frase
<o que o JOGADOR faz, não o que o jogo é>

## Loop principal
1. <ação>
2. <consequência>
3. <recompensa que puxa de volta ao passo 1>

## Uma partida dura
<minutos>

## O que NÃO tem
- sem multijogador
- sem mundo aberto
- sem árvore de habilidades
- <acrescente o que este jogo recusa>

## Como sei que está bom
<critério observável, não "ser divertido">
CONC

cat > "$DESTINO/README.md" <<RM
# $NOME

<uma frase>

## Rodar
\`\`\`bash
godot --path .                 # abrir
./testar.sh                    # portão frio + testes (headless)
\`\`\`

Conceito em [CONCEITO.md](CONCEITO.md).
RM

echo "criado: jogos/$SLUG"
echo "validando..."
( cd "$DESTINO" && ./testar.sh )
