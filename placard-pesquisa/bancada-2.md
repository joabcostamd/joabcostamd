# BANCADA 2 — CASCATA / REAÇÃO EM CADEIA (PROPOSTA 4: O PRUMO)

**Veredito: REPROVADA COMO CASCATA.** A cadeia disparou **zero** vezes em 48.000 mesas com política
gulosa, nas 24 células da grade. O que sobra do Prumo é um buff de conservação de cartas que
empurra pontos/meta para 1,003 — acima do teto duro de 1,0 declarado pelo próprio painel.

---

## 0. ANTES DE TUDO: A LINHA DE BASE DA ORDEM DE SERVIÇO NÃO EXISTE

A base declarada (recompensa 65% · Tear mediano 8 · vitória 21,8% · pontos/meta 0,79 · seca 2)
é uma **colagem de três células isoladas diferentes**, nunca de uma configuração única:

| número da ordem de serviço | de onde ele realmente vem | o que a MESMA célula dá nos outros campos |
|---|---|---|
| 65,1% recompensa · seca 2 · vitória 21,8% | `v1_pulso_F035` = **só PULSO**, sem tique | Tear mediano **2**, pontos/meta **0,598** |
| Tear mediano 8 · pontos/meta 0,794 | `v2_tear_tick` = **só TIQUE, e com período 3** | recompensa **15,7%**, vitória 28,3% |
| (tique período 4 isolado, `v4`) | — | Tear **6**, pontos/meta 0,709, recompensa 15,5% |

Reproduzi as três células isoladas no meu motor e elas batem dentro do ruído
(só-pulso: 65,1 / 2 / 0,598 / Tear 2 / 20,9% · só-tique4: 15,3 / 0,686 / Tear 6 / 23,1% ·
núcleo cru: 14,3 / seca 7 / 0,43 / Tear 2 / 10,9%). **O motor está certo; o alvo é que não existe.**

**A base COMBINADA real (PULSO 0,35 + TIQUE 4), medida aqui pela primeira vez em 2.000 mesas:**

`recompensa 65,5% · gap mediano 1 · seca 2/4 · eventos 2,30 · cruzes 0,000 (100% das mesas sem)
· pontos 1.346 · pontos/meta 0,944 · maior evento 2.736 · pico/mediana 8,44× · Tear 6 (máx 7)
· vitória 39,9% (R1 95,8 · R2 78,4 · R3 45,6 · R4 13,8 · R5 4,8 · R6 0,3) · m5 = 57,7%`

**As duas correções já aprovadas, juntas, já ultrapassam o alvo de 0,79 e chegam a 0,944.**
Isso contamina o alvo "0,85–0,95" de todo o lote e precisa ser recalibrado antes de julgar
qualquer item. Não é opinião: é a medição pareada da própria base.

---

## 1. A TABELA — BASE × PRUMO

As **24 células** ({teto 2,3,4,ilimitado} × {Tear sobe/não sobe na cadeia} × {bônus_elo 0,1,2})
saíram **numericamente idênticas entre si nas 30 métricas**. Nenhum dos três eixos tem efeito,
porque o elo 2 nunca acontece. Por isso a coluna "Prumo" é uma só.

| métrica | BASE (pulso+tique) | PRUMO (todas as 24 células) | caçadora dedicada | alvo do painel |
|---|---|---|---|---|
| **m5 gulosa_completa × profunda** | 57,7% | **56,6%** | — | 45–75% ✔ |
| **m5 gulosa_míope × profunda** | 57,7% | **56,6%** (idêntica) | — | — |
| frac. colheitas com ≥1 elo | 0,0% | **0,0%** | 1,5% | 15–30% ✘ |
| mesas com cadeia 2+ | 0,0% | **0,0%** | 3,4% | 55–70% ✘ |
| mesas com cadeia 3+ | 0,0% | **0,0%** | 0,07% | 8–15% ✘ |
| maior cadeia observada | 1 | **1** | 3 | — |
| cruzes/mesa (gulosa) | 0,000 | **0,000** | 0,031 | ≥0,25 ✘ |
| cruzes por POUSO | 0,000 | **0,000** | 0,000 | maioria ✘ |
| pct. mesas com zero cruz | 100% | **100%** | 96,9% | — |
| cartas consumidas por evento | 5,00 | **4,32** | 4,34 | 5→4 ✔ |
| eventos/mesa | 2,30 | **2,47** | 2,46 | — |
| turnos com recompensa | 65,5% | **68,5%** | 69,4% | ≥65% ✔ |
| seca mediana / p90 | 2 / 4 | **2 / 4** | 2 | ≤3 ✔ |
| pontos/mesa mediana | 1.346 | **1.466** | — | — |
| **pontos/meta mediana** | 0,944 | **1,003** | 1,020 | 0,85–0,95, nunca >1,0 ✘ |
| maior evento único | 2.736 | **2.736** | 2.870 | — |
| pico/mediana (fator explosão) | 8,44× | **8,29×** | 8,15× | — |
| Tear mediano / máx | 6 / 7 | **6 / 8** | — | — |
| vitória global | 39,9% | **45,6%** | 48,8% | — |
| vitória R1..R6 | 95,8 78,4 45,6 13,8 4,8 0,3 | **97,6 86,8 58,6 25,2 4,8 0,6** | — | — |
| heat linha1/linha5 | 1,61 | **1,44** | — | <2,0 ✔ |
| teto R15 mordendo | 0,0% | **0,0%** | — | ≤8% ✔ |
| derrota decidida aos 2/3 | 64,3% | **63,4%** | — | <50% ✘ (ambos) |
| guarda de segurança (teto ilimitado) | — | **nunca atingida** (0 mesas) | — | — |

Células extras (pouso × pulso no desabamento), sobre a melhor célula:
`primeira_vazia` 1,003 / 45,6% / m5 56,6 · `ultima_vazia` 1,009 / 46,5% / m5 57,3.
Ligar ou desligar o pulso no desabamento move a vitória em 0,2 p.p. — **ruído**, porque não há pouso
que preencha linha nenhuma.

---

## 2. POR QUE ZERO — O DIAGNÓSTICO CAUSAL (é geometria, não tuning)

Contadores instrumentados **só nos posicionamentos reais** (as chamadas de prévia foram excluídas),
1.500 mesas por política. "Pista" = existe uma linha horizontal abaixo da viajante em **exatamente 4/5**
no instante da queda.

| política | quedas reais | **pista existia** | queda acertou a pista | sem casa abaixo | distância média |
|---|---|---|---|---|---|
| gulosa, pouso primeira | 3.866 | **0** | 0 | 31% | 1,10 |
| gulosa, pouso com MIRA | 3.866 | **0** | 0 | 31% | 1,10 |
| caçadora, pouso primeira | 3.948 | 192 (4,9%) | 42 (21,9% das pistas) | 29% | 1,12 |
| caçadora, pouso com MIRA | 3.951 | 216 (5,5%) | 93 (43,1% das pistas) | 29% | 1,14 |

**A falha é em dois estágios, e os dois são geométricos:**

1. **A pista quase nunca existe.** Para a gulosa: **zero vezes em 3.866 quedas.** Nunca. A gulosa
   nunca deixa uma linha parada em 4/5 — fechar é sempre localmente correto. É *literalmente o mesmo
   diagnóstico* que a auditoria deu para a cruz. O Prumo foi vendido como "a rampa de acesso que
   ensina a segurar uma linha em 4/5"; ele **pressupõe** essa habilidade em vez de ensiná-la. A pista
   de pouso é a cruz com outro nome, e por isso herda o problema inteiro dela.
2. **Quando a pista existe, a queda erra.** A grade tem ~9 cartas em 25 casas; a primeira casa vazia
   abaixo está a 1,1 linha de distância e quase nunca é o buraco único de uma linha em 4/5.
   `primeira_vazia_abaixo` erra 78% das pistas. Uma regra de MIRA (pousar na primeira casa vazia
   abaixo que *feche* alguma linha — determinística, sem modal, 100% visível na prévia; **fora da
   especificação do painel**, medida por mim para isolar os estágios) sobe o acerto para 43% e a
   fração de colheitas com elo de 1,5% para **3,1%** — ainda 3× abaixo do sinal de morte de 10%.

E há um terceiro fato estrutural que o documento não registra: **a viajante nunca pode fechar a
própria coluna** (ela sai de uma casa e entra em outra da mesma coluna, a contagem não muda), então
das 12 linhas vivas só **5 horizontais + 2 diagonais** podem ser fechadas por pouso — e a horizontal
de destino precisa estar em 4/5 com o buraco exatamente na coluna certa. A "cruz de pouso", que
era o argumento central da proposta, mediu **0,000 em todas as políticas, inclusive na caçadora**.

---

## 3. O QUE O PRUMO REALMENTE FAZ (e é preciso dizer)

Sem cascata, o Prumo continua fazendo **uma** coisa, e ela é real e mensurável: a viajante não vai
para a pilha `colhida`. **Cartas consumidas por evento: 5,00 → 4,32.** Isso é o ataque direto ao
teto duro de 3 eventos do C03, e ele funciona: eventos/mesa 2,30 → 2,47, turnos com recompensa
65,5% → 68,5%, vitória 39,9% → 45,6%, e o mapa de calor fica *menos* enviesado (1,61 → 1,44),
não mais.

Mas isso é um **buff de conservação disfarçado de mecânica de pico**. Ele custa 40 linhas, não
produz um único momento novo, não move a cruz de 0,000, não move o fator explosão (8,44 → 8,29)
e empurra pontos/meta para **1,003** — quebrando o teto que o próprio painel escreveu.

---

## 4. RECOMENDAÇÃO

**Não implementar o PRUMO como cascata.** Não há dial que o salve: a ordem de nerf pré-declarada
(bônus_elo → 0, depois teto → 2) é irrelevante, porque as 24 células já são idênticas. A regra de
corte do painel — "se fração de colheitas com elo < 10% em todas as células, a proposta CAI" —
foi acionada com folga: **0,0% na gulosa, 1,5% na melhor política dedicada, 3,1% com uma regra de
mira que o painel proibiu**.

Três coisas que eu recomendo que sobrevivam:

1. **Recalibrar a linha de base antes de qualquer outra decisão do lote.** PULSO 0,35 + TIQUE 4
   dá 0,944 e vitória 39,9%, não 0,79 e 21,8%. Enquanto isso não for corrigido, os alvos
   "0,85–0,95" das outras duas bancadas estão sendo medidos contra um número que não existe.
   Minha sugestão de dial, medida de passagem: `PULSO F=0,15 + TIQUE 4` dá pontos/meta 0,814 e
   recompensa 65,3% — reconstrói o 0,79 pretendido **sem** perder o ritmo, e é uma constante só.
2. **Guardar a sobrevivência da carta separada da cascata.** "A carta que você jogou não vai para
   a pilha" é uma frase, ~10 linhas, e vale +0,06 de pontos/meta e +5,7 p.p. de vitória sozinha.
   Se o TEAR-PRODUTO (bancada 1) devolver a curva ao lugar, isso vira um candidato barato de
   conservação — mas ele deve ser julgado como **economia de cartas**, não como dopamina.
3. **A habilidade "segurar uma linha em 4/5" continua órfã.** O Prumo foi escolhido pelo painel
   como a rampa pedagógica para ela; a medição mostra que ele exige a habilidade em vez de ensiná-la.
   Quem for atacar a cruz tem de atacá-la de frente (preço, como a Proposta 5; ou risco, como
   Avesso/Agulha), não por via oblíqua.

---

## 5. O QUE ME SURPREENDEU

- **O zero absoluto.** Eu esperava 5–10%, não 0 pistas em 3.866 quedas. O que eu não tinha previsto
  é que a gulosa não é só *rápida* em fechar 4/5 — ela é **exaustiva**: não existe um único instante
  do jogo, em 1.500 mesas, em que uma linha em 4/5 sobreviva a um turno.
- **As 24 células idênticas até a terceira casa decimal.** É o resultado mais limpo que eu já
  produzi e o mais inútil de todos: uma grade de 24 células que mede exatamente um bit.
- **A prévia é o teste mais barato de todos e teria matado isto em 20 minutos.**
  `_previa_igual_ao_resultado_com_cascata` passa perfeitamente — porque nunca há cascata para
  divergir. Um teste verde que prova o vazio.
- **O mapa de calor foi para o lado errado do esperado.** O risco 4 da proposta previa que a linha 1
  ficaria supervalorizada (>2× a linha 5). Mediu 1,44 contra 1,61 da base: o Prumo deixou a grade
  **mais uniforme**, porque a única coisa que ele muda é onde a carta termina, e ela termina embaixo.

## 6. O QUE NÃO FUNCIONOU (e vale tanto quanto o que funcionou)

- **`teto_de_elos` (2/3/4/ilimitado): efeito zero.** A guarda de segurança (64 iterações) nunca foi
  atingida. Cadeia ilimitada é indistinguível de cadeia de 2. O medo de laço infinito era infundado:
  a monotonicidade para baixo dá o teto de 4 quedas de graça, e eu provei construtivamente
  (`cadeia3.gd`: 3 elos, pousos em B3 e B5, 3.080 pontos, Tear 3→6, conservação 15==15) que o
  **motor encadeia** — é o **jogo** que nunca apresenta a configuração.
- **`bonus_elo` (0/1/2): efeito zero.** Nunca multiplicou nada.
- **`Tear sobe / não sobe durante a cadeia`: efeito zero.** Era o eixo que a ordem de serviço pediu
  explicitamente; ele não tem em que morder.
- **`pouso = ultima_vazia_abaixo`: efeito zero na cascata** (+0,006 de pontos/meta, que é só a
  viajante caindo mais fundo e liberando espaço acima).
- **`pulso_no_desabamento`: efeito zero**, porque não há desabamento que preencha linha.
- **A MIRA (minha própria tentativa de resgate, fora da especificação): falhou.** Dobra o acerto
  (22% → 43%) e ainda assim entrega 3,1% de colheitas com elo contra os 15–30% pedidos. Registro
  para que ninguém a proponha de novo achando que é a chave.
