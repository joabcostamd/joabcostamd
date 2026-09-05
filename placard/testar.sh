#!/usr/bin/env bash
# Suíte do PLACARD. O núcleo primeiro: é o mais rápido e o que mais quebra.
set -e
cd "$(dirname "$0")"

GODOT="${GODOT:-godot}"

## Teto de tempo por chamada do Godot. Um teste travado não pode segurar a
## suíte: este projeto já perdeu 2,6 horas com um `fluxo` órfão girando o laço
## principal a 100% de CPU, sem imprimir nada. `timeout` mata; o cão de guarda
## dentro do próprio teste explica o que houve. Os dois, porque o cão só fala se
## o processo ainda responder.
TETO="${TETO:-90}"
if command -v timeout >/dev/null 2>&1; then
    GODOT_LIMITADO=(timeout --foreground "$TETO" "$GODOT")
else
    GODOT_LIMITADO=("$GODOT")
fi
if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "MODO DEGRADADO — Godot não encontrado no PATH; rodando só os validadores"
  python3 ferramentas/medir_layout.py
  python3 ferramentas/validar_contraste.py
  exit 0
fi

limpar() { grep -vE "^(WARNING|OpenGL|libpulse|   at:)" | grep -v "^$"; }

## Roda um teste e OLHA o código de saída do Godot, não o do grep.
##
## Num pipe, `$?` é o da última etapa — o grep, que quase sempre dá zero. Então
## `set -e` não vê teste morto por tempo (124) nem asserção falhada (1), e a
## suíte segue verde por cima de um teste que não aconteceu. É a pior falha
## possível numa suíte: a que mente para o dono.
rodar() {
    local saida; saida=$(mktemp)
    ## O `|| codigo=$?` é obrigatório: com `set -e` no topo do arquivo, um
    ## comando simples que falha derruba o script ANTES da linha seguinte, e a
    ## saída do teste nunca chega a ser impressa. A suíte morreria muda.
    local codigo=0
    "$@" > "$saida" 2>&1 || codigo=$?
    limpar < "$saida"
    if [ "$codigo" -eq 124 ] || [ "$codigo" -eq 137 ]; then
        ## O Godot às vezes NÃO SAI depois do quit(). Medido: 9 em 30 rodadas do
        ## teste de fluxo, sempre depois de imprimir o resultado, com a saída
        ## byte a byte igual à de uma rodada boa. É trava do motor no
        ## desligamento, não teste que não terminou — tentamos calar o áudio e
        ## desmontar a cena com calma, e não mudou nada.
        ##
        ## Então a verdade é o que o teste IMPRIMIU. Se ele disse OK, passou; o
        ## processo pendurado é defeito do motor e vira aviso. Se não disse nada,
        ## aí sim travou de verdade e a suíte cai.
        if grep -qE "OK — [0-9]+ asserções|AFERIÇÃO OK" "$saida"; then
            echo "   (passou, mas o Godot não saiu sozinho em ${TETO}s — trava"
            echo "    conhecida de desligamento do motor, ver CLAUDE.md)"
            rm -f "$saida"; return 0
        fi
        echo "   MORREU POR TEMPO — ${TETO}s sem sequer imprimir resultado."
        rm -f "$saida"; exit 1
    fi
    if [ "$codigo" -ne 0 ]; then
        echo "   FALHOU — código $codigo."
        rm -f "$saida"; exit 1
    fi
    rm -f "$saida"
}

echo "── núcleo: cartas, mãos, grade, metas, acaso ──"
"$GODOT" --headless --import >/dev/null 2>&1 || true
rodar "${GODOT_LIMITADO[@]}" --headless --script res://testes/nucleo.gd

echo
echo "── mesa: turno, janela, parcela, tear, avesso, fecho ──"
rodar "${GODOT_LIMITADO[@]}" --headless --script res://testes/mesa.gd

echo
echo "── desafio: as três réguas, o dial, a geometria e a rede ──"
rodar "${GODOT_LIMITADO[@]}" --headless --script res://testes/desafio.gd

echo
echo "── loja: níveis, selos, relíquias, dinheiro e a rodada 6 ──"
rodar "${GODOT_LIMITADO[@]}" --headless --script res://testes/loja.gd

echo
echo "── run: as 18 mesas, as 3 vidas, o perfil e os desbloqueios ──"
rodar "${GODOT_LIMITADO[@]}" --headless --script res://testes/run.gd

echo
echo "── conquistas: o catálogo, as marcas e a conta ──"
rodar "${GODOT_LIMITADO[@]}" --headless --script res://testes/conquistas.gd

echo
echo "── juice: limites do peso, vazamento e som ──"
rodar "${GODOT_LIMITADO[@]}" --headless --script res://testes/juice.gd

echo
echo "── fluxo: menu, partida, run inteira, fecho ──"
# Roda como cena: o `_ready` das telas só acontece depois que o laço principal
# começa, e sob `--script` o teste mediria um jogo que ainda não nasceu.
rodar "${GODOT_LIMITADO[@]}" --headless res://testes/fluxo.tscn

echo
echo "── aferição contra as bandas da bancada ──"
# O motor precisa REPRODUZIR o protótipo que produziu os números do DESIGN §9.
# Sem isto, "portamos o núcleo" seria uma afirmação sem prova.
rodar "${GODOT_LIMITADO[@]}" --headless --script res://ferramentas/aferir.gd -- "${AFERIR_SEMENTES:-12}"

echo
echo "── capturas da maquete (8 temas × 3 modos) ──"
# Captura exige display: em --headless o renderizador é nulo e não desenha nada.
if command -v xvfb-run >/dev/null 2>&1; then
  xvfb-run -a "$GODOT" --resolution 1280x720 res://maquete/capturas.tscn
  echo
  echo "── escala tipográfica e algarismos ──"
  # Exige display: o TextServer não mede texto sob --headless puro.
  xvfb-run -a "$GODOT" --resolution 640x480 res://maquete/tipografia.tscn 2>/dev/null | limpar
else
  echo "CAPTURAS — puladas — xvfb ausente"
fi

echo
echo "── alvos de toque em todos os tamanhos ──"
python3 ferramentas/medir_layout.py

echo
echo "── contraste WCAG AA em todos os temas ──"
python3 ferramentas/validar_contraste.py
