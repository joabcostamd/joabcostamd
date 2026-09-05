# BANCADA r5 — LINHAS FRACAS

Motor: Godot 4.7.2 headless, núcleo da bancada **fusão** (J1 = núcleo polido + Janela da Colheita).
Volume: **1.000 mesas** gulosa por célula (guarda m5 em 500), **400** profunda, **1.000** planejadora,
600 por iteração de calibragem de K. Sementes `31337 + t·7919`, **pareadas entre todas as células**.
24 células. A profunda ficou em 400 mesas — mesmo volume da bancada de referência, para comparação pareada;
é a única redução, e está registrada.

## 0. A base bate — dígito a dígito

| | citado no briefing | medido aqui |
|---|---|---|
| cruzes/mesa | 0,831 | **0,831** |
| turnos que pagam | 75,8% | **75,8%** |
| seca mediana | 2 | **2** (p90 3) |
| vitória gulosa | 36,1% | **36,1%** |
| guarda de profundidade (m5) | 68,2% | **68,2%** |
| planejadora | 30,7% | **30,7%** (1,636 cruz/mesa) |

K = 4,4042, o valor calibrado da fusão. Nenhuma variante entrou antes disso fechar.

---

## 1. DIAGNÓSTICO — como as linhas pontuam hoje

**O jogador NÃO está fazendo lixo.** Distribuição das linhas colhidas (gulosa, 2.235 linhas em 1.000 mesas):

| ALTA | PAR | DOIS PARES | TRINCA | SEQ | FLUSH | FULL | QUADRA | SEQ COR | REAL |
|---|---|---|---|---|---|---|---|---|---|
| 13,4% | 16,1% | **2,9%** | **21,5%** | 8,5% | 14,1% | 6,7% | 7,9% | 7,2% | 1,8% |

Trinca é a categoria mais comum; Quadra (7,9%) e Sequência de Cor (7,2%) aparecem em taxas
astronômicas para pôquer natural — é o Avesso somado à liberdade de escolher a casa.
**Dois Pares é mais raro que Full House** (2,9% contra 6,7%): já é categoria morta hoje.

**Mãos fracas (Alta ou Par) são 29,5% das linhas colhidas.** E aqui está a assimetria que decide tudo:

> na **planejadora** as fracas são **49,8%** — PAR sozinho é 35,0% e DOIS PARES 16,5%.
> Quem monta a cruz enche a linha com o que tiver, e paga o preço em qualidade de mão.

**Quanto a linha fraca paga:**

| medida | valor |
|---|---|
| fração da meta da rodada (mediana) | **13,1%** (média 17,8%) |
| fração da parcela mediana de uma linha | **52,5%** — Alta sozinha 44%, Par 60% |
| **colheita só de mãos fracas ÷ colheita mediana** | **26,3%** ← a que o jogador sente |
| % dos eventos que são só de mãos fracas | 5,4% (na planejadora, **23,4%**) |
| % dos pontos da mesa vindos de mãos fracas | **10,7%** |
| % dos pontos da mesa vindos da colheita final (50%) | **5,1%** |
| linhas que a mesa termina devendo (3 ou 4 cartas) | **2,45** de média, mediana 2 (planejadora 0,78) |

O piso funciona: nada vale zero. Mas **uma colheita fraca entrega um quarto do que o jogador
está acostumado a receber** — e é isso que parece punição, não o zero.

Hierarquia intrínseca da base (fichas efetivas × mult, sem o fator do evento, ALTA = 1,00):
ALTA 1,00 · PAR 2,26 · DOIS PARES 2,72 · TRINCA 4,85 · SEQ 6,55 · FLUSH 6,72 · FULL 7,23 · QUADRA 15,79 · SEQ COR 23,83 · REAL 36,38.
**O topo já nasce frágil:** Sequência e Flush estão a 2,6% um do outro e o Full a 7,6% do Flush.

---

## 2. A TABELA

`plan−gul` = vitória da planejadora menos a da gulosa. É a dívida aberta do projeto (hoje **−5,4**).
`evF/evMed` = colheita só de mãos fracas ÷ colheita mediana. `FULL/ALTA` = teste de morte do pôquer.
Todas as células com K recalibrado até a razão pontos/meta da gulosa voltar a 0,79.

| variante | K | m5 | rec% | seca | vit gul | vit plan | **plan−gul** | cruz | evF/evMed | %pts fracos | **FULL/ALTA** | inversões | veredito |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **A_BASE** | 4,40 | 68,2 | 75,8 | 2/3 | 36,1 | 30,7 | **−5,4** | 0,831 | 0,263 | 10,7 | 7,23 | — | controle |
| B_b8 | 4,58 | 68,4 | 75,8 | 2/3 | 35,5 | 31,2 | −4,3 | 0,837 | 0,346 | 12,9 | 6,30 | — | aprovada, fraca |
| B_b15 | 4,70 | 68,3 | 75,8 | 2/3 | 35,0 | 32,1 | −2,9 | 0,839 | 0,410 | 15,0 | 5,51 | — | aprovada |
| **B_b15c2** | 4,71 | 68,3 | 75,8 | 2/3 | 34,8 | 32,7 | −2,1 | 0,839 | 0,410 | 15,0 | 5,51 | — | **melhor B puro** |
| B_b20c2 | 4,76 | 68,3 | 75,8 | 2/3 | 34,6 | 33,6 | −1,0 | 0,841 | 0,447 | 17,0 | 5,07 | PAR ≈ DOIS PARES | REPROVADA |
| B_b25 | 4,86 | 68,4 | 75,8 | 2/3 | 33,8 | 33,4 | −0,4 | 0,842 | 0,498 | 20,6 | 4,67 | DOIS PARES < PAR | REPROVADA |
| B_b25c2 | 4,87 | 68,3 | 75,8 | 2/3 | 33,7 | 33,9 | +0,2 | 0,842 | 0,482 | 20,4 | 4,67 | DOIS PARES < PAR | REPROVADA |
| B_b40 | 5,18 | 68,3 | 75,8 | 2/3 | 33,9 | 35,1 | +1,2 | 0,847 | 0,577 | 32,4 | 3,69 | PAR ≥ TRINCA | REPROVADA |
| B_b40c2 | 5,22 | 68,4 | 75,8 | 2/3 | 33,5 | 36,0 | +2,5 | 0,847 | 0,573 | 32,1 | 3,78 | PAR ≥ TRINCA | REPROVADA |
| B_m1 | 4,94 | 68,3 | 75,8 | 2/3 | 33,1 | 33,3 | +0,2 | 0,848 | 0,541 | 15,8 | 3,50 | DOIS PARES < PAR | REPROVADA |
| B_b15m1 | 5,72 | 68,2 | 75,8 | 2/3 | 31,9 | 35,1 | +3,2 | 0,847 | 0,693 | 36,0 | **1,38** | 2 inversões | **PÔQUER MORTO** |
| C_tear1 | 4,46 | 68,2 | 75,8 | 2/3 | 36,0 | 32,7 | −3,3 | 0,831 | 0,262 | 10,7 | 7,23 | — | inerte (teto do Tear) |
| C_desc1 | 4,40 | 68,2 | 75,8 | 2/3 | 36,3 | 32,5 | −3,8 | 0,831 | 0,266 | 10,7 | 7,23 | — | fraca |
| C_desc2 | 4,40 | 68,2 | 75,8 | 2/3 | 36,3 | 33,7 | −2,6 | 0,831 | n/m | 10,7 | =base | — | aprovada |
| C_compra1 | 4,50 | 68,2 | 75,9 | 2/3 | 35,9 | 31,9 | −4,0 | 0,831 | 0,261 | 10,7 | 7,32 | — | fraca |
| C_compra2 | 4,59 | 68,3 | 75,9 | 2/3 | 34,8 | 31,8 | −3,0 | 0,832 | n/m | 10,6 | =base | — | aprovada |
| **C_tudo** | 4,53 | 68,3 | 75,9 | 2/3 | 35,6 | 37,6 | **+2,0** | 0,831 | 0,288 | 10,6 | 7,32 | — | **aprovada** |
| D_003 | 4,20 | 68,3 | 75,8 | 2/3 | 35,5 | 30,8 | −4,7 | 0,832 | 0,269 | 11,2 | 6,55 | — | inerte |
| D_006 | 4,03 | 68,3 | 75,8 | 2/3 | 35,1 | 30,4 | −4,7 | 0,835 | 0,322 | 11,7 | 5,87 | SEQ = FLUSH | limítrofe |
| D_010 | 3,80 | 68,2 | 75,8 | 2/3 | 33,9 | 29,9 | −4,0 | 0,838 | 0,351 | 12,8 | 4,85 | FLUSH < SEQ, FULL = FLUSH | REPROVADA |
| E_flat15 | 5,10 | 68,2 | 75,8 | 2/3 | 36,4 | 32,2 | −4,2 | 0,835 | 0,322 | 12,3 | 6,52 | — | controle |
| E_flat30 | 5,84 | 68,2 | 75,8 | 2/3 | 35,8 | 32,7 | −3,1 | 0,835 | 0,336 | 13,6 | 6,03 | — | controle |
| **BC_rec** | 4,84 | 68,5 | 75,9 | 2/3 | 34,1 | 39,5 | **+5,4** | 0,839 | **0,397** | 14,7 | **5,57** | **nenhuma** | **RECOMENDADA** |
| BC_rec20 | 4,89 | 68,5 | 75,9 | 2/3 | 33,9 | 40,7 | +6,8 | 0,841 | 0,443 | 16,7 | 5,07 | PAR ≈ DOIS PARES | REPROVADA |

**Nenhuma das 24 células estourou uma banda.** A guarda de profundidade ficou entre 68,2% e 68,5%
nas 24, os turnos pagos entre 75,8% e 75,9%, a seca em 2, a cruz entre 0,831 e 0,848, zero violação
de teto duro. O piso da mão fraca **não é a alavanca dessas cinco métricas** — o que reprova aqui é
a hierarquia do pôquer, não as bandas.

---

## 3. O QUE SURPREENDEU — e é o achado desta bancada

**O piso da mão fraca é o botão que devolve retorno ao estrategista.** Não estávamos procurando isso.

A planejadora colhe **49,8% de mãos fracas** contra 29,5% da gulosa. Montar a cruz obriga a encher a
linha com o que vier: quem planeja geometria paga uma multa em qualidade de mão. Pagar melhor a linha
fraca é, aritmeticamente, **reembolsar a multa de quem planeja** — e só ele. A resposta é monótona em
seis doses: −4,3 · −2,9 · −2,1 · −1,0 · +0,2 · +2,5.

**Não é "menos variância" — é a mão fraca especificamente.** Rodamos o controle de falsificação:
+15 e +30 fichas em *toda* linha colhida, forte ou fraca. E_flat30 inflaciona K em 33% (4,40 → 5,84)
e move o gradiente só 2,3 pp. B_b25c2 chega a +0,2 com K em 4,87 — **menos da metade da inflação e
o dobro do efeito**. Alvo errado não paga.

**A moeda não-numérica funciona melhor que qualquer piso em pontos.** C_tudo (+1 Tear, +2 descartes,
+1 na mão por linha fraca) inverte o gradiente (**+2,0**) sem tocar em um único ponto de pontuação:
FULL/ALTA continua 7,32, idêntico à base. É a resposta mais barata que encontramos para a dívida aberta.

**Confirmação fora de amostra.** BC_rec foi desenhada depois de ver os resultados — então foi remedida
com K congelado e **duas famílias de sementes novas**:

| sementes | base plan−gul | BC_rec plan−gul |
|---|---|---|
| 31337 (original) | −5,4 | **+5,4** |
| 91733 | −7,5 | **+4,8** |
| 480011 | −6,8 | **+5,4** |

A inversão se repete nas três. Não é artefato de semente.

---

## 4. O QUE NÃO FUNCIONOU

- **(C) o Tear como moeda é código morto, de novo.** C_tear1 entrega 0,654 de Tear extra por mesa
  e o teto 8 come quase tudo: Tear mediano **7** e máximo **8**, iguais à base; vitória 36,0 contra 36,1.
  A seção 4 do DECISOES já tinha matado o ganho de Tear como dial. Continua morto.
- **(D) a escada do piso é quase inerte e ainda arrisca o topo.** D_003 e D_006 movem o gradiente
  0,7 pp — ruído. Para o efeito aparecer é preciso ir a d=0,10, e ali **Flush (4,85) cai abaixo de
  Sequência (4,94)** e o Full colapsa em cima do Flush. D compra pouquíssimo e paga com a única
  parte da hierarquia que já era frágil.
- **(B) com mult extra é o pior resultado da bancada.** B_b15m1 põe FULL/ALTA em **1,38**: a Carta
  Alta encosta no Full House. É exatamente o critério de reprovação do briefing, cumprido à risca.
- **(B) acima de 15 fichas inverte PAR × DOIS PARES, e estender o piso a DOIS PARES não conserta.**
  Testamos: B_b25c2 dá o piso também ao dois pares e a inversão persiste (1,92 < 2,19). O motivo é
  estrutural — o padrão parcial premia a mão com **mais cartas distintas**, e um par tem quatro
  valores distintos contra três do dois pares. **O piso por padrão parcial é, por construção,
  anti-dois-pares.** A fronteira segura está em pp_base ≤ 15 (b20c2 já empata).
- **A colheita final quase não existe como economia.** São 5,1% dos pontos da mesa e 2,45 linhas
  devendo. Mexer nos 50% é mexer em um vigésimo do jogo.

---

## 5. RECOMENDAÇÃO

**BC_rec**, duas mudanças somadas, ambas só em linha **completa de 5 cartas** no instante da colheita
(pulso, potencial e colheita final ficam intactos):

1. **PISO DO PADRÃO PARCIAL** — linha de Carta Alta, Par ou Dois Pares ganha **+15 fichas por padrão
   parcial**: 3 do mesmo naipe = 1 padrão, 4 = 2; 3 em sequência = 1, 4 = 2; teto de 3.
   *Nome autoexplicativo sugerido para a tela:* **"quase-flush"** e **"quase-escada"**.
2. **TROCO DA LINHA FRACA** — toda linha colhida em Carta Alta ou Par devolve **+1 Tear, +2 descartes
   e +1 no tamanho da mão**. Recompensa que não infla a pontuação.

Entrega: gradiente **−5,4 → +5,4** (confirmado em 3 famílias de sementes), colheita fraca de **26% → 40%**
da colheita mediana, hierarquia do pôquer **estritamente monótona** (FULL/ALTA 5,57 contra 7,23 da base),
todas as bandas dentro (m5 68,5 · pagos 75,9 · seca 2 · vitória gulosa 34,1 · cruz 0,839).

**Ressalva honesta, e não é pequena:** a planejadora sobe para **39,5%** (40,4% e 40,2% nas sementes
novas). Se a banda de vitória 20–40% vale para a **melhor** política, BC_rec encosta no teto e precisa
de K recalibrado contra a planejadora antes de entrar. Se vale para a gulosa — como em todas as
bancadas anteriores, onde "vitória global" é sempre a gulosa — passa com folga.

**Segunda escolha, se a diretriz for não encostar na pontuação:** **C_tudo** sozinho. Inverte o
gradiente (+2,0), hierarquia intocada, K sobe só 2,9%. Mas **não conserta a sensação de punição** —
a colheita fraca continua pagando 29% da mediana.

## 6. O QUE NÃO MEDIMOS
Playtest humano; se o jogador entende "+2 descartes" como prêmio ou como esmola; legibilidade do
"quase-flush" na tela; loja, selos, relíquias e modificadores de mesa (fora do escopo da sonda);
o diagnóstico evF/evMed das células C_desc2 e C_compra2 (elas não alteram pontuação, então a
hierarquia é idêntica à base por construção, mas o número está `null` no resultado.json, não estimado).
