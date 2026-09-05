# PLACARD — livro-razão das decisões

Toda linha deste documento tem um **número medido** atrás. Nada aqui é opinião de designer.

As medições vêm de um protótipo headless do núcleo em GDScript rodado no Godot 4.7.2
(`sonda/`), com RNG semeado e comparações pareadas. Quando um número não foi medido, está
escrito `não medido` — nunca preenchido por estimativa.

**Como usar:** antes de propor qualquer mudança, procure aqui. Metade das boas ideias deste
projeto já foi testada e morreu com um número específico.

---

## 1. O ponto de partida: o núcleo cru

Como o jogo estava quando saiu do documento de design, antes de qualquer ajuste.
2.000 mesas por política, 6 rodadas × 3 tipos de mesa.

| Medição | Valor | Leitura |
|---|---|---|
| Turnos em que nenhuma jogada pontua | **85,9%** | o jogo era mudo |
| Jogadas legais por turno (mediana) | **100** | parecia pesadíssimo… |
| Margem da 2ª melhor jogada | **1,49%** | …e era irrelevante |
| Tempo entre recompensas (mediana) | **24 s** (p90 36 s, máx 60 s) | cadência de quebra-cabeça |
| Seca (turnos seguidos sem pontuar) | mediana **7**, máx 14 | |
| Eventos de pontuação por mesa | **2,3** — teto duro de 3 | ver §5 |
| Cruzes por mesa | **0,00**, 100% das mesas com zero | o evento que dá nome ao jogo |
| Tear ao fim da mesa | mediana **2**, máx 3 | o teto 8 da regra era ficção |
| Taxa de vitória | **11,0%** | |
| Derrotas já decididas aos 2/3 | **72,5%** | tempo jogando partida perdida |
| Cartas vistas numa mesa inteira | **18 de 52** | |
| **Concordância gulosa × profunda** | **58,8%** | **o melhor número do projeto** |

Essa última linha é a que salvou o projeto: 58,8% fica exatamente entre o jogo que se resolve
sozinho (~95%) e o que pune a intuição (~20%). **O núcleo tem profundidade real.** Todo o resto
foi conserto de encanamento em volta de uma boa ideia.

---

## 2. APROVADO — entrou, com o número que aprovou

| Regra | O que faz | Efeito medido |
|---|---|---|
| **PULSO** (fator 0,35) | linha paga um troco ao chegar em 3/5 e 4/5, sem gastar carta nem turno | turnos com recompensa **14,3% → 65,1%**; seca **7 → 2**; espera **6 → 1** turno |
| **TIQUE DO TEAR** | +1 no Tear a cada 4 posicionamentos, além do +1 por colheita | Tear mediano **2 → 8**; razão pontos/meta **0,442 → 0,794** |
| **TEAR MULTIPLICA** | o Tear multiplica em vez de somar | maior evento **2.394 → 10.260** (×4,3); explosão **7,2× → 15,8×**; teto passa a morder em 21,2% das mesas (era 0%); derrota decidida aos 2/3 cai **69,9% → 56,6%**; e o código encolhe |
| **AVESSO** | carta de duas caras forjada pela própria colheita: uma cara vale na linha, a outra na coluna | **1,66/mesa**, 10,8% das jogadas, 37,8% dos pontos; **C3 recebe 28,6%** contra 4,0% do uniforme (**7×**, entropia 0,827); **+2,25 pp** de vitória |
| **JANELA DA COLHEITA** | a linha cheia não colhe na hora: fica **madura** e colhe no próximo posicionamento, junto com tudo que completou no meio-tempo | **cruz 0,000 → 0,831 por mesa** em jogo natural; mesas sem nenhuma **100% → 16,9%**; turnos pagos 65,7% → 75,8%; profundidade 58,8% → 68,2% (dentro da banda 45–75) |
| **BC_rec** | a mão fraca paga melhor: piso de padrão parcial (+15 fichas em Alta/Par/Dois Pares) e troco não-numérico (+1 no multiplicador, +2 descartes, +1 na mão) | **resolve a dívida do estrategista**: gradiente planejadora−gulosa de **−5,4 → +5,4 pp**, repetido em 3 famílias de sementes (−7,5→+4,8 · −6,8→+5,6) |
| **Fecho conta para a meta** | correção de motor: hoje a vitória é calculada **antes** da colheita final, então o fecho nunca vira a mesa | **+6,1 pp** de vitória, **zero conceito novo** — mas leva a 40,7%, fora da banda 20–40: exige recalibrar o K |
| **K = 1,25** na curva de metas | corrige a dificuldade | razão **0,990 → 0,793**; vitória **40,75% → 28,8%** |

O número mais importante desta tabela é o **7× de concentração em C3**. Ele prova que *onde
colocar* é uma decisão de verdade, e não teatro — que era a dúvida existencial do design.

---

## 3. REPROVADO — não entra, com o número que matou

| Ideia | Por que parecia boa | O número que matou |
|---|---|---|
| **AGULHA** (coringa que vem pela compra e resolve como uma carta só) | o momento "veio o coringa!" | resíduo morto **66,7%** (banda 20–40%); é **anti-cruz**: derruba de 0,087 para **0,032/mesa (−63%)**; leva 61,1% dos pontos; C3 em **4,2%** — indistinguível de aleatório |
| **PRUMO / cascata por gravidade** (a carta sobrevive à colheita e cai) | reação em cadeia é o motor de dopamina do Tetris | **0 elos em 48.000 mesas**; em **3.866 quedas a pista de pouso existiu 0 vezes** |
| **ESTRELA** (fechar 4 linhas em C3) | a fantasia de quebrar o jogo | **0 ocorrências** em 1.002 gulosas, 402 profundas e 1.002 caçadoras; **99,1%** das Estrelas contêm mão de mult ≤ 2 (o anticlímax é a norma); produto real mediano **24** contra 1.120 prometido — **47× otimista** |
| **Precificar a cruz** (pagar muito mais por ela) | se o prêmio for enorme, o jogador persegue | preço ×4, ×20 e ×100: gulosa continuou em **0,0000**, 100% das mesas sem cruz; a profunda **piorou** (0,0274 → 0,0174) |
| **Avesso "dobra os outs" da cruz** | argumento central da proposta | **0,088 com** contra **0,087 sem**. Nulo |
| **AGULHA + AVESSO juntos** | dois coringas, mais opções | vitória **73,33%**, razão 1,159 — o jogo vira passeio, e ainda com **0,000 cruz** |

### RESOLVIDO pela Janela da Colheita (rodada 4)

Os três candidatos que **nós** propusemos falharam, e o vencedor foi um quarto, desenhado
pela aritmética depois de calcular que montar uma cruz custa 9 posicionamentos:

| Candidato | Resultado |
|---|---|
| Só a cruz levanta o Tear | dial de **zero bit**: 0,0000 nas 8 variantes; com a cruz já acontecendo, 0,831 com e sem — **99,96% de jogadas idênticas** em 4.815 turnos |
| Maturação do 4/5 | inerte até F=1,0; só 0,012 em F=1,5; somada à Janela **derruba** a cruz para 0,672 |
| Semear mais o tabuleiro | **0,000 a 0,017** para todo S de 3 a 12 com material conservado |
| **Janela da Colheita** ✅ | **0,000 → 0,831** |

Variantes que estouraram a guarda de profundidade e foram descartadas: `janela=2` (76,3%),
`janela até o fim` (77,8%), combinações de 3 e 4 regras (80,3% e 80,5%).

### A descoberta que atravessa as três bancadas

> Em **30.944 turnos de jogo guloso não existiu uma única vez** uma jogada que fechasse duas
> linhas — com coringa na mão e sem.

A configuração que a cruz exige (duas linhas em 4/5 compartilhando uma casa vazia)
**não aparece**. Fechar uma linha em 4/5 é sempre a jogada de maior ganho imediato, então
duas linhas nunca ficam esperando ao mesmo tempo.

**O gargalo é de ORDEM, não de carta nem de preço.** Nenhum coringa conserta, porque o coringa
responde *qual carta?* e o problema é *quando?*.

---

## 3b. ASSISTÊNCIA DE POSICIONAMENTO — mantida, com a régua trocada

O documento já oferece sugestão de jogada: halo verde/amarelo/vermelho nas casas vazias e
**anel numerado nas 5 melhores, ordenado por ganho de pontos**, desligável em três níveis.

**O que a medição diz a favor:** a assistência **não trivializa o jogo**. A jogada de maior
ganho imediato coincide com a ótima em apenas **58,8%** dos turnos, e segui-la sempre custa
só **1,4 ponto percentual** de vitória. O jogador assistido não é punido.

**O que a medição diz contra, e é grave:** a política gulosa do simulador *é* um jogador
seguindo o anel #1, e ela produziu **0,000 cruz em 30.944 turnos**.

> A assistência não faz o jogador perder. Faz o jogador **nunca ver o melhor momento do jogo**.

E não é passiva: uma lista ordenada por ganho imediato **sempre** recomenda fechar a linha em
4/5, que é exatamente o que impede a cruz. Ordenada assim, a assistência é uma máquina de
impedir o clímax — e ensina a jogada errada com ar de autoridade.

**Contradição no próprio documento:** a §15 exige que o jogador pensante vença **12 pp** a mais
que o assistido, sob pena de reprovar o build. O abismo real entre políticas competentes é
**1,4 pp** — a banda pede um abismo **8,6× maior que o maior que existe**. O teste, como está,
reprovaria o jogo.

**Decidido:** manter a feature, em três níveis, e trocar o que ela ordena e o que o teste mede.

| Nível | O que faz | Por quê |
|---|---|---|
| 1 — silenciar o ruído | apaga as ~85 casas que não mudam nada | em 86% dos turnos todas as jogadas dão o mesmo resultado; isso é ruído, não decisão. É informação, não conselho — pode ficar ligado até no modo difícil |
| 2 — mostrar a conta dos dois lados | "fecha a linha 3 (Trinca, 340 pts) **e** derruba a coluna C de 4/5 para 3/5" | o halo vermelho já faz metade; completar é o único mecanismo encontrado que **ensina a recusa** — o problema aberto que seis bancadas não resolveram |
| 3 — recomendação explícita | mantida para quem quer zero estresse, rotulada **"maior ganho agora"** e nunca "melhor jogada" | medimos: não é a melhor em 41% dos turnos. Rótulo honesto ou nada |

**Régua nova do teste de segurança:** medir vitória é medir a coisa errada — o custo da
assistência não aparece lá (1,4 pp). A pergunta que reprova o build passa a ser:
**um jogador que segue a dica chega a ver uma cruz alguma vez?** Hoje a resposta é não.

---

## 3c. POR QUE PAGAR A MÃO FRACA CONSERTA O ESTRATEGISTA

O achado mais útil da rodada 5, e não era o que procurávamos.

**Quem planeja colhe mão ruim.** A política planejadora colhe **49,8%** de mãos fracas contra
**29,5%** da gulosa — porque montar a cruz obriga a encher a linha com o que couber, não com o
que combina. A multa por planejar estava embutida na pontuação da mão fraca.

Logo: pagar melhor a linha fraca **reembolsa exatamente quem planeja, e só ele**. Controle
rodado: pagar mais em *toda* linha infla o K em 33% e move o gradiente só 2,3 pp.

**E o teste de preço que mandamos refazer tinha razão pela metade.** Com a cruz finalmente
acontecendo, o preço passou a ter gradiente (−7,2 · −1,2 · +2,5 · +8,6 · +28,2) — o teste
original de fato media um evento inexistente. Mas o beneficiário foi medido: os +8,6 pp vão para
um bot que **só** joga a cruz; o jogador atencioso ganha **+1,5 pp** com o K subindo 42%.
Por isso **não entra**: premia a monomania, não a atenção.

---

## 3d. NOMES — o exercício falhou, e a falha é o produto

33 nomes propostos, **10 reprovados** (os dois leitores frios erraram sozinhos). Nota do
conjunto: **4/10**. As correções que só um leitor frio acha:

| Conceito | Nome testado | Por que falhou | Nome corrigido |
|---|---|---|---|
| a tabela dos degraus | ESCADA DA CRUZ | **"escada" já é sequência no pôquer** | LINHAS DE UMA VEZ |
| fechar 4 linhas no centro | CRUZ DE 4 | os dois concluíram que uma carta não toca 4 linhas | CRUZ DO CENTRO |
| troco em 3/5 e 4/5 | ADIANTAMENTO | pior par da lista, confundido com "adiada" | PARCELA |
| as 12 unidades que pontuam | LINHA | 12 > 10 num 5×5 travou os dois | só FILEIRA / COLUNA / DIAGONAL |
| ajuda em 3 níveis | AJUDA | colide com REGRAS na mesma tela | DICAS |
| o que ainda fecha a mesa | RECEITA DA META | o mais opaco de todos | COMO FECHAR |
| 3 luzes, +100% | SEGURO | ninguém achou o +100% | REVANCHE |
| cartas que nascem na grade | CARTAS INICIAIS | mesa ou mão? | GRADE INICIAL |
| as 18 mesas | PARTIDA | nome diz partida, rótulo diz mesa | PARTIDA · mesa 7/18 |
| limite do mult somado | TETO DO MULT | ninguém entendeu os dois números | CORTE DO MULT |

**Lição registrada:** nome de mecânica não se valida por gosto. Custa 2 agentes e meia hora
testar com leitor cego, e pegou 10 erros que passariam para a versão final.

---

## 3e. DIREÇÃO DE ARTE — decidida olhando, não lendo

**2D vetorial**, desenhado por código. O 3D briga com a leitura do tabuleiro (perspectiva reduz
cartas do fundo, inclinação esconde o índice do canto, luz e sombra criam ruído sobre a informação
que precisa ser lida rápido) e, o que mais pesa: em 2D a qualidade **tem número** — contraste,
alvo de toque, estouro de `Control` — enquanto em 3D "ficou bonito" não tem teste.

**Tema padrão: Feltro e ouro.** Escolhido pelo Joab entre os oito renderizados de verdade, pelo
argumento mais forte que ele tem: é o único em que uma pessoa que nunca ouviu falar do PLACARD
sabe que é um jogo de cartas **antes de ler qualquer palavra**. Meio segundo de compreensão que os
outros sete gastam explicando — e para um indie que vive de miniatura em página de loja, isso vale
mais que qualquer refinamento de paleta.

Os outros sete são desbloqueáveis, **exceto os dois de fundo claro**: Papel e tinta e Porcelana
ficam liberados desde o início, porque fundo claro é afordância de acessibilidade e não cosmético
de recompensa — quem precisa dele não deve ter que merecê-lo.

| Ordem | Tema | Como se obtém |
|---|---|---|
| — | **Feltro e ouro** | padrão |
| — | Papel e tinta · Porcelana | desde o início (acessibilidade) |
| 1 | Casino noturno | vença a primeira run |
| 2 | Meia-noite | jogue 25 mesas |
| 3 | Veludo e brasa | faça uma Sequência de Cor |
| 4 | Ameixa e ouro | vença no Tabuleiro 3 |
| 5 | Neon arcade | faça uma CRUZ DO CENTRO |

O Neon fica por último de propósito: é o mais impressionante nos primeiros dez segundos e o mais
cansativo no minuto vinte. Tema que grita "uau" vale mais como prêmio que como padrão.

---

## 3f. QUATRO HIPÓTESES DE DESIGN QUE A MEDIÇÃO DERRUBOU

Registradas porque cada uma teria virado uma decisão errada, e três delas eram "conhecimento"
que todo mundo repete.

| Hipótese | O que a medição disse |
|---|---|
| "As cartas saltam mais sobre verde — é por isso que mesa de baralho é verde" | **Falso na tela.** O feltro tinha a MENOR separação de carta entre os temas escuros (12,8 contra 16,9). A lógica vale para papel sob lâmpada, não para pixel |
| "O vermelho perde contraste sobre verde saturado, então copas vira magenta" | **O naipe nunca toca o verde** — é desenhado sobre a carta, que é creme. O magenta resolvia um problema inexistente |
| "As bordas de ciano do Neon fazem as casas vazias competirem com as cartas" | **Proporção idêntica nos três finalistas: 18%.** O incômodo é de croma, que o validador de luminância não mede — e isso é julgamento, não número |
| "A casa vazia precisa de preenchimento E borda fortes" | **Rigor errado.** A exigência reprovava seis temas escuros que se liam perfeitamente. A borda é a afordância e sozinha carrega a informação |

**A lição que fica:** teste rigoroso demais também é teste errado. Se eu tivesse obedecido ao
número sem pensar, teria estragado seis temas para consertar dois.

---

## 3g. A CONSTRUÇÃO — o que só apareceu quando o jogo virou jogo

A sonda tinha 4.813 linhas e cinco rodadas de bancada. Ainda assim, escrever o jogo de verdade
achou coisa que 100.000 mesas não tinham achado. Registrado aqui porque é o argumento contra
"mais uma rodada de simulação".

### O motor foi aferido contra a bancada, e sete de nove métricas fecham

O jogo roda uma aferição de 810 mesas (`ferramentas/aferir.gd`) com um jogador guloso que é
o mesmo da bancada. Sem isso, "portamos o núcleo" seria afirmação sem prova.

| métrica | bancada | jogo | |
|---|---|---|---|
| turnos com recompensa | 75,9% | **75,3%** | ✅ |
| seca mediana | 2 | **2** | ✅ |
| cruzes por mesa | 0,839 | **0,830** | ✅ |
| razão pontos/meta | 0,790 | **0,768** | ✅ |
| Tear mediano | 7 | **7** | ✅ |
| eventos por mesa | 1,17 | **1,16** | ✅ |
| colheita · DUPLA · TRIPLA · TOTAL | 29,0 · 51,9 · 18,2 · 0,85% | **28,7 · 55,4 · 15,2 · 0,7%** | ✅ |
| **Avessos por mesa** | 1,66 | **2,19** | ⚠ |
| **vitória do guloso** | 34,1% | **39,4%** | ⚠ |

As duas divergências são a combinação que o §7 desta ficha já declarava **não medida**, e as
duas apontam para o mesmo lugar: a Janela colhe mais linhas por mesa do que a bancada do
coringa colhia, e como cada linha colhida forja um Avesso, saem 2,19 em vez de 1,66. Mais
Avesso é mais Quina e mais Quadra, e a cauda de pontuação engorda — daí a vitória subir 5
pontos. **Nada disso é regressão de porte: é a soma que nunca tinha sido somada.**

### O K continua em 4,84, e agora por medição própria

Varremos a constante da curva contra o motor de verdade (`ferramentas/calibrar.gd`):

| fator | K | razão | vitória | vitória por rodada 1→6 |
|---|---|---|---|---|
| **1,00** | **4,84** | **0,802** | 38,2% | 87,5 · 75,0 · 41,7 · 16,7 · 8,3 · 0,0 |
| 1,08 | 5,23 | 0,742 | 36,8% | 87,5 · 66,7 · 41,7 · 16,7 · 8,3 · 0,0 |
| 1,16 | 5,61 | 0,691 | 34,7% | 87,5 · 62,5 · 37,5 · 16,7 · 4,2 · 0,0 |
| 1,24 | 6,00 | 0,646 | 31,2% | 79,2 · 58,3 · 37,5 · 8,3 · 4,2 · 0,0 |

**Mantido em 4,84.** É o valor que põe a razão em 0,77–0,80, que é o alvo da calibragem; subir K
para trazer a vitória ao meio da banda derrubaria a razão para 0,69, e a razão é a régua, não a
vitória. A vitória em 39,4% encosta no teto de 40 — exatamente como a bancada previu que
aconteceria com a BC_rec ligada.

**As duas pontas da curva continuam abertas, e as duas dependem da loja, que não existe:**
a rodada 1 é passeio (87,5%) e a rodada 6 é intransponível (0,0%). A bancada tinha 76,1% e 0,6%
com o produto ligado e sem BC_rec. Não corrigir isso mexendo em K: o que falta é poder de
compra entre as mesas, e inventar dificuldade para compensar um sistema ausente é a forma mais
cara de errar.

### O simulador errado mede ruído, não jogo

A primeira aferição reprovou em três métricas, e o defeito era o **jogador**, não o motor. Eu
tinha escrito uma política gulosa que maximiza pontos imediatos — parecia a definição óbvia de
"guloso". Ela produz:

| | política ingênua | política da bancada | |
|---|---|---|---|
| turnos com recompensa | 52,3% | **75,3%** | |
| razão pontos/meta | 0,463 | **0,768** | |
| linhas colhidas em Par | **53,6%** | 16,1% | ← o diagnóstico |
| linhas colhidas em Flush | 0,35% | 14,1% | |
| linhas colhidas em Quadra | 0,26% | 7,9% | |

A política da bancada não maximiza pontos: ela colhe quando dá e, quando não dá, **maximiza o
quanto as linhas ainda prometem** (`melhor_alcancavel` projetado para 5 cartas, pesado por
quantas cartas a linha já tem). Sem essa segunda conta o bot enche casa com qualquer carta e
colhe Par em metade das linhas — e todo número medido em cima dele é ruído com três casas
decimais.

**Lição:** a política do simulador é parte do instrumento, não do experimento. Trocá-la sem
dizer invalida a série inteira. Ela e o descarte (que a bancada usava e eu tinha esquecido, e
que sozinho move a razão de 0,626 para 0,789) estão agora em `ferramentas/politica.gd`, com o
porquê escrito.

---

## 3h. A SEGUNDA CONSTRUÇÃO — dificuldade, loja, conquistas, juice

### O jogo era impossível, e agora tem número dos dois lados

| | sem loja | com loja |
|---|---|---|
| vitória na rodada 6 (Tabuleiro 0) | **0,0%** | **69–74%** |
| mesas da run vencidas | 9,5 de 18 | **16,3 de 18** |
| runs fechadas por inteiro | — | **50–60%** |

A loja não é conteúdo: é a única razão de a curva `1,42^n` ser escalável. Sem crescimento de
poder entre as mesas, a rodada 6 é aritmética fechada.

### A curva dos nove graus, medida

| grau | runs fechadas | mesas de 18 | | grau | runs | mesas |
|---|---|---|---|---|---|---|
| 0 | 50% | 16,1 | | 5 | 7% | 10,3 |
| 1 | 29% | 14,6 | | 6 | 0% | 10,4 |
| 2 | 14% | 12,6 | | 7 | 0% | 6,6 |
| 3 | 14% | 12,2 | | 8 | 0% | 4,6 |
| 4 | 7% | 10,7 | | **Estufa** | **100%** | **18,0** |

Os números vão para a **tela de escolha**. Quem decide quanto quer apanhar tem direito de saber o
que está escolhendo, e "difícil" não informa nada.

### A travessia: o teto é a build, não o código

Depois da rodada 6 a run continua enquanto o jogador aguentar. Medido no Tabuleiro 0, com o
simulado seguindo até cair: rodada mais funda **mediana 8, máxima 18**, maior colheita
**4.334.400**. O jogo tem fim de conteúdo, mas não tem teto de sistema.

### Quatro defeitos que a medição achou, e todos fechavam portas

1. **A geometria 4 comia o baralho inteiro.** "Cartas colhidas não voltam" tirava ~9 cartas por
   mesa; na rodada 4 sobravam 15 e a mão zerava. → piso de **32 cartas**.
2. **A mesa não terminava com a mão vazia — ela parava de responder.** A run repetia o mesmo
   estado para sempre, sem nem gastar uma vida. → a mesa termina quando não há jogada legal,
   fazendo o fecho. *Congelamento não aparece como bug: aparece como jogo quebrado.*
3. **A geometria 7 matava as doze linhas** numa travessia longa. → nunca abaixo de quatro vivas.
4. **As marcas das conquistas dependiam de a TELA chamar um método.** Toda partida jogada por
   teste, simulação ou replay contava zero. → quem conta é quem acontece: a **Mesa** acumula, a
   Run absorve.

### O que os testes de tela pegaram, e nenhum teste de regra pegaria

- O fantasma da carta virava retângulo cinza (véu escuro por cima do desenho).
- O rótulo `SEQUÊNCIA DE COR` media 138 px num espaço de 108 e invadia o painel.
- As duas **diagonais não tinham estado nenhum na tela** — o jogador só descobria que uma estava
  cheia quando ela colhia.
- As cartas voando caíam **sobre o número da pontuação**, cobrindo-o justamente enquanto ele
  contava.
- O saldo `$` da loja era desenhado **fora da tela** (alinhamento à direita desenha *dentro* de
  `[x, x+largura]`, não à esquerda de `x`).
- O botão do fecho da run **só tinha alvo de toque depois do primeiro desenho**.

### Regras novas que a medição impôs ao enfeite

O juice tem teto medido: tremor **9 px** (acima, a tela deixa de ser legível justamente quando
mudou) e pausa **0,14 s** (meio segundo é peso; um segundo é travamento). O peso escala com o
evento, e **essa escala é a informação**: uma linha treme de leve, uma cruz total sacode. O que
acontece a todo turno quase não treme — efeito constante vira irritação em dez minutos.

---

## 4. DIALS QUE SÃO CÓDIGO MORTO — não vire parâmetro nenhum destes

Medidos, deram zero. Transformar isso em opção de balanceamento é dívida técnica gratuita.

| Dial | Resultado |
|---|---|
| Teto de Avessos por mesa (2 / 3 / 4 / sem teto) | **42,2% em todas** as configurações |
| Ganho de Tear por colheita (+1 / +2 / +3) | move a profundidade em **0,08 ponto** |
| `TEAR_TETO` acima de 8 | morde **0%** das mesas |
| Desempate do carimbo da Agulha (declarado "a primeira coisa a medir") | 53,17 × 52,33 |

---

## 5. LIMITES ESTRUTURAIS — aritmética das regras, não simulação

Consequências que saem direto das regras e que nenhum balanceamento contorna:

- Uma colheita manda **5 cartas** para uma pilha que não volta, e o orçamento é de 15/17/19
  posicionamentos. Logo: **teto duro de 3 eventos de pontuação por mesa**, e intervalo mínimo
  de **20 segundos** entre recompensas *por regra*, não por ajuste.
- Uma mesa vê **17 a 19 cartas** das 52 na vida inteira. O baralho nunca esvazia; a regra de
  reembaralhar o descarte praticamente nunca dispara.
- Teto teórico de cruzes: **2** na Pequena e no Chefe, **1** na Grande (17 cartas < 18
  necessárias para duas). A banda "1,5 a 2,5 cruzes por mesa" do documento original era
  **aritmeticamente impossível**.

---

## 6. ERROS DE MEDIÇÃO QUE NÓS COMETEMOS

Registrados de propósito. Errar de novo custa mais caro que admitir.

1. **Base medida errado.** A "linha de base" de uma das rodadas era colagem de duas variantes
   medidas em dificuldades diferentes. Produziu o número "vitória 21,8%" que circulou como
   verdade. O correto, pareado, é **28,8%**. → *Toda bancada agora reproduz a base e confere
   antes de medir variante.*
2. **Medir a cruz com política gulosa mede o teto errado.** Montar uma cruz exige
   planejar ~8 turnos à frente; políticas de 1 e 2 níveis não enxergam isso. Um humano
   enxerga. → *Toda medição de cruz exige uma política planejadora.*
3. **"Maior evento de uma run vencida" foi medido como "de uma mesa vencida".** Escopo
   diferente, número diferente.
4. **Uma proposta chegou com número inventado no texto** ("produto ~1.120"); o medido foi 24.
   → *Número em proposta é hipótese até a bancada rodar.*
5. **Escrevi a fórmula do evento errada no documento de regras**, e quase construí em cima dela.
   Tinha escrito "pontos do evento = soma das linhas × Tear", cada linha com o próprio
   multiplicador. A conta medida é outra: o fator é a **soma dos multiplicadores de todas as
   mãos colhidas**, vezes o Tear, e vale igual para todas elas. Sob a minha versão, colher duas
   linhas juntas pagaria o mesmo que colher as duas separadas — e a Janela da Colheita, que é a
   regra que dá nome ao jogo, não teria razão de existir. → *Toda fórmula do documento é
   reconferida contra o motor medido antes de virar código, e o teste que a guarda compara as
   duas colheitas em vez de conferir um número.*
6. **Medi com o bot errado e quase acreditei.** Ver §3g: uma política gulosa que maximiza pontos
   imediatos parece a definição óbvia de guloso e produz um jogo que não existe.
7. **Um script de bancada sem `quit()` roda para sempre.** Uma calibragem ficou 25 minutos
   ocupando o processador depois de já ter terminado a conta, com a saída presa no buffer. Não
   é erro de medição, é erro de instrumento — e custou o mesmo tempo.

---

## 7. EM ABERTO

| Questão | Situação |
|---|---|
| ~~**Planejar deixou de pagar**~~ ✅ RESOLVIDO pela BC_rec (§3c) | com a Janela, quem planeja a cruz cai de **62,7% para 30,7%** de vitória, enquanto quem joga no impulso sobe de 31,2% para **36,1%**. O gradiente de perícia inverteu. Alvo da próxima bancada: devolver retorno ao planejamento **sem** aumentar o prêmio da cruz (já provado inerte em 4×, 20× e 100×) |
| **A cruz virou o comum** | **71% dos eventos** agora são cruz (banda saudável 0,35–0,55 por evento); eventos por mesa 2,21 → 1,17; explosão 15,6× → 10,0×. Proposta: mover o clímax um degrau acima, para a escada **DUPLA (9 posic, 2×) · TRIPLA (13, 3×) · CRUZ TOTAL (17, 4×)** — a Tripla é 18,2% dos eventos e a Total 0,85%, e a Cruz Total cabe **exata** numa mesa Grande |
| **A pasta ainda se chama `placard/`** | o jogo virou **PLACARD** e o título trocou em todo lugar — `Marca.NOME`, `config/name`, DESIGN, README, HUD. A pasta não. Renomear é seguro (os caminhos `res://` são relativos à raiz do projeto e não mudam), mas é diff grande e decisão do Joab. `placard-pesquisa/` **não** renomeia: é registro do que se decidiu quando o jogo tinha o outro nome |
| **A jogada continua se chamando CRUZ** | de propósito — em português é o que uma grade de palavras cruzando faz. Se algum dia o jogo for traduzido, é a jogada que precisa de nome novo em inglês, não o título |
| **O Godot não sai depois do `quit()`** | 9 em 30 rodadas do teste de fluxo. O teste passa, imprime, chama `quit(0)` e o processo fica vivo a 100% de CPU, com saída idêntica à de uma rodada boa. Calar o áudio e desmontar a cena com calma derrubou o vazamento de saída de 170 para 3 objetos e **não mexeu na taxa**. Contornado no `testar.sh`, que julga pelo que foi impresso. Não diagnosticado: falta saber o que segura o desligamento |
| **Ergonomia do Avesso na tela** | não medido — desenhar uma carta de duas caras que se lê de relance é **condição de corte** do coringa |
| **Ensinar a recusa** | nenhuma bancada achou mecanismo que ensine o jogador a *não* fechar uma linha. É a habilidade central e ninguém a ensina |
| **AVESSO × PRODUTO** | combinação nunca rodada. Agora rodam juntos no jogo: Avessos vão a 2,19/mesa e a vitória a 39,4% (§3g). Não é regressão — é a soma, medida pela primeira vez |
| **A rodada 1 é passeio e a 6 é intransponível** | 87,5% e 0,0% de vitória. As duas pontas esperam a loja, que não existe. Não corrigir com K |
| **34% dos turnos ainda são mudos** | melhor que 86%, ainda não é Balatro (0%) |
| **O maior momento ainda é pequeno** | pico de 4,19× a meta, p99 de 2,36×. É "passei raspando", não "quebrei o jogo" |

---

## 8. O QUE A SIMULAÇÃO NÃO MEDE

Um simulador guloso não sente dopamina. A ausência de emoção no CSV não prova ausência de
emoção no jogador. Continuam sem resposta, e só playtest humano responde:

- o prazer de **ver** a cruz acontecer, com animação e som
- se o Tear subindo de semitom em semitom cria o crescendo prometido
- se 100 jogadas legais por turno **parecem** paralisantes na tela, mesmo sendo equivalentes
- se o jogador entende sozinho que às vezes deve recusar pontos
