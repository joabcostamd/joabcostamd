# BANCADA r5-b — ESTRATEGISTA

**O que esta bancada foi medir:** por que planejar deixou de pagar, e se alguma das sete
propostas devolve retorno ao estrategista sem estourar banda.

**Resposta curta:** o problema **não é** a política. É o jogo. E só **uma** das sete propostas
fecha a lacuna — o bônus de cruzada, mas **fora** do parêntese, não dentro; e quem ele paga
não é "o jogador atencioso", é o caçador de cruz. Isso está medido e não é opinião.

Volume: 1.000 mesas por célula de decisão, 400 na profunda, m5 a 500 (protocolo c4) com
confirmação a 1.000 nas duas pontas. Sementes `31337 + t·7919`, pareadas, 6 rodadas × 3 tipos.
K recalibrado por célula na gulosa até razão 0,79 ± 0,006 (secante amortecida, 600 mesas).
144 células. Nenhuma redução de volume nas células de decisão.

---

## 0. A base bate — e uma nota sobre os números do briefing

| | medido aqui | c4 `resultado.json` | briefing |
|---|---|---|---|
| gulosa, vitória | **37,1%** | 37,1% | 36,1% |
| gulosa, razão | **0,814** | 0,814 | — |
| cruzadas/mesa | **0,826** | 0,826 | 0,831 |
| m5 (n=500 / n=1000) | **67,4 / 68,3** | 67,4 | 68,2 |
| turnos pagos / seca | **75,8% / 2** | 75,8% / 2 | 75,8% / 2 |
| planejadora, vitória | **29,9%** | 29,9% | 30,7% |

Reproduz a c4 **dígito a dígito**. Os números do briefing (0,831 / 36,1 / 68,2 / 30,7) vêm da
bancada de **fusão** — outra rodada da *mesma* configuração. As diferenças são de amostragem
(cruzada ±0,012, vitória ±1,5 pp, m5 ±0,6 pp). Não há bug; adotei os da c4 porque é o código
que rodo, e todas as variantes são pareadas contra ele.

Duas correções de registro: o briefing cita `K = 4,4042` para J1; o valor real em `calib.json`
é **4,3922** (4,4044 é o K de J1_SEMAV). E a diferença planejadora−gulosa na base é
**−7,2 pp**, não −5,4.

**Controle do arnês:** a política TECELÃ com *todos* os pesos em zero reproduz a gulosa bit a
bit (37,1 / 0,814 / 0,826 / 6.477,0 pontos / mesma distribuição n1..n4). O instrumento novo não
introduz viés.

---

## 1. PRIMEIRO, o diagnóstico: (a) ou (b)?

### 1.1 A "ablação decisiva" da proposta 1 é um no-op, e há contador provando

| coeficiente do veto lateral | vitória | razão | cruzadas | pontos/mesa |
|---|---|---|---|---|
| 1.0e7 (atual) | 29,9 | 0,660 | 1,628 | 4.938,1 |
| 1.0e5 | 29,9 | 0,660 | 1,628 | 4.938,1 |
| 1.0e3 | 29,9 | 0,660 | 1,628 | 4.938,1 |
| **0** | **29,9** | **0,660** | **1,628** | **4.938,1** |

Idênticos até a quarta casa. E o contador direto: **0 movimentos punidos pelo veto em 4.230
turnos de planejadora**. O veto **nunca dispara**.

A razão é geométrica e a proposta a tinha nas mãos sem ver: a trava (2), o **túnel**, mantém o
tabuleiro em 16 casas vazias (mediana). Com nove casas ocupadas, nenhuma **terceira** linha
chega a 4/5 — logo `lateral` é sempre 0 e o `1.0e7` é código morto. **A trava (2) torna a trava
(1) inalcançável.** A premissa da proposta ("a lateral virou matéria-prima e a política a trata
como veneno") está errada: ela nunca tem a chance de tratar.

A razão pontos/meta **não** subiu de 0,665. Ficou em 0,660. A leitura (b) não está provada.

### 1.2 A TECELÃ escrita do zero — 25 células, e cinco das seis famílias de peso *pioram*

Implementei a especificação inteira: sem veto, sem alvo fixo, sem túnel, jogando nas 25 casas,
valor = pontos do **evento** e não da linha. Horizonte de 1 posicionamento, **sem enumerar o
baralho e sem simular compra** — ou seja, já é a versão "jogador atencioso real" que o Risco 1
da própria proposta exigia.

**Erro de medição desta bancada, registrado de propósito:** a primeira TECELÃ usou os pesos na
faixa 0–1 que a proposta pediu e ficou **20 pp abaixo da gulosa**. Causa: `_pot_cc` usa
`melhor_alcancavel` e superestima a linha em ~5×, então peso 1,0 num termo de potencial afoga
os pontos do evento. Faixa corrigida para 0,00–0,40.

Vitória por peso (gulosa pareada = 37,1):

| peso | 0 | valores testados |
|---|---|---|
| `w_pulso` | 37,1 | 0,5 → **21,0** · 1,0 → 21,0 · 2,0 → 21,0 |
| `w_pulso` como desempate | 37,1 | 1 → 37,1 · 5 → 34,4 · 20 → 24,0 |
| `w_dens` (C3 = 4 linhas) | 37,1 | 0,02 → 17,4 · 0,08 → 17,0 · 0,20 → **12,4** |
| `w_futuro` (3/5 → 4/5) | 37,1 | 0,02 → 22,3 · 0,15 → 23,4 · 0,40 → 24,5 |
| `w_queima` | 37,1 | 0,05 → 21,0 · 0,40 → 19,3 |
| `w_ramo` | 37,1 | 0,05 → 21,8 · 0,20 → 22,2 |
| **`w_espera` (paciência)** | 37,1 | **0,25 → 37,5** · 0,50 → 37,5 · 1,0 → 35,0 |

**O diagnóstico central da proposta 1 está invertido.** Ligar o Pulso — "ela ignora o Pulso,
`imr` nem entra" — leva os turnos pagos de 75,8% para **85,9%** e as Triplas de 17,5% para
**29,5%**, e derruba a vitória de 37,1 para **21,0** e os pontos de 6.477 para 4.670. Caçar o
Pulso compra turno pago com ponto. O termo mais valioso do jogo é o `dp` — o potencial da **mão
de pôquer** — que a gulosa já tem. Os pontos vêm da qualidade da mão, não do número de linhas.

**O "ramo não disparar" não existe.** Sob `janela = 1` a linha amadurece com `jan=1` e já entra
em `_expirando()`; portanto **qualquer** posicionamento seguinte dispara a colheita. A varredura
{0, 1, 2} turnos é inmensurável — `null`, com a razão. A decisão que sobra é outra: *quando
deixar a primeira linha encher*. É essa que `w_espera` mede, e é a única que paga.

**Melhor TECELÃ:** `w_espera = 0,25`, resto zero. **37,5%** contra 37,1% da gulosa = **+0,4 pp**.
Pontos 6.576 contra 6.477 (**+1,5%**). Cruzadas 0,888 contra 0,826. n1 cai de 29,9% para 21,3%.

A proposta calculou que a planejadora precisa de **+16,9% de pontos** para empatar.
Medido: **+1,5%**.

> **Veredito do diagnóstico: a leitura (a) sobrevive.** A política velha é ruim — mas por causa
> do túnel, não do veto — e consertá-la rende +0,4 pp, não os +7,2 que faltam. **Reescrever a
> bancada não resolve a dívida.** O jogo, hoje, não paga planejamento.

---

## 2. O teste obrigatório: o preço da cruzada, refeito

O teste antigo (DECISOES §3, "4× / 20× / 100×, inerte") precificava um evento de frequência
0,000. Refeito com o evento a 0,847/mesa. **Ele tem gradiente**, e ele é o único lever da lista
com massa. Mas a resposta se parte em duas, e a diferença é *onde* B entra.

### 2.1 B **dentro** do parêntese, como fração da meta: REPROVADO por aritmética

| b | K final | razão final |
|---|---|---|
| 0,05 | 37,3 | 1,441 |
| 0,10 | 167,6 | 2,732 |
| 0,20 | **926,5** | 5,406 |
| 0,40 | **5.492,0** | 10,801 |

A calibração **diverge**. Subir K sobe a meta, que sobe B, que é multiplicado pelo fator (~27×).
A razão converge para `b × E[fator] ≈ 27b` e **nunca chega a 0,79**. O b máximo viável é
**≈ 0,029** — sete vezes menor que o 0,20 central da proposta. E b = 0,025 já estoura a banda de
vitória global (43,5% > 40%).

> Se o painel quiser B dentro do parêntese, B tem de ser **fichas absolutas**, nunca fração da
> meta. A formulação proposta é auto-referente e não é balanceável.

### 2.2 B **fora** do parêntese (piso fixo): funciona, e é o único que funciona

| b (fração da meta) | K | gulosa | **planejadora** | Δ | TECELÃ | m5 | cruz | rec | seca |
|---|---|---|---|---|---|---|---|---|---|
| 0 (base) | 4,392 | 37,1 | 29,9 | **−7,2** | 37,5 | 67,4 | 0,826 | 75,8 | 2 |
| 0,10 | 5,000 | 35,4 | 32,3 | −3,1 | 36,2 | 67,6 | 0,838 | 75,9 | 2 |
| 0,15 | 5,300 | 35,2 | 34,0 | −1,2 | 36,2 | 67,6 | 0,841 | 75,9 | 2 |
| 0,20 | 5,616 | 35,0 | 37,5 | +2,5 | 36,2 | 67,6 | 0,845 | 75,9 | 2 |
| 0,25 | 6,062 | 34,1 | 41,1 | +7,0 | 35,5 | 67,7 | 0,846 | 75,9 | 2 |
| **0,27** | **6,250** | **33,9** | **42,5** | **+8,6** | 35,4 | **67,7** | **0,847** | **75,9** | **2** |
| 0,30 | 6,538 | 33,6 | 45,4 | +11,8 | 35,2 | 67,7 | 0,847 | 75,9 | 2 |
| 0,40 | 7,593 | 33,5 | 61,7 | +28,2 | 35,4 | 67,7 | 0,848 | 75,9 | 2 |

**b = 0,27 atinge a meta-alvo (planejadora ≥ gulosa + 8 pp) e passa nas cinco bandas:**
m5 67,7 (68,6 vs 68,3 da base a n=1000 — Δ **+0,3 pp**, banda 45–75) · turnos pagos 75,9 (≥70) ·
seca 2 (≤3) · vitória global 33,9 (20–40) · cruzadas 0,847 (≥0,5) · violações de teto duro **0**.

Razão de coleta medida: planejadora 1,633 cruzadas/mesa contra 0,847 da gulosa = **1,93**.
A proposta previu 1,97. Acertou na terceira casa.

**Forma do bônus, medida:**
- **Fixo por evento** — Δ +7,0 em b=0,25. É a forma certa.
- **Por linha extra** — Δ +3,0 e vitória global cai para 30,6. Pior nos dois eixos, como a
  proposta previu (razão 1,54 contra 1,97).
- **Fichas absolutas (B=1.000)** — Δ **−2,0**. Decai ao longo das seis rodadas exatamente como a
  proposta temia. A fração da meta é a forma certa.

**Robustez:** com o teto R15 do mult **religado**, b=0,25 ainda dá **+9,5 pp** (m5 67,6) — o
aviso de colapso silencioso da c4 não se materializa sob SOMA. Sob a leitura **PRODUTO**, porém,
b=0,25 **desaba para −2,9 pp**: o valor está calibrado para SOMA e precisaria de novo tuning.

**Custo:** K vai de 4,3922 para 6,25 (**+42%**), sobre um K que a c4 já apontava como ressalva
n.º 1. Vitória global 37,1 → 33,9 (em banda, mas o jogo fica mais duro).

### 2.3 A ressalva que decide, e ela é maior que o resultado

Os +8,6 pp são coletados por um **bot que joga só a cruz**: 1,633 cruzadas/mesa, 92,84% dos
eventos são Dupla, **n3 = 0,00%**, 16 casas vazias, ignora o Pulso, 56,5% de turnos pagos.

O proxy de jogador atencioso **real** — TECELÃ, horizonte 1, sem enumerar baralho — ganha
**+1,5 pp** (35,4 contra 33,9).

> Medido, o beneficiário desta regra é o **monomaníaco da cruz**, não "o jogador atencioso".
> O pedido (e) do Joab — beneficiar o jogador atencioso e estrategista — esta regra atende pela
> metade, e é a metade menos interessante.

---

## 3. As outras cinco propostas

| proposta | célula | gulosa | planejadora | Δ | base = −7,2 | veredito |
|---|---|---|---|---|---|---|
| **3** solteira 0,70 | K 4,337 | 35,7 | 29,4 | −6,3 | +0,9 | pequena demais |
| **3** solteira 0,50 | K 4,121 | 36,7 | 31,2 | −5,5 | +1,7 | pequena demais |
| **3** empilhada em b=0,25 | K 5,760 | 35,0 | 42,5 | +7,5 | +0,5 sobre b=0,25 | não paga a regra |
| **4** escada E3=1,6 E4=2,5 | K 5,000 | 34,0 | 24,7 | **−9,3** | **−2,1** | REPROVADA |
| **4** escada E3=1,3 E4=1,8 | K 4,700 | 35,9 | 26,6 | **−9,3** | **−2,1** | REPROVADA |
| **5** diagonal 1,0 na Tripla | K 4,597 | 35,7 | 27,8 | −7,9 | −0,7 | REPROVADA |
| **6** Avesso calor 3 | K 4,392 | 37,2 | 30,5 | −6,7 | +0,5 | inerte |
| **6** Avesso calor **8** (teto) | K 4,422 | 37,4 | 31,3 | −6,1 | +1,1 | REPROVADA |
| **7** Cruz Acesa 40/400 | K 4,522 | 35,9 | 29,0 | −6,9 | +0,3 | REPROVADA |

**Proposta 3 — solteira paga menos.** Funciona no sinal, é pequena no tamanho: +0,9 a +1,7 pp.
Exatamente o que a própria proposta previu ("o risco real é ser pequeno demais"). Empilhada em
b=0,25 rende **+0,5 pp** — não paga o parágrafo que custa no painel de regras. **O veneno da c2
não aparece:** `turnos_segurando_4_5` fica em 3,52 (base 3,529) e a cruzada da gulosa não cai.
Benefício colateral real e único: é a única proposta que **desinfla K** (4,392 → 4,121).

**Proposta 4 — escada.** Reprovada nas duas calibragens, com o **mesmo −9,3**. A planejadora faz
n3 = 0,00% e n4 = 0,00%; a gulosa faz 17,4% e 0,68%. É presente puro ao guloso e a dívida
**piora 2,1 pp**. Rodar contra a TECELÃ (que faz n3 = 19,2%) não salva: +0,6 pp. A proposta
previu o bloqueio; a medição confirma.

**Proposta 5 — diagonal inteira na Tripla.** Cirúrgica como prometido — m5, cruzada, rec e seca
ficam idênticos à base. E **piora** a dívida em 0,7 pp, porque quem faz Tripla é a gulosa. É
inofensiva, não é conserto. O `% das Triplas que contêm diagonal` que a proposta pediu **não foi
medido** (`null`): a regra já está reprovada pelo delta, e esse número mudaria o tamanho do
efeito, não o sinal.

**Proposta 6 — o Avesso esquenta.** Testei **2,7× acima** do valor central (ganho 8 contra 3) e
a dívida se move +1,1 pp — ruído. E há um achado que mata a regra por dentro: **a política que
SEGURA o Avesso marca menos que a que não segura** (36,5 contra 37,5). Segurar custa um slot de
mão que vale mais do que o calor paga. Não é só pequena: o comportamento que ela quer premiar é,
medido, um erro. O Risco 2 do briefing não se materializa (rec 75,8, seca 2) justamente porque
ninguém segura o coringa.

**Proposta 7 — Cruz Acesa.** Reprovada pelo número que a própria proposta declarou decisivo,
agora **medido e não previsto**:

| | gulosa | planejadora | profunda | TECELÃ |
|---|---|---|---|---|
| casas em 3+ linhas vivas ao fim | **0,355** | **0,110** | 0,268 | 0,366 |
| Cruz Acesa, % das mesas | **3,1%** | **0,0%** | 1,0% | 2,9% |

Razão de coleta **0,31** contra o limiar 0,856. A planejadora **nunca** acende a cruz — 0,0% em
1.000 mesas. Prêmio de forma é prêmio ao jogador que ocupa mais tabuleiro, e quem ocupa mais
tabuleiro é o guloso.

---

## 4. Recomendação

1. **Nenhuma das sete devolve retorno ao jogador atencioso.** Uma devolve retorno ao caçador de
   cruz: **bônus de cruzada, b = 0,27 da meta, FORA do parêntese, fixo por evento**.
   Planejadora 42,5 contra gulosa 33,9 (**+8,6 pp**), cinco bandas passadas, zero violação de
   teto duro. Ao jogador: *"Colher duas ou mais linhas de uma vez paga um bônus por cima."*
2. **Se adotar, adotar sozinha.** Solteira 0,70 por cima rende +0,5 pp e custa uma regra e um
   parágrafo no painel que o Joab quer enxuto.
3. **Antes de adotar, o painel decide o que a bancada não pode decidir:** "devolver retorno ao
   estrategista" é premiar **quem caça a cruz** (medido +8,6) ou **quem joga com atenção**
   (medido +1,5)? São coisas diferentes e esta regra só faz a primeira.
4. **Não adotar:** escada (4), diagonal na Tripla (5), Avesso esquenta (6), Cruz Acesa (7).
   Todas pioram ou não movem a dívida, todas com número pareado.
5. **Se o painel fixar a leitura PRODUTO**, este resultado não vale: b=0,25 sob PRODUTO dá
   −2,9 pp. O valor teria de ser recalibrado do zero.

### Correções ao livro-razão

- **DECISOES §3**, "precificar a cruzada — inerte em 4×, 20×, 100×": precisa de nota. Mediu um
  evento de frequência 0,000. Com o evento a 0,847/mesa o preço tem gradiente monotônico
  (−7,2 → −3,1 → −1,2 → +2,5 → +7,0 → +8,6 → +11,8 → +28,2). A entrada não está errada; está
  **obsoleta**.
- **DECISOES §4**, dials que são código morto: entra o **veto lateral da planejadora**
  (`bancada4.gd`), 0 disparos em 4.230 turnos.
- **DECISOES §6**, erros de medição: entra o desta bancada — pesos de potencial na faixa errada
  por não notar que `melhor_alcancavel` infla a estimativa da linha em ~5×.

---

## 5. O que surpreendeu

- A ablação declarada decisiva é um no-op **exato**: quatro coeficientes de veto dão resultados
  idênticos à quarta casa, e o contador marca zero.
- Ligar o Pulso na política — o conserto principal que a proposta 1 pediu — **derruba** a vitória
  de 37,1 para 21,0, *mesmo* subindo turnos pagos para 85,9% e Triplas para 29,5%.
  **Turno pago não é ponto.**
- Bônus como fração da meta dentro do parêntese é matematicamente incalibrável: K explode para
  5.492 e a razão nunca chega a 0,79.
- **A guarda de profundidade não se mexeu em nenhuma variante** (67,2 a 67,8 contra 67,4). O
  aviso da c4 de que "toda segunda regra come a folga de 6,8 pontos" **não vale para regras de
  preço** — só para regras que mudam a *ordem* das jogadas. Isso é uma correção útil ao modelo
  mental da rodada anterior: o m5 é sensível a reordenação, não a magnitude.
- A política que segura o Avesso para esquentá-lo marca **menos** que a que não segura.

## 6. O que não foi medido (e por quê)

| item | razão |
|---|---|
| malha cruzada completa `w_futuro × w_dens × w_queima` (81 células) | varredura por coordenada; cinco das seis famílias já pioram monotonicamente |
| cláusula (b) da solteira ligada/desligada; variante progressiva; fatores 0,90 e 0,00 | a curva 0,70/0,50 já fixa o tamanho do efeito em 0,9–1,7 pp |
| malha E3×E4 completa e o controle 1/2/4/8 | duas calibragens dão o **mesmo** −9,3; sinal estável e negativo |
| `% das Triplas que contêm diagonal` | a regra já está reprovada pelo delta; o número muda o tamanho, não o sinal |
| Avesso: variante multiplicativa, teto 2/6, ganho 1/5, turnos médios na mão | o teto ganho=8 (2,7× o proposto) move a dívida em +1,1 pp |
| varredura de dials da Cruz Acesa | razão de coleta 0,31 decide sozinha |
| `janela=2` ou `janela=99` com o bônus | ambas já reprovadas por m5 na c4 (76,3 e 77,8) |
| tudo que a §8 da c4 lista: prazer, animação, som, legibilidade do Avesso | simulador não sente |
