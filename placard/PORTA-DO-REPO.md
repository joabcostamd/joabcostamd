# PLACARD

> **Cada carta pontua em duas mãos de pôquer: a fileira e a coluna onde você a colocar.**

Roguelike de pôquer numa grade 5×5. Godot 4.7.2, GDScript, **arte 100% por
código e som sintetizado em tempo real** — não há um arquivo de imagem nem de
áudio de conteúdo neste repositório.

![O menu do PLACARD](placard/capturas-do-jogo/menu.png)

## Começar

    ./setup.sh                                   # Godot 4.7.2 + xvfb
    cd placard && godot --path . res://cenas/jogo.tscn

## Verificar

    cd placard && ./testar.sh

529 asserções, a aferição do motor contra a bancada de simulação, 25 capturas
mais a folha de contato, e os validadores de tipografia, layout e contraste.

## O jogo

Você recebe cartas e escolhe **onde** colocá-las numa grade 5×5. Cada carta cai
em uma fileira e em uma coluna ao mesmo tempo, então cada carta joga duas
partidas de pôquer de uma vez. Fechar as duas juntas é a **cruzada** — e é onde
o jogo paga, porque o evento soma os multiplicadores de todas as mãos colhidas
e o Tear multiplica a soma.

Daí a tensão inteira: fechar uma linha agora é ponto garantido, mas **queima** a
carta que faria a cruzada valer o triplo. A habilidade central do jogo é saber
recusar pontos.

- **18 mesas** por travessia, dificuldade escolhida por você, com a expectativa
  medida mostrada em número — não em adjetivo
- **9 tabuleiros** e três reguladores independentes de dificuldade
- **28 itens** de loja e **26 conquistas**
- **8 temas**, dois deles de fundo claro liberados desde o início, porque fundo
  claro é acessibilidade e não recompensa

## O mapa

| Onde | O que |
|---|---|
| `placard/scripts/nucleo/` | o jogo **sem uma linha de interface** — mesa, mãos, geometria, metas, economia, loja, itens, conquistas. Roda no terminal |
| `placard/scripts/ui/` | as 7 telas, o som sintetizado e o juice |
| `placard/testes/` | 529 asserções |
| `placard/ferramentas/` | aferição, calibração, capturas e os validadores |
| `placard/DESIGN.md` | **as regras, R01 a R46** — normativo, não descritivo |
| `placard/HUD.md` | as três zonas, a proporção 5:7 e os números que fecham |
| `placard/NOME.md` | por que o jogo se chama PLACARD, e os dezoito nomes que morreram antes |
| `placard-pesquisa/` | as medições. `DECISOES.md` é o livro-razão |
| `CLAUDE.md` | como se trabalha aqui |

## Como este jogo foi feito

O número veio antes da regra, e a regra veio antes do código.

Cada decisão de balanceamento passou por uma bancada de simulação antes de
virar linha de GDScript, e `placard-pesquisa/DECISOES.md` guarda todas — as
aprovadas **e as reprovadas**, com o número que matou cada uma. Tem até uma
seção de reguladores que são código morto: parâmetros que a medição provou
inertes, para ninguém tentar de novo.

O jogo já foi **impossível**: na primeira medição a rodada 6 tinha 0,0% de
vitória. Foi a loja que consertou, e o número está lá.
