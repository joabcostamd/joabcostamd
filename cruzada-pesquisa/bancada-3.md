# BANCADA 3 — ESCALADA / TETOS / VARIEDADE
## PROPOSTA 5: O TEAR MULTIPLICA E A ESTRELA

Godot 4.7.2 headless, GDScript. Tudo medido, nada estimado. Sementes idênticas em
todas as células (`31337 + t*7919`) — varredura pareada.
Volume: **1.002 mesas/célula** na política gulosa e caçadora; **402 mesas/célula**
na m5 (gulosa × profunda) e na profunda — **redução registrada** (a busca de 2 níveis
custa ~8× a gulosa; a sonda original também usou 500 para m5). 1.200 chefes na política
Estrela dedicada.

---

## 0. ANTES DE QUALQUER VARIANTE: A LINHA DE BASE DO BRIEFING NÃO FECHA

Reproduzi o núcleo cru primeiro. Ele bate com a auditoria:
turnos com recompensa 14,3% (auditoria 14,1%), seca mediana 7 (7), Tear mediano 2 (2),
razão 0,445 (0,44), vitória 9,8% (11%). **O instrumento está calibrado.**

Aí rodei a linha de base pedida — PULSO 0,35 + TIQUE 4 juntos — e ela **não produz os
números do briefing**. Fui atrás do porquê no `experimento.json` da própria sonda:

| número do briefing | de onde ele realmente vem |
|---|---|
| 65,1% turnos com recompensa | `v1` = **PULSO sozinho** (Tear mediano 2, razão 0,598) |
| vitória 21,8% | `v1` = **PULSO sozinho** |
| Tear mediano 8 | `v2` = **TIQUE sozinho, período 3** (não 4) |
| razão 0,79 | `v2` = **TIQUE sozinho** (vitória 28,3%) |

**A combinação PULSO 0,35 + TIQUE 4 nunca foi rodada.** Eu rodei. Ela é super-aditiva:

| | briefing | medido de verdade (K=1,00) |
|---|---|---|
| turnos com recompensa | 65,1% | **65,9%** ✔ |
| turnos entre recompensas / seca / seca p90 | 1 / 2 / 4 | **1 / 2 / 4** ✔ |
| Tear mediano | 8 | **6** ✘ (tique a cada 4 dá 6; o Tear 8 exige tique a cada **3**) |
| razão pontos/meta | 0,79 | **0,991** ✘ |
| vitória global | 21,8% | **41,1%** ✘ |
| m5 | 58,8% | **56,1%** (na banda) |

Ou seja: **a linha de base já aprovada entrega o jogo quase resolvido** (41% de vitória
global, mesa mediana chegando à meta) e precisa de recalibração de meta antes de qualquer
outra coisa. Varri K na própria base: **K=1,25 devolve razão 0,793 e vitória 28,8%**.
É esta a âncora contra a qual medi tudo — comparar variante contra base errada não vale nada.

---

## 1. TABELA PRINCIPAL — base × produto, **na mesma dificuldade**

BASE = soma de mults, Tear como parcela, teto do evento ligado, K=1,25.
PRODUTO = mults multiplicam, Tear como fator, TEAR_INICIAL=1, ganho_tear=+1,
TEAR_TETO=8, FATOR_PISO=1, piso diagonal 0,60, **teto do evento removido**, K=2,25.

| métrica | BASE (soma) | PRODUTO | leitura |
|---|---|---|---|
| **GUARDA m5 gulosa×profunda** | **55,9%** | **58,7%** | ambas na banda [45,75]; **sem inversão de obviedade** |
| turnos com recompensa | 65,7% | 64,8% | igual |
| turnos entre recompensas / seca / p90 | 1 / 2 / 4 | 1 / 2 / 4 | igual |
| eventos por mesa | 2,39 | 2,22 | igual |
| **cruzadas/mesa (gulosa)** | **0,0000** | **0,0000** | **não mudou nada** |
| % mesas com zero cruzada | 100% | 100% | **não mudou nada** |
| cruzadas/mesa (profunda) | 0,0274 | 0,0174 | **piorou** |
| cruzadas/mesa (caçadora) | 0,0978 | 0,1457 | +49% |
| distribuição de n | n1=100% | n1=100% | **critério (b) da própria proposta: falhou** |
| cascatas/mesa · maior cadeia | 0 · 0 | 0 · 0 | ausência estrutural (é a Proposta 4) |
| pontos/mesa mediana | 1.436 | 2.533 | |
| razão pontos/meta | 0,793 | 0,770 | pareado ✔ |
| vitória global | 28,8% | 28,0% | pareado ✔ |
| vitória R1→R6 | 89/54/24/5/1/0 | 76/55/27/8/2/**0,6** | R1 menos trivial, R6 deixa de ser 0 |
| Tear mediano / máx | 6 / 7 | 7 / 8 | |
| % mesas que encostam no TEAR_TETO | 0% | **21,2%** | alvo 15–35% ✔ |
| **maior evento único** | **2.394** | **10.260** | **×4,3 — o teto emocional** |
| **razão pico/mediana (fator explosão)** | **7,2×** | **15,8×** | **×2,2** |
| pico de mesa vencida / meta p50·p90·p99·máx | 0,52·0,92·1,82·2,23 | 0,69·1,46·2,36·**4,19** | alvo era p99≥100× |
| derrota decidida aos 2/3 | 69,9% | **56,6%** | melhorou 13 pontos |

---

## 2. AS VARREDURAS (todas com m5 medida; **nenhuma célula saiu da banda**)

**ETAPA 1 — K.** 2,00→0,866 · 2,25→**0,770** · 2,50→0,693 · 2,75→0,630 · 3,00→0,577.
K=2,25 é o único que pareia com a base recalibrada (0,793 / 28,8%).

**ETAPA 2 — ganho de Tear por linha colhida.** +1 → razão 0,770 / vit 28,0 / m5 58,65.
+2 → 0,899 / 34,0 / 58,67. +3 → 0,980 / 38,3 / 58,59. **m5 não se move (±0,08 pt).**
O dial "principal contra a inversão de obviedade" **não tem efeito nenhum sobre a m5**,
porque a gulosa nunca espera de qualquer maneira. Fica **+1** (é o único que não infla).

**ETAPA 3 — TEAR_TETO.** 6 → morde em **92,1%** (parede). 8 → **21,2%** (alvo 15–35% ✔).
10, 12, 16, sem teto → **0%** — o Tear nunca passa de 8 com tique 4, então qualquer teto
acima de 8 é ficção, exatamente o erro que a proposta queria remover. **TEAR_TETO = 8.**

**ETAPA 4 — FATOR_PISO.** Sob a gulosa não muda o pico (n=1 sempre). Na Estrela:
piso 1 → produto p10=8, p50=24, p90=64; piso 2 → p10=**24**, p50=32, p90=72, e o pagamento
mediano da Estrela sobe de 4,64× para 6,93× a meta. **Mas o anticlímax não é resolvido por
nenhum dos dois: 99,1% das Estrelas contêm uma mão de mult ≤ 2** (piso 2 → 99,2%).
O anticlímax não é a Carta Alta, é o Par: encher 17 casas por geometria produz Par e Dois
Pares, e o piso não sobe mult 2.

**ETAPA 5 — piso da diagonal.** 0,6 → razão 0,770 / rec 64,8% / seca 2. 0,7 → seca **3**,
rec 63,1%. 0,8 → seca 3, rec 62,2%. 1,0 → seca 3, rec **61,2%** (abaixo do piso de 65%).
Subir a diagonal **quebra a regressão do PULSO**. Na Estrela, 1,00 paga 5,80× contra 4,64×
(só +25%): a diagonal a 0,60 **não** está taxando a fantasia. **Fica 0,60.**
(Fração de eventos n≥3 com diagonal: 100% — por construção a Estrela é feita de diagonais.)

**ETAPA 6 — expoente.** 1,00 → 0,770/28,0. 0,85 → 0,683/23,6. 0,75 → 0,641/20,4. Amortecer
só aperta a dificuldade e corta o pico (maior evento 10.260 → 7.263 → 5.769). **Não acionar.**

**Período do TIQUE.** 3 → razão 0,928, Tear 8. 4 → 0,770, Tear 7. 5 → 0,667, Tear 6.
Com o Tear virando fator, o tique é o dial de dificuldade mais forte que existe. **4 fica.**

---

## 3. O NÚMERO QUE O PAINEL PEDIU: O TETO EMOCIONAL

Maior evento único, por política, com e sem o teto `24+4×rodada` (K=2,25, pareado):

| política | soma (base) | produto, teto LIGADO | produto, teto REMOVIDO | % eventos em que o teto morde |
|---|---|---|---|---|
| gulosa | 2.394 | 8.208 | **10.260** | 1,28% |
| caçadora de cruzada | 3.066 | 9.936 | **24.840** | 2,67% |
| Estrela dedicada (pico/meta) | 6,9× | 3,29× | **121,19×** | **92,58%** |

**Esta é a leitura mais importante da bancada.** Remover o teto do evento é irrelevante para
o jogo como ele é jogado hoje (morde 1,3% — **abaixo dos 8%, logo remover não era
"obrigatório"**) e é **totalmente determinante** para o jogo que a proposta quer criar: com o
teto ligado, a Estrela paga 3,3× a meta e o clímax é decapitado; sem ele, 121×.
O teto não é código morto — é uma tampa em cima do único momento que a proposta promete.

---

## 4. O GATE DA ESTRELA (ETAPA 0)

Com política dedicada de horizonte longo em 1.200 Chefes: **100% das Estrelas fecham.**
Abortadas pela R19: **null — a R19 não existe na sonda, não medi o que não está implementado.**
Abortadas pela R42: **0** — a semeadura só roda em mesa Pequena, e a Estrela (17 cartas)
não cabe numa Pequena (15 posicionamentos), só em Chefe (19).
Parar-na-meta ligado ou desligado: **idêntico** (a Estrela não pontua nada até a 17ª carta).

| | soma | produto |
|---|---|---|
| pagamento da Estrela / meta — p50 · p90 · máx | 1,05 · 2,56 · 6,90 | **4,64 · 17,37 · 121,19** |
| PRODUTO dos 4 mults — p10 · p50 · p90 · máx | — | 8 · **24** · 64 · **288** |
| vitória do Chefe com a política Estrela | 63,4% | 93,3% |

**A "PRODUTO ~1.120" da proposta é 47× otimista.** O produto mediano real é 24.

E o número que decide: **em 1.002 mesas gulosas, 402 profundas e 1.002 caçadoras não houve
uma única Estrela (n=4) nem uma única tripla (n=3).** A Estrela existe apenas para uma
política escrita de propósito para fabricá-la. Frequência alvo era 1 em 40 a 1 em 200 Chefes;
o medido em jogo natural é **0 em 1.002**, e 1 em 1 com política dedicada. Não há um regime
intermediário.

---

## 5. O QUE **NÃO** FUNCIONOU — e é o achado central

**A tese econômica da Proposta 5 está errada.** Ela afirma: "a cruzada não acontece porque
é um mau negócio; a gulosa está certa em recusá-la; corrija o preço e ela passará a caçá-la".

Medido, na mesma semente, com o preço da cruzada multiplicado por 4 a 100×:

| política | base | produto | veredito |
|---|---|---|---|
| **gulosa** | **0,0000** | **0,0000** | não mudou **nada** |
| profunda (2 níveis) | 0,0274 | 0,0174 | piorou |
| caçadora dedicada | 0,0978 | 0,1457 | +49%, longe do alvo 0,30 |

O critério pré-declarado do guardião era explícito: *"se a gulosa continuar em 0,00 com o
produto ligado, a tese está errada e o problema é comportamental, não econômico."*
**A gulosa continuou em 0,0000, com 100% das mesas sem cruzada.**

O motivo é estrutural e não se conserta com número: a gulosa não recusa a cruzada por achá-la
cara — ela **nunca a vê**. Fechar uma linha em 4/5 é sempre a jogada de maior ganho imediato,
então duas linhas nunca ficam simultaneamente em 4/5 compartilhando uma casa vazia. O preço
da cruzada é irrelevante para quem nunca chega ao ponto de decidir sobre ele. Multiplicar
os mults reprecifica um evento que **não ocorre**.

Corolário duro: **o critério (b) da própria proposta reprova a proposta.** "Se n=1 ficar acima
de 95%, o produto NÃO mudou o comportamento e a proposta falhou." Medido: **n=1 = 100,00%**.
E o critério (c), o do print: "se o p99 do maior evento não passar de 20× a meta, não existe
fantasia e só trocamos aritmética." Medido: **p99 = 2,36×**, máximo 4,19×.

Também não funcionou: o **dial anti-inversão** (ganho de Tear +1/+2/+3 move a m5 em 0,08 ponto —
ele não protege contra nada porque não havia risco de inversão a proteger), e o **amortecimento
por expoente** (só encolhe o pico).

---

## 6. O QUE SURPREENDEU

1. **A m5 é insensível ao produto.** Eu esperava movimento em alguma direção, e a proposta
   declarava "risco número um" a inversão para >75%. Todas as 26 células ficaram entre
   **58,6% e 59,7%** — variação menor que o ruído entre base e base recalibrada. O produto
   não adiciona **nem remove** profundidade; ele só reprecifica.
2. **O teto do Tear finalmente morde.** Na base ele nunca é atingido (0%). Com o Tear como
   fator, 21,2% das mesas terminam encostadas no 8. Pela primeira vez em toda a auditoria um
   teto declarado no documento é um teto real, dentro da banda 15–35%.
3. **O produto conserta o pior número de ritmo sem tentar.** "Derrota já decidida aos 2/3"
   cai de 69,9% para 56,6%, porque um Tear alto no fim da mesa mantém eventos tardios capazes
   de virar o placar. Nenhuma outra alavanca desta bancada tocou nesse número.
4. **A rodada 6 deixa de ser 0.** 0,0% → 0,6%. Simbólico, mas é a primeira vez que a sonda
   registra vitória na rodada 6 sem proxy de poder.
5. **O anticlímax é a regra, não a exceção:** 99,1% das Estrelas contêm uma mão de mult ≤ 2.
   A proposta tratava isso como um risco ocasional ("na terceira vez é desinstalar"). É toda vez.

---

## 7. RECOMENDAÇÃO

**Aprovar E1+E2+E3 (Tear como fator, produto dos mults, remoção do teto do evento) —
e REPROVAR a promessa que os acompanha.** Não é aprovar por metade: é aprovar o que foi
medido e recusar o que não foi entregue.

Configuração recomendada, se for adiante:
`TEAR_INICIAL=1 · TEAR_TETO=8 · ganho_tear=+1 · FATOR_PISO=1 · piso_diagonal=0,60 ·
expoente=1,00 · TIQUE=4 · teto_do_evento REMOVIDO · K=2,25`
(e, o que vale mais que tudo isso: **K da linha de base = 1,25**, com ou sem o produto).

**Por quê aprovar:** com a dificuldade pareada, ela é **estritamente melhor ou igual** em toda
métrica de guarda — m5 na banda, ritmo intacto (65% de turnos com recompensa, seca 2), razão e
vitória idênticas — e entrega três ganhos reais: o maior evento sobe **4,3×** (2.394 → 10.260),
o fator explosão sobe **2,2×** (7,2× → 15,8×), o Tear vira um número que significa alguma coisa
(teto morde 21%), e a derrota-decidida-cedo cai 13 pontos. O código **encolhe**. É barato.

**Por quê reprovar a promessa:** a proposta foi vendida como o conserto da cruzada e como a
fantasia de quebrar o jogo. Ela não é nenhum dos dois. Cruzada gulosa: 0,00 antes, 0,00 depois.
p99 do print: 2,36× contra os 100× prometidos. **O produto é um amplificador sem sinal para
amplificar.** Ele multiplica um evento que ninguém produz.

**Consequência para o painel, e é a leitura que eu levaria adiante:** a ordem de execução
mandava rodar a Proposta 5 primeiro porque ela "recalibra a curva e contamina a base das
outras". Ela contamina, sim — mas o resultado inverte a prioridade. O produto **só paga** se
alguma outra coisa fizer a cruzada existir. As duas propostas que **fabricam** o evento
(o PRUMO, que entrega cruzada de pouso sem custo de posicionamento, e o AVESSO, que dobra os
outs) passam a ser pré-requisito, não alternativa. A fusão PRUMO × PRODUTO que o júri de
dopamina guardou para o Lote 2 **é o Lote 1**: o produto sozinho é aritmética à espera de um
motivo, e o Prumo sozinho paga em soma, que é uma reta curta.

Se for preciso escolher **uma** coisa desta bancada para implementar amanhã, não é o produto:
é **K = 1,25 na curva de metas**, porque a linha de base aprovada, como está escrita, entrega
41% de vitória global e razão 0,99 — o jogo já está resolvido antes de qualquer variante entrar.

---

## 8. RESSALVAS HONESTAS

- **"Abortada pela R19" é `null`**: a R19 não existe na sonda. Não é medição ruim, é medição
  ausente — e a R19 é justamente a regra que a proposta apontava como capaz de demolir a
  Estrela. **Isso precisa ser medido no jogo real antes de qualquer decisão sobre a Estrela.**
- **A m5 é medida contra a política PROFUNDA de 2 níveis da sonda.** A Estrela exige horizonte
  17; nenhuma das duas políticas a enxerga. A m5 é uma guarda válida contra "o jogo se resolve
  sozinho", mas ela **não** consegue detectar profundidade de longo horizonte — se a Estrela
  fosse um alvo real, a m5 dos 58,7% estaria subestimando a profundidade adicionada.
- **"Maior evento de uma RUN vencida" foi medido como "de uma MESA vencida"** — a sonda simula
  mesas isoladas, não runs encadeadas com loja.
- **Sem loja, sem selos, sem níveis de mão.** Com níveis de mão o produto explode de forma
  não medida aqui (mult² por linha), e o risco 3 da proposta (rodadas 5–6 virando passeio)
  continua **não testado**.
- R14b e PULSO sob produto tiveram de ser traduzidos por mim (`fichas × mult × Tear × 0,50` e
  `× 0,35`); a especificação não diz o que fazer com eles. Está registrado no `resultado.json`.
