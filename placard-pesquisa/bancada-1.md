# BANCADA 1 — CORINGA. Leitura dos números.

Motor: `mesa2.gd` + `bancada.gd`, construídos sobre o `nucleo.gd` da sonda (avaliador de 5 cartas
**intocado**). 17 asserções em `testes2.gd`, todas passando (codificação do Avesso ida-e-volta nos
52×52 pares, involução do giro, faces por eixo, fichas seguindo a face, dobra pelas pontas,
conservação de FACES, conservação com agulhas `faces == 52 + carimbos`, agulha carimba e a colheita
esvazia 4 casas e não 5, bloqueio da segunda agulha viva na linha, determinismo por semente).

Volume: **1.200 mesas por célula** na política gulosa (redução declarada — o pedido era 2.000;
37 células × 4 políticas não cabiam no orçamento de tempo). m5 em **500 mesas** por célula.
A medição de OUTS rodou com **2.000 mesas**. **Sementes idênticas em todas as células**
(`semente = 31337 + t·7919`, `rodada = t%6+1`, `tipo = (t/6)%3`) — comparação pareada.
`cascatas_por_mesa` e `maior_cadeia` são **0 por construção** nas duas variantes (nenhuma cria cascata);
a métrica só faz sentido na bancada do PRUMO.

---

## 0. A LINHA DE BASE QUE O PAINEL DECLAROU NÃO EXISTE

Antes de medir qualquer variante eu reproduzi a sonda. Bate exatamente:

| célula | rec% | razão/meta | vitória% | Tear med | sonda (experimento.json) |
|---|---|---|---|---|---|
| núcleo puro | 14,3 | 0,442 | 10,42 | 2 | 14,3 / 0,442 / 10,42 / 2 — **idêntico** |
| PULSO 0,35 só | 65,4 | 0,614 | 21,67 | 2 | 65,1 / 0,598 / 21,83 / 2 |
| TIQUE 4 só | 15,3 | 0,720 | 21,58 | 6 | 15,5 / 0,709 / 23,58 / 6 |
| PULSO 0,35 + TIQUE 3 | 65,7 | 1,024 | 47,17 | 7 | 65,7 / 1,017 / 46,33 / 7 |

O motor está validado em quatro pontos conhecidos. **E é por isso que posso afirmar o seguinte:
a linha de base que a ordem de serviço declarou é uma quimera montada com duas variantes
diferentes.** "65,1% de turnos com recompensa" e "vitória 21,8%" vêm da variante **só PULSO**
(`v1_pulso_F035`, Tear 2, razão 0,598). "Tear mediano 8" e "razão 0,79" vêm da variante
**só TIQUE** (`v2_tear_tick`, recompensa 15,7%). As duas juntas nunca foram rodadas.

**PULSO 0,35 + TIQUE 4, medido: razão/meta 0,990 · vitória 40,75% · Tear mediano 6 (máx 7).**
Não 0,79 e 21,8%. Toda comparação abaixo usa essa base real, e eu carrego junto uma segunda base
recalibrada (**PULSO 0,15 + TIQUE 4**, razão 0,837, vitória 29,17%) porque a base literal já está
com a razão/meta praticamente em 1,0 — ou seja, **já está fora da regra "nunca acima de 1,0"
antes de qualquer coringa entrar**, e a taxa de vitória está saturada nas rodadas 1–2 (96,5% e 77,5%),
o que comprime artificialmente o efeito medido de qualquer item.

---

## 1. TABELA PRINCIPAL — base × melhores células

Política GULOSA, 1.200 mesas, sementes pareadas. m5 em 500 mesas.

| métrica | BASE A (P0,35+T4) | AGULHA A0 | AVESSO B3 | BASE B (P0,15+T4) | AGULHA (B) | AVESSO (B) |
|---|---|---|---|---|---|---|
| **m5 gulosa × profunda** | **55,0%** | **55,8%** | **55,2%** | **54,8%** | **55,5%** | **56,5%** |
| turnos com recompensa | 65,7% | 64,0% | 66,1% | 65,6% | 63,9% | 65,8% |
| turnos entre recompensas (med) | 1 | 1 | 1 | 1 | 1 | 1 |
| seca mediana / p90 | 2 / 4 | 2 / 4 | 2 / 4 | 2 / 4 | 2 / 4 | 2 / 4 |
| eventos por mesa | 2,30 | 2,41 | 2,26 | 2,40 | 2,54 | 2,39 |
| **cruzes por mesa** | **0,000** | **0,000** | **0,000** | **0,000** | **0,000** | **0,000** |
| mesas com zero cruz | 100% | 100% | 100% | 100% | 100% | 100% |
| pontos por mesa (mediana) | 1.368 | 1.568 | 1.428 | 1.214 | 1.445 | 1.234 |
| **razão pontos/meta** | **0,990** | **1,027** | **1,005** | **0,837** | **1,009** | **0,849** |
| maior evento único | 2.394 | 2.736 | 2.736 | 2.394 | 2.736 | 2.736 |
| **fator explosão (pico/mediana)** | **7,25×** | 6,93× | 8,00× | 7,25× | 6,87× | 7,93× |
| Tear mediano / máx | 6 / 7 | 6 / 8 | 6 / 7 | 6 / 7 | 6 / 8 | 6 / 7 |
| **vitória global** | **40,75%** | **53,17%** | **43,00%** | **29,17%** | **45,08%** | **31,42%** |
| vitória R1..R6 | 96,5 / 77,5 / 45,5 / 18,5 / 6,0 / 0,5 | 100 / 91 / 66 / 41 / 16 / 5 | 99 / 81 / 49,5 / 22,5 / 5 / 1 | 86 / 50,5 / 27 / 9,5 / 1,5 / 0,5 | 96,5 / 79,5 / 55 / 26,5 / 9 / 4 | 88,5 / 56 / 31 / 9,5 / 2,5 / 1 |
| coringas colocados / mesa | — | 1,30 | 1,66 | — | 1,33 | 1,70 |
| % dos posicionamentos | — | 9,1% | 10,8% | — | 9,0% | 10,7% |
| **% dos pontos via coringa** | — | **61,1%** | **37,8%** | — | **60,0%** | **36,6%** |
| **coringa em C3** | — | **4,2%** | **28,6%** | — | 4,1% | 19,8% |
| entropia do mapa de calor | — | 0,955 | 0,827 | — | 0,957 | 0,844 |
| derrota decidida aos 2/3 (def. própria) | 87,3% | 78,6% | 89,2% | — | 78,8% | 88,2% |

**GUARDA DE PROFUNDIDADE: nenhuma das 32 células saiu da banda.** m5 variou entre **54,1% e 56,6%**
em tudo que eu medi — base, Agulha, Avesso, todas as configurações, as duas bases. Isso é a primeira
notícia e ela é dupla: nenhuma variante **mata** a profundidade, e **nenhuma variante adiciona
profundidade** — o maior efeito de qualquer coringa sobre a m5 foi **+1,6 pontos percentuais**.

---

## 2. O NÚMERO QUE DECIDE: A CRUZ NÃO É UM PROBLEMA DE CARTA

Medição direta do argumento central do AVESSO ("ele dobra os outs da cruz"), 2.000 mesas por célula:

| trajetória | turnos com coringa na mão | desses, com jogada que fecha 2+ linhas | turnos sem coringa | desses, com jogada de cruz | cruzes/mesa |
|---|---|---|---|---|---|
| base, gulosa | 0 | — | 30.944 | **0 (0,00%)** | 0,000 |
| agulha, gulosa | 3.614 | **0 (0,00%)** | 25.042 | 0 (0,00%) | 0,000 |
| avesso, gulosa | 7.410 | **0 (0,00%)** | 23.481 | 0 (0,00%) | 0,000 |
| base, caçadora | 0 | — | 31.114 | 174 (**0,56%**) | 0,087 |
| avesso, caçadora | 6.550 | 1 (**0,015%**) | 24.460 | 175 (0,72%) | 0,088 |
| agulha, caçadora | 3.556 | 5 (0,14%) | 25.274 | 59 (0,23%) | **0,032** |

Leitura, sem rodeio: **em 30.944 turnos de jogo guloso não existiu UMA ÚNICA vez uma jogada que
fechasse duas linhas** — com ou sem coringa na mão. O replay da §4.4 mede "3 outs em 34 = 8,8%"
supondo a configuração já montada (duas linhas em 4/5 compartilhando uma casa vazia). **Essa
configuração não aparece.** Uma linha que chega a 4/5 é fechada no turno seguinte, e a R17 demole a
perpendicular. O gargalo da cruz é de **ORDEM**, não de carta: nenhum coringa conserta isso,
porque o coringa responde "qual carta?" e o problema é "quando?".

E há um resultado invertido que ninguém previu: **a AGULHA PIORA a cruz.** Sob a política
caçadora dedicada, ela derruba as cruzes de 0,087 para **0,032 por mesa** (−63%), porque fecha
linhas mais cedo e mais rápido, destruindo as configurações que a caçadora estava montando. O item
vendido como "a máquina de cruzes" é, medido, um **anti-cruz**.

---

## 3. AGULHA — o que funcionou e o que não funcionou

**Funciona como poder bruto, e só.** +12,4 pp de vitória sobre a base A, +15,9 pp sobre a base B.
Razão/meta vai a **1,027** — acima do teto declarado 1,0 — e a rodada 4 pula de 18,5% para 41% de
vitória. Se a Agulha entrar, **K da curva de metas tem de ser recalibrado antes**, não depois.

**O que NÃO funcionou, item por item, com o número:**

- **A cláusula central (R44e, "ela fica costurada") é inerte.** `fica_carimbada` × `evapora_junto`:
  vitória **53,17% × 50,75%**, m5 **55,8% × 55,5%**, razão **1,027 × 1,019**. O coração declarado da
  proposta vale **2,4 pp de vitória e 0,3 pp de m5**.
- **A taxa de resíduo morto é 66,7%** (banda pedida 20–40%; acima de 40% o painel classificou como
  "a Agulha é armadilha"). Dois terços dos carimbos nunca voltam a participar de nada.
- **O dial que o guardião mandou medir PRIMEIRO não decide nada.** `maior_fichas` ×
  `menor_ficha_que_preserva_a_categoria`: vitória 53,17 × 52,33, m5 55,8 × 55,9, resíduo morto
  66,7% × 66,9%. As quatro células do bloco 2×2 são estatisticamente a mesma célula.
- **O suprimento é desperdiçado.** 3,37 Agulhas criadas por mesa, **1,30 colocadas**. A mesa não
  cicla o baralho o bastante. Uma Agulha única, sem reposição por colheita (A4), entrega
  **50,83%** de vitória contra 53,17% com 3,37 — todo o motor de suprimento vale 2,3 pp.
  `teto` 2 / 3 / 4: 52,5 / 53,17 / 53,17. `bloqueio_inclui_diagonais` ligado/desligado: 53,17 / 53,42.
- **O mapa de calor diz que a decisão é falsa — por diluição, não por degeneração.** Entropia
  **0,955** do máximo e **C3 em 4,2%** dos posicionamentos de Agulha, contra 4,0% de uma escolha
  uniforme entre 25 casas. A tese "a casa certa migra da borda para o centro" **não aparece**: a
  política põe a Agulha em qualquer lugar. A pergunta da tarefa — "qual é a casa certa para um
  coringa?" — a Agulha simplesmente não responde.
- **A QUINA continua decoração.** 0,001 Quina por mesa (2 ocorrências em 2.000 mesas) — ~0,04% dos
  eventos, contra a banda pedida de 0,2–3%. O buraco C06 **não** foi fechado.
- **O único dial que faz alguma coisa é a janela de semeadura.** topo 12 → primeiro achado no turno 6,
  98,9% das mesas veem uma. Uniforme no baralho inteiro → só 0,72 colocadas e a vitória cai para 47,25%.
- **Regressão da linha de base:** turnos com recompensa cai de 65,7% para **63,3–64,2%** (abaixo do
  piso 65%), porque a mesa acaba mais cedo (17 → 15 turnos medianos). Seca mediana 2 e p90 4 intactos.
- **61,1% dos pontos da mesa passam por linhas com Agulha.** No teste equivalente ao limite duro
  do Avesso (≤45%), a Agulha **reprovaria**: o item virou o jogo.

---

## 4. AVESSO — o que funcionou e o que não funcionou

**Funciona como decisão, quase não mexe no poder.** +1,4 pp (extremos) a +2,25 pp (duas maiores
fichas) de vitória. Razão/meta 1,001–1,005 na base A e **0,849** na base B — ou seja, na base
recalibrada ele **não estoura o teto de 1,0**, o que a Agulha estoura em qualquer configuração.

**O que funcionou:**

- **A tese geográfica se realiza, e é o único número positivo de toda a bancada.** Mapa de calor
  do B3: **C3 recebe 28,6%** dos posicionamentos de Avesso (B0: 20,0%), contra ~4% de uma escolha
  uniforme — **7 a 8 vezes**. E os quatro cantos diagonais (A1, E1, A5, E5) vêm logo atrás
  (203, 144, 89, 66 contra ~30 de uma casa comum). Entropia **0,827**, longe da uniformidade (0,955
  da Agulha) e longe da degeneração (nenhuma casa passa de 30%). **A face lida pelas diagonais está
  pesando.** O alvo declarado era ≥25% em C3 — B3 bate, B0 não.
- **Limite duro respeitado:** 35,8% (B0) e 37,8% (B3) dos pontos vêm de linhas com Avesso, abaixo
  do teto de 45%. A grade não virou cenário.
- **Frequência dentro da banda:** 10,4–10,8% dos posicionamentos são Avesso (alvo 8–18%);
  1,61–1,66 forjados e colocados por mesa (alvo 1,0–2,5).
- **Espera forja→uso: mediana 1 turno** (alvo 1–3). O topo do baralho funciona como prometido.
- **Zero regressão:** turnos com recompensa 65,8–66,1% (≥65% ✓), seca 2/4, gap 1 — idênticos à base.
- **O gatilho tem de ser "toda colheita".** TRINCA+ → 0,97 colocados/mesa e 6,3% dos posicionamentos;
  FLUSH+ → 0,42 e **2,7%**, abaixo da banda: vira decoração. Confirmado por medição, não por argumento.
- **`duas_maiores_fichas` bate `extremos_da_linha` em tudo o que importa:** C3 28,6% × 20,0%,
  entropia 0,827 × 0,843, vitória 43,0 × 42,17, razão 1,005 × 1,001. **A hipótese do painel era o
  contrário** (só `extremos` criaria planejamento). Ressalva honesta: minha bancada não tem jogador
  humano arrumando as pontas de propósito, e as políticas não planejam pontas — então este eixo está
  medido **a favor de `duas_maiores` pelo lado errado**, e a decisão entre os dois não deve ser
  fechada só por este número.

**O que NÃO funcionou:**

- **O argumento central caiu.** Ver §2: os outs de cruz não dobraram; eles são zero com e sem
  Avesso na trajetória gulosa, e sob a caçadora o Avesso deixa as cruzes exatamente onde estavam
  (0,088 × 0,087). O autor pediu que o parâmetro 11 o desmentisse. Desmentiu.
- **Duplo pulso em 8,4–9,5%** dos posicionamentos de Avesso; o alvo era ≥20%. O "beat pequeno que
  sustenta a mesa" acontece em menos da metade da frequência prevista.
- **O teto de Avessos por mesa é código morto.** teto 2 / 3 / 4 / sem teto: 42,25 / 42,17 / 42,17 /
  42,17. A taxa natural nunca encosta no teto. Não é um dial, é um número que mente.
- **A face das diagonais é indiferente no placar.** Diagonais lendo `avesso` × lendo `direito`:
  vitória 42,17 × 42,42, m5 56,6 × 56,6. O que muda é só o mapa de calor (a tese geográfica), não o resultado.
- **A QUINA continua em 0,000 por mesa.** O BLOCO C da especificação (recalibrar fichas/mult da Quina
  com ela viva) é **inaplicável**: não há o que recalibrar, a categoria não ocorreu uma vez em 2.000 mesas.
- **Pré-requisito de ergonomia: NÃO MEDIDO — `null`.** A bancada é headless; eu não protótipei o
  `_draw` de 84×92 px com as duas faces em retrato 720×1280. A proposta continua com essa condição
  de corte **aberta**, e ela é a que o guardião usou para reprová-la.

---

## 5. RECOMENDAÇÃO

**Recomendo o AVESSO, célula B3** — `gatilho_da_dobra = toda colheita`, `escolha_das_pontas =
duas_maiores_fichas` (com a ressalva metodológica do §4), `teto_de_avessos = irrelevante, deixar 4`,
`face_das_diagonais = avesso`, `destino = topo do baralho`, `custo do giro = grátis` — **e recomendo
REPROVAR a AGULHA na forma medida.**

Por quê, em três números:

1. **m5 idêntica nos dois (55,2% × 55,8%), então a profundidade não desempata.** O que desempata é
   o mapa de calor: Avesso concentra em C3 e nos cantos diagonais (entropia 0,827, C3 a 7× o
   uniforme); Agulha é indistinguível de aleatório (entropia 0,955, C3 a 1,05× o uniforme).
   **A pergunta "qual é a casa certa para um coringa?" só tem resposta com o Avesso.**
2. **O Avesso cabe no orçamento de poder; a Agulha não.** Na base recalibrada, Avesso leva a
   razão/meta de 0,837 para 0,849 e a Agulha para 1,009 — a Agulha sozinha estoura o teto de 1,0 e
   obriga a mexer no K da R21 antes de qualquer outra coisa. E 61,1% dos pontos passando por ela
   é o item virando o jogo.
3. **A cláusula que era o coração da Agulha está morta na medição:** `fica` × `evapora` = 2,4 pp,
   resíduo morto 66,7% (banda 20–40%), e o `desempate_do_carimbo` — declarado "a primeira coisa a
   medir" — não muda nada. Pela **condição de morte declarada** na própria especificação
   ("se a proposta perdeu o seu coração, deve ser REJEITADA INTEIRA, não remendada"), a Agulha cai.

**Duas ressalvas que a recomendação não pode esconder:**

- **O Avesso não conserta a cruz, e nenhum coringa conserta.** Se o objetivo do lote era tirar
  m8 de 0,00, a resposta desta bancada é **negativa para a família inteira**. O gargalo está na
  ordem em que as linhas fecham, não na carta que fecha — o que aponta para as bancadas do PRUMO
  (que muda o que acontece DEPOIS da colheita) e do TEAR-PRODUTO (que muda o PREÇO de esperar),
  não para um coringa.
- **O Avesso, medido, é um item de decisão com efeito quase nulo no placar (+1,4 a +2,25 pp).**
  Ele é seguro e é bonito; ele não é, sozinho, "o núcleo em nível estado da arte". Se o painel
  quiser poder, a forma mais barata e menos deformante que eu medi é **uma Agulha única por mesa,
  sem reposição** (`E_AGULHA_teto1_colheita0`: vitória 50,83%, razão 1,019, m5 56,5%) — mas ela
  exige recalibrar K e continua sem entregar uma cruz.

**Não combinar.** AGULHA + AVESSO na mesma mesa (base recalibrada): vitória **73,33%**, razão/meta
**1,159**, turnos com recompensa 74,0%, 3,24 eventos por mesa — e **ainda 0,000 cruz por mesa**.
O jogo vira passeio sem entregar o clímax. Registrado, não recomendado.

---

## 6. O QUE MAIS ME SURPREENDEU

1. **A linha de base declarada não existia.** As duas correções aprovadas nunca tinham sido medidas
   juntas; juntas elas entregam razão/meta 0,99 e 40,75% de vitória, e a rodada 1 já vence 96,5% das
   vezes. **O núcleo já está com o teto de poder estourado antes de qualquer coringa.** Isso muda a
   prioridade do lote inteiro: recalibrar K é mais urgente que escolher item.
2. **Zero jogadas de cruz em 30.944 turnos.** Eu esperava um número pequeno; encontrei o número
   zero. Isso reclassifica o problema: a cruz não é rara, é **estruturalmente inexistente** sob
   qualquer política que feche linhas cheias.
3. **A Agulha reduz cruzes em 63%** na política que as caça. O coringa acelera o fechamento e come
   o próprio material da cruz.
4. **Os coringas criados não chegam à mão.** 3,37 forjados, 1,30 jogados. Todo desenho de suprimento
   por colheita é quase inerte porque o baralho não cicla dentro de 15–19 posicionamentos.
5. **`duas_maiores_fichas` venceu `extremos`** no eixo geográfico, contra a hipótese explícita do
   painel — com a ressalva de que minha bancada não modela um jogador arrumando pontas de propósito.

---

## 7. O QUE ESTÁ `null` E POR QUÊ

- **Ergonomia do Avesso (as duas faces legíveis em 84×92 px, retrato 720×1280): `null`.** Bancada
  headless, sem `_draw`. A condição de corte da proposta permanece aberta.
- **BLOCO C do Avesso (recalibrar fichas/mult da QUINA): `null` / inaplicável.** A Quina ocorreu
  0 vezes em 2.000 mesas com Avesso e 2 vezes em 2.000 com Agulha. Não há tabela a recalibrar.
- **`cascatas_por_mesa` e `maior_cadeia_observada`: 0 por construção**, não por medição — nenhuma
  variante desta bancada cria cascata.
- **`derrota_decidida_aos_2/3`: definição própria** (pontos < 45% da meta no marco de 2/3), porque
  o critério do 72,5% da auditoria não está escrito em lugar nenhum. **Não comparar com 72,5%.**
- **m5 da base "58,8%" não é reprodutível aqui**: aquele número foi medido no núcleo puro, sem
  PULSO e sem TIQUE. Com as duas correções ligadas, a m5 da base é **55,0%** — ainda dentro da
  banda, e é contra ela que as variantes devem ser lidas.
