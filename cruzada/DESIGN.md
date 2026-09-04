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

**R06b — GRADE INICIAL.** Toda mesa **Pequena** nasce com **3 cartas já postas**, sorteadas por
um fluxo de acaso próprio. Numa grade 5×5 vazia todas as casas são equivalentes por simetria: o
primeiro posicionamento seria uma decisão sem conteúdo, e a primeira decisão de uma mesa é a
que ensina. As três cartas quebram a simetria e o turno 1 já vale alguma coisa.

**R06c — DOIS FLUXOS DE ACASO.** O baralho e a grade inicial sorteiam de geradores separados,
ambos derivados da semente da mesa. Separados de propósito: assim mudar a grade inicial não
reembaralha o baralho, e um replay continua verificável quando uma das duas regras muda.

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

**R11 — AS FICHAS DE UMA LINHA.** É a parte que não depende do evento:

    fichas_da_linha = fichas_base_da_categoria
                    + soma_das_fichas_das_5_cartas
                    + piso_do_padrão_parcial        (só em mão fraca — R15)

**R12 — O FATOR DO EVENTO, E POR QUE ELE É UM SÓ.** *Aqui mora a cruzada.*

    fator = (Σ multiplicadores de TODAS as mãos colhidas no evento) × Tear

    pontos_da_linha  = piso(fichas_da_linha × fator)     × 0,60 se for diagonal
    pontos_do_evento = Σ pontos_das_linhas

O fator é **comum a todas as linhas do evento** — não é cada linha com o multiplicador dela.
Colher uma Trinca (mult 3) sozinha paga `fichas × 3 × Tear`; colher a mesma Trinca junto com
um Flush (mult 4) paga `fichas × 7 × Tear` **para as duas**. É exatamente essa partilha que faz
a cruzada valer mais que duas colheitas separadas, e é o motivo de a Janela (R08) existir.

*A leitura é SOMA dos mults, vezes o Tear.* Não é produto: sob produto um teto morderia 57,5%
das cruzadas e 78,5% das CRUZ TOTAIS, e a escada 2×/3×/4× colapsaria em silêncio. E **não
existe teto de multiplicador** — o antigo `24 + 4×rodada` foi removido: ele mordia 0% e era
matemática escondida.

**R13 — A PARCELA (troco de 3/5 e 4/5).** Uma linha paga **35%** do que pagaria ao chegar em
3 e em 4 cartas, sem gastar carta nem turno:

    parcela = piso(fichas_parciais × mult_parcial × Tear × 0,35)   × 0,60 se for diagonal

Uma vez por limiar; linha madura não pulsa mais; linha que é colhida no mesmo posicionamento
não pulsa. Com menos de 5 cartas só as categorias por valor contam — três cartas de copas não
são Flush enquanto faltarem duas, e **o piso do padrão parcial não entra na parcela**: ele é
recompensa de colheita, não de promessa.

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

**R19 — FECHO.** Ao acabarem os posicionamentos, as linhas com **3 ou 4 cartas** pagam
**50%**, pela mesma conta da parcela, e **esse fecho conta para a meta**. Linha com 1 ou 2
cartas não paga nada. O que ficou **maduro** e não chegou a ser colhido é colhido aqui, inteiro,
antes do fecho. O contrário era um `if` na ordem errada que valia
**6,1 pontos percentuais** de vitória. São 5,1% dos pontos da mesa: pouco em economia, decisivo
em quantas mesas viram no último clique.

**R20 — VITÓRIA E DERROTA.** Bater a meta encerra a mesa na hora, com vitória. Esgotar os
posicionamentos sem bater gasta 1 vida das 3 e repete a mesa com semente **derivada**:
`semente_mesa = mistura(semente_run, rodada × 10 + mesa, tentativa)`. `randi()` aqui é bug.

---

## 4b. A DIFICULDADE — três réguas, e nenhuma porta fechada

**R26 — A DIFICULDADE É UMA COISA SÓ.** Três números, e tudo o mais escreve neles:

| Régua | Faixa | O que muda |
|---|---|---|
| **Orçamento** | −3 a +6 | posicionamentos por mesa |
| **Geometria** | 0 a 8 | quanto o tabuleiro atrapalha, cumulativo |
| **Metas** | ×0,70 a ×1,25 | a altura da meta |

O dial **Tabuleiro 0–8** é um *preset* que **escreve** nas três réguas; ele não soma com elas.
Um caminho de código por dificuldade é como se ganha um modo fácil que ninguém testou e um
difícil que ninguém consegue.

**R27 — OS GRAUS DA GEOMETRIA**, cumulativos:

| Grau | O que entra |
|---|---|
| 1 | um posicionamento a menos em toda mesa |
| 2 | duas casas nascem lacradas (nunca o centro: lacrar C3 tira 4 linhas de uma vez) |
| 3 | colunas pagam um multiplicador a menos, com piso em 1 |
| 4 | a pilha colhida não volta — com **piso de 32 cartas** no baralho da run |
| 5 | a loja perde uma vaga |
| 6 | a cruzada só soma mults de categorias **diferentes** |
| 7 | uma linha morre por rodada: ela **colhe normalmente e paga zero** |
| 8 | as metas sobem 25% |

Duas dessas linhas são correções de defeito medido, não escolhas de design. **O piso de 32
cartas** existe porque sem ele o grau 4 zerava o baralho na rodada 4 e a run congelava com a mão
vazia. **A linha morta colhe** porque uma linha que enche e nunca limpa trava a grade — e ela não
empresta o multiplicador às outras, senão fechar linha morta viraria jogada boa.

**R28 — A ESTUFA.** Orçamento +4, cinco descartes, metas ×0,70 e **a derrota não existe**: a mesa
perdida repete de graça. Não é versão de mentira — a coleção desbloqueia igual. É a promessa de
que existe um lugar onde o jogo **termina**, e ela é banda da aferição: medido, a Estufa fecha
**18 de 18 mesas**.

**R29 — A REDE DE SEGURANÇA.** Três peças, e todas contra o mesmo abandono:

- **SEGUNDA MÃO** — repetir a mesma mesa dá **+1 posicionamento por tentativa, teto +3**, e
  **nunca** reduz a meta. Ferramenta ensina que dá para virar; desconto ensina que perder é o
  caminho.
- **QUASE LÁ** — derrota com **≥ 80%** da meta **devolve a vida**. A mesa em que se chega perto é
  justamente a que dói perder, e é ali que se desinstala.
- **FIANÇA** — três luzes. Acende ao perder uma mesa, ou quando uma colheita derruba uma linha em
  4/5 que **a carta do jogador não tocou**. Com as três acesas, a colheita seguinte paga **o
  dobro** e as luzes zeram. Máximo **uma luz por mesa**; as luzes atravessam mesas e zeram entre
  runs. Ela **nunca** acende por demolição escolhida: a Janela demole 4/5 por design, e premiar
  isso faria da autossabotagem a estratégia ótima.

**R30 — NENHUMA MESA É IMPOSSÍVEL.** Piso duro de **7 posicionamentos** em qualquer configuração:
com menos, nenhuma linha chega às 5 cartas e a mesa fica invencível por aritmética. E a mesa
**termina** quando não há jogada legal — sem carta na mão ou sem casa vazia —, fazendo o fecho.
Sem isso a run congelava repetindo o mesmo estado, sem nem gastar uma vida.

---

## 4c. A ECONOMIA E A LOJA — o que faz a rodada 6 existir

Sem loja, a vitória da rodada 6 é **zero**. Medido, no jogo pronto, com o jogador simulado. A
loja não é conteúdo: é a única razão de a curva de metas ser escalável.

**R31 — O DINHEIRO.**

| Fonte | Valor |
|---|---|
| Vitória Pequena / Grande / Chefe | $3 / $4 / $5 |
| Posicionamento não usado | $1 cada, teto $4 |
| Juros | $1 a cada $5 guardados, teto $4 |
| **Derrota paga** | $1 por fatia inteira de 20% da meta atingida, teto $4 |

A derrota paga porque sair de uma mesa perdida com zero no bolso transforma uma mesa perdida em
duas: sem dinheiro não há loja, e sem loja não há como virar.

**R32 — A LOJA.** Três vagas depois de toda mesa vencida, sorteadas por semente derivada da run.
Rerrolar custa $1 e sobe $1 a cada vez na mesma loja. **SEGUIR sempre visível**: a loja nunca
prende ninguém.

**Divulgação progressiva:** rodada 1 vende só nível de mão; selo de casa entra na 2, selo de eixo
na 3, relíquia na 4. Não é racionar poder — é um conceito por vez, e a rodada 1 é onde o jogador
ainda está aprendendo o que é uma linha.

**R33 — NÍVEL DE MÃO.** Cada compra soma `max(fichas_base_do_nível_0 × 0,35 ; 8)` às fichas base
e **+1** ao multiplicador daquela categoria. O passo usa **sempre** as fichas do nível zero: não
é composto, senão a Sequência Real dobraria sozinha em quatro compras e a tabela perderia a
hierarquia. Full House sobe de 14 em 14, Sequência de Cor de 35 em 35, Par de 8 em 8.

**R34 — SELOS E RELÍQUIAS.** Selo de casa cola numa das 25 casas; selo de eixo numa das 12
linhas; relíquia é global. **Onde colar é o jogo:** a casa central participa de 4 linhas, os
cantos de 3, o resto de 2 — o mesmo selo em duas casas é uma build diferente. Efeitos iguais
**empilham**, e é assim que build extrema existe.

O catálogo é **dado**, não código: um item novo é uma linha de tabela e, no máximo, um gancho a
mais em `Poderes`. O motor nunca pergunta "tenho a relíquia Novelo?" — ele pergunta "qual é o
Tear inicial?".

**R35 — O QUE A LOJA ENTREGA, MEDIDO.** No Tabuleiro 0, com o jogador simulado:

| | sem loja | com loja |
|---|---|---|
| vitória na rodada 6 | **0,0%** | **69%** |
| mesas da run vencidas | 9,5 de 18 | **16,3 de 18** |
| runs fechadas por inteiro | — | **56%** |

---

## 4d. A TRAVESSIA — depois da rodada 6 não existe teto

**R44 — FECHAR A RODADA 6 É UMA ESCOLHA, NÃO UM FIM.** A vitória fica registrada na hora, e o
jogador decide: parar com ela na mão, ou **seguir**. Quem segue não arrisca nada — a vitória já
está guardada.

**R45 — A CURVA NÃO TEM FIM PORQUE ELA É UMA FÓRMULA.** `pequena(n) = arredonda(2178 × 1,42^(n-1))`
vale para qualquer `n`. A rodada 15 pede 295 mil na Pequena e 679 mil no Chefe; a rodada 20 pede
1,7 milhão e 3,9 milhões. O que acaba não é o jogo: são as três vidas.

**Medido**, com o jogador simulado seguindo até cair, no Tabuleiro 0:

| | valor |
|---|---|
| rodada mais funda, mediana | **8** |
| rodada mais funda, máxima | **18** |
| maior colheita vista | **4.334.400** |
| mesas vencidas por run | 22,8 |

**R46 — DOIS CUIDADOS QUE A TRAVESSIA EXIGE**, e os dois são correções de coisa que quebraria:
a geometria 7 nunca deixa menos de **quatro linhas vivas** (numa travessia longa ela mataria as
doze, e tabuleiro sem linha viva não é difícil, é encerrado); e a tela troca os seis pontinhos de
rodada por um número, porque "rodada 12 de 6" não quer dizer nada.

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

## 5b. O JUICE — enfeite com regra

**R36 — TRÊS REGRAS PARA TODO EFEITO.** Nenhum pode **esconder informação**, **atrasar o próximo
clique** ou **durar mais que o gesto que o causou**. Tremor que continua depois do impacto é
enjoo, não impacto; partícula que cobre a carta é ruído com cara de produção.

**R37 — O PESO ESCALA COM O EVENTO.** Tremor, pausa e fagulhas saem do número de linhas colhidas
e do fator. Uma colheita de uma linha treme de leve; uma CRUZ TOTAL sacode a tela. **A diferença
entre as duas é a própria informação, sentida antes de lida.** O que acontece a todo turno —
pousar uma carta — quase não treme: efeito constante vira irritação em dez minutos.

Tetos duros: tremor **9 px** (acima disso a tela deixa de ser legível justamente quando mudou) e
pausa **0,14 s** (meio segundo é peso, um segundo é travamento).

**R38 — A PAUSA SEPARA O IMPACTO DO PAGAMENTO.** Durante ela, o placar **não corre** e nada mais
anda. É a separação que faz o número parecer merecido em vez de aparecer.

**R39 — AS CARTAS VOAM PARA A BARRA DA META**, em arco, não em linha reta — linha reta lê como
deslize, arco lê como objeto arremessado. Elas caem sobre o que estão enchendo, e não sobre o
número que precisa ser lido.

**R40 — O SOM É SINTETIZADO, SEM UM ARQUIVO DE ÁUDIO.** Onda gerada por código: senoide com
envelope, ruído filtrado para o baque. Mesma escolha da arte — o jogo inteiro cabe no repositório
porque nada dele é asset.

**A escada do Tear é a peça central:** cada degrau toca **um semitom acima** do anterior. Subir o
Tear deixa de ser um número mudando num painel e passa a ser uma nota mais alta, e o ouvido
entende "está crescendo" antes de o olho ler. A colheita é um acorde cuja altura vem do Tear e
cuja largura vem do número de linhas — cada linha a mais é literalmente uma nota a mais.

O volume é uma régua de quatro degraus, não um liga/desliga: quem quer o jogo baixinho não quer
escolher entre alto e mudo.

---

## 5c. AS CONQUISTAS

**R41 — CONQUISTA ENSINA REGRA, NUNCA PEDE GRIND.** Metade delas nomeia algo que o jogo já faz e
o jogador ainda não notou: quem lê *"colha as quatro linhas que passam por C3"* descobre um jogo
que estava ali o tempo todo. Nenhuma pede contagem alta sem decisão nova — o teste reprova quem
tentar pôr uma.

**R42 — TODAS VISÍVEIS DESDE O COMEÇO.** A conquista escondida não puxa ninguém.

**R43 — QUEM CONTA É QUEM ACONTECE.** As marcas ficam na **Mesa**, não na tela: uma partida
jogada por teste, simulação ou replay conta igual à jogada com a tela aberta. `marcas` guarda o
maior valor visto, `contas` soma — confundir os dois quebra metade da lista.

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

**Onde a conta aparece, e por quê.** A conta do nível 2 **flutua junto do cursor**, não numa faixa
fixa sob a mesa. A faixa custaria 18 px de altura da grade, e a medição mostrou que isso derruba a
casa de **64 para 61 px** — abaixo do alvo de toque. *O elemento onde o dedo trabalha é o único
que não cede tamanho.*

O que ela derruba vem em **cor de alerta**: o preço tem de ser lido como preço, senão a conta vira
propaganda da jogada. E ela fala também das linhas que a jogada só **aproxima** (`leva a fileira 4
a 3/5 e paga a parcela`) — sem isso, ela ficaria muda em 86% dos turnos, e dica muda quase sempre
lê como dica quebrada.

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
