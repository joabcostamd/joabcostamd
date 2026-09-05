# BANCADA DO CANDIDATO 1 — "SÓ A CRUZADA LEVANTA O TEAR"

## VEREDITO: **REPROVADA**

Não por estourar banda. Por **inércia**: a regra não muda uma única decisão da política
gulosa, e todas as outras políticas pioram. Ela cobra Tear e espetáculo e não devolve nada.

---

## 0. Decisões fixadas ANTES de medir (o briefing exigiu, estão no topo do `resultado.json`)

- **O Tear MULTIPLICA o quê:** `FATOR = (produto dos mults das mãos fechadas) × max(1, Tear)`.
  O produto vem da regra 6 do núcleo polido ("os multiplicadores se multiplicam entre si"),
  o Tear multiplica o produto inteiro. Tear inicial = 1 (com 0 o produto zeraria o jogo).
- **O teto da R15 (`24 + 4×rodada`)**: DESLIGADO na base e em todas as variantes — o núcleo
  polido o remove junto com o TEAR MULTIPLICA. O motor continua **registrando** quando ele
  morderia, e a fase E roda as quatro leituras (produto/soma × teto on/off).
- **K recalibrado por célula** até a razão pontos/meta da gulosa voltar a ~0,79. Sem isso a
  comparação seria vencida por deflação de meta (este candidato *tira* ganho: sem recalibrar,
  ele "perderia" só por ficar mais difícil).
- AVESSO ligado, AGULHA desligada em tudo.
- **Asserção de teto duro no código** (`push_error` acima de `floor((posic+sementes)/9)`
  cruzadas: 2 / 1 / 2). Disparou **0 vezes em 36.072 mesas**.
- 1.002 mesas por célula por política, sementes pareadas; m5 em 200 mesas.

---

## 1. A BASE, reproduzida (passo 2)

| métrica | declarado no briefing | medido aqui |
|---|---|---|
| cruzadas/mesa gulosa | 0,000 | **0,0000** |
| cruzadas/mesa caçadora b1 | 0,146 | **0,1457** |
| cruzadas/mesa profunda | 0,015 | **0,015** |
| % mesas com zero (gulosa) | 100% | **100,0%** |
| % turnos com recompensa | 65,7% | **64,8%** |
| seca mediana / p90 | 2 / 4 | **2 / 4** |
| maior evento único | 10.260 | **10.260** (exato) |
| pico/mediana | 15,8× | **15,64×** |
| Tear mediano / máx | 8 | **7 / 8** |
| razão pontos/meta | 0,79 | **0,823** |
| vitória global | 28,8% | **30,54%** (banda 20–40) |
| GUARDA m5 | 58,8% | **59,3%** (banda 45–75) |

A base bate. As duas diferenças (razão 0,823 e vitória 30,5%) vêm da calibragem de K ter sido
feita em 600 mesas e medida em 1.002; ambas ficam dentro das bandas e o K é o mesmo em todas as
células, então a comparação é pareada.

**A base declarada continua sendo uma quimera montada de duas bancadas**: `65,7% / seca 2 /
razão 0,79 / vitória 28,8%` vêm da leitura ADITIVA; `10.260 / 15,8×` vêm da leitura PRODUTO.
Fixei o PRODUTO e recalibrei K até a razão voltar — é a única forma de ter as duas metades ao
mesmo tempo.

## 2. A PLANEJADORA (passo 3) — e ela bate no teto aritmético

Não é a caçadora da b1 (que é gulosa com veto e nunca escolhe alvo). Esta escolhe o alvo
(L,C) **depois de ver as sementes**, maximizando braços já pagos; joga **só nos 8/12/16
braços**; nunca colhe de lado durante a montagem; usa os descartes só para a qualidade das
duas linhas alvo; troca de alvo quando `braços_faltantes + 1 > orçamento restante`.

Na BASE: **1,4511 cruzadas/mesa, 0,0% de mesas com zero, máximo 2.**
Por tipo de mesa: **Pequena 1,616 · Grande 1,000 (100% das mesas, teto absoluto 1) · Chefe
1,742**. Ela resolve o tabuleiro: encosta no teto aritmético do briefing em todas as três mesas.

Consequência metodológica desagradável: **a cláusula "planejadora ≥ 1,0 e < 40% de zero" é
satisfeita pela BASE**. Ela não discrimina candidato nenhum. A única cláusula que discrimina é
a da gulosa — e ela marca 0,0000 em tudo.

## 3. O CANDIDATO, varrido (passo 4) — 8 variantes, 1.002 mesas cada

| | BASE | V1 +nlin/tq4 | V2 +2/tq4 | V3 +nlin/tq0 | V4 +2/tq0 | V5 +1/tq4 | V6 +3/tq4 | V7 +nlin/tq3 | V8 +2/tq2 |
|---|---|---|---|---|---|---|---|---|---|
| K recalibrado | 2,15 | 1,691 | 1,691 | 0,543 | 0,543 | 1,691 | 1,691 | 2,186 | 3,037 |
| **cruz/mesa GULOSA** | **0,0000** | **0,0000** | **0,0000** | **0,0000** | **0,0000** | **0,0000** | **0,0000** | **0,0000** | **0,0000** |
| cruz/mesa PROFUNDA | 0,015 | 0,013 | 0,013 | 0,010 | 0,010 | 0,013 | 0,013 | 0,010 | 0,017 |
| cruz/mesa CAÇADORA | 0,1457 | 0,1427 | 0,1427 | 0,1397 | 0,1397 | 0,1427 | 0,1427 | 0,1417 | 0,1417 |
| cruz/mesa PLANEJADORA | 1,4511 | 1,4022 | 1,4022 | 1,3144 | 1,3144 | 1,4042 | 1,4002 | 1,4351 | 1,4202 |
| **DISTÂNCIA plan−gul** | **1,4511** | 1,4022 | 1,4022 | 1,3144 | 1,3144 | 1,4042 | 1,4002 | 1,4351 | 1,4202 |
| % mesas 0 cruz (gulosa) | 100,0 | 100,0 | 100,0 | 100,0 | 100,0 | 100,0 | 100,0 | 100,0 | 100,0 |
| cruz/EVENTO (planej.) | 0,947 | 0,958 | 0,958 | 0,961 | 0,961 | 0,956 | 0,958 | 0,947 | 0,955 |
| **TEAR mediano / médio** | **7 / 6,70** | 5 / 4,43 | 5 / 4,43 | **1 / 1,00** | **1 / 1,00** | 5 / 4,43 | 5 / 4,43 | 6 / 5,95 | 8 / 7,65 |
| **maior evento único** | **10.260** | 6.840 | 6.840 | **1.710** | **1.710** | 6.840 | 6.840 | 10.260 | 13.680 |
| pico/mediana | 15,64 | 11,52 | 11,52 | 7,92 | 7,92 | 11,52 | 11,52 | 14,25 | 13,03 |
| % turnos recompensa | 64,8 | 64,8 | 64,8 | 65,0 | 65,0 | 64,8 | 64,8 | 64,7 | 64,8 |
| seca med/p90 | 2/4 | 2/4 | 2/4 | 2/4 | 2/4 | 2/4 | 2/4 | 2/4 | 2/4 |
| razão pontos/meta | 0,823 | 0,840 | 0,840 | 0,847 | 0,847 | 0,840 | 0,840 | 0,823 | 0,823 |
| vitória % | 30,54 | 33,13 | 33,13 | 36,73 | 36,73 | 33,13 | 33,13 | 32,14 | 33,03 |
| GUARDA m5 % | 59,3 | 59,3 | 59,3 | 60,5 | 60,5 | 59,3 | 59,3 | 59,0 | 58,5 |
| **hold 4/5 (gulosa)** | **1,0** | **1,0** | **1,0** | **1,0** | **1,0** | **1,0** | **1,0** | **1,0** | **1,0** |
| hold 4/5 (profunda) | 1,766 | 1,772 | 1,772 | 1,629 | 1,629 | 1,772 | 1,772 | 1,824 | 1,894 |
| hold 4/5 (planej.) | 1,865 | 1,879 | 1,879 | 1,886 | 1,886 | 1,879 | 1,877 | 1,869 | 1,874 |
| % colheitas adiadas (prof) | 52,1 | 52,2 | 52,2 | 45,8 | 45,8 | 52,2 | 52,2 | 54,6 | 56,9 |
| % colheitas adiadas (plan) | 63,2 | 63,6 | 63,6 | 63,8 | 63,8 | 63,5 | 63,6 | 63,2 | 63,4 |
| asserção de teto quebrada | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

`+nlin` = a cruzada dá +1 por linha (como a base); `+1/+2/+3` = valor fixo; `tqN` = TIQUE do
Tear a cada N posicionamentos (`tq0` = desligado). Em todas as variantes
`tear_ganho_simples = 0`, que é a regra do candidato.

### O que a tabela diz

1. **Nenhuma banda estourou.** Recompensa 64,7–65,0%; seca 2/4; m5 58,5–60,5%; vitória
   30,5–36,7%. A reprovação não é por dano lateral.
2. **A gulosa é 0,0000 em todas as 9 células**, exatamente como a base. O critério declarado
   pedia > 0,25.
3. **Todo delta de cruzada é negativo.** Profunda 0,015 → 0,010–0,017. Caçadora 0,1457 →
   0,1397–0,1427. Planejadora 1,4511 → 1,3144–1,4351. A regra não melhorou uma única política.
4. **A DISTÂNCIA encolhe pelo lado errado.** O briefing avisou que a métrica boa é
   planejadora − gulosa, e que encolher é bom. Aqui ela encolhe (1,4511 → 1,3144) porque a
   **planejadora desceu**, não porque a gulosa subiu. É o falso positivo exato contra o qual o
   aviso foi escrito, e é por isso que a distância nunca pode ser lida sem o par.
5. **`hold 4/5` da gulosa é 1,0 em todas as células.** Este era o termômetro direto do problema:
   uma linha que chega a 4/5 é fechada no turno seguinte, sempre, com a regra e sem ela.
   O candidato não move o termômetro em 0,0.
6. **O risco declarado dispara.** V3/V4 (sem TIQUE) deixam o Tear parado em **1**, com maior
   evento 1.710 (16,7% da base) e explosão 7,92× (metade). Isso é abaixo do "cai abaixo de 4 e
   a regra se autodestrói" por uma margem larga. V1/V2/V5/V6 ficam em Tear médio **4,43** —
   raspando o limiar. Só V8 (TIQUE a cada 2) recupera o Tear, e recupera pelo TIQUE, não pela
   cruzada: é a regra financiando-se com aquilo que ela dizia substituir.

### Prova de que a regra é inerte por construção, não por falta de tuning

**Fase D.** Com o **mesmo K**, a gulosa da BASE e a da V1 escolhem a mesma jogada em
**99,96% dos 4.815 turnos comparados**, e **90,33% das mesas são idênticas do primeiro ao
último posicionamento**. Os 0,04% restantes são mesas que param em turnos diferentes porque a
pontuação acumulada difere.

A razão é algébrica: no modo produto o Tear é um **fator comum a todos os movimentos do mesmo
turno** (`FATOR = produto_dos_mults × Tear`). Mudar *quem levanta* o Tear muda a magnitude de
todo o turno por igual e **não reordena nada**. Uma política de 1 nível decide por ordenação.
Logo: **nenhuma regra que só mexa no Tear pode mudar a gulosa.** O candidato 1 é, para a
gulosa, matematicamente inerte — e isso vale para qualquer preço, exatamente como já havia
acontecido com o experimento de 4×/20×/100×.

### Dial morto

`tear_ganho_cruzada` ∈ {+1 por linha, +1, +2, +3} devolve números **idênticos até a quarta
casa** para gulosa, profunda e caçadora (V1 = V2 = V5 = V6). Só a planejadora os distingue, por
0,004 cruzada/mesa — ruído. É mais um dial de zero bit, na mesma prateleira dos já reprovados na
seção 6.5 do núcleo polido. **Não vire parâmetro.**

---

## 4. Parâmetro recomendado

**Nenhum.** Se a regra tiver de entrar por razão narrativa (ela já existe como o chefe 6,
*O Tear Preso*), a única versão que não demole o núcleo é a **V8** — `tear_ganho_simples=0`,
`tear_ganho_cruzada=2`, TIQUE a cada **2** posicionamentos, K=3,04 — que devolve Tear mediano 8
e maior evento 13.680. Mas ela compra isso com o TIQUE e continua entregando 0,0000 cruzada
gulosa. **Como modificador de chefe: serve. Como regra do núcleo: não.**

---

## 5. O que me surpreendeu

**(a) A escada 9/13/17 existe, é a estratégia dominante, e ninguém a tinha medido.**
Planejadora dedicada, 1.002 mesas, na BASE:

| figura | posic. | cruzadas/mesa | % mesas sem | razão pts/meta | vitória | maior evento | teto morderia |
|---|---|---|---|---|---|---|---|
| DUPLA | 9 | 1,451 | 0,0% | 1,188 | 64,2% | 33.516 | 12,4% |
| TRIPLA | 13 | 1,000 | 0,0% | 2,185 | 79,6% | 74.752 | 57,6% |
| **CRUZ TOTAL** | 17 | 0,880 | 12,0% | **5,823** | **90,8%** | **398.400** | 94,3% |
| ESCADA (auto) | — | 0,999 | 0,1% | 6,092 | 96,9% | 398.400 | 88,9% |

A Cruz Total cabe exatamente numa mesa Grande, vale **39× o teto emocional da base** e leva a
vitória a 90,8%. A coincidência aritmética do briefing é real e é grande demais para ficar
sem regra de preço.

**(b) O teto da R15 colapsa a escada, e o colapso não é monotônico.** Ligando o teto
`24+4×rodada` no modo PRODUTO, ele morde **12,7% das duplas, 56,5% das triplas e 94,5% das
Cruzes Totais**, e o fator cai de 2,313 / 5,417 / 12,403 para **2,085 / 3,134 / 2,782**. Isto é:
com o teto ligado, a **Cruz TOTAL (17 posicionamentos) passa a valer MENOS que a TRIPLA (13)**.
Pagar mais passa a render menos. É o colapso silencioso que o briefing previu, agora com número.

**(c) A escada 2×/3×/4× não existe em leitura nenhuma.** Fator medido da cruzada sobre as
mesmas mãos colhidas em separado:

| leitura | dupla | tripla | total | teto mordeu |
|---|---|---|---|---|
| SOMA (mults somam) | 1,424 | 1,887 | 2,098 | 0,0% em tudo |
| PRODUTO, teto OFF | 2,313 | 5,417 | 12,403 | (só registrado) |
| PRODUTO, teto ON | 2,085 | 3,134 | 2,782 | 12,7 / 56,5 / 94,5% |

A frase "a soma de mults da R15 já produz 2×/3×/4×" é **falsa nas três leituras**. A SOMA
entrega menos que o prometido, o PRODUTO sem teto entrega muito mais na tripla e na total, e o
PRODUTO com teto entrega uma escada não-monotônica. **Se 2/3/4 é o alvo de design, tem de ser
escrito, não herdado.** (Também confirmado: sob a leitura SOMA o teto realmente nunca morde,
0,0% até na Cruz Total — a observação do C08 sobrevive; o teto só existe no modo produto.)

**(d) O PULSO NÃO financia a montagem da cruz.** O briefing afirmava, por contagem aritmética,
que montar uma dupla é só 17% mais seco que o jogo guloso. Medido: durante a montagem a
planejadora paga em **47,5% dos turnos** contra 64,8% da gulosa, com **seca mediana 4 e p90 8**
contra 2 e 4. A conta de "4 pulsos em 9 posicionamentos" ignorava o `pulso_max_linha = 2` e os
turnos de montagem que não geram pulso nenhum. **Caçar cruzada continua sendo um deserto.**

**(e) O critério intencional × acidental proposto no briefing não funciona.** Ele classifica
**99,7% das cruzadas da planejadora como acidentais**, porque no instante do gatilho fechar duas
linhas *é* sempre a melhor jogada gulosa. O critério olha o último turno; a intenção está nos
oito anteriores. O substituto barato que funciona é `pct_colheitas_adiadas_de_propósito`:
**0,0% na gulosa, 52,1% na profunda, 63,2% na planejadora.**

**(f) Tirar Tear aumentou a taxa de vitória** (30,54% → 36,73% na V3/V4, com K recalibrado). Não
é buff: com o Tear travado a variância desaba, e um jogo mais previsível bate a meta mediana com
mais frequência mesmo com a mesma razão mediana. É um efeito colateral que qualquer candidato
deflacionário vai produzir, e que engana quem comparar vitória sem olhar pico/mediana junto.

---

## 6. O que NÃO funcionou

- **A tese do candidato.** "Tira o incentivo de fechar cedo" pressupõe um agente que compare
  o valor de fechar agora com o valor do Tear depois. Nenhuma política de 1 nível faz isso, e o
  Tear é fator comum — a gulosa não tem como enxergar o incentivo nem que quisesse. `hold 4/5`
  ficou em 1,0 em todas as células: **ninguém segurou nada.**
- **Desligar o TIQUE** (V3/V4) para "forçar" a cruzada a ser a única fonte de Tear. Como a
  cruzada não acontece, o Tear congela em 1, o evento máximo cai 83% e o jogo perde a escalada.
  É exatamente o risco declarado, e ele se realizou.
- **Compensar com TIQUE mais rápido** (V7 tq3, V8 tq2). Recupera o Tear e o espetáculo, mas
  por uma via que não tem nada a ver com a cruzada. É trocar a regra por outra e chamar de a mesma.
- **Aumentar o prêmio da cruzada via Tear** (V6, +3 por cruzada). Zero bits. Pela quarta vez
  neste projeto, mexer no preço de um evento que a política nunca vê não muda nada.
- **A cláusula "planejadora ≥ 1,0" como critério.** Ela é atendida pela base. Qualquer bancada
  que reporte "PARCIAL" com base nela está reportando a qualidade da própria planejadora.

---

## 7. Recomendação à decisão (uma frase por item)

1. **Descartar o candidato 1 do núcleo**; mantê-lo como modificador do chefe 6, na forma V8.
2. **Medir o candidato 4** (atrasar a destruição da R17 em um turno) com esta mesma planejadora
   — é o único dos quatro cuja mecânica pode mover `hold 4/5` da gulosa acima de 1,0, que é a
   única métrica que se moveria se o horizonte encurtasse.
3. **Nomear e precificar a escada 9/13/17 antes de qualquer outra coisa** — ela já é a
   estratégia dominante do jogo e hoje está sem preço declarado.
4. **Decidir o teto da R15 de propósito**, porque hoje ele é a diferença entre uma Cruz Total
   valer 12,4× e valer menos que uma tripla.

---

### Arquivos
- `resultado.json` — todas as medições, com as decisões de leitura no topo.
- `faseA.json` (calibragem de K) · `faseB.json` (base × 8 variantes × 4 políticas) ·
  `faseC.json` (escada 9/13/17) · `faseD.json` (invariância da gulosa) ·
  `faseE.json` (4 leituras da fórmula × teto).
- `banca1.gd` — a planejadora. `mesa2.gd` — motor com PRODUTO, meta_K, regra do candidato,
  rastreio do 4/5 e asserção de teto duro.
