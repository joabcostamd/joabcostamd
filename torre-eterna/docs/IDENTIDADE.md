# Identidade visual

O sistema visual do jogo inteiro: cor, letra, luz, forma, movimento e como tudo
isso aparece na loja. Não é um documento de tela de título — é a regra que
qualquer tela nova tem que obedecer, e a referência de onde saem os prompts de
arte em `docs/PROMPTS-ARTE.md`.

> **Restrição dura do projeto, e ela é a identidade.** Não existe uma única
> imagem no jogo: toda a arte é desenhada por código, em `_draw()`. Isso não é
> limitação, é a assinatura — formas geométricas puras, contorno luminoso,
> nenhuma textura. Um sistema visual que dependa de textura, ruído fotográfico
> ou pincel **não pode ser implementado** e por isso não entra aqui.

---

## 1. A ideia em uma frase

**Um instrumento de precisão numa noite muito escura.**

Não é ficção científica de nave. É o painel de uma máquina antiga que ainda
funciona, sozinha, muito depois de quem a construiu ter ido embora. A luz vem
de dentro dela e do que ela atira — nunca do ambiente. Por isso o fundo é quase
preto e a cor só aparece onde há energia.

Três palavras que decidem qualquer dúvida de arte: **escuro, luminoso, exato.**

---

## 2. Cor

### 2.1 A base — o que NÃO brilha

| Papel | Hex | Onde |
|---|---|---|
| `FUNDO` | `#080b14` | Fundo da janela e da arena |
| `FUNDO2` | `#0e1424` | Segundo plano, tiras, sulcos |
| `PAINEL` | `#121a2e` | Corpo de painel |
| `PAINEL2` | `#18223c` | Ficha, cartão, item dentro do painel |
| `BORDA` | `#243356` | Divisória silenciosa |
| `BORDA_FORTE` | `#3b5a9e` | Divisória que separa de verdade |

Tudo aqui é **azul-noite dessaturado**, nunca cinza neutro. Cinza puro ao lado de
neon fica sujo; azul escuro faz o neon parecer mais quente do que ele é.

### 2.2 O texto

| Papel | Hex | Contraste | Uso |
|---|---|---|---|
| `TEXTO` | `#e6ecf7` | 13,4:1 | Título, número grande, o que importa |
| `TEXTO2` | `#93a3c4` | 6,2:1 | Corpo, descrição |
| `TEXTO3` | `#778bb6` | 4,6:1 | Rodapé, legenda, valor indisponível |

`TEXTO3` está no limite de propósito: 4,5:1 é o mínimo da WCAG para texto
pequeno, e ele é usado justamente em corpo de 10–13 px. **Nenhum texto do jogo
pode ficar abaixo disso**, e há um portão de acessibilidade que reprova se
alguém tentar. O modo de alto contraste não salva um texto mal escolhido: ele
estica o gama em torno do meio-cinza, e como texto e painel são ambos escuros,
os dois sobem juntos.

### 2.3 Os neons — o que brilha

| Papel | Hex | Significado fixo |
|---|---|---|
| `ACENTO` | `#38bdf8` | Ciano. A torre, você, o que é seu |
| `ACENTO2` | `#a78bfa` | Violeta. Prestígio, lei, o que muda as regras |
| `OURO` | `#fbbf24` | Ouro. Dinheiro e recompensa |
| `VERDE` | `#4ade80` | Confirmação, ganho, vida |
| `VERMELHO` | `#f87171` | Dano, perda, perigo |
| `LARANJA` | `#fb923c` | Aviso, correção, atenção |
| `ROSA` | `#f472b6` | Gema, raro, o que é especial |

**Regra inegociável: cor tem significado, e o significado não muda de tela.**
Ciano é sempre você. Violeta é sempre uma regra mudando. Se uma tela nova usar
violeta para decorar, ela quebrou o sistema — e quem joga com daltonismo, que
distingue por posição e forma antes de cor, perde a única pista consistente.

### 2.4 Os três degraus do neon

Todo neon aparece em três intensidades, e sempre nesta ordem:

1. **Núcleo** — a cor pura, fina, no centro do traço. É o que se lê.
2. **Halo** — a mesma cor a 25–35% de alfa, 2 a 3 px em volta. É o que brilha.
3. **Derrame** — a mesma cor a 8–12% de alfa, num raio de 8 a 20 px. É o que
   pinta o ar em volta.

Nunca desenhe só o núcleo (fica chapado) nem só o halo (fica borrado). E o
derrame é a **primeira coisa que sai** quando o nível de detalhe cai — ele é
100% atmosfera e 0% informação.

### 2.5 As dez eras

Cada era troca a paleta de fundo, o céu, o chão e o clima. É a maior mudança
visual do jogo e ela é **procedural e paramétrica**: brilho, saturação e acento
por era. A regra é que o brilho **soma luz** em direção ao acento da era — já
errei isso uma vez, multiplicando, e o efeito foi escurecer as eras escuras.

---

## 3. Tipografia

### 3.1 As famílias

| Papel | Fonte | Licença | Cobre |
|---|---|---|---|
| Display | **Orbitron** | SIL OFL 1.1 | Latim |
| Interface | **Exo 2** | SIL OFL 1.1 | Latim, latim estendido, cirílico, grego |
| Reserva | **Noto Sans** (Thai/SC/TC/JP/KR) | SIL OFL 1.1 | Tailandês e CJK |

**Por que Orbitron.** É o padrão de fato para logotipo de jogo futurista:
letras largas, geométricas, com muito ar entre os traços — exatamente o que faz
um contorno de neon respirar. Uma fonte estreita fecha o vão interno das letras
e o halo empasta.

**Por que Exo 2.** É a única techy livre que cobre latim estendido, cirílico e
grego na mesma família. O vietnamita tem diacríticos empilhados que quebram a
maioria das fontes, e russo mais ucraniano são o terceiro maior público da
Steam — os dois não podem cair numa letra diferente do resto da tela.

**Onde Orbitron NÃO entra.** Ela não tem cirílico nem CJK. Em russo, ucraniano,
chinês, japonês, coreano e tailandês, o título usa a fonte de interface num peso
mais forte: uma letra que **existe** em peso forte lê melhor do que uma letra
bonita que vira caixa vazia.

### 3.2 A escala

| Nome | px | Fonte | Uso |
|---|---:|---|---|
| Display | 40+ | Orbitron | Logo, banner de chefe, prestígio |
| Título | 21–25 | Orbitron / Exo 2 700 | Cabeçalho de painel |
| Subtítulo | 16–19 | Exo 2 600 | Nome de item, botão principal |
| Corpo | 13–15 | Exo 2 400 | Descrição, lore |
| Legenda | 11–12 | Exo 2 400 | Rodapé, dica, unidade |

Nada abaixo de 11 px. Num celular a 1142×2031 lógicos, 10 px já é ilegível.

### 3.3 Números

Este jogo é feito de número em coluna: ouro, dano, custo, contagem de onda.
**Algarismo de largura fixa (`tnum`) é obrigatório** — com algarismo
proporcional a coluna dança a cada quadro, porque o `1` é mais estreito que o
`8`. É a diferença entre um painel que parece um instrumento e um que parece um
rascunho.

Notação grande (`1,23 K`, `4,56 M`, `1,00e308`): o número em `TEXTO`, o sufixo
em `TEXTO2`. O olho lê a magnitude primeiro.

---

## 4. Forma

### 4.1 Cantos

| Raio | Onde |
|---|---|
| 16 px | Janela modal |
| 12 px | Painel |
| 10 px | Botão, ficha grande |
| 6–8 px | Chip, etiqueta, ficha pequena |
| 0 px | Barra de progresso, régua, divisória |

Barra de progresso é **reta**. Canto arredondado numa barra esconde o começo e
o fim do preenchimento, que é justamente a informação.

### 4.2 Traço

- Divisória: 1 px, `BORDA`
- Contorno de item: 1 px, cor do item a 40%
- Contorno de item selecionado: 2 px, cor pura
- Aura de elite: arco de 2 px a 55%
- Aura de chefe: dois arcos, 3 px a 28% e 1,5 px a 10%, o de fora respirando

### 4.3 Ícones

Todos vetoriais, desenhados por código, no mesmo esqueleto: **encaixados numa
caixa quadrada, traço de 2 px na escala 1×, sem preenchimento sólido a não ser
que a forma peça.** Um ícone do jogo tem que ser reconhecível a 13 px, que é o
tamanho em que ele aparece dentro de um chip.

---

## 5. Movimento

| Gesto | Duração | Curva |
|---|---:|---|
| Janela entra | 200–220 ms | saída suave + salto de 1,05–1,07 |
| Janela sai | 180–200 ms | linear no alfa |
| Aviso entra | 180 ms | saída suave |
| Pulso de destaque | 900–1100 ms, em laço | seno |
| Tremor de impacto | 50–500 ms | decaimento quadrático |
| Câmera lenta | 300–800 ms | fator, não relógio |

**Duas regras que já foram violadas neste projeto e custaram caro:**

1. **Todo movimento anda em tempo real, não em tempo de jogo.** Com câmera lenta
   a 0,25×, um relógio que devia contar 0,8 s contava 3,2 s — a morte de um chefe
   congelava a tela por três segundos. Com o turbo a 4×, o mesmo feedback
   evaporava em um quarto do tempo, bem quando havia mais coisa acontecendo.
2. **"Movimento reduzido" desliga movimento de verdade** — tremor, zoom,
   partícula, pulso. Escalar o campo de visão inteiro é justamente o movimento
   que provoca enjoo, e a opção já prometeu tirá-lo sem tirar.

---

## 6. Composição das artes de loja

O que muda de tamanho para tamanho não é o recorte: é **quanta informação cabe.**

| Peça | Tamanho | O que precisa ser legível |
|---|---|---|
| Capsule principal | 616×353 | Logo + torre + uma onda de inimigos |
| Capsule pequena | 462×174 | **Só o logo.** É lida a 231×87 numa lista. |
| Header | 460×215 | Logo + torre |
| Hero | 3840×1240 | Cena larga, logo fora do centro |
| Library | 600×900 | Torre vertical, logo no terço de baixo |
| Logo (transparente) | 1280×720 | Só a marca, fundo alfa |

**Regras de composição:**

- A torre fica no **centro exato** ou no terço, nunca entre os dois.
- O inimigo vem **de fora para dentro**, sempre em direção à torre.
- A luz nasce na torre e nos projéteis. Nada de sol, lua ou lâmpada.
- Espaço vazio é 60% da imagem. Neon só funciona com escuridão em volta.
- Em nenhuma peça o texto passa de duas linhas.

---

## 7. O que este sistema proíbe

- **Textura, ruído fotográfico, pincel, sujeira.** O jogo é vetor.
- **Gradiente de mais de dois pontos.** Só do escuro para a cor.
- **Sombra projetada preta.** A sombra aqui é ausência de luz, não borrão.
- **Cor sem significado.** Ver 2.3.
- **Emoji na interface.** A fonte não tem glifo e vira caixa vazia — já
  aconteceu, e existe um portão que reprova.
- **Texto sobre neon.** Neon é fundo ruim: o texto vai sobre a base escura, e o
  neon fica na moldura.
- **Serifa.** Em nenhum lugar, em nenhum tamanho.

---

## 8. Onde isto vive no código

| Elemento | Arquivo |
|---|---|
| Paleta, widgets, medidas | `scripts/ui/ui_kit.gd` |
| Tipografia e cadeia de reserva | `scripts/core/tipografia.gd` |
| Ícones vetoriais | `scripts/ui/icone.gd` |
| Fundo, céu, chão e clima das eras | `scripts/render/art_bg.gd` |
| Torre | `scripts/render/art_tower.gd` |
| Inimigos e traços de cepa | `scripts/render/art_enemy.gd` |
| Tremor, flash, zoom, câmera lenta | `scripts/render/juice.gd` |
| Filtro de daltonismo e alto contraste | `scripts/render/filtro_acessibilidade.gd` |
| Nome, subtítulo, estúdio, copyright | `data/marca.json` |
