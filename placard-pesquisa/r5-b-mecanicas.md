# BANCADA MECANICAS — RODADA 5

Medicao, nao opiniao. Tudo aqui tem numero atras; onde nao ha medicao esta escrito `nao medido`.

---

## 0. Motor e base

O briefing mandou copiar `placard/c4`. Copiei — e **c4 nao reproduz a base citada**: com o K do
proprio c4 (4,3922) ela da cruz **0,826**, vitoria **37,1**, m5 **67,4**. Os numeros do briefing
(0,831 / 36,1 / 68,2) sao os da bancada **fusao**, com **K = 4,40**. Como o briefing manda parar e
consertar se a base nao bater, troquei a base de codigo para `placard/fusao`, que e superconjunto
de c4 (mesmo nucleo, mesmas politicas, mais cfg). Reproduzido em 1.000 mesas pareadas:

| | citado | medido aqui |
|---|---|---|
| cruzes/mesa (gulosa) | 0,831 | **0,831** |
| turnos que pagam algo | 75,8% | **75,8%** |
| seca mediana / p90 | 2 / 3 | **2 / 3** |
| razao pontos/meta | 0,800 | **0,801** |
| vitoria gulosa | 36,1 | **36,1** |
| guarda de profundidade (m5) | 68,2 | **68,2** |
| turnos segurando 4/5 | 3,52 | **3,52** |
| planejadora cruzes / vitoria | 1,636 / 30,7 | **1,636 / 30,8** |
| distancia planejadora−gulosa | 0,805 | **0,805** |
| escada n2 / n3 / n4 | 51,9 / 18,2 / 0,85 | **51,92 / 18,19 / 0,85** |
| violacoes do teto duro 2/1/2 | 0 | **0** |

**BASE CONFIRMADA.** Toda variante foi recalibrada em K pela mesma rotina (3 iteracoes, alvo
razao 0,79). Essa rotina levou a **BASE de controle a K=4,5273 (vitoria 34,6)**. Todas as
comparacoes abaixo sao contra esse controle, nao contra o 36,1 publicado.

Volume: 1.000 mesas gulosa (m5 em 500, inercia em 300), 400 profunda (inercia em 150),
1.000 planejadora, por celula. 33 celulas. Sementes pareadas, 6 rodadas x 3 tipos.

---

## 1. Numeros de BASE que ninguem tinha medido (pedidos no briefing)

| medicao | valor |
|---|---|
| % de eventos que incluem uma diagonal | **47,0%** |
| % de posicionamentos nas 9 casas diagonais | **45,5%** (uniforme seria 36,0%) |
| casa mais quente do tabuleiro (todos os posicionamentos) | **6,7%**; C3 = **6,7%**; entropia **0,991** |
| jogadas legais por turno (mediana) | **85** |
| margem da 2a melhor jogada | **2,935%** |
| descartes usados por mesa | **2,645** de 2/3/3 |
| **pergunta (d) do Joab — quanto pagam as linhas que NAO fecham** | **5,2% dos pontos da mesa**; em mesa perdida **11,8%**; mediana **468** pontos contra evento mediano **3.250** (7x menor) |
| colheitas por mesa | 1,17 |
| cartas compradas por mesa | 29,5 |

Duas correcoes de leitura que o projeto vinha carregando:

1. **"As diagonais estao esquecidas" e falso.** Elas recebem 45,5% dos posicionamentos e entram em
   47,0% dos eventos. Nao ha buraco a preencher.
2. **"O descarte e o recurso mais fraco" e falso** para o descarte simples: a gulosa gasta 2,645
   dos 2/3/3 por mesa. O numero "quase zero" do historico e de `extra_descartes_usados`, outro contador.
3. O **C3 a 28,6%** do historico e o mapa de calor **do Avesso**, nao dos posicionamentos. Sobre
   todos os posicionamentos nenhuma casa passa de 6,7% e a entropia e 0,991.

---

## 2. TABELA — base x variantes (gulosa 1.000 / profunda 400 / planejadora 1.000)

`inerG/inerP` = % de turnos em que a jogada escolhida e IDENTICA com e sem a mecanica
(>95% = inerte). `dist` = cruzes planejadora − gulosa. `viol` = violacoes do teto duro 2/1/2.

| celula | K | vit G | vit P | vit D | P−G pp | cruz G | dist | m5 | inerG | inerP | rec | seca | viol | extra turnos | fecho% | beira% |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **BASE (controle)** | 4,53 | **34,6** | 29,9 | 26,25 | −4,7 | 0,831 | 0,808 | 68,2 | — | — | 75,8 | 2/3 | 0 | 0 | 5,2 | 0 |
| CTRL_FV (fecho conta p/ vitoria) | 4,53 | **40,7** | 30,9 | 31,25 | −9,8 | 0,831 | 0,808 | 68,2 | — | — | 75,8 | 2/3 | 0 | 0 | 6,4 | 0 |
| **P1 RESPIRO** | | | | | | | | | | | | | | | | |
| R_31 (R3=1,R4=2) | 4,63 | 33,6 | 28,5 | 26,25 | −5,1 | 0,831 | 0,809 | 68,2 | **100,0** | **100,0** | 75,5 | 2/3 | 0 | 0,23 | 5,6 | 0 |
| R_32 (R3=2,R4=3) | 4,65 | 34,0 | 28,3 | 26,0 | −5,7 | 0,831 | 0,810 | 68,2 | **100,0** | **100,0** | 75,4 | 2/3 | 0 | 0,46 | 5,7 | 0 |
| R_33 (R3=3,R4=4) | 4,74 | 33,2 | 27,5 | 26,0 | −5,7 | 0,831 | 0,811 | 68,2 | **100,0** | **100,0** | 75,3 | 2/3 | 0 | 0,68 | 5,7 | 0 |
| R_04 (so R4=4) | 4,53 | 34,6 | 29,9 | 26,25 | −4,7 | 0,831 | 0,808 | 68,2 | **100,0** | **100,0** | 75,8 | 2/3 | 0 | **0,04** | 5,3 | 0 |
| R_26 (R3=2,R4=6) | 4,72 | 33,2 | 27,9 | 25,75 | −5,3 | 0,831 | 0,811 | 68,2 | **100,0** | **100,0** | 75,4 | 2/3 | 0 | 0,49 | 5,7 | 0 |
| R_T3 (teto 3) | 4,65 | 34,0 | 28,3 | 26,0 | −5,7 | 0,831 | 0,810 | 68,2 | **100,0** | **100,0** | 75,4 | 2/3 | 0 | 0,46 | 5,7 | 0 |
| **R_PTS (o mesmo em PONTOS)** | 4,72 | **33,5** | **27,9** | 26,25 | −5,6 | 0,831 | 0,811 | 68,1 | 100,0 | 100,0 | 75,8 | 2/3 | 0 | (0,46 eq.) | 5,2 | 0 |
| R_R2 (a DUPLA tambem devolve 1) | 4,91 | 33,4 | **33,8** | 25,75 | **+0,4** | 0,832 | 1,129 | 67,9 | 100,0 | 100,0 | 75,0 | 2/3 | **317** | 1,07 | 6,6 | 0 |
| R_ALL1 (qualquer cruz devolve 1) | 4,86 | 33,5 | **34,2** | 25,75 | **+0,7** | 0,832 | 1,127 | 67,9 | 100,0 | 100,0 | 75,2 | 2/3 | **316** | 0,83 | 6,5 | 0 |
| R_R2_2 (R2=2,R3=3,R4=4) | 5,18 | 34,6 | 32,4 | 29,25 | −2,2 | 0,840 | 1,134 | 68,1 | 100,0 | 99,9 | 74,7 | 2/3 | **324** | 1,91 | 5,8 | 0 |
| **P2 ULTIMA COSTURA** (controle = CTRL_FV) | | | | | | | | | | | | | | | | |
| F_035 (F=0,35) | 5,50 | 37,6 | 24,1 | 32,25 | −13,5 | 0,831 | 0,825 | 68,1 | **100,0** | **100,0** | 75,7 | 2/3 | 0 | 0 | **17,1** | 0 |
| F_050 (F=0,50) | 5,83 | 38,4 | **22,4** | 33,75 | −16,0 | 0,831 | 0,828 | 68,1 | **100,0** | **100,0** | 75,7 | 2/3 | 0 | 0 | **22,8** | 0 |
| F_065 (F=0,65) | 6,13 | 39,2 | **21,3** | 34,25 | −17,9 | 0,831 | 0,829 | 68,1 | **100,0** | **100,0** | 75,7 | 2/3 | 0 | 0 | **27,9** | 0 |
| F_080 (F=0,80) | 6,33 | **40,2** | **20,5** | 35,75 | −19,7 | 0,831 | 0,831 | 68,1 | **100,0** | **100,0** | 75,7 | 2/3 | 0 | 0 | **32,3** | 0 |
| F_C4 (C=4, F=0,65) | 4,15 | **41,9** | 33,2 | 33,75 | −8,7 | 0,830 | 0,800 | 68,3 | 100,0 | 100,0 | 75,8 | 2/3 | 0 | 0 | 1,9 | 0 |
| F_D10 (diagonais 1,0 no fecho) | 6,18 | 39,5 | 21,5 | 35,25 | −18,0 | 0,831 | 0,830 | 68,1 | 100,0 | 100,0 | 75,7 | 2/3 | 0 | 0 | 29,5 | 0 |
| F_TB1 (Tear +1 por linha no fecho) | 6,08 | 39,2 | 21,1 | 33,75 | −18,1 | 0,831 | 0,829 | 68,1 | 100,0 | 100,0 | 75,7 | 2/3 | 0 | 0 | 27,7 | 0 |
| **P3 BEIRA** | | | | | | | | | | | | | | | | |
| B_1 (B=1) | 4,72 | 33,2 | 29,2 | 30,25 | −4,0 | 0,834 | 0,809 | 68,6 | **97,1** | **90,3** | 76,0 | 2/3 | 0 | 0 | 5,4 | **2,86** |
| B_2 (B=2) | 4,65 | 35,2 | 30,1 | 29,0 | −5,1 | 0,838 | 0,801 | 68,9 | **95,1** | **86,5** | 76,0 | 2/3 | 0 | 0 | 5,0 | **5,16** |
| **B_3 (B=3)** | 4,63 | **35,7** | **31,6** | **32,75** | −4,1 | 0,836 | 0,802 | 68,8 | **92,9** | **84,1** | 76,1 | 2/3 | 0 | 0 | 5,0 | **7,40** |
| B_5 (B=5) | 4,72 | 34,1 | **32,5** | 31,0 | **−1,6** | 0,842 | 0,796 | 69,0 | **90,2** | **80,7** | 76,4 | 2/3 | 0 | 0 | 5,3 | **10,5** |
| B_3C (jogar da Beira compra) | 4,63 | 35,7 | 31,6 | 32,75 | −4,1 | 0,836 | 0,802 | 68,8 | 92,9 | 84,1 | 76,1 | 2/3 | 0 | 0 | 5,0 | 7,40 |
| B_3A (descarte agressivo) | 4,62 | 35,7 | 31,8 | 33,0 | −3,9 | 0,836 | 0,802 | 68,7 | 92,8 | 84,2 | 76,1 | 2/3 | 0 | 0 | 5,0 | 7,43 |
| B_3D (descartes 3/4/4) | 5,84 | 33,4 | 24,5 | 30,5 | −8,9 | 0,852 | 0,794 | 68,2 | 93,5 | 83,2 | 76,1 | 2/3 | 0 | 0 | 4,4 | 6,37 |
| B3_R2 (Beira 3 + Respiro na dupla) | 4,90 | 36,0 | **36,7** | 32,5 | **+0,7** | 0,837 | 1,127 | 68,7 | 92,8 | 83,8 | 75,3 | 2/3 | **320** | 1,07 | 6,1 | 7,53 |
| **P4 FIO DE OURO** | | | | | | | | | | | | | | | | |
| O_08 (diagonal 0,8 na tripla+) | 4,61 | 34,0 | 28,6 | 26,5 | −5,4 | 0,831 | 0,809 | 68,2 | **100,0** | **100,0** | 75,8 | 2/3 | 0 | 0 | 5,2 | 0 |
| O_10 (1,0) | 4,72 | 33,2 | 27,9 | 26,0 | −5,3 | 0,831 | 0,811 | 68,2 | **100,0** | **100,0** | 75,8 | 2/3 | 0 | 0 | 5,3 | 0 |
| O_13 (1,3) | 4,79 | 32,9 | 26,7 | 26,25 | −6,2 | 0,831 | 0,812 | 68,2 | **99,9** | **100,0** | 75,8 | 2/3 | 0 | 0 | 5,2 | 0 |
| O_10T (1,0 so na CRUZ TOTAL) | 4,53 | 34,7 | 29,9 | 26,25 | −4,8 | 0,831 | 0,808 | 68,2 | **100,0** | **100,0** | 75,8 | 2/3 | 0 | 0 | 5,2 | 0 |
| O_TD (+1 Tear se o evento tem diagonal) | 4,56 | 35,0 | 29,5 | 27,25 | −5,5 | 0,831 | 0,809 | 68,2 | **100,0** | **100,0** | 75,8 | 2/3 | 0 | 0 | 5,4 | 0 |

Triplas por mesa ficaram em **0,210–0,217** em TODAS as 33 celulas (base 0,213). Cruz Total em
**0,007–0,011**. m5 em 67,9–69,0. Nenhuma celula estourou rec, seca nem cruz/mesa.

---

## 3. Veredito por proposta

### [1] RESPIRO — **REPROVADA**, e reprovada pelo proprio teste que a proposta pediu

1. **A celula de controle critica derruba a hipotese central.** A proposta diz: "todo premio em
   pontos e lavado pela curva de metas; turno nao e". Calibrei em pontos exatamente o mesmo ganho
   medio (500 pontos por turno devolvido, achado por secante ate a razao pontos/meta igualar a de
   R_32 no mesmo K). Resultado: **R_PTS 33,5 / 27,9 contra R_32 34,0 / 28,3**. Diferenca dentro do
   ruido. **Turno e lavado por K exatamente como ponto.** K subiu de 4,53 para 4,65 (turnos) e
   4,72 (pontos) — a lavagem e a mesma operacao.
2. **Zero bits de decisao**: inercia gulosa **100,0%** e profunda **100,0%** em todas as celulas.
   (Aviso honesto: isso e por construcao — as politicas so olham pontos imediatos. Mas e tambem o
   que a UI vai mostrar: a mecanica nunca muda qual casa acende.)
3. **Cruz, triplas e m5 nao se mexem**: 0,831 / 0,213 / 68,2 em toda a varredura.
4. **Ela taxa o planejador e paga o improvisador.** A vitoria da gulosa cai 34,6 → 33,2–34,0; a da
   planejadora cai mais, 29,9 → 27,5–28,5. Motivo medido: o premio esta na TRIPLA, e a planejadora
   quase nao faz triplas (92,9% dos eventos dela sao DUPLA); ela paga a inflacao de K sem receber.
   R_04 (so a CRUZ TOTAL devolve) devolve **0,04 turno por mesa** — precifica o que nao acontece,
   exatamente o erro de 4x/20x/100x ja registrado em DECISOES.md §3.
5. **A unica configuracao em que o planejador finalmente vence — R_R2 e R_ALL1, +0,4 e +0,7 pp —
   quebra o teto duro.** 317 e 316 violacoes em 1.000 mesas de planejadora, todas na mesa GRANDE:
   as cruzes por mesa Grande vao de **1,000 (max 1, 44.000 mesas sem uma violacao) para 1,949**.
   E a fantasia da Grande morrendo, exatamente o risco que a propria proposta nomeou.
   E note: sao as celulas que a proposta ofereceu como CONTROLE NEGATIVO ("para provar que o efeito
   vem do degrau alto"). O efeito vem so do degrau comum, e o degrau comum quebra a aritmetica.
6. **Custo em conceito: 1 conceito novo + um orcamento que muda no meio da mesa** — e o orcamento
   e justamente a grandeza contra a qual o jogador planeja.

### [2] ULTIMA COSTURA — **REPROVADA**, mas produziu o maior achado da rodada

1. **Nao ensina a recusa, que era a metade forte do argumento.** turnos segurando 4/5:
   **3,504** (base 3,517). % de mesas terminando com 3+ linhas em 4/5: **0,1%** (base 0,2%).
   Colheitas por mesa 1,19 (base 1,17). Nada mudou no comportamento. Inercia 100,0/100,0.
2. **Ela desaba o planejador**: 30,9 → **22,4** (F=0,50) → 21,3 (0,65) → **20,5** (0,80). A
   distancia planejadora−gulosa vai de −9,8 pp para **−19,7 pp**. E a celula mais anti-planejador
   da rodada inteira. Motivo: o fecho paga quem deixa linhas soltas no tabuleiro; a planejadora
   termina com os bracos da cruz ja colhidos, entao ela so paga o K inflado (4,53 → 6,33).
3. Onde ela funciona: a fracao dos pontos vinda do fecho entra na banda proposta 15–30% em
   F=0,35 (17,1), F=0,50 (22,8) e F=0,65 (27,9); F=0,80 vai a 32,3 e leva a vitoria global a
   **40,2 — fora da banda 20–40**. A profunda ganha bastante (26,25 → 33,75/35,75). Mas nada disso
   compra o objetivo declarado.
4. C=4 (F_C4) mata o fecho (1,9% dos pontos) e leva a vitoria a **41,9 — fora da banda**.
5. **O achado, e ele nao e uma mecanica:** hoje o motor calcula a vitoria ANTES da colheita final
   (`if not venceu: colheita_final()`), entao **o fecho nunca pode virar a mesa**. So permitir que
   ele conte (celula CTRL_FV, nenhuma outra mudanca, mesmo K, mesma cruz, mesmo m5, mesma seca)
   vale **+6,1 pp para a gulosa (34,6 → 40,7), +5,0 pp para a profunda e +1,0 pp para a
   planejadora**. Isso e um ponto de regra a decidir no documento, nao um numero de balanceamento —
   e ele muda a leitura de qualquer coisa que se meça em cima do fim de mesa daqui pra frente.
6. **Custo em conceito: 0** (substitui uma regra que ja existe) — e a mais barata da lista. Nao
   salva o resto.

### [3] BEIRA — **APROVADA em B=2 ou B=3**, a unica com decisao medida

1. **Unica proposta abaixo do corte de 95%**: inercia gulosa **92,9%** e profunda **84,1%** em
   B=3 (B=5: 90,2 / 80,7). Ou seja, em ~1 turno em 14 a Beira muda a jogada da gulosa e em ~1 em 6
   muda a da profunda.
2. **% de posicionamentos vindos da Beira**: 2,86 (B=1, abaixo da banda, decoracao) · **5,16**
   (B=2) · **7,40** (B=3) · **10,5** (B=5). B=2/3/5 dentro da banda 5–25%.
3. **Todas as bandas limpas**: m5 68,6–69,0 (banda 45–75), rec 76,0–76,4, seca 2/3, cruz
   0,834–0,842, vitoria 33,2–35,7, **zero violacoes do teto duro**.
4. **E o unico lever que estreita o abismo de pericia sem quebrar nada**: planejadora 29,9 →
   **31,6** (B=3) / **32,5** (B=5); profunda 26,25 → **32,75** (B=3). A distancia P−G em vitoria
   melhora de −4,7 para −4,1 (B=3) e **−1,6** (B=5).
5. **Ela FALHA no teste que a propria proposta escolheu como prova.** A margem da 2a melhor jogada
   **cai**: 2,935% → 2,857 (B=1..3) → **2,732** (B=5). As jogadas legais sobem de 85 para 120
   (B=3) e 130 (B=5). Mais opcoes, nao opcoes mais decisivas. O ganho de decisao aparece na
   inercia, nao na margem — e a carga visual e real: +41% de casas-carta na tela em B=3.
6. **Dois ramos da varredura nao existem, e isso e conclusao, nao lacuna:**
   - "jogar da Beira **tambem compra**" (B_3C) e **byte a byte identica** a B_3: jogar da Beira
     nao consome carta da mao, a mao ja esta com 5, a compra e no-op.
   - "descarte agressivo" (B_3A) tambem e identica: a gulosa **ja** gasta 2,63 dos 2/3/3 descartes
     por mesa. O descarte nao estava ocioso.
7. **Corte por B, nao por descartes_max — confirmado.** B_3D (3/4/4 descartes) infla K para 5,84,
   derruba a vitoria para 33,4 e a planejadora para **24,5**. E a pior celula da familia.
8. **Custo em conceito: 1** (uma fileira aberta de onde tambem se joga) + uma linha nova no
   invariante de conservacao de cartas (ja implementada e verificada: 52 faces).

### [4] FIO DE OURO — **REPROVADA. Dial de zero bit, registrar como tal em DECISOES.md**

1. **A premissa e falsa, e esse e o numero que decide.** As diagonais nao estao esquecidas: elas
   recebem **45,5% dos posicionamentos** (uniforme seria 36,0%) e entram em **47,0% dos eventos**.
2. Inercia gulosa **100,0 / 100,0 / 99,9** e profunda **100,0** nos tres fatores. Triplas por mesa
   0,213 → 0,215 / 0,214 / 0,217. Cruz 0,831 em todas. m5 68,2 em todas. Mapa de calor
   inalterado (C3 6,7%, entropia 0,991).
3. K recalibrado devolve **menos** vitoria: 34,6 → 34,0 / 33,2 / **32,9**; planejadora 29,9 →
   28,6 / 27,9 / **26,7**.
4. **O_10T (so a CRUZ TOTAL) e literalmente a base**: K identico (4,527), vitoria 34,7 contra 34,6,
   todas as demais metricas iguais. A Cruz Total ocorre **0,010 vez por mesa** — precificou-se de
   novo o que nao acontece. A diferenca que a proposta alegava (a TRIPLA ocorre em 18,2% dos
   eventos) e verdadeira, e mesmo assim o resultado e nulo: **o degrau existe, o preco dele nao
   compra decisao nenhuma.**
5. O_TD (+1 Tear com diagonal no evento) tambem inerte (100,0%), vitoria 35,0.
6. **Custo em conceito: 1 excecao a uma regra existente** ("60%, exceto quando..."). Excecao custa
   mais que regra.

---

## 4. O que surpreendeu

- **A hipotese "pontos sao lavados por K, turnos nao" e falsa e foi medida diretamente.** Foi a
  celula que o proprio briefing marcou como obrigatoria, e ela derruba a proposta 1 inteira.
- **O fecho nunca podia virar a mesa no motor.** Vale +6,1 pp de vitoria consertar isso. Isso e
  regra, nao balanceamento — precisa de decisao de documento antes da proxima medicao.
- **Tudo que paga por linhas soltas no tabuleiro (o fecho) e tudo que paga por eventos raros
  (Respiro, Fio de Ouro) TAXA a planejadora**, porque a planejadora colhe cedo, colhe duplas e nao
  deixa sobra. O padrao atravessa 3 das 4 propostas: **premiar um evento nao devolve pericia; o que
  devolve pericia e dar ao jogador mais controle sobre a carta que ele vai ter na mao.** So a
  Beira faz isso, e so ela mexeu na inercia.
- **A carga de decisao da Beira nao aparece na margem da 2a melhor** (que cai) e sim na inercia
  (que despenca). Se o projeto for usar "margem da 2a melhor" como regua de decisao, ela vai
  reprovar a unica mecanica que adiciona decisao. Trocar de regua.

## 5. O que NAO funcionou (para nao repetir)

- Premiar a TRIPLA e a CRUZ TOTAL, em turno (P1) ou em ponto (P4): **inerte em 100% dos turnos**,
  em 10 celulas diferentes, com 3 moedas diferentes. Fecha o assunto "precificar o degrau alto".
- Premiar a DUPLA em turno: **funciona e quebra o teto duro 2/1/2** (316–324 violacoes, Grande de
  1,000 para 1,95). Nao ha ajuste de R que salve: R_R2_T5 (teto 5 por mesa) da as mesmas 317.
- Fecho junto com F alto: **F=0,80 estoura a banda de vitoria (40,2)**; C=4 estoura pelo outro
  lado (41,9); e todos derrubam a planejadora.
- Aumentar descartes junto com a Beira (B_3D): pior celula da familia.

## 6. Recomendacao (uma so, e condicionada)

**Levar adiante SO a BEIRA, em B=3, sem mexer em descartes_max, sem o ramo "compra ao jogar".**
E a unica com decisao medida (inercia 92,9/84,1), a unica que estreita o abismo de pericia
(planejadora +1,7 pp, profunda +6,5 pp) e nao encosta em nenhuma banda. Custo: 1 conceito e
+41% de cartas na tela — decidir isso e playtest, nao simulacao.

**Antes de qualquer outra medicao desta familia, resolver a regra do fecho** (ele conta para a
meta ou nao?). Sao 6,1 pp de vitoria pendurados num `if`.

O que **nao** deve voltar: Respiro em qualquer R, e Fio de Ouro em qualquer fator ou escopo.

## 7. O que esta bancada NAO mediu

- Nada da assistencia, da UI, do painel de regras, nem dos pedidos (a) e (b) do Joab.
- Propostas de prioridade 3 e 4 (Bordado, Enxoval, Contador): **nao medidas**, ficaram fora por
  orcamento de tempo, como o briefing autorizou.
- A carga cognitiva real da Beira na tela: **nao medida** e nao mensuravel aqui.
- O teste de inercia usa as politicas existentes (gulosa 1 nivel, profunda 2 niveis). Uma politica
  que enxergasse o fim da mesa poderia dar outro numero para a proposta 2; **nao medido**.
