# NOTAS DA SONDA — PLACARD

Protótipo headless **descartável** do núcleo, em GDScript, rodado em Godot 4.7.2 headless.
Não é o jogo. É um instrumento de medição.

Arquivos:
- `nucleo.gd` — avaliador de mãos (§5.1), geometria das 12 linhas vivas (R03/R03b).
- `mesa.gd` — grade, pilhas, posicionamento, colheita, cruz, Tear, R14b, R42, RNG próprio.
- `sonda.gd` — políticas e as 12 medições.
- `testes.gd` — 43 asserções (todas passam), incluindo a matemática do replay da §4.4 e a
  recomputação da curva de metas da §6.2 pela fórmula da R21.
- `metricas.json` — saída.

Rodar: `godot --headless --path . --script testes.gd` e `--script sonda.gd`.


## 0. Os números, em uma tela (política GULOSA, 2.000 mesas, núcleo sem loja)

| Medida | Valor | Leitura |
|---|---|---|
| m1 jogadas legais / turno | mediana **100** | a grade é larga |
| m2 resultados imediatos distintos / turno | mediana **1** | 85,9% dos turnos: as 100 jogadas dão o mesmo resultado (zero) |
| m2b turnos em que alguma jogada pontua | **14,1%** | 1 turno em 7 tem decisão de pontuação |
| m3 turnos entre recompensas | mediana **6** (p90 9, máx 15) | **24 s** entre recompensas (p90 36 s, máx 60 s) |
| m4 pontos por evento | mediana **236**, p90 425, máx 2.052 | fator de explosão **8,7×** |
| m5 gulosa = profunda | **58,8%** | nem resolvido, nem armadilha — profundidade real |
| m6 margem do topo | mediana **5,1%** (pontos) / 1,5% (score) | a 2ª melhor jogada quase empata |
| m7 vitória (núcleo sem loja) | global **11,0%**; R1 Pequena 58,9%; R5–R6 **0%** | ver ressalva D11 |
| m8 cruzes por mesa | **0,00** — 100% das mesas sem cruz | especialista dedicado: 0,14 e 86% sem |
| m9 maior seca por mesa | mediana **7** turnos (28 s), máx 14 | |
| m10 Tear ao fim da mesa | mediana **2**, máx **3** (teto da regra: 8) | o Tear nunca chega perto do teto |
| m11 turnos por mesa | mediana **17** | |
| m12 derrota já decidida aos 2/3 | **72,5%** das derrotas | o último terço é jogado já perdido |

Comparação entre políticas (vitória global / cruzes por mesa / eventos por mesa):
aleatória **0,0% / 0,06 / 1,1** · gulosa **11,0% / 0,00 / 2,3** ·
profunda **12,4% / 0,015 / 2,4** · caçadora-de-cruz **10,9% / 0,14 / 2,1**.

---

## 1. O que eu tive que decidir por conta própria (documento ambíguo)

**D01 — `real` (Sequência Real) = royal *flush*.**
A §5.2 lista a asserção "10-J-Q-K-Á é Sequência Real" sem falar de naipe. Mas o enum normativo
põe `real=9` **acima** de `seq_cor=8`. Se "Sequência Real" fosse qualquer 10-J-Q-K-Á, uma
sequência de naipes trocados (mult 10) valeria mais que um straight flush (mult 8), o que é
incoerente. Implementei REAL = straight flush terminado em Ás. **Impacto zero na prática:**
em 8.000+ mesas o avaliador nunca produziu REAL nem QUINA.

**D02 — a R14b não tem teto de mult.**
A fórmula da R14b é escrita sem `min(teto_do_evento, ...)`. A §5.1 diz que "não existe outro teto
no jogo", o que sugere que o teto se aplica; a R14b não o cita. Implementei **sem** teto.
Irrelevante: na colheita final `mult + Tear` nunca passou de ~20 e o teto mínimo é 28.

**D03 — "melhor categoria GARANTIDA com as cartas presentes" (R14b) com 3 ou 4 cartas.**
O documento não fecha isto. Flush, sequência, full e sequência de cor **exigem 5 cartas**, logo
não podem ser *garantidas* com 3 ou 4. Implementei só as categorias por valor:
ALTA / PAR / DOIS PARES / TRINCA / QUADRA. É a leitura conservadora e a que casa com a distinção
"garantida × alcançável" da §4.3. **Isto importa muito**: se a intenção era pagar "3 copas = FLUSH",
a colheita final vale bem mais do que eu medi, e essa é a rede de segurança central do jogo.
**Decida isso explicitamente antes de construir.**

**D04 — a parcela diagonal dentro da cruz (R15).**
"Só a parcela correspondente a ela sofre o piso de 60%" não define parcela. Implementei
`pontos = Σ_linhas ( fichas_da_linha × mult_efetivo_do_evento × (0,60 se diagonal) )`, com piso
por parcela. É a única leitura que devolve o valor da R12 quando há uma linha só.

**D05 — onde caem as 3 cartas semeadas da R42.**
O documento não diz. Sorteei casas vazias uniformemente pelo fluxo `semeadura`.

**D06 — política de descarte (e uma descoberta pelo caminho).**
A R08 dá 2/3/3 descartes mas nenhuma política. Minha primeira regra foi a óbvia — "troca quando
estou travado" — e ela **nunca disparou uma vez em 8.000 mesas**. O motivo é estrutural e vale
registrar: **no núcleo puro não existe estado de travamento.** Qualquer carta entra em qualquer
casa vazia, e uma linha fecha por ter 5 cartas, não por ter as cartas *certas*. Então sempre que
uma linha está em 4/5 alguma jogada pontua, e nunca há o momento "minha mão não serve".
O descarte no PLACARD não é um escape, é só **qualidade de mão** (trocar lixo por carta que
melhora a categoria da linha). Reescrevi a regra assim: troca quando nenhuma jogada pontua,
ainda restam ≥ 4 posicionamentos, e há ≥ 2 cartas "mortas" (rendem menos de 35% do que a melhor
carta da mão rende em potencial). O uso medido está em `extra_descartes_usados_por_mesa`.
**Consequência de design:** o descarte é o recurso mais fraco do núcleo, e a R19b
(descarte de emergência) protege contra um problema que o núcleo não tem.

**D07 — turno = 1 posicionamento.**
A R08 diz que descarte "não gasta posicionamento", então descarte acontece dentro do turno.
A conversão para segundos (4 s/turno) usa posicionamentos.

**D08 — gulosa conforme a ordem de serviço, não conforme a §7.4.**
A tarefa define GULOSA = maior ganho imediato, desempate por potencial da linha. A §7.4 define a
gulosa do jogo **com desconto de dano perpendicular (R17)**. Implementei a da tarefa.
O desempate por potencial usa peso convexo pelo progresso da linha
(`[0; 0,02; 0,08; 0,30; 0,75; 1,0]` para 0..5 cartas) vezes o valor projetado da linha se completar.
Sem esse peso convexo a gulosa fica burra (1,3 colheitas/mesa); com ele chega a ~2,2, que é o
teto prático (o teto duro é 3 — ver §2).

**D09 — a política PROFUNDA.**
Busca de 2 níveis: para os 8 melhores candidatos da gulosa, aplica a jogada e amostra 4 compras
possíveis da pilha `baralho+descarte`, medindo a melhor resposta imediata seguinte.
Valor = ganho imediato + 0,9 × média da melhor resposta.

**D10 — POLÍTICA EXTRA (não pedida, mas necessária): `cacadora_de_cruz`.**
Descobri que a gulosa faz **zero** cruzes em 2.000 mesas e a busca de 2 níveis faz **29 em
2.000** (1,5% das mesas). Não porque a cruz seja rara, mas porque ela exige **recusar
pontos agora** por 2–4 turnos, o que uma busca de 2 níveis não enxerga. Para saber se o clímax
prometido é alcançável **por alguém**, escrevi uma quarta política que proíbe fechar uma linha
sozinha quando a perpendicular daquela casa ainda dá para armar dentro do orçamento.
Ela é o *melhor caso*, um jogador especialista que joga para a cruz. Use os números dela como
**limite superior**, não como jogo típico.

**D11 — fora de escopo (por ordem da tarefa).**
Sem loja, sem selos, sem relíquias, sem modificadores, sem níveis de mão, sem chefes, sem vidas,
sem Fiança, sem Estufa, sem Tabuleiro. **As taxas de vitória das rodadas 4–6 são, por isso,
pessimistas por construção** e não devem ser lidas como defeito: a própria §6.2 prova a rodada 6
usando Full House nível 3 e Sequência de Cor nível 2, que são compras de loja. Incluí um cenário
`cenario_proxy_de_poder` (todas as categorias com nível = min(3, rodada−1)) só para mostrar quanto
do buraco vem da progressão ausente. É uma aproximação grosseira, **não** o jogo do documento.
Medido: vitória 34% / 36% / 33% / 27% / 13% / **2,8%** nas rodadas 1 a 6. Ou seja, mesmo dando de
graça 3 níveis em **todas** as onze categorias — bem mais poder do que a §6.2 assume — a rodada 6
continua praticamente invencível. **O buraco da rodada 6 não é só falta de loja.** Ou os selos e
relíquias carregam quase toda a escalada de 13,3×, ou a base 1,42 da R21 é agressiva demais.

---

## 2. Regras que se mostraram impossíveis ou contraditórias ao implementar

Estas não são opinião. São aritmética das próprias regras.

**C01 — o orçamento de animação da §6.1 é aritmeticamente impossível.**
A §6.1 orça, por mesa Pequena, "3 colheitas × 1,34 s + **1,5 cruzes** × 2,62 s".
Mas: uma Pequena vê **18 cartas na vida inteira** (15 posicionamentos da R09 + 3 semeadas da R42);
toda carta colhida vai para a pilha `colhida` e **nunca volta** (R04b). Uma colheita simples
consome 5 cartas; uma cruz de 2 linhas consome 9 (a casa do cruzamento é compartilhada).
`3×5 + 1,5×9 = 28,5 cartas` — contra 18 disponíveis. **Falta 58% de material.**
O mesmo vale para Grande (17 cartas para 4×5 + 2×9 = 38) e Chefe (19 para 5×5 + 2,5×9 = 47,5).
Consequência: os alvos de duração de mesa da §6.1 foram calculados sobre um jogo que essas
regras não produzem.

**C02 — a banda 2 da §7.4 ("mediana de cruzes por mesa 1,5–2,5") é impossível.**
Teto teórico de cruzes por mesa, com jogo perfeito e zero desperdício:
Pequena **2** (18 cartas = exatamente 9+9), Grande **1** (17 < 18), Chefe **2** (19).
Uma *mediana* de 1,5–2,5 exige que a mesa mediana empate com o máximo teórico em toda mesa.
Na Grande a banda é matematicamente inatingível. Medido: a política especialista chega a
~0,3 cruz/mesa e as políticas normais a **0,00**.

**C03 — teto duro de 3 eventos de pontuação por mesa.**
Todo evento consome no mínimo 5 cartas que somem para sempre. Com 18/17/19 cartas por mesa,
o número máximo de **eventos de pontuação em uma mesa inteira é 3**. Não é balanceamento; é
conservação. Uma mesa dura 15–19 turnos (60–80 s a 4 s/turno). Logo o intervalo **mínimo**
entre recompensas é de 5 turnos ≈ **20 segundos**, e o típico medido é o dobro disso.

**C04 — a R19b (anti-mão-morta) é código morto no núcleo.**
Qualquer carta entra em qualquer casa vazia (R07), e o orçamento (15–19) é sempre menor que as
25 casas, então **sempre** existe casa vazia e **sempre** existe jogada legal. A R19b só pode
disparar com casas lacradas por modificador. O teste `_nunca_mao_morta` não consegue falhar
pelo núcleo — ele testa modificadores, não a regra.

**C05 — a R43 (cascata) nunca dispara no núcleo.**
As três fontes declaradas (empurrão/Esteira, preenchimento/Semear-Muda, valor-naipe efetivo/
Espelho-Ímã) são todas itens. Sem itens, cascata = 0.

**C06 — a QUINA é inalcançável e a REAL é praticamente inalcançável no núcleo.**
Quina precisa de Espelho ou Sósia (a própria §5.1 admite). Em 8.000+ mesas simuladas o avaliador
nunca devolveu REAL. Duas das onze linhas da tabela de mãos são decoração no jogo base.

**C07 — invariante do replay da §4.4 não vale para mesas Pequenas.**
`posicionamentos usados − 5 × linhas colhidas = cartas na grade` só fecha porque o replay é um
Chefe. Numa Pequena o termo `+3` da semeadura (R42) precisa entrar. Corrija antes de virar teste.

**C08 — o teto do mult (R15) quase nunca morde no núcleo.**
O teto é `24 + 4×rodada` (28 a 48). Sem selos e sem níveis de mão, a soma de mults de um evento
raramente passa de 15. A banda 11 da §7.4 ("o teto morde em ≤ 8% dos eventos") passa trivialmente
com 0% — e portanto **não mede nada** até a loja existir. Não é contradição, é uma banda que só
começa a valer no jogo completo.

---

## 3. Minha impressão honesta, como quem acabou de implementar o núcleo

**O jogo é bom. Ele não é o que foi pedido.**

Implementando isto, a sensação foi de estar construindo um **quebra-cabeça de território** muito
elegante, não uma máquina de dopamina. E dá para apontar exatamente onde a diferença mora.

Três coisas ficaram evidentes na escrita do código, antes mesmo de medir:

1. **A pontuação é rara por construção, e isso é estrutural, não ajustável por número.**
   Em Balatro você joga uma mão e ela pontua — sempre, toda vez, 100% das ações. Aqui você
   coloca uma carta e, na esmagadora maioria dos turnos, **nada acontece**. Você está enchendo
   uma linha. A recompensa vem no 5º tijolo. O núcleo do PLACARD tem uma razão de
   ação-para-recompensa medida de **1 recompensa a cada 6 ações** (mediana; p90 = 9 ações,
   pior caso 15), com teto duro de 3 recompensas por mesa e apenas **14% dos turnos** oferecendo
   sequer a possibilidade de pontuar. Isso não é um problema de tuning: vem direto da conservação de
   cartas (R04b + R09 + R11). Para mudar isso é preciso mudar a *regra*, não a tabela.

2. **A cruz — o clímax prometido — exige a habilidade mais avançada do jogo: recusar pontos.**
   Foi a coisa mais surpreendente de implementar. Escrevi a gulosa, escrevi a profunda de dois
   níveis, e a gulosa fez **zero cruzes em 2.000 mesas** (100% das mesas sem clímax) enquanto a
   profunda fez 29 em 2.000 (1,5% das mesas). Não por azar: fechar
   a linha assim que ela chega a 4/5 é sempre o movimento localmente correto, e a cruz exige
   deixar uma linha em 4/5 parada por 2 a 4 turnos enquanto você constrói a perpendicular —
   arriscando o orçamento inteiro. Escrevi então uma política *dedicada* a caçar cruz — ela
   chega a 0,14 por mesa e **86% das mesas dela ainda terminam sem nenhuma**, e ela nunca fez duas
   na mesma mesa. Um jogador novo **nunca** vai ver uma cruz por acidente.
   Ou seja: o momento que a §4.1 promete nos "10 primeiros segundos" é, na verdade, conteúdo de
   nível intermediário. Isso é profundidade — é ótimo para um jogo de estratégia — mas é o
   oposto de "dopamina infinita".

3. **É simples de entender e não é simples de jogar bem.** A regra cabe numa frase e eu a
   implementei sem dúvida nenhuma sobre o que ela quer dizer. Mas a *decisão* de cada turno é
   pesada: 85 casas legais, o custo espacial da R17 (pontuar arranca carta de 5 linhas), e o
   fato de que a jogada óbvia diverge da jogada certa em **41% dos turnos** (m5 = 58,8% de
   concordância entre a gulosa e a busca profunda — o número mais saudável da auditoria inteira,
   e a melhor notícia do documento). Isso é
   xadrez-com-cartas, não caça-níquel. "Sem tutorial longo" ✔. "Ultra simples de jogar" ✘.

O que o jogo *tem* de viciante é real, mas é de outra família: é o vício de **otimização e
descoberta de build** (o mesmo do Into the Breach ou do Slay the Spire), não o de **retorno
variável em alta frequência** (o do Balatro, do Vampire Survivors, das slot machines).
São dois motores diferentes. O documento construiu o primeiro com muito cuidado e escreveu
na capa o nome do segundo.

**A parte frustrante que eu vi de perto:** a mesa mediana termina em **43% da meta** e o jogador
descobre que perdeu **muito antes de o jogo acabar** — em **72,5% das derrotas** a meta já estava
fora de alcance realista no marco de 2/3 dos turnos. O jogador passa o último terço de cada mesa
perdida colocando cartas sem propósito. A R41 ("a meta saiu do alcance, agora é pelo recorde")
existe exatamente para isso e é, na minha leitura, a regra mais importante do documento inteiro
para o objetivo (c) "não frustrante". Ela precisa disparar cedo e ser generosa. (Ressalva
importante: as taxas de vitória aqui são do núcleo **sem loja**; o buraco absoluto encolhe com
progressão. A *forma* do problema — saber cedo que perdeu — não.)

**Se o objetivo (b) "dopamina infinita" for inegociável, a mudança não é de número, é de regra.**
As alavancas que eu vi de dentro do código, na ordem em que mudariam mais o ritmo:

- **Pagar linhas parciais durante a mesa, não só no fim.** Hoje a R14b (metade do valor para
  linhas com 3+) só roda no fim, e paga mediana 106 pontos — menos que **um** evento normal (236).
  Rodá-la também *durante* — um "pulso" pequeno toda vez que uma linha chega a 3/5 e a 4/5 —
  atacaria diretamente os **85,9% de turnos em que nenhuma das 100 jogadas produz resultado
  diferente de zero**. É a mudança de maior impacto e menor custo.
- **Devolver ao baralho as cartas colhidas** (ou parte delas). Hoje a pilha `colhida` nunca volta,
  e é ela que impõe o teto de 3 eventos. Devolvendo, o teto some.
- **Arrumar o Tear.** Ele tem teto 8 na regra e **na prática termina em 2 (máximo observado: 3)**,
  porque só sobe 1 por linha colhida e só cabem ~3 colheitas na mesa. O único número que "sobe a
  mesa inteira" sobe duas vezes e para. Ou ele sobe mais rápido, ou o teto 8 é ficção.
- **Mesas menores e mais numerosas.** 3 mesas de 8 posicionamentos batem melhor que 1 de 19:
  mais fins-de-mesa, mais colheitas finais, mais pagamentos.
- **Fazer a cruz acontecer sozinha para o novato**, por exemplo dando um bônus explícito por
  esperar (um selo de tutorial, ou um "aviso de cruz armada" que segure a linha por 1 turno),
  em vez de esperar que ele descubra que recusar pontos é bom.

Nada disso é urgente se o jogo aceitar ser o que ele é. **Ele é muito bom no que é.** Mas o Joab
pediu uma máquina de dopamina, e o que está no documento é um quebra-cabeça de território
excelente e exigente. Vale ele escolher — com os números na mão — qual dos dois quer construir,
porque as duas coisas puxam o design para lados opostos.

---

## 4. Confiabilidade dos números

- 2.000 mesas por política (gulosa, aleatória, profunda, caçadora), cobrindo as 6 rodadas × 3
  tipos de mesa, com sementes distintas por política e por mesa. m5 medido em 500 mesas por
  trajetória (a busca profunda é cara).
- RNG próprio (xorshift64*), determinístico e semeado — nada de `randi()` global.
- Nenhum número neste relatório foi estimado. Os únicos `null` do JSON são amostras de tamanho
  zero, e são informativos: `gulosa/m4_magnitude/eventos_cruz` é `null` **porque a política
  gulosa não fez nenhuma cruz em 2.000 mesas**, e `aleatoria/m6_margem_do_topo` é `null` porque
  a política aleatória não ordena jogadas (não há "melhor" nem "segunda melhor" para comparar).
- **A maior incerteza não é estatística, é de leitura da regra: a decisão D03** (o que conta como
  categoria "garantida" numa linha de 3–4 cartas). Ela move sozinha o valor da colheita final,
  que é a rede de segurança do jogo inteiro.
