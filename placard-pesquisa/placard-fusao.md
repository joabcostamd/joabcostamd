# BANCADA FUSAO — as combinacoes dos 4 candidatos

Arquivos: `resultado.json` (todas as celulas cruas + vereditos), `bruto.json` (saida do motor),
`recal.json` (recalibragem de K das celulas de maturacao), `extra.json` (sensibilidade da formula),
`progresso.log` / `recal.log` / `extra.log`. Codigo: `mesa2.gd`, `bancada4.gd`, `variantes.gd`, `run.gd`.

## 0. Ponto de partida e o que foi conferido na fonte

Copiei a bancada **c4** (a mais completa das quatro: e a unica com a politica PLANEJADORA, com as
duas metricas novas do briefing — `turnos_segurando_4_5` e `pct_colheitas_adiadas` — e com a
assercao do teto duro no codigo) e portei para dentro dela os tres botoes que faltavam:
`tear_ganho_simples/cruzada` (c1), `mat_F/mat_teto/gulosa_ve_ritmo` (c2) e `n_sementes/vies/posic_ov`
(c3). Assim as quatro regras rodam no MESMO motor, com as MESMAS sementes.

Conferi os quatro `resultado.json` linha a linha antes de comecar (nao pelo resumo):

| bancada | veredito no arquivo | numero-chave conferido na fonte |
|---|---|---|
| c1 (so a cruzada levanta o Tear) | REPROVADA | gulosa 0,0000 em **todas** as 8 variantes; planejadora cai 1,4511 -> 1,3144…1,4351; Tear mediano 7 -> 5 (V1) e -> 1 (V3/V4) |
| c2 (maturacao do 4/5) | REPROVADA | gulosa 0,000 em F=0,08…1,0 e **0,012** em F=1,5; cacadora cai 0,146 -> 0,081 monotonicamente |
| c3 (semear) | REPROVADA | gulosa 0,000 para todo S de 3 a 12 com vies aleatorio; so S>=8 enviesado sobe (1,000), com **1,00 de 9 bracos pagos** pelo jogador |
| c4 (janela da colheita) | APROVADA (janela=1) | gulosa **0,826**, planejadora 1,628, m5 67,4, K +105% |

Os quatro mediram o que disseram ter medido. **Nenhum foi tratado como nao-medido.**

Uma divergencia metodologica real, que registro: c1, c2 e c3 fixaram a leitura **PRODUTO** (os mults
das maos multiplicam entre si) e c4 fixou **SOMA**. Herdei a leitura de c4 porque este codigo e o
dela, e remedi a sensibilidade (secao 6): a leitura muda o PRECO da cruzada, nao a frequencia.

## 1. Decisoes fixadas ANTES de medir (topo do resultado.json)

- **FATOR do evento = (SOMA dos mults das maos colhidas) x TEAR.** O Tear multiplica o evento
  inteiro. Teto 24+4*rodada REMOVIDO; a fracao em que ele TERIA mordido continua reportada.
- **K recalibrado POR CELULA** ate a razao pontos/meta mediana da GULOSA voltar a 0,79 ± 0,006.
  Comparacao na mesma dificuldade, nunca no mesmo K.
- **Material conservado** nas celulas com sementes: os posicionamentos caem para manter
  cartas-por-mesa em 18/17/19 (S=6 -> 12/11/13 posicionamentos).
- **Linha que nasce cheia na semeadura colhe no turno 0**, antes do jogador, mesmo com a janela
  ligada (no turno 0 nao ha jogador para decidir esperar). Pontua e sobe o Tear, mas nao entra em
  `cruzadas_por_mesa`; vai para `eventos_fantasma_por_mesa`. Medido: 0,002/mesa com S=6.
- **Maturacao x janela nao se pagam duas vezes**: uma linha MADURA tem conta=5 e a maturacao so paga
  linhas paradas em **4/5**. Sem esse cuidado a combinacao c2+c4 remuneraria o mesmo turno de espera
  por dois caminhos e o resultado seria artefato.
- **Teto duro no codigo**: <=2 (Pequena) / <=1 (Grande) / <=2 (Chefe). **0 violacoes em 44.000 mesas.**
  A Grande deu exatamente 1,000 com maximo 1 em toda celula e em toda politica.

Volume: 1.000 mesas gulosa (m5 em 500), 400 profunda, 1.000 planejadora, 1.000 cacadora-b1, por
celula; 600 mesas por iteracao de calibragem de K. Sementes `31337 + t*7919`, pareadas.

## 2. A BASE reproduz as tres bancadas

gulosa **0,000** cruzada / 100% de mesas zeradas / rec **64,8%** / seca **2/4** / Tear **7** /
maior evento **10.260** (exato) / pico-mediana **15,64x** / razao **0,800** / vitoria **31,2%** /
**m5 59,0%** / cacadora-b1 **0,144** com 85,6% de mesas zeradas / planejadora **1,490** com 0% zeradas.
Bate com c1 (0,1457 / 1,4511), c2 (0,146 / 1,455), c3 (0,144 / 1,437) e c4 (0,146 / 1,483).

## 3. A TABELA (1.000 mesas por celula, sementes pareadas)

| combinacao | K | GULOSA | PROFUNDA | CACADORA | PLANEJADORA | dist. p-g | %mesas 0 (gul) | cruz/evento | rec% | seca | Tear | maior ev | pico/med | razao | vit% | **m5** | seg 4/5 | %adiadas | veredito |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| BASE (nucleo polido) | 2.17 | **0.000** | 0.005 | 0.144 | 1.490 | 1.490 | 100.0% | 0.000 | 64.8% | 2/4 | 7 | 10260 | 15.64 | 0.800 | 31.2 | **59.0** | 0.00 | 0.0% | PARCIAL |
| J1  = c4 sozinho (recomendado) | 4.40 | **0.831** | 0.820 | 0.857 | 1.636 | 0.805 | 16.9% | 0.710 | 75.8% | 2/3 | 7 | 32600 | 10.03 | 0.800 | 36.1 | **68.2** | 3.52 | 80.2% | **APROVADA** |
| J1+c1  (so cruzada levanta Tear) | 4.39 | **0.831** | 0.820 | 0.857 | 1.636 | 0.805 | 16.9% | 0.708 | 75.8% | 2/3 | 7 | 32600 | 10.06 | 0.792 | 35.7 | **68.4** | 3.52 | 80.1% | **APROVADA** |
| J1+c1' (V8: +2 fixo, tique 2) | 7.79 | **0.831** | 0.825 | 0.857 | 1.637 | 0.806 | 16.9% | 0.713 | 75.8% | 2/3 | 8 | 56320 | 9.94 | 0.790 | 35.5 | **68.5** | 3.52 | 80.2% | **APROVADA** |
| J1+c3  S=6 sementes (conserva) | 3.14 | **0.823** | 0.838 | 0.859 | 1.588 | 0.765 | 17.7% | 0.746 | 92.0% | 1/1 | 6 | 24235 | 10.06 | 0.774 | 32.6 | **72.8** | 3.09 | 79.9% | **APROVADA** |
| J1+c3/2 S=3 sementes (conserva) | 4.00 | **0.835** | 0.843 | 0.857 | 1.632 | 0.797 | 16.5% | 0.731 | 83.4% | 1/2 | 6 | 28160 | 9.71 | 0.777 | 34.3 | **75.2** | 3.37 | 79.8% | REPROVADA m5=75.2 |
| J1+c2/2 maturacao F=0,75 | 6.63 | **0.764** | 0.830 | 0.814 | 1.637 | 0.873 | 23.6% | 0.752 | 82.1% | 2/3 | 7 | 32600 | 9.31 | 0.805 | 37.6 | **71.8** | 3.78 | 84.8% | **APROVADA** |
| J1+c2  maturacao F=1,50 | 8.83 | **0.672** | 0.788 | 0.741 | 1.637 | 0.965 | 32.8% | 0.730 | 81.9% | 2/3 | 6 | 32600 | 9.57 | 0.799 | 38.1 | **72.1** | 3.74 | 85.9% | **APROVADA** |
| J1+c2+c1 | 8.63 | **0.666** | 0.805 | 0.733 | 1.635 | 0.969 | 33.4% | 0.730 | 81.8% | 2/3 | 6 | 32600 | 9.59 | 0.802 | 39.4 | **72.4** | 3.74 | 85.9% | **APROVADA** |
| J1+c3+c2 (as tres melhores) | 6.24 | **0.651** | 0.768 | 0.732 | 1.594 | 0.943 | 34.9% | 0.743 | 96.3% | 0/1 | 5 | 24235 | 10.20 | 0.786 | 36.2 | **80.3** | 3.25 | 85.5% | REPROVADA m5=80.3 |
| J1+c3+c2+c1 (as quatro) | 6.24 | **0.651** | 0.785 | 0.732 | 1.594 | 0.943 | 34.9% | 0.741 | 96.3% | 0/1 | 5 | 24235 | 10.20 | 0.775 | 36.0 | **80.5** | 3.25 | 85.5% | REPROVADA m5=80.5 |
| J2+c1  (antidoto de m5 do J2) | 4.97 | **0.853** | 0.918 | 0.884 | 1.635 | 0.782 | 14.7% | 0.764 | 76.7% | 2/3 | 7 | 38892 | 10.01 | 0.785 | 34.2 | **76.9** | 3.59 | 80.4% | REPROVADA m5=76.9 |

`dist. p-g` = planejadora menos gulosa, a metrica que o briefing manda reportar. `seg 4/5` =
turnos que uma linha passa parada em 4/5. As celulas de maturacao tiveram K **recalibrado em ate
12 iteracoes** (secante amortecida): com F alto a maturacao e uma renda que sobe junto com a meta e
a calibragem de 4 iteracoes do c4 nao convergia — na primeira passada JM15 ficou com razao 1,008 e
vitoria 49,9%, o que teria feito a maturacao "vencer" por inflacao de meta. Os numeros da tabela ja
sao os convergidos (razao 0,799 / vitoria 38,1).

## 4. O que as combinacoes dizem

**Nenhuma combinacao bate o candidato 4 sozinho.** J1 domina a fronteira: nao existe celula com mais
cruzada na gulosa E m5 menor ou igual. As outras tres regras, somadas a ela, sao inertes ou negativas.

**(a) c1 e um dial de zero bit tambem DEPOIS que a cruzada existe.** Esta era a hipotese mais forte
de sinergia e ela **falhou de forma medida**: c1 foi reprovado sozinho porque a gulosa nunca fazia
cruzada, entao "so a cruzada levanta o Tear" equivalia a "nada levanta o Tear". Com a janela ligada
a gulosa faz 0,83 cruzada por mesa — o gatilho de c1 passa a existir de verdade. Resultado:
**J1 0,831 vs J1+c1 0,831**, m5 68,2 vs 68,4, distancia 0,805 vs 0,805, seg4/5 3,52 vs 3,52. Igual
ate a terceira casa. A explicacao da fase D da b1 continua valendo com a cruzada acontecendo: o Tear
e **fator comum a todos os movimentos do mesmo turno** e nao reordena nada; ele so muda K (4,40 ->
4,39). A variante V8 (`+2` fixo, tique a cada 2) so faz cosmetica: Tear mediano 8 e maior evento
56.320, com K inflado para 7,79 e a mesma 0,831 cruzada.

**(b) c2 (maturacao) e ANTI-cruzada quando somada a c4, e o mecanismo e claro.** F=0,75 leva a gulosa
de 0,831 para **0,764**; F=1,50 para **0,672** (-19%). As duas regras compram a MESMA decisao — "nao
feche ainda" — mas por objetos diferentes: a janela segura uma linha **cheia** enquanto o jogador
procura a perpendicular; a maturacao paga para deixar uma linha **em 4/5** parada. Elas competem
pelo mesmo turno. `seg 4/5` sobe (3,52 -> 3,74) e `%adiadas` sobe (80,2 -> 85,9), mas as cruzadas
CAEM: o jogador passa a ser pago por adiar coisas que nao viram cruzada. E o custo em dificuldade e
brutal: K de 4,40 para **8,83** (+101% sobre o ja inflado J1, +307% sobre a base).

**(c) c3 (semear) nao muda a cruzada e gasta a guarda de profundidade.** S=6 conservado: gulosa
0,823 (vs 0,831), planejadora 1,588 (vs 1,636) — sem ganho — e **m5 de 68,2 para 72,8**. S=3 (metade)
**estoura**: m5 75,2. O unico ganho real de c3 e colateral e vale registrar: ele **desinfla a meta**,
K cai de 4,40 para **3,14**, que era a ressalva n.1 da bancada c4. Mas paga isso destruindo a
textura de ritmo — rec 92,0% e **seca 1/1** (com S=6+c2, rec 96,3% e seca **0/1**: nao existe mais
turno seco, nada a desejar) — e cortando o Tear (7 -> 6) e o maior evento (32.600 -> 24.235).

**(d) As tres e as quatro juntas sao as piores celulas da bancada.** JSM/JSMT: gulosa **0,651**
(-22% contra J1 sozinho) e **m5 80,3/80,5**, muito acima do teto de 75. As regras nao se somam: cada
uma torna a jogada obvia um pouco mais obvia, e a soma resolve o tabuleiro pela UI.

**(e) c1 nao e antidoto do m5 de J2.** J2 sozinho reprovou em c4 so por m5=76,3. Com c1 junto:
**76,9**. Continua reprovada, e a gulosa (0,853) fica so 0,022 acima de J1.

## 5. O achado que organiza tudo: a guarda de profundidade e o orcamento escasso

O gargalo de toda combinacao e o **m5**, nao a cruzada. Ordenando as celulas por m5:

J1 68,2 · J1+c1 68,4 · J1+c1' 68,5 · **c2/2 71,8** · **c2 72,1** · c2+c1 72,4 · **c3 S6 72,8** ·
c3 S3 **75,2 ✗** · J2+c1 **76,9 ✗** · tres juntas **80,3 ✗** · quatro juntas **80,5 ✗**.

A base gasta 59,0 dos 75 pontos de banda. **A janela sozinha consome 9,2 dos 16 que sobravam.**
Toda segunda regra gasta os 6,8 restantes e a terceira estoura. Isso nao e coincidencia de tuning:
as quatro regras atacam a mesma doenca (o horizonte 9) pelo mesmo remedio — tornar visivel no turno
atual um valor que estava no turno 9. Cada uma que entra torna a jogada certa mais obvia; a
concordancia gulosa-x-profunda e exatamente a medida de "quao obvia esta a jogada". **O horizonte e
um recurso finito e a janela ja gasta quase tudo.**

Corolario para o design: nao existe "empilhar melhorias de cruzada". Escolhe-se **uma**.

## 6. Sensibilidade (celulas extras, sobre a regra vencedora)

| leitura | gulosa | profunda | planejadora | m5 | %cruzadas com o teto R15 mordendo |
|---|---|---|---|---|---|
| SOMA, teto R15 OFF (a adotada) | 0,831 | 0,820 | 1,636 | 68,2 | 29,8% |
| PRODUTO, teto OFF | 0,826 | 0,844 | 1,632 | 68,3 | **57,5%** |
| SOMA, teto R15 **LIGADO** | 0,831 | 0,845 | 1,635 | 68,1 | 29,4% |

**A ambiguidade da formula nao ameaca esta recomendacao**: as tres leituras dao a mesma frequencia
de cruzada (0,826-0,831) e o mesmo m5 (68,1-68,3). Ela muda o preco. Mas o aviso do teto do mult
continua valendo com forca: sob PRODUTO o teto morderia **57,5%** das cruzadas — se o painel fixar
PRODUTO **e** religar o teto, a escada colapsa em silencio. Sob SOMA, religar o teto e quase
inofensivo (a gulosa nem percebe: 0,831 identico), o que e um argumento a favor da leitura SOMA.

## 7. Recomendacao

**Adotar o candidato 4 sozinho: `janela = 1 turno, colheita conjunta livre`. Nao combinar com nada.**

Duas frases, como o criterio 5 pede: *"Uma linha completa nao e colhida na hora: ela fica MADURA por
um turno. No turno seguinte ela colhe — sozinha, ou junto com tudo o que tiver completado no meio
tempo."*

O que isso entrega (1.000 mesas): gulosa **0,831** cruzada/mesa com **83,1% das mesas** tendo pelo
menos uma; planejadora **1,636** com 0% de mesas zeradas; Pequena 0,869 / Grande **0,713** / Chefe
0,912 na gulosa, e 1,935 / **1,000** / 1,976 na planejadora — o teto aritmetico 2/1/2 batido na casa
decimal, com 0 violacoes. Bandas: rec 75,8% (>=60), seca 2/3 (<=3), vitoria 36,1% (20-40),
**m5 68,2%** (45-75), Tear 7, teto duro limpo.

**As tres ressalvas continuam sendo as de c4 e nenhuma combinacao as resolveu:**
1. **K sobe 103%** (2,17 -> 4,40). A unica coisa que desinfla e semear (K 3,14), e ela custa a guarda
   de profundidade e o ritmo. Se a inflacao de meta incomodar, e uma decisao de curva, nao de regra.
2. **cruz/evento 0,710** — a cruzada deixa de ser excecao e vira o modo normal de colher, e
   eventos/mesa cai de 2,21 para 1,17. O jogo fica com menos eventos, cada um maior
   (maior evento 10.260 -> 32.600, pico/mediana 15,6x -> 10,0x).
3. **Planejar deixa de pagar**: a razao pontos/meta da planejadora cai de 1,126 (base) para 0,665.
   A janela entrega a cruzada tao barata que o planejamento vira desperdicio. Nenhuma das outras
   tres regras corrige isso — a maturacao chega a piorar (0,44).

Se o painel quiser a versao mais conservadora com o mesmo veredito, `J1+c1'` (V8) e aceitavel e
**gratuita em cruzada** (0,831, m5 68,5): ela nao muda o jogo, so devolve Tear mediano 8 e um teto
de evento mais alto para a fantasia do chefe 6. Nao a recomendo — e um dial de zero bit medido
duas vezes, agora tambem com a cruzada acontecendo.

## 8. Observacoes de metodo para as proximas bancadas

- O criterio "intencional x acidental" do briefing continua quebrado (marca ~100% de acidente em
  toda politica, inclusive na planejadora, porque o gatilho da cruzada e quase sempre tambem a
  melhor jogada gulosa). Use `pct_colheitas_adiadas_de_proposito`: 0,0% na base gulosa, 80,2% com
  a janela — e a leitura honesta de "a regra criou a decisao de esperar".
- `turnos_segurando_4_5` na base e **0,000** para a gulosa e 0,843 para a planejadora: o termometro
  do briefing esta certo e a janela o leva a **3,52**.
- Reportar cruzada por mesa sozinha continua enganoso. Com a janela, `cruzadas_por_evento` = 0,710:
  o numero por mesa sobe em parte porque ha **menos eventos**, nao so mais cruzadas.
- A calibragem de K de 4 iteracoes nao converge em regras que criam renda proporcional a meta.
  Qualquer bancada futura com maturacao/pulso generoso precisa de secante amortecida e de conferir
  a razao final; sem isso o candidato mais inflacionario vence por inflacao.
