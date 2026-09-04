# PLACARD

Roguelike de pôquer em grade 5×5. Godot 4.7.2, GDScript, arte 100% por código.

> **Cada carta pontua em duas mãos de pôquer: a linha e a coluna onde você a colocar.**

O design foi medido antes de ser construído — a pesquisa está em
[`../cruzada-pesquisa/`](../cruzada-pesquisa/), e `DECISOES.md` de lá é o livro-razão
de tudo o que foi aprovado e reprovado, com o número atrás de cada decisão.

## Estado: maquete de direção de arte

Ainda não há jogo. O que existe é a maquete que decide o visual antes da primeira
regra ser escrita — porque a direção de arte define a estrutura de cenas e o que dá
para verificar automaticamente, e trocar depois custa reescrever a apresentação.

| Arquivo | O que é |
|---|---|
| `maquete/temas.gd` | os 8 temas como tokens de cor **e** parâmetros de juice |
| `maquete/carta.gd` | a carta desenhada por código: pips, figuras, naipes, Avesso |
| `maquete/tela.gd` | a tela de partida com um estado fixo e realista |
| `maquete/capturas.gd` | renderiza 8 temas × 3 modos e monta a folha de contato |
| `ferramentas/validar_contraste.py` | WCAG AA sobre todos os temas |
| `HUD.md` | o estudo de HUD: as três zonas, a proporção 5:7 e os números que fecham |

## Rodar

    ./testar.sh

Gera 24 capturas em `maquete/capturas/` mais a `FOLHA-DE-CONTATO.png`, e valida
contraste. Sem Godot no PATH, roda em modo degradado só com o validador.

Para ver a maquete ao vivo:

    godot --path . res://maquete/maquete.tscn

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
