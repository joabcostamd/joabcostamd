# CRUZADA — estudo de HUD

Documento de decisão da tela de partida. Cada número aqui foi conferido com o layout rodando,
não estimado. Escrito antes das regras do jogo porque a direção de arte define a estrutura de
cenas e o que dá para verificar automaticamente — trocar depois custa reescrever a apresentação.

## 1. A regra que organiza tudo

> **O centro só tem o que o jogador toca.**

Três zonas, e a divisão não é estética: é por **tipo de interação**.

| Zona | O que é | Conteúdo | Interação |
|---|---|---|---|
| Esquerda | **estado** | pontos, meta, multiplicador, jogadas e descartes restantes | consulta, nunca toca |
| **Centro** | **jogo** | a grade 5×5 e a mão | tudo aqui é clicável |
| Direita | **referência** | tabela das 9 mãos, modificador da mesa, botão REGRAS | consulta ocasional |

O erro que isso corrige: na primeira maquete a tabela de mãos ficava à direita mas dentro da
área de jogo, e a mão era empurrada para a beirada da tela. O olho tinha que atravessar
informação estática para chegar na decisão.

**Consequência prática:** quando o jogo ganhar arraste de carta, a área de soltura é exatamente
a coluna do meio. Nenhum alvo de arraste cai sobre um painel.

## 2. Proporção — 5:7 em todo lugar

Carta de baralho francês é 63×88 mm. Razão 5:7, altura = largura × **1,4**.

A constante mora em `maquete/carta.gd` como `Carta.RAZAO` e ninguém escreve outro número.
Vale para a mão **e** para a casa da grade.

Por que importa: a primeira maquete desenhava a grade em casas **quadradas** e a mão em 1:1,42.
Casa quadrada faz a grade parar de ler como baralho — o olho reconhece proporção antes de
reconhecer naipe.

## 3. Os números que fecham — 1280×720

| Medida | Valor |
|---|---|
| Margem externa | 24 |
| Barra do topo | y 12..64 |
| Conteúdo | y 72..708 (636 de altura) |
| Colunas | 343 · vão 20 · **505** · vão 20 · 343 |
| Casa da grade | **64 × 90** · vão 5 |
| Grade | 340 × 468 |
| Rótulos de fileira | 108 à direita da grade |
| Rótulos de coluna | 24 de altura |
| Carta da mão | **82 × 115** · vão 12 |
| Vertical usado | **635 de 636** |

**A célula sai da restrição mais apertada** entre largura e altura, calculada em tempo de
desenho — fixar o número quebraria assim que a janela mudasse.

**Por que a mão tem teto de 82 px.** Sem o teto ela cresce junto com a coluna central, come a
altura disponível e a casa da grade cai para 62 px — 2 abaixo do alvo de toque. A grade é a coisa
mais importante da tela, então quem cede é a mão. Esse é o tipo de conflito que só aparece quando
se calcula, e por isso o cálculo mora no código e não numa planilha.

## 4. Alvos de toque

| Elemento | Menor lado | Mínimo | |
|---|---|---|---|
| Casa da grade | 64 | 64 (primário) | ✓ |
| Carta da mão | 82 | 64 (primário) | ✓ |
| Botão REGRAS | 44 | 44 (secundário) | ✓ |

## 5. Hierarquia visual

Ordem de leitura desenhada de propósito, do que domina para o que recua:

1. **A grade** — maior área, maior contraste (carta clara sobre fundo escuro), centro do campo visual
2. **A pontuação** — o maior número da tela, 50 px, porque é ele que se lê de relance enquanto sobe
3. **O multiplicador** — 50 px na cor de recompensa; é o único número que sobe a mesa inteira
4. **A linha cheia** — borda grossa + tarja sólida + halo, o estado mais importante do turno
5. **Os rótulos de linha** — colados na linha, nunca num painel distante: o olho não deve viajar
6. **A tabela de mãos** — texto de 16 px, cor normal, sem destaque salvo o que já foi feito
7. **A barra do topo** — a informação mais fria da tela

## 6. Reflow para retrato (360×800)

Três colunas não cabem em 360 de largura. A estratégia é **empilhar por prioridade**, não encolher:

- a coluna de estado vira faixa horizontal no topo, com pontos, meta e multiplicador em três colunetas
- a coluna de referência vira tabela de duas colunas no vão entre a grade e a mão
- o botão REGRAS sobe para a barra
- os rótulos de fileira **não cabem como texto**: viram cinco pontinhos de progresso numa faixa de
  22 px, e só a fileira cheia ganha um chip

A grade continua com casa de 64 px de largura: em retrato ela é o único elemento que não pode
encolher, porque é onde o dedo trabalha.

## 7. O fundo é identidade, não matiz

Cada tema declara o seu **estilo de fundo**, não só a sua cor:

| Estilo | Como é feito | Temas |
|---|---|---|
| `brilho` | brilho radial em 18 camadas fracas | Casino, Veludo, Ameixa |
| `grade` | linhas acesas ortogonais + horizonte | Neon |
| `tecido` | trama cruzada de 4 px quase invisível | Feltro |
| `papel` | manchas largas e fraquíssimas | Papel, Porcelana |
| `vinheta` | fundo liso, só bordas escuras | Meia-noite |

Enquanto os oito compartilhavam o mesmo brilho radial, vários pareciam o mesmo tema repintado —
foi o que a folha de contato mostrou. Tema separado por matiz sozinho não se separa.

## 8. Verificação

    ./testar.sh

1. **24 capturas** — 8 temas × (1280×720 · 360×800 · escala de cinza) + folha de contato
2. **Contraste WCAG AA** — 96 pares, reprova o build abaixo do mínimo
3. **Escala de cinza** — não é filtro, é a paleta que um jogador com acromatopsia enxerga
4. **Proporção** — nenhuma carta fora de 5:7, porque todas saem de `Carta.RAZAO`

Inspeção que ainda é humana: o centro contém **só** grade e mão, e nada de status ou tabela
invadindo. É a regra da seção 1, e é o que se olha primeiro em toda captura nova.
