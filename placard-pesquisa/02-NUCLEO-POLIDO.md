# PLACARD — O NÚCLEO POLIDO

Tudo aqui tem número medido atrás. Fonte: bancadas 1, 2 e 3 (Godot 4.7.2 headless,
1.002 a 2.000 mesas por célula, sementes pareadas). Li os três `resultado.json` na fonte,
não os resumos.

**Aviso que precede tudo: a linha de base do briefing não existe.** As três bancadas, sozinhas,
acharam a mesma coisa: "65% de recompensa + 21,8% de vitória" vem da variante **só PULSO**;
"Tear 8 + razão 0,79" vem da variante **só TIQUE, com período 3**. As duas juntas nunca tinham
sido rodadas. Rodadas agora: **razão 0,990 · 0,944 · 0,991** (b1/b2/b3) e **vitória 40,75% ·
39,9% · 41,1%** — a rodada 1 vence 96,5% das vezes. **O jogo já está praticamente resolvido
antes de qualquer item entrar.** A primeira coisa a implementar é **K = 1,25 na curva de
metas** (devolve razão 0,793 e vitória 28,8%).

---

## 1. O NÚCLEO EM UMA PÁGINA

**Cada carta pontua em duas mãos de pôquer: a linha e a coluna onde você a colocar.**

1. Grade 5×5. Você tem 5 cartas na mão, coloca **uma** carta numa casa vazia por turno e
   compra de volta até 5. A carta fica ali.
2. Linha, coluna e as duas diagonais são mãos de pôquer. As diagonais pagam 60%
   (subir esse piso quebra o ritmo: seca mediana 2 → 3, recompensa 64,8% → 61,2%).
3. **Linha com 5 cartas é colhida na hora**: pontua e as 5 cartas somem do tabuleiro para
   sempre.
4. **PULSO**: uma linha paga um troco ao chegar em 3/5 e em 4/5, sem gastar carta nem turno
   (turnos com recompensa 14,3% → 65,7%; seca mediana 7 → 2).
5. **TEAR**: um número que sobe +1 a cada colheita e +1 a cada 4 cartas colocadas, teto 8,
   e **multiplica** o evento inteiro (Tear mediano 6 → 7; encosta no teto em 21,2% das mesas).
6. Se a mesma carta fecha mais de uma linha, **os multiplicadores das mãos se multiplicam
   entre si**. Isso é a CRUZ.
7. Toda colheita prensa as duas cartas de maior valor daquela linha num **AVESSO** — uma
   carta de duas caras — que volta para o topo do baralho (chega à mão no turno seguinte:
   espera mediana **1 turno**).
8. Um Avesso mostra uma cara na linha e a outra na coluna e nas diagonais. Na mão, um toque
   gira e troca as caras. Ao ser colocado, congela.
9. Você tem 15/17/19 posicionamentos, 2–3 descartes e uma meta por mesa.
10. Entre mesas, loja.

Dez regras. A décima primeira não existe de propósito.

---

## 2. O SISTEMA DE CORINGAS — a resposta direta

Foram medidos dois desenhos de coringa lado a lado, mesmas sementes, 1.200 mesas por célula.
**Entra o AVESSO. Sai a AGULHA (o coringa clássico, "vira qualquer carta").**

**Como o coringa entra:** ele não é comprado na loja e não existe no turno 1. Ele é
**fabricado pela sua própria colheita** (regra 7). Medido: **1,66 Avessos por mesa**
(alvo 1,0–2,5), **10,8% dos posicionamentos** (alvo 8–18%), espera forja→uso de **1 turno**
(alvo 1–3). O gatilho tem de ser *toda colheita*: exigir Trinca+ derruba para 0,97/mesa e
exigir Flush+ derruba para 0,42/mesa (2,7% dos posicionamentos — vira decoração).

**Que decisão ele cria:** não "o que esta carta é?", e sim **"esta carta é boa para quem?"**.
Você olha os dois números impressos lado a lado e escolhe qual eixo alimentar. É a única
pergunta que só existe porque a frase única já diz que a carta pertence a duas mãos.

**O número que prova que funciona — e é o único número positivo de toda a bancada de coringas:**
o mapa de calor. Com Avesso na mão, **C3 recebe 28,6% dos posicionamentos** contra ~4,0% de
uma escolha uniforme entre 25 casas — **7 vezes**. Entropia do mapa **0,827** (longe da
uniformidade, e nenhuma casa passa de 30%: não degenerou). A AGULHA, no mesmo teste, põe o
coringa em C3 em **4,2%** — indistinguível de aleatório (entropia 0,955).
**A pergunta "qual é a casa certa para um coringa?" só tem resposta com o Avesso.**

**E ele cabe no orçamento.** Pontos vindos de linhas com Avesso: **37,8%** (teto duro 45%).
A Agulha: **61,1%** — o item virou o jogo. Razão pontos/meta na base recalibrada: Avesso
**0,849**, Agulha **1,009** (estoura o teto de 1,0 sozinha). Zero regressão do Pulso:
recompensa 66,1%, seca 2/4 — idênticas à base.

**Ressalva que não vou esconder:** o Avesso vale só **+1,4 a +2,25 pontos percentuais** de
vitória — é **decisão, não poder**. E a condição de corte dele (as duas caras legíveis em
84×92 px em retrato) está **`null`**: a bancada é headless. Prototipar o `_draw` antes da
primeira linha de regra; se não couber legível, entra a Agulha única por mesa (vitória
42,58%, razão 0,985), que é pior e é segura.

---

## 3. O MOTOR DE DOPAMINA — o que entrou, com a tabela

| mudança | métrica | antes | depois |
|---|---|---|---|
| **PULSO** (fator 0,35 em 3/5 e 4/5) | turnos com recompensa | 14,3% | **65,7%** |
| | seca mediana / p90 | 7 / 9 | **2 / 4** |
| **TIQUE DO TEAR** (+1 a cada 4) | Tear mediano | 2 | **6** |
| | razão pontos/meta | 0,442 | 0,990 |
| **K = 1,25 na meta** (correção) | razão pontos/meta | 0,990 | **0,793** |
| | vitória global | 40,75% | **28,8%** |
| **TEAR MULTIPLICA** (E1+E2+E3) | maior evento único | 2.394 | **10.260** (×4,3) |
| | pico/mediana (explosão) | 7,2× | **15,8×** (×2,2) |
| | mesas que encostam no teto do Tear | 0% | **21,2%** |
| | derrota já decidida aos 2/3 | 69,9% | **56,6%** |
| | m5 (guarda) | 55,9% | **58,7%** |
| **AVESSO** (dobra + giro) | Avesso em C3 | — | **28,6%** (uniforme: 4,0%) |
| | pontos via coringa | — | 37,8% (teto 45%) |
| | vitória | 29,17% | **31,42%** |

Duas leituras honestas:

**(a)** O TEAR MULTIPLICA foi medido **na mesma dificuldade** (razão 0,793 × 0,770; vitória
28,84% × 28,04%). Não é buff: é o mesmo jogo com teto emocional 4,3× maior e **menos código**
(o teto do evento `24+4×rodada` sai; ele mordia 0% e era matemática escondida).

**(b)** **AVESSO e PRODUTO nunca foram medidos juntos.** As bancadas rodaram em paralelo,
cada uma sobre a base aditiva. A soma é **hipótese**, não medição.

---

## 4. OS DESAFIOS AO LONGO DA RUN

A curva de dificuldade está medida e ela é dura na ponta certa. Vitória por rodada,
base recalibrada: **88,6 · 54,5 · 24,0 · 4,8 · 1,2 · 0,0**. Com o produto:
**76,1 · 55,1 · 27,0 · 7,8 · 1,8 · 0,6**.

Três coisas boas nisso: a rodada 1 deixa de ser passeio (88,6% → 76,1%); a **rodada 6 deixa de
ser zero** pela primeira vez em toda a auditoria (0,0% → 0,6%), sem poder de loja; e a
derrota-decidida-cedo cai 13 pontos (69,9% → 56,6%), porque um Tear alto no fim da mesa mantém
eventos tardios capazes de virar o placar — nenhuma outra alavanca tocou nesse número.

**O que sustenta horas** não são chefes com regras novas — é a mochila de 19 posicionamentos
disputada por três estratégias que se canibalizam pelo mesmo recurso escasso (as 18/17/19
cartas que a pilha colhida nunca devolve): colher cedo para subir o Tear, segurar para a
cruz, ou fabricar Avessos. A guarda diz que a disputa é real: a concordância entre a jogada
gulosa e a profunda ficou entre **54,1% e 59,7% em todas as 73 células das três bancadas** —
nenhuma saiu da banda 45–75%, por nenhum lado.

**O que NÃO está medido:** loja, selos, níveis de mão e modificadores de mesa. A rodada 6 com
poder de loja ligado é território virgem. Não invente número aqui.

---

## 5. A TABELA FINAL

| métrica | núcleo cru (auditoria) | base declarada (não existe) | **núcleo polido** |
|---|---|---|---|
| turnos com recompensa | 14,3% | 65% | **64,8–66,1%** |
| seca mediana / p90 | 7 / 9 | 2 / — | **2 / 4** |
| eventos por mesa | 2,34 | 3 | 2,2–2,4 |
| razão pontos/meta | 0,442 | 0,79 | **0,77–0,85** |
| vitória global | 10,4% | 21,8% | **28–31%** |
| Tear mediano / teto morde | 2 / 0% | 8 / — | **7 / 21,2%** |
| maior evento único | 1.881 | — | **10.260** |
| fator explosão (pico/mediana) | 7,9× | — | **15,8×** |
| m5 (guarda 45–75%) | 58,8% | 58,8% | **55–59%** |
| **cruzes/mesa (gulosa)** | **0,000** | 0,00 | **0,000** |
| cruzes/mesa (jogador que caça) | 0,087 | 0,14 | **0,146** |

**Contra o Balatro, só o honesto** (não medi o Balatro; o que segue é estrutural, não
medição minha): lá o print é notação científica; aqui o maior evento é **10.260 pontos,
4,19× a meta no máximo medido**. São ordens de grandeza diferentes e não adianta fingir — a
aposta do PLACARD é que **o print não é o número, é o tabuleiro**. No ritmo a comparação é
justa: no Balatro toda mão jogada pontua; o PLACARD saiu de 14,3% para **65,7%**. Os 34% de
turnos mudos que sobram são a distância que falta.

---

## 6. O QUE FOI TESTADO E REPROVADO (a seção que vale ouro)

**1. A CRUZ — o evento que na época dava nome ao jogo — não é consertável por carta, por preço nem
por cascata. As três bancadas atacaram por três caminhos diferentes e as três mediram zero.**
- Em **30.944 turnos de jogo guloso não existiu UMA ÚNICA vez** uma jogada que fechasse duas
  linhas — com coringa na mão (3.614 turnos com Agulha, 7.410 com Avesso) e sem.
  A configuração "duas linhas em 4/5 compartilhando uma casa vazia" **não aparece**.
- O argumento central do Avesso ("ele dobra os outs") **caiu**: 0,088 cruzes/mesa com
  Avesso contra 0,087 sem, na política caçadora. Nulo.
- **A AGULHA é anti-cruz**: derruba de 0,087 para **0,032/mesa (−63%)**, porque fecha
  linhas mais cedo e come o material que a caçadora estava montando.
- **A tese econômica está errada.** Multipliquei o preço da cruz por 4 a 100× e a gulosa
  continuou em **0,0000, 100% das mesas sem cruz**; a profunda **piorou** (0,0274 → 0,0174).
  A gulosa não recusa a cruz por achá-la cara: **ela nunca chega a vê-la.**

**2. O PRUMO (a carta sobrevive à colheita e cai) — reprovado como cascata.**
Zero elos em 48.000 mesas; as 24 células saíram numericamente idênticas (os três eixos
varridos medem zero bits). Causa: em **3.866 quedas, uma pista de pouso — linha abaixo em 4/5 —
existiu 0 vezes**. Ele foi vendido como a rampa que ensina a segurar um 4/5, mas **pressupõe**
essa habilidade em vez de ensiná-la. O que sobra é um buff de conservação (5,00 → 4,32 cartas
por evento) que empurra a razão para 1,003.

**3. A ESTRELA (fechar 4 linhas em C3) — reprovada como fantasia.**
**0 em 1.002 mesas gulosas, 0 em 402 profundas, 0 em 1.002 caçadoras.** Só existe com uma
política escrita para fabricá-la, e aí é 100%: não há regime intermediário. Pior: **99,1% das
Estrelas contêm uma mão de mult ≤ 2** — o anticlímax é a norma, e `FATOR_PISO=2` não corrige
(99,2%). O "PRODUTO ~1.120" prometido é **47× otimista**: o real mediano é **24**.

**4. Critérios de reprovação que as próprias propostas escreveram e que dispararam:**
n=1 em **100,00%** dos eventos (limite era 95%); p99 do print **2,36×** a meta (era exigido
≥100×, com corte em 20×); resíduo morto da Agulha **66,7%** (banda 20–40%).

**5. Dials que são código morto (mediram zero):** teto de Avessos por mesa (2/3/4/sem teto →
42,2% em tudo); ganho de Tear por colheita +1/+2/+3 (move a m5 em **0,08 ponto**); TEAR_TETO
acima de 8 (morde **0%**); o desempate do carimbo da Agulha, declarado "a primeira coisa a
medir" (53,17 × 52,33). Não vire parâmetro nenhum deles.

**6. Não combinar AGULHA + AVESSO:** vitória **73,33%**, razão **1,159** — e ainda
**0,000 cruz**. O jogo vira passeio sem entregar o clímax.

---

## 7. VEREDITO DE VÍCIO

**Sim, se.** E o "se" é grande o bastante para eu não arredondar.

**O que já segura:** o turno ficou vivo (65,7% dos turnos pagam contra 14,3%; seca 7 → 2).
O tabuleiro ganhou geografia sentida (C3 a 7× o uniforme com Avesso na mão). O teto emocional
foi de 2.394 a 10.260 e a explosão dobrou (7,2× → 15,8×). A guarda de profundidade passa em
73 de 73 células. Isso é um loop de 30 minutos que funciona.

**O que ainda não segura horas, sem suavizar:**

- **O jogo não entrega o evento que dá nome a ele.** Jogo natural: 0,000 por mesa. Jogador
  que joga *de propósito* para ela: 0,146/mesa, cerca de **0,9 por run de 6 mesas**. Recomendo
  assumir isso — a cruz é a jogada de especialista, não o loop. Mas aí o jogo precisa
  **ensinar a recusa**, e nenhuma das três bancadas achou um mecanismo que ensine.
- **O maior momento possível ainda é pequeno.** 4,19× a meta no máximo, p99 de 2,36×. É
  "passei raspando", não "quebrei o jogo".
- **34% dos turnos ainda são mudos.**
- **O Avesso é decisão sem poder** (+2 pp de vitória) e sua condição de corte (legibilidade)
  está aberta.

**O que falta, em ordem:** (1) K=1,25, hoje; (2) protótipo do `_draw` do Avesso;
(3) uma bancada medindo AVESSO × PRODUTO juntos, que nunca foi rodada; (4) uma bancada sobre
**a ordem em que as linhas fecham** — é ali que a cruz mora, e nenhuma das seis propostas
do painel atacou isso de frente.

---

## 8. O QUE AINDA NÃO SABEMOS

A simulação mede decisão. Ela não mede **nada** do que faz alguém jogar de novo à 1 da manhã:

- **O prazer de ver a cruz acontecer.** Meço 0,146/mesa; não meço se o jogador grita.
- **O giro do Avesso.** Dois futuros impressos, um dedo, escolha irreversível. É a aposta
  central do item e a única coisa que sei dele é que dispara pulso duplo em 9,5% dos casos
  (previsão era ≥20%). Se for confuso, o item cai e nenhum número teria avisado.
- **Ergonomia:** duas caras legíveis em 84×92 px em retrato, em meio segundo. `null`.
- **Som e animação.** A escada de semitons do Tear, o hitstop, o peso da colheita. Zero medido.
- **A R19** (o invariante anti-travamento) **não existe na sonda**. Ela é justamente a regra
  que pode demolir uma linha armada um turno antes de fechar. Isso é medição **ausente**, não
  ruim, e precisa ser feita no jogo real.
- **Loja, selos e níveis de mão:** nada. O produto com níveis de mão explode de forma não
  medida, e o risco "rodadas 5–6 viram passeio" continua não testado.
- **Se o jogador entende as regras 7 e 8 sem ninguém explicar.** A colheita que cospe uma
  carta de duas caras é o único ponto do núcleo que pode exigir uma segunda frase. Dez minutos
  de playtest respondem isso melhor que 100.000 mesas.
