# CRUZADA — as regras

> **Cada carta pontua em duas mãos de pôquer: a linha e a coluna onde você a colocar.**

Este documento é normativo: o código implementa o que está aqui, e o que não está aqui não
existe no jogo. Toda regra abaixo tem uma medição atrás dela em `../cruzada-pesquisa/`, e a
referência está citada no fim de cada seção. Quando um número não foi medido, está escrito
**não medido** — nunca preenchido por estimativa.

Ordem de leitura para quem chega agora: §1 (o turno), §2 (as linhas), §3 (o que paga),
§4 (a economia da mesa). O resto é detalhe de implementação.

---

## 0. GLOSSÁRIO — as sete palavras do jogo

Os nomes foram testados com dois leitores cegos e 10 de 33 reprovaram; estes são os que
passaram (`DECISOES.md` §3d).

| Palavra | O que é |
|---|---|
| **CASA** | uma das 25 posições da grade 5×5 |
| **FILEIRA · COLUNA · DIAGONAL** | as 12 unidades que pontuam. Nunca "linha" na tela: 12 > 10 numa grade 5×5 travou os dois leitores |
| **MADURA** | fileira/coluna/diagonal com as 5 casas cheias, esperando a colheita |
| **COLHEITA** | o evento que avalia as maduras, paga e limpa as casas |
| **PARCELA** | o troco que uma linha paga ao chegar em 3/5 e em 4/5 |
| **TEAR** | o número que multiplica a colheita inteira |
| **AVESSO** | a carta de duas caras, forjada pela própria colheita |
| **CRUZADA** | uma colheita que paga duas ou mais mãos de uma vez |

Neste documento "linha" é usado como termo técnico coletivo para as 12 unidades. Na tela,
nunca.

---

## 1. O TURNO

**R01 — GRADE.** 5×5, 25 casas, todas vazias no começo da mesa.

**R02 — MÃO.** 5 cartas. Um baralho francês de 52, embaralhado por semente.

**R03 — O TURNO TEM TRÊS PASSOS, NESTA ORDEM:**

1. **descarte** (opcional) — troca de 1 até a mão inteira; não gasta posicionamento;
2. **posicionamento** (obrigatório) — 1 carta da mão numa casa vazia; a carta fica ali;
3. **compra** — de volta até o tamanho da mão.

O posicionamento é obrigatório de propósito: é o que impede o jogo de virar solitário de
espera. Como sempre há casa vazia (§5), nunca há mão morta.

**R04 — AS TRÊS PILHAS.** `baralho` (compra) · `descarte` (o que foi trocado) ·
`colhida` (o que a colheita removeu). Baralho vazio reembaralha o descarte; **a pilha colhida
nunca volta**. Invariante verificado a todo instante:

    52 = mão + grade + colhida + baralho + descarte

**R05 — FICHAS DA CARTA.** 2 a 10 valem a face · J/Q/K valem 10 · Ás vale 11.

**R06 — ORÇAMENTO.** 15 posicionamentos na mesa Pequena, 17 na Grande, 19 no Chefe.
Descartes: 2 · 3 · 3.

---

## 2. AS LINHAS E A JANELA DA COLHEITA

**R07 — DOZE LINHAS VIVAS.** 5 fileiras, 5 colunas e as 2 diagonais. A diagonal paga **60%**.
Subir esse piso quebra o ritmo — a seca mediana vai de 2 para 3 turnos e a recompensa cai de
64,8% para 61,2% dos turnos.

**R08 — A JANELA DA COLHEITA.** *A regra que dá nome ao jogo.*

> Uma linha que recebe a 5ª carta **não é colhida no ato**: entra em **MADURA** e continua na
> grade, ocupando as 5 casas, sem receber cartas novas.
> No **posicionamento seguinte**, todas as maduras são colhidas **num único evento**, junto com
> qualquer linha que complete nesse mesmo posicionamento.

Texto para o jogador, 12 palavras:
*"Linha cheia fica madura um turno. Colhe no próximo, junto com outras."*

Casos-limite, todos com asserção no `testes/`:

- linha que amadurece no **último** posicionamento da mesa colhe na hora, sem janela;
- **sem restrição de perpendicularidade** na colheita conjunta (93,8% já são perpendiculares
  sozinhas; restringir muda −1%);
- **sem limite** de "só a primeira madura da mesa" (no-op medido: 0,820 contra 0,826);
- uma linha madura **não volta a pulsar**;
- casas vazias no fundo do poço: mínimo 9 (Pequena) e 7 (Chefe) em 11.000 mesas — nunca zero.

**Por que ela existe:** sem a janela, em **30.944 turnos de jogo natural não aconteceu uma
única vez** uma jogada que fechasse duas linhas. Fechar uma linha em 4/5 é sempre o maior
ganho imediato, então duas nunca ficam esperando ao mesmo tempo. O gargalo era de **ordem**,
não de carta nem de preço: coringa não conserta (mede 0,088 contra 0,087) e preço não conserta
(×4, ×20 e ×100 mediram 0,0000). Com a janela: **0,831 cruzada por mesa**, 83,1% das mesas com
pelo menos uma. *(`04-REGRA-DA-CRUZADA.md`)*

**R09 — A ESCADA DA COLHEITA.** O clímax mora um degrau acima da cruzada, porque a cruzada
virou o comum (71% dos eventos):

| Nome na tela | O que é | Frequência medida |
|---|---|---|
| colheita | uma linha | 29,0% dos eventos |
| **DUPLA** | duas linhas | 51,9% |
| **TRIPLA** | três linhas | 18,2% |
| **CRUZ TOTAL** | quatro linhas | 0,85% |

A CRUZ TOTAL custa 17 posicionamentos e cabe **exatamente** numa mesa Grande. É o melhor jogo
do CRUZADA e precisa ter nome na tela.

---

## 3. O QUE PAGA

**R10 — A CATEGORIA DA MÃO.** As 11 categorias, com fichas base e multiplicador:

| # | Categoria | Fichas | Mult |
|---|---|---|---|
| 0 | Carta Alta | 5 | 1 |
| 1 | Par | 10 | 2 |
| 2 | Dois Pares | 20 | 2 |
| 3 | Trinca | 30 | 3 |
| 4 | Sequência | 30 | 4 |
| 5 | Flush | 35 | 4 |
| 6 | Full House | 40 | 4 |
| 7 | Quadra | 60 | 7 |
| 8 | Sequência de Cor | 100 | 8 |
| 9 | Sequência Real | 120 | 10 |
| 10 | Quina (cinco iguais) | 140 | 12 |

A Quina só existe com Avesso. `A-2-3-4-5` e `10-J-Q-K-A` são sequências; nada entre elas.

**R11 — PONTOS DE UMA LINHA.**

    pontos_da_linha = (fichas_base + soma_das_fichas_das_5_cartas + piso_do_padrão) × mult
    se for diagonal: × 0,60

**R12 — PONTOS DO EVENTO.** *A leitura é SOMA dos mults, vezes o Tear. Não é produto.*

    pontos_do_evento = Σ pontos_das_linhas_colhidas × Tear

Sob produto, um teto morderia 57,5% das cruzadas e 78,5% das CRUZ TOTAIS, e a escada
2×/3×/4× colapsaria em silêncio. **Não existe teto de multiplicador** — o antigo
`24 + 4×rodada` foi removido: ele mordia 0% e era matemática escondida.

**R13 — A PARCELA (troco de 3/5 e 4/5).** Uma linha paga **35%** do que pagaria completa ao
chegar em 3 e em 4 cartas, sem gastar carta nem turno. Uma vez por limiar; linha madura não
pulsa mais.

É a regra que fez o jogo deixar de ser mudo: turnos com recompensa **14,3% → 65,7%**, seca
mediana **7 → 2** turnos. *(`02-NUCLEO-POLIDO.md` §3)*

**R14 — O TEAR.** Começa em 1. Sobe **+1 a cada colheita** e **+1 a cada 4 posicionamentos**.
Teto **8**. Multiplica o evento inteiro.

O teto e o ganho por colheita são dials mortos acima disso: teto 9+ morde 0% das mesas, e
+1/+2/+3 por colheita move a profundidade em 0,08 ponto. **Não vire parâmetro de balanceamento
nenhum dos dois.**

**R15 — O PISO DO PADRÃO PARCIAL** *(metade da BC_rec)*. Linha colhida em **Carta Alta, Par ou
Dois Pares** ganha **+15 fichas por padrão parcial**, teto de 3 padrões:

- 3 cartas do mesmo naipe = 1 padrão · 4 = 2 padrões — na tela: **quase-flush**;
- 3 cartas em sequência = 1 padrão · 4 = 2 padrões — na tela: **quase-escada**.

**R16 — O TROCO DA LINHA FRACA** *(a outra metade)*. Toda linha colhida em **Carta Alta ou
Par** devolve **+1 Tear, +2 descartes e +1 no tamanho da mão**.

**Por que as duas juntas:** quem planeja a cruz colhe **49,8% de mãos fracas** contra 29,5% de
quem joga no impulso — montar geometria obriga a encher a linha com o que vier. Pagar melhor a
linha fraca **reembolsa exatamente quem planeja, e só ele**. Sem isso, planejar rendia menos que
não planejar: gradiente **−5,4 pontos percentuais**. Com isso: **+5,4**, confirmado em três
famílias de sementes independentes (−7,5→+4,8 · −6,8→+5,4). *(`r5-b-fracas.md`)*

O controle de falsificação está registrado: pagar mais em *toda* linha infla a curva de metas
em 33% e move o gradiente só 2,3 pontos. **Alvo errado não paga.**

**R17 — TETO DO PISO.** `+15` é fronteira, não sugestão. Em `+20` o Par empata com Dois Pares;
em `+25` inverte. O piso por padrão parcial é, por construção, anti-dois-pares (um par tem
quatro valores distintos contra três do dois pares). E `+15` somado a multiplicador extra põe
Full House a 1,38× a Carta Alta: **pôquer morto**. Não mexa nesses números sem rodar a bancada
de novo.

---

## 4. A MESA

**R18 — A META.** `pequena(n) = arredonda(2178 × 1,42^(n-1))`, `grande(n) = arredonda(pequena(n)
× 1,50)`, `chefe(n) = arredonda(pequena(n) × 2,30)` — sempre a partir do valor **já arredondado**
de `pequena(n)`.

| rodada | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| **Pequena** | 2.178 | 3.093 | 4.392 | 6.236 | 8.855 | 12.575 |
| **Grande** | 3.267 | 4.640 | 6.588 | 9.354 | 13.283 | 18.863 |
| **Chefe** | 5.009 | 7.114 | 10.102 | 14.343 | 20.367 | 28.922 |

O `2178` é `450 × 4,84`, onde 4,84 é a constante calibrada até a razão pontos/meta voltar a
0,79 com a Janela e a BC_rec ligadas. Ela **não** é um dial de dificuldade: é o resultado de uma
calibragem. Mexer nela sem remedir invalida todas as bandas.

**R19 — FECHO.** Ao acabarem os posicionamentos, as linhas incompletas (3 ou 4 cartas) pagam
**50%** — e **esse fecho conta para a meta**. O contrário era um `if` na ordem errada que valia
**6,1 pontos percentuais** de vitória. São 5,1% dos pontos da mesa: pouco em economia, decisivo
em quantas mesas viram no último clique.

**R20 — VITÓRIA E DERROTA.** Bater a meta encerra a mesa na hora, com vitória. Esgotar os
posicionamentos sem bater gasta 1 vida das 3 e repete a mesa com semente **derivada**:
`semente_mesa = mistura(semente_run, rodada × 10 + mesa, tentativa)`. `randi()` aqui é bug.

---

## 5. O AVESSO — o coringa

**R21 — A FORJA.** Toda colheita prensa as **duas cartas de maior valor** daquela linha num
**AVESSO** — uma carta de duas caras — que volta para o **topo do baralho**.

O gatilho tem de ser *toda colheita*: exigir Trinca+ derruba de 1,66 para 0,97 por mesa;
exigir Flush+ derruba para 0,42 (2,7% dos posicionamentos — vira decoração).

**R22 — AS DUAS CARAS.** Um Avesso mostra uma cara na **fileira** e a outra na **coluna e nas
diagonais**. Na mão, um toque gira e troca as caras. Ao ser posicionado, **congela**.

**R23 — POR QUE ESTE CORINGA E NÃO O CLÁSSICO.** O coringa clássico ("vira qualquer carta")
responde *qual carta?*. O Avesso responde **"esta carta é boa para quem?"** — a única pergunta
que só existe porque a frase única do jogo diz que a carta pertence a duas mãos.

O número que decide: com Avesso na mão, a casa central **C3 recebe 28,6% dos posicionamentos**
contra 4,0% de uma escolha uniforme — **7×**, entropia 0,827. O coringa clássico põe em C3
**4,2%**: indistinguível de aleatório. *A pergunta "qual é a casa certa para um coringa?" só
tem resposta com o Avesso.*

**R24 — ORÇAMENTO DO AVESSO.** 1,66 por mesa · 10,8% dos posicionamentos · espera forja→uso de
1 turno · 37,8% dos pontos da mesa (teto duro 45%). O coringa clássico levava 61,1% — o item
virava o jogo. **Não somar os dois:** juntos dão 73,3% de vitória e razão 1,159, o jogo vira
passeio.

**R25 — CONDIÇÃO DE CORTE, EM ABERTO.** As duas caras precisam ser legíveis em 84×92 px em
retrato, em meio segundo. Isso é **não medido** — a bancada é headless. Prototipar o desenho
antes de fechar a regra. Se não couber legível, entra o coringa clássico único por mesa
(vitória 42,58%, razão 0,985), que é pior e é seguro.

---

## 6. AS DICAS — assistência honesta

Três níveis, desligáveis, com uma régua trocada por medição:

| Nível | O que faz | Por quê |
|---|---|---|
| 1 | apaga as casas que não mudam nada | em 86% dos turnos todas as jogadas dão o mesmo resultado; isso é ruído, não decisão — é informação, não conselho |
| 2 | mostra a conta dos dois lados: *"fecha a fileira 3 (Trinca, 340) **e** derruba a coluna C de 4/5 para 3/5"* | é o único mecanismo encontrado que **ensina a recusa** |
| 3 | recomendação explícita, rotulada **"maior ganho agora"** — nunca "melhor jogada" | medimos: não é a melhor em 41% dos turnos. Rótulo honesto ou nada |

**A armadilha, registrada:** uma lista ordenada por ganho imediato **sempre** recomenda fechar
a linha em 4/5, que é exatamente o que impedia a cruzada. A assistência não faz o jogador
perder (custa 1,4 ponto percentual) — ela fazia o jogador **nunca ver o melhor momento do jogo**.
Por isso o teste que reprova o build não é "quem pensa vence mais": é **um jogador que segue a
dica chega a ver uma cruzada alguma vez?**

---

## 7. O QUE NÃO ESTÁ AQUI, E POR QUÊ

Não invente número nestas áreas — nenhuma delas foi medida:

| Área | Situação |
|---|---|
| loja, selos, relíquias, níveis de mão | `null` em todas as bancadas |
| modificadores de mesa | `null` |
| rodada 6 com poder de loja | território virgem |
| ergonomia do Avesso na tela | condição de corte do item (R25) |
| se o jogador entende a R08 sem explicação | dez minutos de playtest respondem melhor que 100.000 mesas |

E o que a simulação **por construção** não mede: o prazer de ver a cruzada acontecer, se o
Tear subindo de semitom em semitom cria o crescendo, se "+2 descartes" soa prêmio ou esmola,
se 100 jogadas legais *parecem* paralisantes mesmo sendo equivalentes.

---

## 8. IDEIAS JÁ TESTADAS E MORTAS

Antes de propor, procure em `../cruzada-pesquisa/DECISOES.md` §3. Metade das boas ideias deste
projeto já foi testada e morreu com um número específico. As cinco maiores:

| Ideia | O número que matou |
|---|---|
| coringa clássico (Agulha) | resíduo morto 66,7% (banda 20–40); **anti-cruzada**: −63% |
| cascata por gravidade (a carta cai) | **0 elos em 48.000 mesas**; em 3.866 quedas a pista de pouso existiu 0 vezes |
| fechar 4 linhas no centro como fantasia de quebrar o jogo | 0 ocorrências em 2.406 mesas; 99,1% contêm mão de mult ≤ 2 |
| precificar a cruzada | ×4, ×20, ×100: gulosa em 0,0000, 100% das mesas sem cruzada |
| só a cruzada levantar o Tear | 99,96% de jogadas idênticas em 4.815 turnos |

---

## 9. AS BANDAS QUE REPROVAM O BUILD

Números do núcleo aprovado. Uma medição fora destas bandas é regressão, não gosto:

| Métrica | Banda | Valor aprovado |
|---|---|---|
| turnos com recompensa | ≥ 70% | 75,9% |
| seca mediana / p90 | ≤ 3 | 2 / 3 |
| cruzadas por mesa (jogo natural) | ≥ 0,5 | 0,839 |
| vitória (jogo natural) | 20–40% | 34,1% |
| **concordância gulosa × profunda** | **45–75%** | **68,5%** |
| gradiente planejador − guloso | ≥ 0 | **+5,4 pp** |
| Full House ÷ Carta Alta | > 3,0 | 5,57 |
| violações de teto duro | 0 | 0 |
| conservação das pilhas | sempre | asserção |

A linha da concordância é a que salvou o projeto: 68,5% fica entre o jogo que se resolve
sozinho (~95%) e o que pune a intuição (~20%). **É a prova de que a decisão central é real.**
