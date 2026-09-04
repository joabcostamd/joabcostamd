# CRUZADA — RODADA 5

Três bancadas (81 células) e uma especificação de interface. Números conferidos nos
`resultado.json`, não nos resumos dos agentes.

**Aviso de calibragem, e ele muda como se lê tudo abaixo.** As três bancadas mediram a mesma
dívida em três bases: **−5,4 pp** (b-fracas, K=4,4042, código `fusao`), **−7,2 pp**
(b-estrategista, K=4,3922, `c4`) e **−4,7 pp** (b-mecanicas, base recalibrada a K=4,5273). Nas
sementes novas a mesma base deu −7,5 e −6,8. A dívida vale entre −4,7 e −7,5 pp conforme a
calibragem; um conserto de +5 pp está no limite do que se distingue da variação da própria base.

---

## 1. AS CINCO RESPOSTAS

### (a) O compêndio de regras

**Entra, com o rótulo REGRAS, como folha lateral que não pausa nem troca de cena — e o achado
que muda a proposta é que em paisagem a tabela de mãos já está na tela, então o compêndio é
antes de tudo um recurso de retrato.**

A especificação foi escrita depois de ler o wireframe, não de memória, e isso mudou três coisas:
o Receituário já é painel permanente em paisagem (`0,64,300,532`, tecla `R`) e **não existe em
retrato**; `R`, `1`–`6`, `Esc`, `Tab`, `F`, `T`, `X` e `Ctrl+Z` já estão ocupados, sobrando
`?`/`F1`/`H` e o Select do gamepad; e em retrato a base lógica 720×1280 numa tela de 360×800 faz
um botão de 48 lógicos virar 24 px reais — metade do mínimo de toque. Daí 96×96 lógicos na zona
do polegar (`604,952`), e não no topo.

Cinco abas fixas: **A CONTA · MÃOS · A MESA · PEÇAS · ATALHOS**. A CONTA vem primeiro porque a
dúvida mais frequente é "ganhei pontos sem fechar nada" — o Pulso é a maior fatia dos **75,8%**
de turnos que pagam algo e é a única recompensa em que nada sai da mesa. A segunda invenção que
vale é o quinto campo da tabela de mãos: `40 + 27 × 9 = 603`, o que a mão pagaria **no seu Tear
e no seu nível agora**. Uma tabela que mostra `30 ×3` com Tear 5 mente por omissão. Vem com
instrumentação (`metricas.csv`) e cinco critérios de reprovação escritos antes do código: <30%
abrem na mesa 1 · mediana <1,5 s sem trocar de aba · >25% terminam em aba diferente · queda >80%
de aberturas da rodada 1 à 4 · `mudou_jogada` >60%.

**Conflito não resolvido, e é da casa:** o compêndio proíbe CRUZADA em rótulo (§12 do documento)
e usa DUPLA · TRIPLA · CRUZ TOTAL; a proposta de nomes mata esses três por colidirem com Par e
Trinca. **Os dois documentos não entram juntos como estão.** O teste decide: DUPLA e TRIPLA não
foram testados, CRUZADA DE 2 passou 2/2, CRUZADA DE 4 reprovou 0/2. Recomendo a escada contada
em linhas e a §12 revisada.

### (b) Os nomes novos

**Dos 33 nomes, 10 reprovaram — os dois leitores frios erraram sozinhos — e a nota que eles
mesmos deram ao conjunto foi 4/10.**

O princípio está certo: função vence clima. "Multiplicador da Mesa" acertou 2/2 com confiança 8;
"Tear" não teria chance. O que falhou foi **família de palavras repetida**: três colheitas, três
"faltas", três "mults", quatro painéis de prévia, e o pior par da lista — COLHEITA ADIADA ×
ADIANTAMENTO, que os dois disseram que inverteriam sob pressão. Tabela completa no §2.

### (c) As mecânicas que entram

**Três entram; a mais vistosa da rodada, o bônus de cruzada, fica de fora por medição.**

| Entra | O número | Custo |
|---|---|---|
| **BC_rec** — piso do padrão parcial (+15 fichas em ALTA/PAR/DOIS PARES) + troco da linha fraca (+1 Tear, +2 descartes, +1 na mão) | gradiente **−5,4 → +5,4**, repetido em 3 famílias de sementes (−7,5→+4,8 · −6,8→+5,6) | 2 conceitos, ambos na 1ª colheita |
| **Fecho conta para a meta** — hoje o motor calcula vitória antes de `colheita_final()` | **+6,1 pp** gulosa (34,6→40,7), +5,0 profunda, com K, cruzada, m5 e seca idênticos | **0 conceitos** |
| **Beira B=3** | única com decisão medida: inércia **92,9%** gulosa / **84,1%** profunda (corte 95%); planejadora +1,7 pp, profunda +6,5 pp | 1 conceito, **+41% de cartas na tela** |

Ressalva no fecho: ele leva a vitória a **40,7%**, fora da banda 20–40. Não é "custo zero" como a
bancada escreveu — é zero em conceito, com recalibragem de K obrigatória.

### (d) Como pontuam as linhas que não formam mão completa

**Pagam 5,2% dos pontos da mesa (11,8% numa mesa perdida), mediana 468 contra 3.250 do evento
mediano — sete vezes menos — e por três caminhos só.**

1. **Pulso**, em 3/5 e 4/5: `(base parcial + fichas) × (mult + Tear) × 0,35`, duas vezes por
   linha no máximo; diagonal ×0,60 por cima.
2. **Colheita final**: linha com 3 ou 4 cartas paga o mesmo com `× 0,50`. **Com 0, 1 ou 2 cartas
   paga zero.**
3. **De mais nenhum jeito.** Linha incompleta não colhe e não sai do tabuleiro.

O detalhe que vai gerar reclamação: em linha parcial só valem CARTA ALTA, PAR, DOIS PARES,
TRINCA e QUADRA. **Sequência, Cor e Full não valem parcialmente** — quatro cartas do mesmo naipe
ainda não são uma Cor, e o jogo não paga por promessa. O que muda: o `× 0,5` passa a aparecer em
**toda** badge de linha durante a mesa inteira, não só no fim.

### (e) Como o estrategista volta a ser premiado

**Pagando melhor a mão fraca — não aumentando o prêmio da cruzada.**

A pista do briefing estava certa: refeito com o evento a 0,847/mesa, o preço **tem** gradiente
monotônico (−7,2 · −3,1 · −1,2 · +2,5 · +7,0 · +8,6 · +11,8 · +28,2 para b de 0 a 0,40). A
entrada de DECISOES §3 está **obsoleta**, não errada. Mas o beneficiário foi medido: os +8,6 pp
em b=0,27 são colhidos por um bot que só joga a cruz (1,633 cruzadas/mesa, 92,84% dos eventos são
dupla, n3 = 0,00%, ignora o Pulso). O proxy de jogador atencioso real (TECELÃ, horizonte 1) ganha
**+1,5 pp**, e K vai de 4,3922 a 6,25 (**+42%**).

O piso da mão fraca faz o serviço por outro caminho, e o mecanismo é limpo: a planejadora colhe
**49,8%** de mãos fracas contra 29,5% da gulosa, porque montar a cruz obriga a encher a linha com
o que vier. Pagar a linha fraca **reembolsa a multa de quem planeja, e só ele** — dose monótona
em seis níveis (−4,3 · −2,9 · −2,1 · −1,0 · +0,2 · +2,5). Controle de falsificação rodado: pagar
+30 fichas em **toda** linha infla K em 33% e move o gradiente só 2,3 pp. Alvo errado não paga.

---

## 2. A TABELA DE NOMES

| Conceito | Antigo | Novo | Rótulo | Fricção (2 leitores) |
|---|---|---|---|---|
| as 12 unidades que pontuam | linha viva | LINHA | "12 linhas" | **0/2 REPROVADO** — 12 > 10 num 5×5 travou os dois. → tirar o guarda-chuva da tela; só FILEIRA/COLUNA/DIAGONAL, contador `5 fileiras · 5 colunas · 2 diagonais` |
| a horizontal | linha 3 | FILEIRA | Fileira 3 | 2/2, ambos avisando que linha e fileira são sinônimos |
| colhe no próximo posicionamento | JANELA DA COLHEITA | COLHEITA ADIADA | Colhe depois | 2/2 (nenhum acertou *quando*) |
| troco em 3/5 e 4/5 | PULSO | ADIANTAMENTO | +Adiantado | **0/2 REPROVADO** — pior par da lista com "adiada". → **PARCELA** (`+parcela 3/5`) |
| mult que sobe e não desce | TEAR | MULTIPLICADOR DA MESA | MULT x6 | 2/2, confiança 8 — o melhor da lista |
| +1 a cada 4 posicionamentos | TIQUE DO TEAR | PASSO DO MULT | +1 a cada 4 | 2/2 no formato, **0/2 no referente** → `+1 a cada 4 JOGADAS` |
| coringa de duas caras | AVESSO | CARTA DUAS CARAS | Duas caras | 2/2, um marcou opaco ("pode ser 'conta em duas linhas'", a regra base) |
| a tabela dos degraus | A ESCADA | ESCADA DA CRUZADA | 2 - 3 - 4 | **0/2 REPROVADO** — "escada" já é sequência. → **LINHAS DE UMA VEZ** |
| fecha 2 linhas | DUPLA | CRUZADA DE 2 | 2 LINHAS | 2/2 |
| fecha 3 linhas | TRIPLA | CRUZADA DE 3 | 3 LINHAS | 1/2 → `3 LINHAS — fileira + coluna + diagonal` |
| fecha 4 linhas em C3 | CRUZ TOTAL | CRUZADA DE 4 | 4 LINHAS | **0/2 REPROVADO** — os dois concluíram que uma carta não toca 4 linhas. → **CRUZADA DO CENTRO** |
| ajuda em 3 níveis | ASSISTÊNCIA | AJUDA | AJUDA | **0/2 REPROVADO** por coexistir com REGRAS. → **DICAS** |
| nível 1 | silenciar o ruído | SÓ O QUE MUDA | Só o que muda | 2/2 (soa frase, não botão) |
| nível 2 | conta dos dois lados | GANHA E PERDE | Ganha e perde | 2/2 |
| nível 3 | recomendação | MAIOR GANHO AGORA | Maior ganho | 2/2 — manter o "agora" (não é a melhor em 41%) |
| linha em 3/5 | — | 3/5 | 3/5 + | 2/2 na fração, **0/2 no "+"** → trocar por `pago` |
| linha em 4/5 | — | FALTA 1 | Falta 1 | 2/2, colide com CARTAS QUE FALTAM e "Faltam 1.892" |
| linha cheia esperando | MADURA | PRONTA | PRONTA | 2/2 (um deduziu que colher é ação do jogador — não é) |
| unidade de ação | POSICIONAMENTO | JOGADA | JOGADAS 8/19 | 2/2 |
| as 11 categorias | RECEITUÁRIO | TABELA DE MÃOS | MÃOS | 2/2, confiança 8 |
| contador do baralho | BARALHO ABERTO | CARTAS QUE FALTAM | FALTAM | 2/2 → rótulo `AINDA NO BARALHO` |
| o que ainda fecha a mesa | MÍNIMO DOURADO | RECEITA DA META | Faltam 1.892 | **0/2 REPROVADO**, o mais opaco dos dois. → **COMO FECHAR** |
| 3 luzes de azar, +100% | FIANÇA | SEGURO | SEGURO 2/3 | **0/2 REPROVADO** — ninguém achou o +100%. → **REVANCHE 2/3** |
| pontuação antes de soltar | PRÉVIA FANTASMA | PRÉVIA | PRÉVIA | 2/2 |
| o botão do manual | (não existia) | REGRAS | ? REGRAS | 2/2, confiança 8 |
| evento de 1 linha | colheita | COLHEITA SIMPLES | 1 LINHA | 2/2 |
| o piso das fichas | PISO NUMÉRICO | MÍNIMO GARANTIDO | mínimo | 1/2 ("mínimo de quê?") → `nenhuma colheita vale zero` |
| pagamento de fim de mesa | COLHEITA FINAL | COLHEITA FINAL | FINAL x0,5 | 2/2 |
| categoria atual × possível | GARANTIDA/ALCANÇÁVEL | JÁ TEM / PODE TER | Já tem: Par | 2/2 |
| cartas que nascem na grade | SEMEADURA | CARTAS INICIAIS | início | **0/2 REPROVADO** (mesa ou mão?). → **GRADE INICIAL** |
| as 18 mesas | RUN | PARTIDA | Mesa 7/18 | **0/2 REPROVADO** — nome diz partida, rótulo diz mesa. → `PARTIDA · mesa 7/18` |
| limite do mult somado | teto do evento | TETO DO MULT | x52 - x48 | **0/2 REPROVADO** — ninguém entendeu os dois números. → **CORTE DO MULT** (`cortado: x52 → x48`) |
| colher esvazia as perpendiculares | (sem nome) | DESMANCHE | — | **não testado** — nome novo do compêndio; entra no próximo teste |

---

## 3. O QUE FOI MEDIDO E REPROVADO

| Ideia | O número que matou |
|---|---|
| Bônus de cruzada **dentro** do parêntese | auto-referente: K diverge para **5.492**, razão nunca chega a 0,79; b máximo ≈0,029 |
| Bônus **fora**, b=0,27 (o único lever que fecha a lacuna) | fecha para o bot monomaníaco (+8,6) e não para o atencioso (**+1,5**); K +42% |
| Bônus em fichas absolutas (B=1.000) | **−2,0**: decai ao longo das 6 rodadas |
| Bônus por linha extra | +3,0 e vitória global cai a 30,6 — pior nos dois eixos |
| Escada superlinear (E3/E4) | **−9,3** nas duas calibragens: piora a dívida em 2,1 pp |
| Diagonal inteira na Tripla | −0,7 pp: quem faz Tripla é a gulosa |
| Avesso esquenta | a política que **segura** o Avesso marca menos (36,5 × 37,5): premia um erro |
| Cruz Acesa | a planejadora acende a cruz em **0,0%** das mesas contra 3,1% da gulosa |
| Respiro (turno de volta) | pagar em pontos = pagar em turnos (33,5/27,9 × 34,0/28,3): turno é lavado por K. Inércia 100/100 em 10 células. A única config vencedora quebra o teto duro: **317 violações**, Grande de 1,000 → 1,95 |
| Última Costura | não ensina a recusa (segurando 4/5: 3,504 × 3,517) e derruba a planejadora de 30,9 a **20,5** |
| Fio de Ouro | premissa falsa: as diagonais já levam **45,5%** dos posicionamentos e 47,0% dos eventos. Inércia 100%; "só na Cruz Total" é literalmente a base (0,010/mesa) |
| Piso da mão fraca >15 fichas, ou com mult | inverte DOIS PARES < PAR; com mult, **FULL/ALTA = 1,38** — pôquer morto |
| Escada do piso (D) | inerte até d=0,10, e ali FLUSH (4,85) cai abaixo de SEQUÊNCIA (4,94) |
| Tear como moeda | 0,654 extra/mesa e o teto 8 come tudo — morreu de novo |
| Veto lateral da planejadora | **0 disparos em 4.230 turnos**: código morto |
| Caçar o Pulso na política | turnos pagos 75,8→85,9%, e vitória **37,1 → 21,0**. Turno pago não é ponto |

---

## 4. O QUE ISSO CUSTA

| Conceito novo | Quando aparece |
|---|---|
| **Beira** — uma fileira aberta de onde também se joga | **turno 1** |
| **Piso do padrão parcial** (quase-flush / quase-escada) | 1ª colheita (turno ~6–9) |
| **Troco da linha fraca** | 1ª colheita |
| Fecho conta para a meta | 0 — substitui regra existente |
| DESMANCHE | 0 — nomeia regra que já existe |

**No turno 1: 1 conceito**, dentro do orçamento de 2; somados na mesa: 3. Não corto por excesso
de conceito — corto por medição: fica de fora o **bônus de cruzada**, o mais vistoso e o mais
fraco onde importa.

O custo real da Beira não é conceito, é tela: **+41% de cartas**, jogadas legais de 85 para
**120**. E ela falha no teste que a própria proposta escolheu — a margem da 2ª melhor jogada
**cai** (2,935% → 2,857%). Mais opções, não mais decisivas; o ganho está na inércia. **Ou se
troca a régua, ou se corta a Beira — não dá para as duas coisas.**

---

## 5. O ESTADO DO JOGO DEPOIS DESTA RODADA

Cada coluna foi medida sozinha, contra a sua própria base. **A combinação nunca foi rodada.**

| Métrica | Antes (`fusao`) | BC_rec | Beira B=3 | Fecho conta | Banda |
|---|---|---|---|---|---|
| turnos que pagam | 75,8% | 75,9% | 76,1% | 75,8% | ≥70 |
| seca mediana | 2 (p90 3) | 2 | 2 | 2 | ≤3 |
| cruzadas/mesa | 0,831 | 0,839 | 0,836 | 0,831 | ≥0,5 |
| vitória gulosa | 36,1% | 34,1% | 35,7% | **40,7%** | 20–40 |
| guarda de profundidade | 68,2% | 68,5% | 68,8% | 68,2% | 45–75 |
| **planejadora − gulosa** | **−5,4 pp** | **+5,4 pp** | −4,1 pp | −9,8 pp | ≥0 |
| decisão (inércia gulosa) | — | não medida | **92,9%** | 100% | <95 |
| violações do teto duro | 0 | 0 | 0 | 0 | 0 |

A única linha fora de banda é a vitória do fecho (40,7 > 40): exige K novo.

---

## 6. O QUE AINDA NÃO SABEMOS

1. **Se BC_rec paga o jogador atencioso ou só o caçador de cruz.** É a pergunta mais importante
   em aberto. b-fracas mediu BC_rec contra a **planejadora**, que b-estrategista mostrou ser um
   bot monomaníaco (1,633 cruzadas/mesa, n3 = 0,00%, ignora o Pulso). BC_rec **nunca** rodou
   contra a TECELÃ, o proxy de jogador atencioso. Uma célula resolve.
2. **A combinação.** BC_rec + Beira + fecho nunca rodaram juntos com K único. A Beira muda a
   **ordem** das jogadas (inércia 92,9%) e é o tipo de regra que come folga de m5 — regras de
   preço não comem (67,2–67,8 em todas as variantes), regras de ordem sim.
3. **O K.** Já era a ressalva n.º 1 e sai desta rodada com três valores para a mesma base.
4. **A banda de vitória vale para qual política?** BC_rec põe a planejadora em 39,5% (40,4% e
   40,2% nas sementes novas) — encosta no teto de 40 se a banda valer para a melhor política.
5. **Divergência interna registrada:** o `resultado.json` de b-fracas dá +5,6 pp na semente
   480011 na célula e +5,4 na seção de recomendação do mesmo arquivo. Arredondamento, anotado.
6. **Tudo que é humano:** se "+2 descartes" soa prêmio ou esmola; se a Beira parece bagunça; se
   o Avesso se lê de relance; se alguém abre REGRAS; se DESMANCHE é a palavra certa.

---

## 7. RECOMENDAÇÃO

**Construir. A rodada 6 de simulação não é o próximo passo mais barato.**

Cinco rodadas, dezenas de milhares de mesas, nenhuma linha do jogo escrita. E olhe o que a
rodada 5 produziu de mais útil: **um teste com dois leitores humanos que reprovou 10 de 33
nomes** e **um `if` no motor que valia 6,1 pp de vitória**. Nenhum dos dois exigiu bancada. O
que ainda falta saber é, na maior parte, o que o próprio livro-razão declara não mensurável por
simulação desde a §8.

O que construir, nesta ordem:

1. **Núcleo já aprovado** com as três entradas: BC_rec, fecho contando para a meta (com K
   recalibrado — 40,7 está fora de banda) e a Beira **atrás de uma chave desligada**, até um
   humano ver 120 jogadas legais na tela.
2. **O botão REGRAS e a aba A CONTA** desde o primeiro jogável. A CONTA é o instrumento que
   permite, pela primeira vez, perguntar se quem vê o preço perpendicular passa a **recusar**
   fechar linhas em 4/5 — a habilidade central que seis bancadas não ensinaram.
3. **Os nomes corrigidos do §2** antes de a primeira string entrar no `textos.csv`. Renomear
   depois custa código, tradução e memória muscular.

**Uma célula, não uma rodada, antes de fechar o balanceamento:** BC_rec contra a TECELÃ. Se
pagar o jogador atencioso, o item (e) está resolvido e o assunto morre. Se pagar só o
monomaníaco, temos duas regras premiando o mesmo bot e nenhuma premiando o Joab jogando com
atenção — e aí a pergunta deixa de ser "qual regra" e passa a ser "o que é, medido, um jogador
atencioso", que só se responde vendo um humano jogar 20 minutos.
