# Torre entre Dimensões — mapa de decisões

Data: 2026-09-12 · Régua de planejamento: v1
**Fase: planejamento. Nenhuma linha de gameplay antes deste documento fechar a fase 2.**

> Este arquivo é **o estado da entrevista**. Não existe arquivo de sessão separado: os 🔴🟡🟢
> abaixo são o ponto onde paramos, e viajam por git entre a nuvem e a máquina local.
>
> O `portao-plano.py` lê exatamente este formato. Não invente outro.

---

## Legenda

**Estado** — 🔴 ABERTA (ninguém decidiu) · 🟡 PROPOSTA (recomendação do agente, falta o martelo
do Joab) · 🟢 FECHADA (decidida, com motivo escrito)

**Origem** — 👤 o Joab decidiu · 📏 saiu de medição · 🤖 recomendação do agente que o Joab aceitou

Decisão 🟢 **precisa** de marca de origem. Sem ela o portão pergunta "quem decidiu?" e bloqueia.
Decisão 🟢 só reabre com motivo escrito.

---

## Estado geral

| Bloco | Assunto | Estado |
|---|---|---|
| B0 | Identidade | 🔴 |
| B1 | Espaço e movimento | 🔴 |
| B2 | Estrutura da partida | 🔴 |
| B3 | Ação central | 🔴 |
| B4 | Progressão na partida | 🔴 |
| B5 | Meta-progressão | 🔴 |
| B6 | Conteúdo e espaço | 🔴 |
| B7 | Oposição | 🔴 |
| B8 | Telas e fluxo | 🔴 |
| B9 | Arquitetura e dados | 🔴 |
| B10 | Apresentação | 🔴 |
| B11 | Produto | 🔴 |
| B12 | Produção de assets por IA | 🔴 |

Fase alcançada: **nenhuma** · Próximo bloco: **B0** (3 decisões fechadas, pesquisa de mercado pronta)

---

## As decisões

Uma por vez, na ordem que o grafo de `BLOCOS.md` mandar. Formato exato:

### D-001 · B0 · O defeito do gênero que este jogo ataca 🟢 👤

**Valor:** a **repetição** — cada partida precisa ser visivelmente outra.
**Motivo:** é a queixa nº 1 do gênero em várias fontes independentes (*"fica repetitivo muito
rápido, sem força narrativa"*). Atacar a passividade exigiria dar um corpo ao jogador, o que
briga com a promessa de uma torre só. Ver `PESQUISA.md` §6.
**Trava:** a ação central (B3), a progressão (B4) e o conteúdo (B6).

### D-002 · B1 · O jogador TEM corpo no mundo 🟢 👤 *(emendada)*

> ⚠️ **Reaberta e invertida em 2026-09-12.** Valor anterior: *"sem corpo no mundo, só a torre"*.
> **Motivo da virada:** a mecânica "a última linha é você" (Legion TD 2) dá **razão mecânica**
> para o personagem existir — ele não é enfeite, é a defesa final. Sem ele, vazamento tira vida
> direto, o que é punitivo, e a noite volta a ser assistir. Registro completo em `DECISOES.md`.

**Valor:** um personagem jogável, que luta junto com as torres e é a última linha de defesa.
**Um só** personagem — nunca exército, nunca herói com árvore de habilidade.
**Motivo:** resolve três coisas de uma vez — dá razão mecânica ao personagem, tira a crueldade
de perder vida a cada vazamento, e cria o momento de tensão que faz a noite valer a pena.
**O custo aceito:** um personagem animado. Um só, e é o teto — o resto do jogo continua sem
personagem nenhum, que era a economia original.
**Trava:** a câmera (B1), a ação central (B3) e o orçamento de assets (B12).

### D-003 · B2 · Uma partida dura 10 a 15 minutos 🟢 👤

**Valor:** 10 a 15 minutos, com fim definido.
**Motivo:** faixa do *Megabonk*. Cabe em qualquer sessão, convida ao "só mais uma", e limita
quanto conteúdo precisamos produzir. Derrota custa pouco, então dificuldade alta é permitida.
**Trava:** o ritmo (B2), a progressão dentro da partida (B4) e o número de ondas (B7).

### D-005 · B0 · O modelo do jogo é o Thronefall, não o Kingdom Rush 🟢 👤

**Valor:** tower defense **3D minimalista e low-poly**, com caminho fixo. Escopo de 6 a 8 torres
com evolução e 5 a 8 mapas. **Sem personagem animado, sem herói.**

**Motivo:** três medidas sustentam isso.
1. *Thronefall*: 2 pessoas, 1 milhão de cópias, US$ 1,5 mi nos dois primeiros meses, €12,99,
   quase 19 mil análises extremamente positivas. O *Kingdom Rush* faturou mais (US$ 6,1 mi),
   mas é franquia de 15 anos com 4 sequências — e o *Bloons TD 6* já ocupa o 3D grande.
2. **Conta de asset:** um Kingdom Rush em 3D são 20-30 inimigos animados = 60 a 90 clipes.
   Personagem animado é o asset mais caro e **o pior caso para consistência de arte gerada por
   IA** — o risco nº 1 registrado na régua.
3. *"Fazer coisas pequenas é o único jeito de terminar alguma coisa com 1 a 3 pessoas."*
   — Paul Schnepf, criador do Thronefall.

**Trava:** o estilo de arte (B10), a fábrica de assets (B12), o volume de conteúdo (B6) e a
oposição (B7).

### D-006 · B3 · As 12 peças do jogo 🟢 👤

**Valor:** a mescla pesquisada em 9 jogos. Cada peça cabe numa frase, e nenhuma precisa de
tutorial:

| # | peça | de onde | a frase |
|---|---|---|---|
| 1 | 4 famílias de torre | Kingdom Rush | *"cada torre é boa contra um tipo de inimigo"* |
| 2 | 3 caminhos, um até o topo | Bloons TD 6 | *"escolha um caminho para levar até o fim; nos outros dois você para no meio"* |
| 3 | pontos fixos de construção | Thronefall | *"você só constrói nos lugares marcados"* |
| 4 | dia e noite | Thronefall | *"de dia constrói, de noite defende"* |
| 5 | bloqueadores | Kingdom Rush | *"seus soldados param o inimigo no caminho"* |
| 6 | casa × moinho | Thronefall | *"casa dá ouro seguro; moinho dá mais, se sobreviver"* |
| 7 | duas habilidades com recarga | Kingdom Rush | *"dois botões para a hora certa"* |
| 8 | mutadores | Thronefall | *"ligue a dificuldade que quiser, e ganhe mais"* |
| 9 | inimigo com mania | Bloons TD 6 | *"esse tem escudo — flecha não passa"* |
| 10 | você é a última linha | Legion TD 2 | *"o que passar pelas torres, você enfrenta"* |
| 11 | repetir rende menos | Orcs Must Die | *"misturar torres rende mais que empilhar a mesma"* |
| 12 | o dinheiro volta ao matar | Orcs Must Die | *"cada inimigo morto devolve parte do que você gastou"* |

**Motivo:** as torres do Kingdom Rush resolvem **variedade**; as mecânicas do Thronefall resolvem
**simplicidade**. Cada um conserta o defeito do outro. A peça 11 é o **antídoto** ao defeito que
os três jogos de referência têm em comum — uma opção que anula as outras.
**Trava:** o conteúdo (B6), a oposição (B7), a progressão (B4) e a arquitetura (B9).

### D-007 · B4 · Compra livre, sem sorteio de cartas 🟢 👤

**Valor:** o menu de torres está sempre disponível. O jogador escolhe e paga. **Zero
aleatoriedade** na oferta.
**Motivo:** sorteio exige duas regras extras para ser justo (garantia de oferta e troca paga), e
cada regra a mais é risco de reembolso. A variedade entre partidas vem dos **mapas**, dos
**mutadores** e das **manias dos inimigos** — que não precisam de explicação nenhuma.
**Consequência:** as peças "sorteio controlado" e "pular pagando" ficam **fora**. A lista fecha
em 12.
**Trava:** a progressão na partida (B4) e as telas (B8).

### D-008 · B4 · Fúria da última linha 🟢 👤

**Valor:** conforme as torres caem, o personagem fica mais forte. Ideia do Joab.

**Os três freios, que entram junto:**
1. a força extra **dura só aquela noite** — não vira estratégia permanente
2. **não devolve a torre nem o ouro** gasto nela — perder continua sendo ruim
3. o simulador mede: a política *"deixar cair de propósito"* **não pode vencer mais** que a
   política *"defender"*

**Motivo:** faz a última linha ser de verdade e cria a emoção que o gênero quase não tem —
quanto pior a situação, mais forte você fica. O risco real é o jogador querer perder torres de
propósito; os três freios existem para isso, e o freio 3 é **medido**, não suposto.
**Trava:** o balanceamento (B4) e os critérios de qualidade do `CONCEITO.md`.

### D-009 · B10 · As 6 regras de ensino 🟢 📏

**Valor:** o jogo ensina pelas regras do *Plants vs Zombies* — sem tela de tutorial · fazer o
jogador executar a ação uma vez · imagem em vez de texto · aviso que some quando ele entende ·
aprender fazendo · ensino espalhado pelo jogo inteiro.
**Motivo:** medido. Introdução longa é o motivo nº 1 de devolução na Steam, e *"se você não
explica o jogo em uma frase, ele é complexo demais"*. As 12 peças acima já passam nesse teste.
**Trava:** o tutorial (B11) e as telas (B8).

### D-010 · B6 · Quatro famílias de torre, três caminhos cada 🟢 👤

**Valor:** flecha · magia · bloqueador · explosão. Cada uma com 3 caminhos de melhoria, e **só
um caminho pode chegar ao topo** — nos outros dois a torre para no meio.
**Motivo:** são exatamente os quatro papéis do Kingdom Rush, que cobrem as cinco manias de
inimigo sem sobra. Dão 12 torres finais custando perto de 4 modelos, porque cada caminho é
variação da mesma peça.
**Trava:** o balanceamento (B4), a fábrica de assets (B12) e as telas de construção (B8).

### D-011 · B7 · Quinze inimigos, cinco manias 🟢 👤

**Valor:** 15 inimigos. Cinco manias: **escudo · voo · velocidade · cura · blindagem**.
**Motivo:** cinco manias, uma resposta diferente para cada, e quinze corpos cabem numa família
visual coerente para a IA gerar.
**Trava:** o balanceamento (B4) e a fábrica de assets (B12).

### D-012 · B7 · As manias só aparecem com mutador 🟢 👤

**Valor:** o jogo base não tem mania nenhuma. Escudo, voo, velocidade, cura e blindagem só
aparecem quando o jogador liga um mutador.

**O pedido do Joab:** *"as manias só devem aparecer quando o jogador usa mutadores; em fases
iniciais não podem deixar o jogo muito difícil"*.

**O conflito que isso cria:** sem mania nenhuma no jogo base, **as quatro famílias de torre
viram a mesma coisa**. Nada obriga o jogador a trocar de torre, ele acha a mais forte e usa só
ela — que é exatamente o defeito medido no Thronefall, no Kingdom Rush e no TDS.

**O risco que o agente levantou, e o Joab manteve a decisão assim mesmo:** sem mania no jogo
base, nada obriga a trocar de torre — o jogador acha a mais forte e usa só ela. É o defeito
medido no Thronefall (a lança), no Kingdom Rush (os heróis fortes) e no TDS (o Accelerator).

**Como vamos saber se o risco virou problema, sem depender de opinião:** o simulador mede, com
as três políticas de habilidade, **sem nenhum mutador ligado**:
- nenhuma família de torre pode aparecer em mais de **60%** das partidas vencedoras
- nenhuma pode aparecer em menos de **10%**

Se o alerta disparar, esta decisão volta para a mesa com **número na mão**, não com palpite. A
proposta que ficou guardada para esse caso era introduzir as manias aos poucos, mapa a mapa —
regra 6 do *Plants vs Zombies*, espalhar o ensino:

| mapa | entra | o jogador aprende |
|---|---|---|
| 1 | nenhuma | só construir e defender |
| 2 | escudo | *"flecha não fura — preciso de magia"* |
| 3 | voo | *"soldado não alcança"* |
| 4 | velocidade | *"torre lenta não pega"* |
| 5 | cura | *"tenho que matar aquele primeiro"* |
| 6+ | blindagem e combinações | juntar tudo |

**O que os mutadores fazem:** ligam as manias. *"Nesta partida, todo inimigo voa."* É onde a
variedade de torre passa a importar, e é escolha do jogador — nunca imposição.

**A vantagem que essa escolha traz, e que pesa a favor:** o começo do jogo fica realmente fácil
de entender, que é a regra nº 1 contra o reembolso na Steam.

**Trava:** o conteúdo dos mapas (B6), o tutorial (B11) e o balanceamento (B4).

### D-013 · B6 · Quinze mapas, alguns viram DLC 🟢 👤

**Valor:** quinze mapas planejados desde o começo. Parte entra no lançamento, parte fica como
DLC futuro — a divisão é decidida no bloco de produto (B11).
**Motivo:** planejar os quinze agora garante que a curva de manias (D-012) tenha espaço para
crescer sem aperto, e que o DLC não seja remendo depois.
**Trava:** a produção (B11) e a fábrica de assets (B12).

### D-014 · B2 · A noite começa quando o jogador quiser 🟢 👤

**Valor:** o jogador aperta para começar a noite quando estiver pronto. **Em dificuldade maior,
o tempo de preparação é reduzido** — vira relógio.
**Motivo:** é o modelo do Thronefall, e resolve ritmo sem punir quem pensa devagar. O relógio
só aparece para quem pediu dificuldade.
**Trava:** as telas (B8) e o balanceamento (B4).

### D-015 · B6 · Mapa tem duas camadas: layout e mundo 3D 🟢 👤

> ⚠️ **A imagem que o Joab viu é ESBOÇO, não o jogo.** A grade colorida é o esqueleto lógico.
> Em cima dela ainda tem que nascer o mundo 3D inteiro, como no Thronefall.

**Valor:** o mapa é **duas camadas separadas**, e nunca se misturam.

| camada | o que é | onde vive |
|---|---|---|
| **layout** | a grade: nível de cada célula, penhasco, rampa, ponte, caminho, ponto de construção, frentes | dado puro, gerado e **testável sem abrir o Godot** |
| **mundo 3D** | malha do terreno com penhasco real, árvore em cacho, água com as linhas desenhadas, construção, sombra dura, luz direcional, câmera isométrica alta | montado **a partir** do layout, na máquina local |

**Motivo:** é a regra 2 do `CLAUDE.md` aplicada ao mapa — a lógica é `static func` pura e a
apresentação só desenha. O layout dá para gerar, validar e simular **na nuvem, sem editor**. O
mundo 3D é trabalho local, com o MCP e o olho.

**A consequência que mais importa:** trocar o visual inteiro do jogo não toca no layout, e
mudar a regra do layout não quebra a arte. São duas linhas de produção independentes.

**O que ainda falta decidir (vira D-0xx quando chegarmos no B10 e no B12):** como cada peça do
layout vira geometria — o penhasco é malha esculpida ou bloco empilhado? a árvore é instância
em MultiMesh? a água é shader ou malha? — e o contrato de asset de cada família.

**Valor do modo sem fim:** além dos quinze mapas à mão, os gerados viram modo sem fim.

| passo | o quê |
|---|---|
| 1 | ~20 **peças de mapa desenhadas à mão** — curva, bifurcação, reta com pontos de construção, ponte, estreitamento |
| 2 | o gerador **encaixa** só peças compatíveis (*Wave Function Collapse*) |
| 3 | o **validador roda antes de entregar**: existe caminho? há pontos de construção ao alcance? comprimento na faixa? Falhou, gera outro |
| 4 | **a semente é o mapa** — mesma semente, mesmo mapa, compartilhável |
| 5 | a **dificuldade é medida** pelo simulador com as 3 políticas |

**Motivo (medido, com fonte):** a pesquisa acadêmica mostra que posição aleatória de torre e
caminho *"quase sempre gera fase impossível de vencer"*, e que validação reduz **73%** as fases
injogáveis. O `kit-puzzle` deste repositório já é essa máquina: o mesmo algoritmo valida, gera,
dá a dica e mede a dificuldade.

**A separação que isso exige:** quinze mapas à mão = **a campanha**, que ensina e vende.
Gerados = **modo sem fim**, que faz rejogar. São duas linhas de produção diferentes.

**Trava:** o conteúdo (B6), a arquitetura (B9) e a produção (B11).

### D-004 · B0 · A leitura do tema dimensional 🔴

**Valor:** <em aberto — 5 opções apresentadas, aguardando escolha>
**Motivo:** —
**Trava:** a ação central (B3), o conteúdo (B6), a apresentação (B10) e a fábrica de assets (B12).

### D-016 · B1 · Onde o castelo fica no mapa 🟢 👤

**Valor:** quatro arranjos, sorteados por mapa — **meio**, **embaixo da tela**, **no canto** e
**escada** (o terreno sobe em degraus e o castelo fica no alto da tela).

**Motivo:** o Joab pediu os dois últimos por nome. E eles mudam o jogo, não só a foto: com o
castelo embaixo, o inimigo desce em cima do jogador e a defesa fica comprimida; na escada, cada
degrau só tem 3 rampas, então a subida inteira é um funil — o inimigo passa por todos, um atrás
do outro.

**Como a escada funciona:** a câmera é isométrica, então "alto da tela" é `x+y` pequeno. O corte
dos degraus acompanha `x+y`; na tela os andares saem empilhados, como arquibancada.

**O que isso obrigou a consertar:** inimigo só nasce na parte baixa do mapa e a pelo menos 18
passos do castelo; quando o castelo está num canto, o espaçamento das entradas afrouxa até caber
3 frentes; ponte agora também vence um degrau (o rio afunda o leito).

**Medido:** aprovação em 40 sementes — meio 39, escada 36, embaixo 36, canto 32. O gerador
anda na semente seguinte quando uma reprova, então isso nunca chega ao jogador.

**Trava:** o conteúdo (B6) e a apresentação (B10).

### D-017 · B0 · O nome do jogo 🟡 🤖

**Valor proposto:** **Veilspire** — *veil* é o véu fino entre as dimensões, *spire* é a torre.
Uma palavra, duas sílabas fortes, livre na Steam e na busca em setembro de 2026.

**Alternativas verificadas:** *Lastspire* (livre, mas "last" já está gasto em jogo de defesa) ·
*Fendra* (de "fenda", livre, fácil em português, mas não diz que é torre).
**Descartados por já existirem:** tudo com *Rift* (Riftfall, Rift Riff, The Riftbreaker,
The Rift Tower Defense), *Hollowspire*, *Nighthold*, *Dawnhold*, *Witchspire*.

**Falta:** o Joab escolher. Enquanto estiver 🟡 o nome não entra em `project.godot`, em arte,
nem em nome de pasta.
**Trava:** a identidade visual (B10) e a página da loja (B11).

<!-- Copie o bloco acima para cada decisão nova. Exemplos de cabeçalho válido:
### D-014 · B1 · Câmera do jogo 🟢 👤
### D-015 · B1 · O jogador pula 🟡 🤖
### D-022 · B3 · Ganho de calor por segundo 🟢 📏
-->

---

## Está pronto quando

- [ ] todo bloco da fase alvo está 🟢 na tabela de estado geral
- [ ] toda decisão 🟢 tem **motivo escrito** e **marca de origem**
- [ ] nenhuma decisão 🟡 sobrou em bloco que trava código
- [ ] `portao-plano.py` devolve a fase esperada
