# CRUZADA — livro-razão das decisões

Toda linha deste documento tem um **número medido** atrás. Nada aqui é opinião de designer.

As medições vêm de um protótipo headless do núcleo em GDScript rodado no Godot 4.7.2
(`sonda/`), com RNG semeado e comparações pareadas. Quando um número não foi medido, está
escrito `não medido` — nunca preenchido por estimativa.

**Como usar:** antes de propor qualquer mudança, procure aqui. Metade das boas ideias deste
projeto já foi testada e morreu com um número específico.

---

## 1. O ponto de partida: o núcleo cru

Como o jogo estava quando saiu do documento de design, antes de qualquer ajuste.
2.000 mesas por política, 6 rodadas × 3 tipos de mesa.

| Medição | Valor | Leitura |
|---|---|---|
| Turnos em que nenhuma jogada pontua | **85,9%** | o jogo era mudo |
| Jogadas legais por turno (mediana) | **100** | parecia pesadíssimo… |
| Margem da 2ª melhor jogada | **1,49%** | …e era irrelevante |
| Tempo entre recompensas (mediana) | **24 s** (p90 36 s, máx 60 s) | cadência de quebra-cabeça |
| Seca (turnos seguidos sem pontuar) | mediana **7**, máx 14 | |
| Eventos de pontuação por mesa | **2,3** — teto duro de 3 | ver §5 |
| Cruzadas por mesa | **0,00**, 100% das mesas com zero | o evento que dá nome ao jogo |
| Tear ao fim da mesa | mediana **2**, máx 3 | o teto 8 da regra era ficção |
| Taxa de vitória | **11,0%** | |
| Derrotas já decididas aos 2/3 | **72,5%** | tempo jogando partida perdida |
| Cartas vistas numa mesa inteira | **18 de 52** | |
| **Concordância gulosa × profunda** | **58,8%** | **o melhor número do projeto** |

Essa última linha é a que salvou o projeto: 58,8% fica exatamente entre o jogo que se resolve
sozinho (~95%) e o que pune a intuição (~20%). **O núcleo tem profundidade real.** Todo o resto
foi conserto de encanamento em volta de uma boa ideia.

---

## 2. APROVADO — entrou, com o número que aprovou

| Regra | O que faz | Efeito medido |
|---|---|---|
| **PULSO** (fator 0,35) | linha paga um troco ao chegar em 3/5 e 4/5, sem gastar carta nem turno | turnos com recompensa **14,3% → 65,1%**; seca **7 → 2**; espera **6 → 1** turno |
| **TIQUE DO TEAR** | +1 no Tear a cada 4 posicionamentos, além do +1 por colheita | Tear mediano **2 → 8**; razão pontos/meta **0,442 → 0,794** |
| **TEAR MULTIPLICA** | o Tear multiplica em vez de somar | maior evento **2.394 → 10.260** (×4,3); explosão **7,2× → 15,8×**; teto passa a morder em 21,2% das mesas (era 0%); derrota decidida aos 2/3 cai **69,9% → 56,6%**; e o código encolhe |
| **AVESSO** | carta de duas caras forjada pela própria colheita: uma cara vale na linha, a outra na coluna | **1,66/mesa**, 10,8% das jogadas, 37,8% dos pontos; **C3 recebe 28,6%** contra 4,0% do uniforme (**7×**, entropia 0,827); **+2,25 pp** de vitória |
| **K = 1,25** na curva de metas | corrige a dificuldade | razão **0,990 → 0,793**; vitória **40,75% → 28,8%** |

O número mais importante desta tabela é o **7× de concentração em C3**. Ele prova que *onde
colocar* é uma decisão de verdade, e não teatro — que era a dúvida existencial do design.

---

## 3. REPROVADO — não entra, com o número que matou

| Ideia | Por que parecia boa | O número que matou |
|---|---|---|
| **AGULHA** (coringa que vem pela compra e resolve como uma carta só) | o momento "veio o coringa!" | resíduo morto **66,7%** (banda 20–40%); é **anti-cruzada**: derruba de 0,087 para **0,032/mesa (−63%)**; leva 61,1% dos pontos; C3 em **4,2%** — indistinguível de aleatório |
| **PRUMO / cascata por gravidade** (a carta sobrevive à colheita e cai) | reação em cadeia é o motor de dopamina do Tetris | **0 elos em 48.000 mesas**; em **3.866 quedas a pista de pouso existiu 0 vezes** |
| **ESTRELA** (fechar 4 linhas em C3) | a fantasia de quebrar o jogo | **0 ocorrências** em 1.002 gulosas, 402 profundas e 1.002 caçadoras; **99,1%** das Estrelas contêm mão de mult ≤ 2 (o anticlímax é a norma); produto real mediano **24** contra 1.120 prometido — **47× otimista** |
| **Precificar a cruzada** (pagar muito mais por ela) | se o prêmio for enorme, o jogador persegue | preço ×4, ×20 e ×100: gulosa continuou em **0,0000**, 100% das mesas sem cruzada; a profunda **piorou** (0,0274 → 0,0174) |
| **Avesso "dobra os outs" da cruzada** | argumento central da proposta | **0,088 com** contra **0,087 sem**. Nulo |
| **AGULHA + AVESSO juntos** | dois coringas, mais opções | vitória **73,33%**, razão 1,159 — o jogo vira passeio, e ainda com **0,000 cruzada** |

### A descoberta que atravessa as três bancadas

> Em **30.944 turnos de jogo guloso não existiu uma única vez** uma jogada que fechasse duas
> linhas — com coringa na mão e sem.

A configuração que a cruzada exige (duas linhas em 4/5 compartilhando uma casa vazia)
**não aparece**. Fechar uma linha em 4/5 é sempre a jogada de maior ganho imediato, então
duas linhas nunca ficam esperando ao mesmo tempo.

**O gargalo é de ORDEM, não de carta nem de preço.** Nenhum coringa conserta, porque o coringa
responde *qual carta?* e o problema é *quando?*.

---

## 3b. ASSISTÊNCIA DE POSICIONAMENTO — mantida, com a régua trocada

O documento já oferece sugestão de jogada: halo verde/amarelo/vermelho nas casas vazias e
**anel numerado nas 5 melhores, ordenado por ganho de pontos**, desligável em três níveis.

**O que a medição diz a favor:** a assistência **não trivializa o jogo**. A jogada de maior
ganho imediato coincide com a ótima em apenas **58,8%** dos turnos, e segui-la sempre custa
só **1,4 ponto percentual** de vitória. O jogador assistido não é punido.

**O que a medição diz contra, e é grave:** a política gulosa do simulador *é* um jogador
seguindo o anel #1, e ela produziu **0,000 cruzada em 30.944 turnos**.

> A assistência não faz o jogador perder. Faz o jogador **nunca ver o melhor momento do jogo**.

E não é passiva: uma lista ordenada por ganho imediato **sempre** recomenda fechar a linha em
4/5, que é exatamente o que impede a cruzada. Ordenada assim, a assistência é uma máquina de
impedir o clímax — e ensina a jogada errada com ar de autoridade.

**Contradição no próprio documento:** a §15 exige que o jogador pensante vença **12 pp** a mais
que o assistido, sob pena de reprovar o build. O abismo real entre políticas competentes é
**1,4 pp** — a banda pede um abismo **8,6× maior que o maior que existe**. O teste, como está,
reprovaria o jogo.

**Decidido:** manter a feature, em três níveis, e trocar o que ela ordena e o que o teste mede.

| Nível | O que faz | Por quê |
|---|---|---|
| 1 — silenciar o ruído | apaga as ~85 casas que não mudam nada | em 86% dos turnos todas as jogadas dão o mesmo resultado; isso é ruído, não decisão. É informação, não conselho — pode ficar ligado até no modo difícil |
| 2 — mostrar a conta dos dois lados | "fecha a linha 3 (Trinca, 340 pts) **e** derruba a coluna C de 4/5 para 3/5" | o halo vermelho já faz metade; completar é o único mecanismo encontrado que **ensina a recusa** — o problema aberto que seis bancadas não resolveram |
| 3 — recomendação explícita | mantida para quem quer zero estresse, rotulada **"maior ganho agora"** e nunca "melhor jogada" | medimos: não é a melhor em 41% dos turnos. Rótulo honesto ou nada |

**Régua nova do teste de segurança:** medir vitória é medir a coisa errada — o custo da
assistência não aparece lá (1,4 pp). A pergunta que reprova o build passa a ser:
**um jogador que segue a dica chega a ver uma cruzada alguma vez?** Hoje a resposta é não.

---

## 4. DIALS QUE SÃO CÓDIGO MORTO — não vire parâmetro nenhum destes

Medidos, deram zero. Transformar isso em opção de balanceamento é dívida técnica gratuita.

| Dial | Resultado |
|---|---|
| Teto de Avessos por mesa (2 / 3 / 4 / sem teto) | **42,2% em todas** as configurações |
| Ganho de Tear por colheita (+1 / +2 / +3) | move a profundidade em **0,08 ponto** |
| `TEAR_TETO` acima de 8 | morde **0%** das mesas |
| Desempate do carimbo da Agulha (declarado "a primeira coisa a medir") | 53,17 × 52,33 |

---

## 5. LIMITES ESTRUTURAIS — aritmética das regras, não simulação

Consequências que saem direto das regras e que nenhum balanceamento contorna:

- Uma colheita manda **5 cartas** para uma pilha que não volta, e o orçamento é de 15/17/19
  posicionamentos. Logo: **teto duro de 3 eventos de pontuação por mesa**, e intervalo mínimo
  de **20 segundos** entre recompensas *por regra*, não por ajuste.
- Uma mesa vê **17 a 19 cartas** das 52 na vida inteira. O baralho nunca esvazia; a regra de
  reembaralhar o descarte praticamente nunca dispara.
- Teto teórico de cruzadas: **2** na Pequena e no Chefe, **1** na Grande (17 cartas < 18
  necessárias para duas). A banda "1,5 a 2,5 cruzadas por mesa" do documento original era
  **aritmeticamente impossível**.

---

## 6. ERROS DE MEDIÇÃO QUE NÓS COMETEMOS

Registrados de propósito. Errar de novo custa mais caro que admitir.

1. **Base medida errado.** A "linha de base" de uma das rodadas era colagem de duas variantes
   medidas em dificuldades diferentes. Produziu o número "vitória 21,8%" que circulou como
   verdade. O correto, pareado, é **28,8%**. → *Toda bancada agora reproduz a base e confere
   antes de medir variante.*
2. **Medir a cruzada com política gulosa mede o teto errado.** Montar uma cruzada exige
   planejar ~8 turnos à frente; políticas de 1 e 2 níveis não enxergam isso. Um humano
   enxerga. → *Toda medição de cruzada exige uma política planejadora.*
3. **"Maior evento de uma run vencida" foi medido como "de uma mesa vencida".** Escopo
   diferente, número diferente.
4. **Uma proposta chegou com número inventado no texto** ("produto ~1.120"); o medido foi 24.
   → *Número em proposta é hipótese até a bancada rodar.*

---

## 7. EM ABERTO

| Questão | Situação |
|---|---|
| **Como fazer a cruzada acontecer** | 4 candidatos em medição: só a cruzada levanta o Tear · maturação do 4/5 · semear mais o tabuleiro · um 4º desenhado pela aritmética |
| **Ergonomia do Avesso na tela** | não medido — desenhar uma carta de duas caras que se lê de relance é **condição de corte** do coringa |
| **Ensinar a recusa** | nenhuma bancada achou mecanismo que ensine o jogador a *não* fechar uma linha. É a habilidade central e ninguém a ensina |
| **AVESSO × PRODUTO** | combinação nunca rodada |
| **34% dos turnos ainda são mudos** | melhor que 86%, ainda não é Balatro (0%) |
| **O maior momento ainda é pequeno** | pico de 4,19× a meta, p99 de 2,36×. É "passei raspando", não "quebrei o jogo" |

---

## 8. O QUE A SIMULAÇÃO NÃO MEDE

Um simulador guloso não sente dopamina. A ausência de emoção no CSV não prova ausência de
emoção no jogador. Continuam sem resposta, e só playtest humano responde:

- o prazer de **ver** a cruzada acontecer, com animação e som
- se o Tear subindo de semitom em semitom cria o crescendo prometido
- se 100 jogadas legais por turno **parecem** paralisantes na tela, mesmo sendo equivalentes
- se o jogador entende sozinho que às vezes deve recusar pontos
