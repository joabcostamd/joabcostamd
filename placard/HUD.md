# PLACARD — estudo de HUD

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

Três colunas não cabem em 360 de largura. A estratégia é **empilhar por prioridade**, não encolher.
E a prioridade é uma regra, não gosto: **o elemento onde o dedo trabalha é o único que não cede
tamanho.**

| Medida | Valor |
|---|---|
| Margem externa | 8 |
| Barra de estado da fileira | 8 |
| Vão entre casas / entre cartas | 4 |
| **Casa da grade** | **64 × 90** |
| **Carta da mão** | **65 × 91** |

- a coluna de estado vira faixa horizontal no topo, com pontos, meta e multiplicador em colunetas
- os rótulos de fileira **não cabem como texto**: viram uma **barra de progresso de 8 px** na borda
  externa da grade — a mesma informação em forma
- a **tabela de mãos sai da tela** e vai para trás do botão REGRAS. É referência, e referência é a
  primeira coisa a sair quando o dedo precisa de espaço
- no vão entre a grade e a mão entra a informação mais quente que ainda não estava na tela: o
  modificador desta mesa

**A versão anterior reprovava e passou despercebida:** casa de 58 px e carta de 59 px, ambas abaixo
do mínimo de 64. Os números de paisagem tinham sido conferidos por script; os de retrato foram
presumidos porque a captura "parecia certa". Por isso `ferramentas/medir_layout.py` agora mede os
dois e reprova o build — captura bonita não é medida.

## 7. O fundo é identidade, não matiz

Cada tema declara o seu **estilo de fundo**, não só a sua cor:

| Estilo | Como é feito | Temas |
|---|---|---|
| `brilho` | brilho radial em 18 camadas fracas | Casino, Veludo, Ameixa |
| `grade` | linhas acesas ortogonais + horizonte | Neon |
| `tecido` | trama cruz de 4 px quase invisível | Feltro |

## 9. A escala tipográfica

Cinco papéis, cinco degraus, razão **1,25** ancorada em 14. Nenhum tamanho fora daqui entra na
tela, e a escala mora em `temas.gd` junto das cores — o validador só confere.

| Papel | Tamanho | Onde | Razão |
|---|---|---|---|
| `T_ROTULO` | **14** | PONTOS, MÃOS, RODADA, VIDAS, MESA — caixa alta | — |
| `T_CORPO` | **17** | nomes das mãos, frases, botões, contadores | ×1,21 |
| `T_NUMERO` | **21** | fichas e multiplicadores da tabela | ×1,24 |
| `T_TITULO` | **26** | PLACARD | ×1,24 |
| `T_HEROI` | **52** | a pontuação e o multiplicador da mesa | ×2,00 |

O salto de `TITULO` para `HEROI` é ×2 **de propósito**: não é degrau da escala, é quebra de
categoria. O número da pontuação não compete com título nenhum — ele é de outra ordem.

**O que a escala substituiu.** Os tamanhos eram escolhidos um a um: 11, 13, 14, 16, 18 e 50. O
13 e o 14 ficavam lado a lado com razão ×1,08 — dois degraus que ninguém distingue, ou seja, um
degrau desperdiçado. E entre 18 e 50 havia ×2,78 de nada. Os rótulos em 11 e 13 estavam abaixo do
mínimo recomendado para texto de jogo.

**Os algarismos são tabulares.** Medido: os dez dígitos do Nunito têm exatamente 30,0 px a 50 px
de corpo, Regular e Bold. Isso importa mais aqui que em quase qualquer outra interface — a
pontuação sobe contando, e com dígitos de larguras diferentes o número **treme** enquanto conta.
`maquete/tipografia.gd` mede isso a cada rodada de teste.

## 10. Os quatro detalhes que separam premium de improvisado

Nenhum deles é caro. Todos são um `draw_rect` ou dois.

| Detalhe | O que é | Por que funciona |
|---|---|---|
| **Filete** | linha de 1 px do acento por dentro da borda do painel | borda grossa é a assinatura da interface improvisada; a linha fina é a da cara |
| **Mesa embutida** | o tabuleiro afunda na mesa: fundo mais escuro, sombra interna só no topo, filete na borda | numa mesa de carteado o feltro é rebaixado na madeira, e é o degrau que faz o objeto parecer caro |
| **Fio de luz** | 1 px claro na aresta de cima da casa vazia | a luz vem de cima, então só a aba superior a recebe: a casa lê como marcação rebaixada, não como buraco recortado |
| **Painel do tamanho do conteúdo** | a moldura termina onde o conteúdo termina | vazio DENTRO de moldura lê como inacabado; vazio FORA dela lê como respiro |

E uma regra de alinhamento que custou uma rodada para achar: **a mão alinha pelo centro da MESA**,
não da grade nem da coluna. O eixo que o olho usa é a massa visual inteira — grade mais rótulos —,
e centrar cada bloco na sua própria referência desalinha os dois por alguns pixels que se veem.
| `papel` | manchas largas e fraquíssimas | Papel, Porcelana |
| `vinheta` | fundo liso, só bordas escuras | Meia-noite |

**A casa vazia é token próprio** (`casa` e `casa_borda`), nunca `painel` com alfa. Derivar a cor da
casa de outra cor funciona no tema escuro e faz o tabuleiro **sumir** no claro — foi o que a escala
de cinza mostrou no Papel e tinta, onde sobravam nove cartas boiando sem grade embaixo. O validador
exige 3:1 entre a **borda** da casa e o fundo: a borda é a afordância de "cabe carta aqui", e é ela
que carrega a informação, não o preenchimento.

Enquanto os oito compartilhavam o mesmo brilho radial, vários pareciam o mesmo tema repintado —
foi o que a folha de contato mostrou. Tema separado por matiz sozinho não se separa.

## 8. Verificação

    ./testar.sh

1. **24 capturas** — 8 temas × (1280×720 · 360×800 · escala de cinza) + folha de contato
2. **Alvos de toque** — `medir_layout.py` mede casa e carta em 1280×720, 1920×1080, 360×800 e
   390×844, e reprova abaixo de 64 px
3. **Contraste WCAG AA** — 104 pares, reprova o build abaixo do mínimo
4. **Escala de cinza** — não é filtro, é a paleta que um jogador com acromatopsia enxerga
5. **Proporção** — nenhuma carta fora de 5:7, porque todas saem de `Carta.RAZAO`

Inspeção que ainda é humana: o centro contém **só** grade e mão, e nada de status ou tabela
invadindo. É a regra da seção 1, e é o que se olha primeiro em toda captura nova.
