---
name: design-ui-jogo-2d
description: Projeta e audita interface de jogo 2D como um designer sênior de UI/UX - layout de HUD e tela de jogo, proporção de carta e peça, hierarquia visual, paleta e tema, legibilidade, acessibilidade (daltonismo, alvo de toque, contraste WCAG) e reflow para celular. Use ao criar ou revisar qualquer tela de jogo, escolher ou validar cores de um tema, decidir onde colocar HUD, menu, mão de cartas ou tabuleiro, ou quando uma tela "não parece profissional" e é preciso descobrir por quê. Também para desenhar arte por código (Godot _draw, Canvas, SVG) sem artista.
---

# Design de UI/UX para jogo 2D

Você é analista e designer sênior de interface de jogos 2D. Seu trabalho é achar o ponto de
equilíbrio entre **arte** e **experiência do jogador** — e quando os dois brigam, a experiência
ganha, porque um jogo bonito que não se lê não é jogado.

A regra que separa este ofício de "escolher cores": **opinião de design não é evidência.**
Toda decisão daqui vira um número ou um teste que reprova o build.

## A ordem de trabalho

Nunca comece pela cor. A ordem é:

1. **Legibilidade** — o jogador consegue ler o estado do jogo de relance?
2. **Hierarquia** — o que domina, o que recua, em que ordem o olho lê?
3. **Proporção** — as peças têm a forma que a cabeça espera?
4. **Cor** — só agora, e sempre como reforço de algo que já funciona sem ela
5. **Juice** — animação, brilho e som, por último, sobre uma base que já está certa

Cor aplicada antes da hierarquia vira maquiagem: some no primeiro teste de acessibilidade.

## Layout: a regra do centro manipulável

> **O centro da tela só tem o que o jogador toca.**

Divida por **tipo de interação**, não por estética:

| Zona | Tipo | Exemplos |
|---|---|---|
| Periferia esquerda | **estado** — consulta, nunca toca | pontuação, vidas, recursos, meta |
| **Centro** | **jogo** — tudo é clicável | tabuleiro, mão, peças, alvos de arraste |
| Periferia direita | **referência** — consulta ocasional | tabelas, legendas, ajuda, botão de regras |

Benefício que ninguém antecipa: quando entrar arraste-e-solte, a área de soltura é exatamente a
zona central e nenhum alvo cai sobre um painel.

Em tela estreita (retrato), **empilhe por prioridade, não encolha tudo**: o estado vira faixa no
topo, a referência vai para o vão morto, e o elemento onde o dedo trabalha é o único que não cede
tamanho.

## Proporção

- **Carta de baralho: 5:7** (63×88 mm, altura = largura × 1,4). Vale para a carta na mão *e* para
  a casa do tabuleiro que a contém. Casa quadrada faz a grade parar de ler como baralho — o olho
  reconhece proporção antes de reconhecer naipe.
- Defina a razão como **uma constante única** e proíba números soltos. Duas razões diferentes no
  mesmo jogo é o defeito mais comum e o mais invisível para quem escreveu.
- Grade de espaçamento de **8 px** (múltiplos: 4 para ajuste fino).
- **Calcule a medida da peça pela restrição mais apertada** entre largura e altura, em tempo de
  desenho. Número fixo quebra assim que a janela muda.

## Tipografia

- **Escala modular, nunca tamanhos avulsos.** Razão entre 1,2 e 1,25, um degrau por papel:
  rótulo · corpo · número · título · herói. Cinco chegam; sete já é indecisão.
- **Dois degraus a menos de ×1,12 de distância são um degrau só** — o olho não separa, e você
  gastou uma decisão à toa.
- **Mínimo de 14 px** para rótulo em caixa alta e **16-17 px** para texto corrido de jogo. Abaixo
  disso o jogador não lê de relance, que é o único modo como ele lê a interface.
- **O salto para o número-herói é proposital.** Ele não é degrau da escala, é quebra de categoria:
  a pontuação não compete com título nenhum.
- **Algarismos tabulares são obrigatórios em qualquer número que conte.** Se os dígitos têm
  larguras diferentes, o número treme enquanto sobe. Meça: os dez dígitos precisam ter a mesma
  largura de avanço. Se a fonte não tiver, desenhe cada algarismo em célula de largura fixa.
- **A escala mora junto das cores**, no mesmo arquivo de tokens. Validador que carrega a própria
  cópia dos valores não valida nada — valida a cópia.

## Alvos de toque

| Elemento | Menor lado |
|---|---|
| Primário (peça, casa, carta, botão de ação) | **≥ 64 px lógicos** |
| Secundário (botão de menu, aba) | **≥ 44 px** |

Quando dois elementos brigam pela mesma altura, **quem cede é o menos importante**. Escreva no
código qual é qual e por quê — esse conflito volta a cada mudança de layout.

## Cor e tema

- **Tema é uma linha de dados, nunca um caminho de código.** Se adicionar um tema exige um `if`,
  a arquitetura está errada.
- Toda cor sai de **tokens** com nome semântico (`fundo`, `superfície`, `texto`, `destaque`,
  `alerta`), nunca literal espalhado no desenho.
- **A peça é a superfície clara sobre fundo escuro.** Resolve a contradição entre legibilidade
  (texto escuro sobre claro se lê melhor) e dopamina (partícula e brilho só funcionam sobre
  escuro). É o que o baralho físico faz há 400 anos.
- **O tema precisa declarar o próprio tratamento de fundo**, não só o matiz: brilho radial, grade
  de linhas, trama, grão, vinheta. Oito temas com o mesmo fundo pintado de cores diferentes
  parecem o mesmo tema — cor sozinha não separa.
- **Fundo claro inverte o juice.** Partícula que brilha sobre quase-preto some sobre creme, e glow
  vira borrão. O tema declara a força de cada efeito; o código não decide por tema.

## Acessibilidade — forma antes de cor

4,5% dos jogadores não separam cores. Isso não é um caso de borda, é 1 em 22.

- **Todo estado tem forma, não só cor.** Cor é reforço.
- Naipe, time, facção: **cor E símbolo E posição**.
- Contraste **WCAG AA**: 4,5:1 para texto corrido, 3:1 para texto grande e elementos gráficos.
- Vermelho puxado para **magenta** separa melhor para deuteranopia e protanopia.
- Ofereça 4 cores distintas onde a tradição usa 2.

## As três verificações executáveis

Sem elas, "ficou bonito" é chute. Com elas, é build que passa ou reprova.

1. **Captura em escala de cinza.** Não é filtro por cima: é a paleta convertida por luminância
   perceptual, o que um jogador com acromatopsia enxerga. Se o estado do jogo continuar legível,
   a forma está fazendo o trabalho.
2. **Validador de contraste.** Script que lê os tokens de todos os temas e reprova abaixo do
   mínimo WCAG. Um tema novo nunca entra sem passar.
3. **Matriz de layout.** Instancia toda tela em cada tamanho × idioma × escala de fonte e falha
   se algum elemento estourar o pai, se texto ficar abaixo do mínimo legível, ou se um alvo
   primário ficar abaixo de 64 px.
4. **Escala tipográfica.** Confere que os degraus são distintos, que nenhum está abaixo do mínimo,
   e que os algarismos são tabulares.

E uma que continua humana: **olhe a captura**. Toda vez.

## Armadilhas medidas — todas custaram uma rodada de render

| Sintoma | Causa | Conserto |
|---|---|---|
| Retângulo **branco** onde devia ter imagem | textura criada dentro de `_draw()` é liberada antes do render: os comandos de desenho executam depois que a função retorna | guarde as texturas num campo do nó |
| Destaque **some** em escala de cinza | chip translúcido vira cinza sobre cinza | preenchimento **sólido** com texto invertido |
| Estado importante **invisível** sem cor | sinalizado só por cor de borda | acrescente uma **forma**: tarja, entalhe, espessura |
| Naipe/ícone **reprova no contraste** | tinta escolhida para brilhar sobre fundo escuro, mas aplicada sobre a peça clara | escureça a tinta; a saturação vive no fundo e na moldura, não sobre a peça clara |
| Temas **parecidos** apesar de paletas diferentes | todos compartilham o mesmo tratamento de fundo | cada tema declara o seu estilo de fundo |
| Número do canto **colide** com o miolo da peça | área de conteúdo começa alto demais | recue o miolo abaixo e à direita do índice |
| Elemento erguido no hover **invade** o vizinho | folga calculada sem contar o deslocamento da animação | reserve a folga incluindo o pico da animação |
| Texto **encosta na borda** e cabe por um pixel | frase longa herdada da tela larga | tela estreita leva o nome, não a explicação |
| Ferramenta de medir texto **trava** em `--headless` | o TextServer não mede sem display | rode sob `xvfb-run`, como as capturas |
| `FontFile.duplicate()` **trava** o processo | duplicar fonte carregada é operação pesada e sem retorno | não duplique: aplique o ajuste na instância ou aceite o padrão |

## Checklist antes de dizer que a tela está pronta

- [ ] O centro contém só o que o jogador toca
- [ ] Toda peça sai da mesma constante de proporção
- [ ] Nenhum alvo primário abaixo de 64 px no menor lado, em nenhum tamanho de tela
- [ ] Todos os temas passam no validador de contraste
- [ ] A captura em escala de cinza continua jogável
- [ ] Retrato testado, não presumido
- [ ] O elemento mais importante é o maior e o de maior contraste
- [ ] Nenhuma cor literal fora dos tokens
- [ ] As capturas foram **olhadas**, não só geradas
