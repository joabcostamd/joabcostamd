# PLACARD

Roguelike de pôquer em grade 5×5. Godot 4.7.2, GDScript, arte 100% por código.

> **Cada carta pontua em duas mãos de pôquer: a linha e a coluna onde você a colocar.**

O design foi medido antes de ser construído — a pesquisa está em
[`../placard-pesquisa/`](../placard-pesquisa/), e `DECISOES.md` de lá é o livro-razão
de tudo o que foi aprovado e reprovado, com o número atrás de cada decisão.

## Estado: jogável, do menu ao fim da travessia

O jogo existe inteiro. Abre, deixa escolher a dificuldade, joga 18 mesas, vende
na loja, tira vida, dá conquista e volta ao menu.

| Pasta | O que é |
|---|---|
| `scripts/nucleo/` | o jogo **sem uma linha de interface** — mesa, mãos, geometria, metas, economia, loja, itens, conquistas, run. Roda no terminal |
| `scripts/ui/` | as telas — menu, partida, loja, temas, conquistas, desafio — mais o som sintetizado e o juice |
| `cenas/` | as 7 cenas do Godot |
| `testes/` | 522 asserções em 8 arquivos |
| `ferramentas/` | aferição contra a bancada, calibração do K, capturas, e os validadores de contraste, tipografia e layout |
| `maquete/` | a maquete que decidiu o visual **antes** da primeira regra. Fica de pé: é o registro de por que a arte é essa |
| `DESIGN.md` | as regras, R01 a R46. Regra antes de código |
| `HUD.md` | as três zonas, a proporção 5:7 e os números que fecham |
| `NOME.md` | por que o jogo se chama PLACARD, e os dezoito nomes que morreram antes |

## Rodar

    godot --path . res://cenas/jogo.tscn

Para verificar tudo:

    ./testar.sh

522 asserções, a aferição do motor contra a bancada, 25 capturas da maquete mais
a folha de contato, e os validadores de tipografia, layout e contraste. Sem Godot
no PATH, roda em modo degradado só com os validadores em Python.

## Por que 2D vetorial

O 3D briga com a leitura do tabuleiro: perspectiva reduz as cartas do fundo,
inclinação esconde o índice do canto, e luz e sombra criam ruído de contraste
exatamente sobre a informação que precisa ser lida rápido. Balatro é 2D;
Hearthstone e Runeterra usam 3D só no espetáculo em volta, mantendo as cartas
planas e de frente.

E há a razão prática: em 2D a qualidade tem número — contraste, alvo de toque,
estouro de `Control`. Em 3D, "ficou bonito" não tem teste.

## Os oito temas

**O padrão é o Feltro e ouro** — o único dos oito em que uma pessoa que nunca ouviu falar do
PLACARD sabe que é um jogo de cartas antes de ler qualquer palavra.

Os outros são desbloqueáveis, **exceto os dois de fundo claro**, que ficam liberados desde o
início: fundo claro é afordância de acessibilidade e não cosmético de recompensa. O Neon arcade é
o último a abrir, de propósito — é o mais impressionante nos primeiros dez segundos e o mais
cansativo no minuto vinte, então vale mais como prêmio que como padrão.

Seis de fundo escuro (Casino noturno · Feltro e ouro · Neon arcade ·
Veludo e brasa · Meia-noite · Ameixa e ouro) e dois de fundo claro (Papel e tinta ·
Porcelana). Cada um declara o **próprio tratamento de fundo** — brilho radial, grade de
linhas, trama, grão ou vinheta — porque tema separado só por matiz não se separa. Os claros carregam parâmetros de juice próprios: partícula que brilha
sobre quase-preto some sobre creme, e glow vira borrão.

**A carta é sempre a superfície clara.** Texto escuro sobre claro onde se lê,
fundo escuro onde o juice acontece — é o que o baralho físico faz há 400 anos, e
resolve a contradição entre legibilidade e dopamina.

## Layout

Três zonas, divididas por tipo de interação e não por estética: **esquerda é estado**
(consulta), **centro é jogo** (tudo clicável), **direita é referência**. A regra é que o
centro só contém o que o jogador toca — quando entrar arraste de carta, a área de soltura
já é exatamente a coluna do meio.

Carta é **5:7** em todo lugar, da mão à casa da grade, a partir de `Carta.RAZAO`. Casa
quadrada faz a grade parar de ler como baralho. Detalhes e a conta em `HUD.md`.

## Acessibilidade

Naipe tem **cor e forma**, sempre, e a forma é a informação principal. O modo de
4 cores é o padrão; o clássico de 2 cores é opção. Toda captura tem uma passada
em escala de cinza — não é filtro, é a paleta que um jogador com acromatopsia
enxerga. Foi ela que reprovou a primeira versão do estado "linha cheia", que
dependia só da borda dourada e sumia sem cor.
