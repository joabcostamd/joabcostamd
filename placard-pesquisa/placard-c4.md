# BANCADA c4 — JANELA DA COLHEITA. Leitura dos números.

Motor: `mesa2.gd` + `bancada4.gd`, construídos sobre o `nucleo.gd` da sonda (avaliador de 5 cartas
**intocado**) e sobre o `mesa2.gd` da bancada 1 (AVESSO intocado). O que eu acrescentei ao motor
foram três chaves de configuração — `produto`/`tear_ini`/`teto_evento` (o núcleo polido da b3),
`meta_k`, e `janela`/`janela_junta`/`janela_max_por_mesa`/`janela_cond_perp` (o candidato 4).
Nada mais foi tocado.

**32 asserções passando**: as 17 originais da b1 (`testes2.gd`, intactas) mais 15 novas
(`testes4.gd`) escritas para a janela: a linha cheia fica na grade e não pontua no turno em que
enche; colhe no posicionamento seguinte; a cruz por janela acontece num único evento com n=2;
o último posicionamento colhe na hora (regra 5); o antídoto "só a primeira madura" força a
segunda a colher imediatamente; **conservação de FACES com a janela ligada** nas três durações
(1, 2, até o fim) — o estado novo "cheia mas ainda na grade" não quebra a R04b; nada maduro
sobrevive ao fim da mesa; e o **TETO DURO 2/1/2 verificado em toda mesa de toda célula**.

---

## 0. A LEITURA DA FÓRMULA, FIXADA ANTES DE MEDIR (o aviso do enunciado)

O enunciado pede que as quatro bancadas usem a mesma leitura e que ela esteja no topo do JSON.
A minha está em `resultado.json → _LEITURA_DA_FORMULA_FIXADA_ANTES_DE_MEDIR`. Em texto:

> **pontos do evento = Σ_linhas [ (fichas base da mão + fichas das cartas) × FATOR × (0,60 se diagonal) ]**
> **FATOR = (SOMA dos mults das mãos colhidas no evento) × Tear.**
> O Tear multiplica o evento inteiro (b3); os mults **somam** entre si (é o que o próprio
> candidato 4 escreve: "mults somados", e é o que produz a escada 2×/3×/4× que o enunciado
> declara como alvo de valor). Teto do evento `24+4×rodada` **removido**, como no núcleo polido.

**Por que essa escolha não contamina a comparação:** para n=1 linha as duas leituras
(soma × Tear e produto × Tear) são **idênticas**. A BASE tem 0,000 cruz, logo a BASE é
byte-a-byte a mesma sob qualquer leitura. As leituras só divergem dentro da cruz. Medi a
outra leitura na célula **J1_PROD** (mults multiplicam entre si). Resultado adiante: ela muda o
**preço** e não muda a **frequência** — mais uma confirmação de que preço não é o problema.

Aritmética da escada sob a leitura fixada, com duas mãos de fichas f e mult m iguais:
separadas pagam `2·f·m·T`; juntas pagam `(2f)·(2m)·T` = **exatamente 2×**. Tripla 3×, total 4×.
Sob a leitura produto a dupla pagaria `(2f)·(m²)·T` = **4× com m=4** — acima do alvo declarado.
Por isso a soma é a leitura fiel ao candidato.

---

## 1. PASSO 2 — A BASE REPRODUZIDA. Bate.

Antes de qualquer variante eu reproduzi os dois pontos de ancoragem conhecidos, com as mesmas
sementes das bancadas anteriores (`31337 + t·7919`, rodada `t%6+1`, tipo `(t/6)%3`):

| ponto de ancoragem | medido aqui | fonte |
|---|---|---|
| base **aditiva** da b1 (PULSO 0,35 + TIQUE 4, K=1) | rec 66,1% · seca 2/4 · razão 0,962 · vitória 40,5% · Tear 6/7 · maior evento **2.394** | b1: 65,7 / 2/4 / 0,990 / 40,75 / 6/7 / 2.394 |
| núcleo **polido** da b3 (PRODUTO, K=2,25, sem Avesso) | razão 0,763 · vitória 27,67% · Tear **7/8** · maior evento **10.260** · pico/mediana **15,83×** · m5 57,9% | b3: 0,770 / 28,0 / 7/8 / 10.260 / 15,8× / 58,7% |
| caçadora da b1 sobre a base polida | **0,146** cruz/mesa · **85,4%** de mesas com zero | enunciado: 0,146 / 86% |

Os três batem. **O instrumento está calibrado nos três números que o enunciado cita.**

Duas correções honestas ao enunciado, herdadas das bancadas anteriores e que eu confirmo:
o "Tear mediano 8" da base é **7 (máx 8)** com tique 4; e "razão 0,79 com K=1,25" vale para a
base **aditiva** — no núcleo com PRODUTO o K que devolve 0,79 é **2,25**, não 1,25. Usei
K recalibrado por variante (seção 2).

**O número que diagnostica a doença, medido em 1.000 mesas:**
`turnos_segurando_4_5` **= 0,000** na base gulosa. Não "quase zero": **zero**. Em 1.000 mesas,
**nenhuma** linha que chegou a 4/5 sobreviveu ao posicionamento seguinte. A razão é
geométrica e não estatística: **qualquer carta cabe em qualquer casa**, então uma linha em 4/5 é
sempre fechável no turno seguinte, e fechar sempre paga mais que não fechar. O enunciado estava
certo, e o número é exatamente 0.

---

## 2. A RECALIBRAÇÃO DE K — obrigatória, e ela é o primeiro custo da regra

O enunciado exige comparar as variantes na **mesma razão pontos/meta**, não no mesmo K.
Calibrei cada variante até razão ≈ 0,79 na política gulosa (600 mesas por passo, 2 a 3 passos).

| variante | K que devolve razão 0,79 | inflação de pontos vs BASE | razão na BASE se o K não fosse mexido |
|---|---|---|---|
| BASE | **2,1475** | — | 0,79 |
| J1 (janela 1) | **4,3922** | **+105%** | ~1,37 (+0,58) |
| J1_CONDPERP | **2,3582** | **+9,8%** | ~0,87 (+0,08) |
| J2 (janela 2) | 5,0435 | +135% | ~1,52 |
| JFIM (até o fim) | 6,3494 | +196% | ~2,06 |
| J1_PROD (mults multiplicam) | 5,8969 | +175% | ~1,77 |

**Primeiro veredito parcial, e ele é duro:** a falsificação nº 4 que o próprio proponente
escreveu — *"a razão pontos/meta deve subir pouco (< +0,10)"* — **falha por um fator de 6** na
janela de 1 turno livre. A regra é mecanicamente neutra (não move ficha, mult nem carta), mas
economicamente **dobra a produção de pontos da mesa**, porque passa a somar mults em ~70% dos
eventos. Isso não invalida a regra: invalida a frase "é uma mudança puramente temporal". Ela
obriga a refazer a curva de metas inteira. É uma constante, mas é a constante do jogo todo.

O único ponto da varredura que respeita a falsificação nº 4 é a **janela condicionada**
(`J1_CONDPERP`: a linha só amadurece se alguma perpendicular já estiver em 4/5): +9,8%. Só que
ela respeita a nº 4 **porque não faz nada** — ver 5.3. Não há ponto intermediário nesta varredura.

---

## 3. PASSO 3 — A POLÍTICA PLANEJADORA (e por que a caçadora da b1 não servia)

A caçadora da b1 (`melhor_cacadora`) é uma gulosa com veto: ela proíbe queimar uma casa de
cruzamento, mas **nunca escolhe um alvo e nunca constrói na direção dele**. Por isso chega a
0,146/mesa. A planejadora que escrevi:

1. escolhe o alvo `(L,C)` — centro obrigatoriamente vazio — maximizando `braços já ocupados`
   (as sementes da Pequena contam de graça) e penalizando `perigo` (braços vazios que fechariam
   uma linha lateral, o imposto da R17);
2. joga **só nas 8 casas de braço** até que ambas as linhas estejam em 4/5, escolhendo a carta e
   o braço que mais elevam o potencial da mão-alvo daquele eixo;
3. **veta com peso 10⁷** qualquer posicionamento que feche uma linha que não seja L ou C
   (é a modelagem direta do imposto da R17: colheita lateral = +1 posicionamento);
4. usa os descartes só pela qualidade das duas mãos alvo;
5. reavalia o alvo quando `braços_faltantes + 1 > posicionamentos restantes`, e cai na gulosa
   quando nenhum alvo é viável.

**Validação na BASE (obrigatória pelo enunciado):** 1,483 cruz/mesa, **0,0% das mesas com
zero**, contra 0,000 da gulosa e 0,146 da caçadora da b1. Por tipo de mesa: Pequena **1,601**,
Grande **1,000**, Chefe **1,852** — **89,0% do teto aritmético 2/1/2** declarado no enunciado
(com a janela ela chega a **97,7%**: 1,911 / 1,000 / 1,976). O teto da Grande é atingido
exatamente e nunca ultrapassado: nas **334 mesas Grandes** de cada célula, **100% têm uma
cruz e nenhuma tem duas**. A planejadora funciona, e ela **confirma a CONTA 4 por medição**.

E ela confirma a CONTA (a): na BASE, jogar para a cruz **paga**. Razão pontos/meta da
planejadora **1,122** contra 0,825 da gulosa — **+36%** com o mesmo material e as mesmas metas.
A cruz nunca foi cara. Ela era invisível.

---

## 4. A TABELA. Base × variantes, 1.000 mesas por célula, sementes pareadas

| metrica | BASE | J1 | J1_CONDPERP | J1_JUNTA | J1_PRIMEIRA | J2 | JFIM | J1_PROD | BASE_SEMAV | J1_SEMAV | J1_CONDPERP_JUNTA |
|---|---|---|---|---|---|---|---|---|---|---|---|
| K da meta (recalibrado) | 2,1475 | 4,3922 | 2,3582 | 4,3922 | 4,4268 | 5,0435 | 6,3494 | 5,8969 | 2,1731 | 4,4044 | 2,3582 |
| razao pontos/meta (gulosa) | 0,825 | 0,814 | 0,818 | 0,814 | 0,813 | 0,793 | 0,790 | 0,805 | 0,799 | 0,828 | 0,818 |
| **cruzes/mesa GULOSA** | 0,000 | 0,826 | 0,098 | 0,817 | 0,820 | 0,849 | 0,897 | 0,817 | 0,000 | 0,832 | 0,098 |
| **cruzes/mesa PROFUNDA** | 0,018 | 0,825 | 0,015 | 0,815 | 0,762 | 0,938 | 0,960 | 0,828 | 0,023 | 0,818 | 0,015 |
| **cruzes/mesa PLANEJADORA** | 1,483 | 1,628 | 1,506 | 1,628 | 1,629 | 1,637 | 1,000 | 1,631 | 1,484 | 1,628 | 1,506 |
| **DISTANCIA planej. - gulosa** | 1,483 | 0,802 | 1,408 | 0,811 | 0,809 | 0,788 | 0,103 | 0,814 | 1,484 | 0,796 | 1,408 |
| cruzes/mesa cacadora b1 | 0,146 | 0,847 | — | — | — | — | — | — | — | — | — |
| mesas com ZERO cruz (gulosa) | 100,0% | 17,4% | 90,2% | 18,3% | 18,0% | 15,1% | 10,3% | 18,3% | 100,0% | 16,8% | 90,2% |
| mesas com ZERO cruz (planej.) | 0,0% | 0,0% | 0,0% | 0,0% | 0,0% | 0,0% | 0,0% | 0,0% | 0,0% | 0,0% | 0,0% |
| cruzes/mesa MAX (gulosa/planej.) | 0 / 2 | 1 / 2 | 1 / 2 | 1 / 2 | 1 / 2 | 1 / 2 | 1 / 1 | 1 / 2 | 0 / 2 | 1 / 2 | 1 / 2 |
| violacoes do teto duro 2/1/2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| **cruzes por EVENTO (gulosa)** | 0,000 | 0,701 | 0,046 | 0,687 | 0,682 | 0,759 | 0,897 | 0,702 | 0,000 | 0,727 | 0,046 |
| eventos por mesa (gulosa) | 2,22 | 1,18 | 2,14 | 1,19 | 1,20 | 1,12 | 1,00 | 1,16 | 2,20 | 1,15 | 2,14 |
| % cruzes perpendiculares (gulosa) | — | 93,8 | 99,0 | 99,3 | 93,9 | 95,8 | 97,7 | 93,8 | — | 94,0 | 100,0 |
| % cruzes acidentais (planej.) | 96,5 | 41,4 | 96,5 | 41,4 | 41,0 | 45,9 | 100,0 | 41,5 | 96,1 | 42,0 | 96,5 |
| turnos com recompensa (gulosa) | 64,8% | 75,8% | 65,5% | 75,9% | 75,4% | 76,8% | 79,2% | 76,0% | 64,8% | 75,8% | 65,5% |
| seca mediana / p90 (gulosa) | 2 / 4 | 2 / 3 | 2 / 4 | 2 / 3 | 2 / 3 | 2 / 3 | 2 / 3 | 2 / 3 | 2 / 4 | 2 / 3 | 2 / 4 |
| **GUARDA m5 (banda 45-75%)** | 59,0% | 67,4% | 60,8% | 67,4% | 68,0% | 76,3% | 77,8% | 67,5% | 57,3% | 67,7% | 60,7% |
| vitoria % (gulosa) | 30,70 | 37,10 | 32,10 | 36,70 | 37,20 | 34,70 | 37,10 | 37,90 | 29,40 | 36,30 | 32,10 |
| Tear mediano / max | 7 / 8 | 7 / 8 | 7 / 8 | 7 / 8 | 7 / 8 | 7 / 8 | 7 / 8 | 7 / 8 | 7 / 8 | 7 / 8 | 7 / 8 |
| maior evento unico | 10260 | 32600 | 18768 | 32600 | 32600 | 38892 | 55632 | 390096 | 10260 | 32600 | 18768 |
| pico / mediana | 15,64 | 10,39 | 27,36 | 10,68 | 10,91 | 10,09 | 9,33 | 105,29 | 15,83 | 9,95 | 27,36 |
| **turnos segurando 4/5** | 0,000 | 3,529 | 0,566 | 3,534 | 3,470 | 3,595 | 3,657 | 3,543 | 0,000 | 3,537 | 0,566 |
| colheitas adiadas (planej.) | 62,7% | 63,5% | 62,6% | 63,5% | 62,4% | 64,2% | 60,5% | 63,4% | 62,9% | 63,4% | 62,6% |
| casas vazias min (mediana/min) | 16 / 11 | 9 / 7 | 16 / 7 | 9 / 7 | 9 / 7 | 9 / 7 | 8 / 7 | 9 / 7 | 16 / 11 | 9 / 7 | 16 / 7 |
| % cruzes em que o teto do mult morderia | — | 28,8 | 24,5 | 28,3 | 28,7 | 36,3 | 53,8 | 58,3 | — | 29,3 | 24,5 |

### por tipo de mesa (cruzes/mesa, % mesas com >=1)
| variante | politica | Pequena | Grande | Chefe |
|---|---|---|---|---|
| BASE | gulosa | 0,000 (0,0%) | 0,000 (0,0%) | 0,000 (0,0%) |
| BASE | planejadora | 1,601 (100,0%) | 1,000 (100,0%) | 1,852 (100,0%) |
| J1 | gulosa | 0,854 (85,4%) | 0,713 (71,3%) | 0,912 (91,2%) |
| J1 | planejadora | 1,911 (100,0%) | 1,000 (100,0%) | 1,976 (100,0%) |
| J1_CONDPERP | gulosa | 0,140 (14,0%) | 0,051 (5,1%) | 0,103 (10,3%) |
| J1_CONDPERP | planejadora | 1,649 (100,0%) | 1,000 (100,0%) | 1,873 (100,0%) |
| J1_JUNTA | gulosa | 0,845 (84,5%) | 0,704 (70,4%) | 0,903 (90,3%) |
| J1_JUNTA | planejadora | 1,911 (100,0%) | 1,000 (100,0%) | 1,976 (100,0%) |
| J1_PRIMEIRA | gulosa | 0,851 (85,1%) | 0,713 (71,3%) | 0,897 (89,7%) |
| J1_PRIMEIRA | planejadora | 1,911 (100,0%) | 1,000 (100,0%) | 1,979 (100,0%) |
| J2 | gulosa | 0,875 (87,5%) | 0,737 (73,7%) | 0,936 (93,6%) |
| J2 | planejadora | 1,923 (100,0%) | 1,000 (100,0%) | 1,991 (100,0%) |
| JFIM | gulosa | 0,920 (92,0%) | 0,784 (78,4%) | 0,988 (98,8%) |
| JFIM | planejadora | 1,000 (100,0%) | 1,000 (100,0%) | 1,000 (100,0%) |
| J1_PROD | gulosa | 0,839 (83,9%) | 0,701 (70,1%) | 0,912 (91,2%) |
| J1_PROD | planejadora | 1,932 (100,0%) | 1,000 (100,0%) | 1,964 (100,0%) |
| BASE_SEMAV | gulosa | 0,000 (0,0%) | 0,000 (0,0%) | 0,000 (0,0%) |
| BASE_SEMAV | planejadora | 1,601 (100,0%) | 1,000 (100,0%) | 1,855 (100,0%) |
| J1_SEMAV | gulosa | 0,857 (85,7%) | 0,719 (71,9%) | 0,921 (92,1%) |
| J1_SEMAV | planejadora | 1,914 (100,0%) | 1,000 (100,0%) | 1,973 (100,0%) |
| J1_CONDPERP_JUNTA | gulosa | 0,140 (14,0%) | 0,051 (5,1%) | 0,103 (10,3%) |
| J1_CONDPERP_JUNTA | planejadora | 1,649 (100,0%) | 1,000 (100,0%) | 1,873 (100,0%) |


| figura (custo em posicionamentos) | mesa | cruzes/mesa | % mesas com >=1 | n=2 | n=3 | n=4 | razao pontos/meta | vitoria % | maior evento | % em que o teto do mult morderia |
|---|---|---|---|---|---|---|---|---|---|---|
| DUPLA (9) | BASE | 1,485 | 100,0% | 93,6% | 0,0% | 0,0% | 1,127 | 62,75 | 16786 | 5,3% |
| CRUZ TOTAL (17) | BASE | 0,882 | 88,2% | 0,0% | 0,0% | 79,0% | 2,537 | 85,38 | 31540 | 78,5% |
| TRIPLA (13) | BASE | 1,000 | 100,0% | 0,0% | 97,4% | 0,0% | 1,386 | 66,38 | 15828 | 12,5% |
| DUPLA (9) | J1 | 1,629 | 100,0% | 92,8% | 0,0% | 0,0% | 0,699 | 34,25 | 16786 | 7,1% |
| CRUZ TOTAL (17) | J1 | 0,976 | 97,6% | 7,6% | 1,7% | 87,6% | 1,301 | 61,63 | 31540 | 71,4% |
| TRIPLA (13) | J1 | 1,000 | 100,0% | 0,0% | 93,5% | 1,1% | 0,761 | 33,75 | 15828 | 12,5% |
| DUPLA (9) | J1_CONDPERP | 1,509 | 100,0% | 93,3% | 0,0% | 0,0% | 1,074 | 58,63 | 16786 | 5,6% |
| CRUZ TOTAL (17) | J1_CONDPERP | 0,895 | 89,5% | 1,0% | 0,1% | 79,8% | 2,344 | 84,25 | 31540 | 77,5% |
| TRIPLA (13) | J1_CONDPERP | 1,000 | 100,0% | 0,0% | 96,3% | 1,0% | 1,266 | 62,50 | 15828 | 12,6% |

Por tipo de mesa (planejadora dedicada, base sem janela):

| figura | Pequena | Grande | Chefe |
|---|---|---|---|
| DUPLA (9) | 1,600 (100,0%) | 1,000 (100,0%) | 1,856 (100,0%) |
| TRIPLA (13) | 1,000 (100,0%) | 1,000 (100,0%) | 1,000 (100,0%) |
| CRUZ TOTAL (17) | 0,652 (65,2%) | 1,000 (100,0%) | 1,000 (100,0%) |


---

## 5. O QUE OS NÚMEROS DIZEM

### 5.1 A regra funciona. O horizonte encurtou de verdade.

Os três números de falsificação que o proponente pediu:

| falsificação declarada | alvo | medido (J1) | passa? |
|---|---|---|---|
| PROFUNDA sai de 0,015 e chega a ≥ 0,3 | ≥ 0,30 | **0,825** | sim, por 2,7× |
| GULOSA sai de 0,0000 e chega a ≥ 0,15 | ≥ 0,15 | **0,826** | sim, por 5,5× |
| PLANEJADORA perto do teto (≥ 0,9) | ≥ 0,90 | **1,628** | sim |
| **DISTÂNCIA planejadora − gulosa ENCOLHE** | — | **1,483 → 0,802 (−46%)** | **sim** |
| razão pontos/meta sobe pouco (< +0,10) | < +0,10 | **+0,58** | **NÃO** |
| m5 fica em 45–75% | banda | **67,4%** | sim (mas +8,4 pt) |

A métrica que o enunciado declarou como a única que importa — **a distância entre a planejadora
e a gulosa** — cai de 1,483 para 0,802. E há uma segunda medição da mesma coisa, mais bonita:
**a caçadora da b1 perde a razão de existir.** Na base ela batia a gulosa por 0,146 a 0,000;
com a janela ela faz 0,847 contra 0,826 da gulosa — uma vantagem de **0,021**. A política
escrita para caçar cruz deixa de ter vantagem sobre quem não está caçando nada. Isso é o
horizonte 9 virando horizonte 3, medido de dois jeitos independentes.

`turnos_segurando_4_5` vai de **0,000 → 3,529**. O termômetro que o enunciado pediu sai do zero.

### 5.2 A geometria se autorregula — a restrição "só linhas que compartilham carta" é código morto

**93,8% das cruzes gulosas já são perpendiculares** sem nenhuma restrição, e a célula
`J1_JUNTA` (restringir a colheita conjunta a linhas que compartilham uma carta) devolve
0,817 contra 0,826 — **−1%**, dentro do ruído. O piso de 70% que o proponente colocou como
gatilho para restringir **não é atingido de baixo em nenhum ponto da varredura**.
**Não restrinjam. A regra livre é mais curta e mede igual.**

### 5.3 OS DOIS ANTÍDOTOS DECLARADOS FALHAM — e falham por motivos opostos

O proponente pré-declarou dois freios para o caso de a regra ir longe demais. **Os dois foram
medidos e os dois são inúteis, em direções contrárias.**

**(a) "janela só para a primeira linha madura de cada mesa" (`J1_PRIMEIRA`) é um no-op.**
Exige K=4,4268 contra 4,3922 do J1 livre, e entrega 0,820 cruz/mesa contra 0,826.
O motivo é geométrico e eu não tinha previsto: com a janela os eventos por mesa desabam de
2,22 para 1,18, ou seja **a mesa típica já só tem uma maturação**. Limitar a uma por mesa não
limita coisa alguma.

**(b) "janela apenas quando a perpendicular já estiver em 4/5" (`J1_CONDPERP`) desliga a regra.**
Gulosa **0,098** cruz/mesa (90,2% das mesas com zero), profunda **0,015** — literalmente o
número da BASE. `turnos_segurando_4_5` volta de 3,529 para 0,566.

A explicação de (b) é a coisa mais interessante que esta bancada encontrou, e ela é dinâmica,
não geométrica: **a janela livre funciona por realimentação positiva.** Uma linha amadurece →
no turno seguinte qualquer jogada colhe, e a jogada que colhe mais é a que fecha uma segunda
linha → a gulosa passa a ter motivo para *segurar* linhas em 4/5 (seg45 de 0,000 para 3,529) →
mais linhas em 4/5 aumentam a chance de a próxima maturação encontrar uma perpendicular pronta.
A condição de (b) exige que o estado final do laço já exista antes de o laço começar. Ela mata a
partida do motor. **A janela é liga/desliga: não existe meio-termo nesta varredura.** Quem
achar 0,826 cruz/mesa demais não tem, por enquanto, um dial para baixar — tem de desenhar
outro freio (por exemplo: a janela vale só nas mesas Chefe, ou só uma vez por run).

### 5.4 A leitura do multiplicador muda o preço e não muda a frequência

`J1_PROD` (mults multiplicam entre si na cruz) exige K=5,90 contra 4,39 — o prêmio da cruz
sobe muito — e entrega **0,817 cruz/mesa contra 0,826**. Idêntico. É a terceira confirmação
independente, nesta bancada, da tese que as três bancadas anteriores já tinham medido com
4×/20×/100×: **o preço da cruz não move a frequência dela.** Só a ordem move.

### 5.5 O AVESSO não interage

`BASE_SEMAV` × `BASE` e `J1_SEMAV` × `J1`: a diferença em cruzes/mesa fica dentro do ruído.
O Avesso não ajuda nem atrapalha a cruz, com ou sem janela. A previsão do enunciado
("o Avesso pode fechar a linha num turno e a coluna no seguinte, dentro da janela") **não se
materializa em número**: o Avesso é 1,7 carta por mesa e a janela já produz o estado sozinha.

### 5.6 O teto do multiplicador (R15) morde — e só na cruz, exatamente como o aviso previa

Com o teto `24+4×rodada` **removido** (núcleo polido), medi quantos eventos o teto **teria**
cortado. Na base gulosa: **1,0% dos eventos**. Com a janela: **21,5% dos eventos e 28,8% das
cruzes**. Na CRUZ TOTAL da escada: **78,5% das cruzes**. Se alguém reintroduzir o teto,
a escada 2×/3×/4× colapsa em silêncio e a bancada seguinte vai concluir "a tripla não compensa"
quando o culpado é o teto. **O teto tem de ficar removido, e isso agora tem número.**

### 5.6b O teto emocional sobe, mas o FATOR EXPLOSÃO cai

`maior_evento_unico` vai de **10.260 para 32.600** (×3,2) — o teto emocional que a b3 tinha
conquistado triplica de novo. Mas a **razão pico/mediana**, que a b3 declarou como patrimônio
(15,8×), **cai para 10,39×**: como quase todo evento vira cruz, o evento mediano sobe junto
com o pico e a explosão relativa encolhe 34%. O jogador vê números maiores e sente menos
diferença entre um turno normal e o clímax. Isso não estoura nenhuma banda declarada — a lista
de métricas obrigatórias pede a razão mas não fixa piso para ela — e eu registro como perda.
(Sob a leitura PRODUTO o efeito inverte: `J1_PROD` tem pico/mediana **105,29×** e maior evento
**390.096** — outro motivo, além do alvo 2×/3×/4×, para a leitura fixada ser a soma.)

### 5.7 Travamento do tabuleiro: existe, é medível, e com janela = 1 não é fatal

`casas_vazias` mínimo por mesa: base **mediana 16 / mínimo 11**; com janela 1 **mediana 9 /
mínimo 7**. O tabuleiro fica visivelmente mais cheio (uma linha madura ocupa 5 casas), mas
**nunca chegou a zero em 11.000 mesas** e o `_nunca_mao_morta` continua verdadeiro. Com janela 2
e "até o fim" o mínimo é o mesmo 7 — o travamento não foi o modo de falha desses dois.

---

## 6. A ESCADA 9 / 13 / 17 — o que ninguém tinha medido

O enunciado avisa que, se ninguém medir a escada, o melhor jogo do PLACARD fica sem ser
descoberto. Escrevi mais duas planejadoras (TRIPLA: centro em (r,r) ou (r,4−r), r≠2, 12 braços +
1 gatilho = 13 posicionamentos; CRUZ TOTAL: centro obrigatoriamente (2,2), 16 braços + 1 = 17) e
rodei as três figuras sobre a base polida, 800 mesas por célula. Os números estão na segunda
tabela acima. O resumo, na BASE (gulosa de referência: razão 0,825, vitória 30,7%):

| figura | custo | cruzes/mesa | razão pontos/meta | vitória | ganho sobre a gulosa |
|---|---|---|---|---|---|
| DUPLA | 9 posicionamentos | 1,485 | **1,127** | 62,8% | **1,37×** |
| TRIPLA | 13 posicionamentos | 1,000 | **1,386** | 66,4% | **1,68×** |
| CRUZ TOTAL | 17 posicionamentos | 0,882 (11,8% falham) | **2,537** | 85,4% | **3,07×** |

A escada existe, é monótona, e **a CRUZ TOTAL cabe exatamente numa mesa Grande** — 17 células,
17 posicionamentos — com 88,2% de sucesso e vitória de 85,4%. A coincidência aritmética do
enunciado é real e é o melhor jogo do PLACARD. O ganho medido (3,07×) é menor que o 5,6×
projetado na CONTA (a), pela razão simples de que as duas diagonais pagam 60% e os turnos que
sobram depois do disparo são desperdiçados.

**Isto é um sistema de dificuldade completo que já está nas regras e nunca foi nomeado na tela.**
Nomeiem: DUPLA / TRIPLA / TOTAL, custo 9 / 13 / 17, valor 2× / 3× / 4×.

---

## 7. O QUE NÃO FUNCIONOU (a seção que eu não vou suavizar)

**1. `janela = 2` está REPROVADA pela guarda de profundidade.** m5 = **76,3%**, acima da banda
45–75%. Cruzes por evento 0,759, acima do 0,75 que o próprio proponente declarou como
"falhou por sucesso". O jogo passa a ser resolvido pela UI.

**2. `janela = até o fim` está REPROVADA duas vezes.** m5 = **77,8%**; cruzes por evento
**0,897** na gulosa e **1,000** na planejadora — literalmente **um único evento por mesa**.
A previsão do proponente ("até o fim degenera") está certa e agora tem número.

**3. A tese "é uma mudança puramente temporal" é falsa em consequência.** Ela não mexe em ficha,
mult nem carta — e mesmo assim exige **+105% na curva de metas**. Quem implementar isso não
está mudando uma regra: está reescrevendo a economia inteira e depois recalibrando.

**4. A janela mata o retorno de jogar para a cruz.** Este é o achado que mais me incomodou e ele
não estava previsto em nenhum dos cinco riscos declarados. Na BASE, a planejadora tem razão
pontos/meta **1,122** contra 0,825 da gulosa: planejar **paga +36%**. Com a janela e o K
recalibrado, a planejadora cai para **0,660** contra 0,814 da gulosa: planejar **custa −19%**.
A regra socializa a cruz — e ao socializá-la, mais a recalibração que ela obriga, ela
**taxa quem a persegue de propósito**. O clímax deixa de ser o prêmio da perícia e vira a
paisagem. Isso não estoura nenhuma banda declarada, e por isso não reprova a regra pelo critério
escrito; mas é uma perda de profundidade que nenhuma métrica da lista captura, e o painel
precisa decidir se aceita.

**5. A métrica `pct_cruzes_acidentais` é degenerada para a gulosa.** O critério operacional do
enunciado — "o posicionamento-gatilho também era a melhor jogada da gulosa?" — dá **100% por
construção** quando a política É a gulosa. O número informativo é o da planejadora: **41,4%
acidentais / 58,6% intencionais** com janela, contra 96,5% acidentais na base (na base, o
gatilho no centro é sempre a jogada gulosa — o que foi não-guloso foram os 8 turnos anteriores,
e nenhum critério de um turno vê isso). **A mistura saudável que o enunciado pediu existe, mas
só a planejadora consegue exibi-la.**

**6. A `pct_colheitas_adiadas` também precisa de ressalva.** Com a janela ela sobe para 80% na
gulosa, mas isso é artefato: como a colheita acontece sozinha no turno seguinte, a gulosa deixa
de precisar jogar na casa crítica. O número honesto é o da planejadora: **63,5%**.

**7. O ritmo da montagem da cruz não é o que a CONTA (c) previu.** A planejadora tem
`turnos com recompensa` de **51,3%** na base e **56,5%** com janela, contra 64,8% e 75,8% da
gulosa, e seca p90 de **8** na base. O PULSO financia parte da montagem, mas não toda:
montar uma cruz continua sendo mais seco que jogar guloso, e não "17% mais seco" — é ~20% menos
turnos pagos e o dobro da seca de cauda.

---

## 8. O PARÂMETRO QUE EU RECOMENDO E O VEREDITO

### O parâmetro recomendado

**`janela = 1 turno`, colheita conjunta LIVRE (sem a restrição "só linhas que compartilham
carta"), teto do multiplicador removido.** É a célula `J1`.

- `janela = 2` e `até o fim` estão **reprovadas** pela guarda de profundidade (m5 76,3% e 77,8%,
  acima de 75%) e por cruzes/evento (0,759 e 0,897, acima do 0,75 que o próprio proponente
  declarou como "falhou por sucesso"). A previsão do enunciado estava certa: 1 é o ponto.
- a restrição "compartilham carta" é **desnecessária**: 93,8% das cruzes já são perpendiculares
  sem ela, e ligá-la muda o resultado em −1%. Duas frases valem mais que três.
- os dois antídotos declarados (`só a primeira madura`, `só com perpendicular em 4/5`) **não
  servem como dial**: um não faz nada, o outro desliga a regra (5.3).
- e a curva de metas **tem** de ser refeita junto: `K` de 2,1475 para 4,3922 no núcleo polido,
  ou seja **metas +105%**. Sem isso a razão pontos/meta vai para ~1,37 e o jogo se resolve sozinho.

### O veredito, pelo critério que eu declarei ANTES de medir

O critério era: **APROVADA** se, sem estourar nenhuma banda, a planejadora fizer ≥ 1,0
cruz/mesa com < 40% de mesas em zero **e** a gulosa passar de 0,25/mesa.

| exigência | limiar | J1 medido | |
|---|---|---|---|
| planejadora, cruzes/mesa | ≥ 1,0 | **1,628** | ✔ |
| planejadora, mesas com zero | < 40% | **0,0%** | ✔ |
| gulosa, cruzes/mesa | > 0,25 | **0,826** | ✔ |
| turnos com recompensa | ≥ 60% | 75,8% | ✔ |
| seca mediana | ≤ 3 | 2 | ✔ |
| guarda de profundidade m5 | 45–75% | 67,4% | ✔ |
| vitória global | 20–40% | 37,10% | ✔ |
| razão pontos/meta | ~0,79 | 0,814 | ✔ |
| teto duro 2/1/2 | 0 violações | **0 em 28.400 mesas** (mais 7.200 da escada e 960 dos testes) | ✔ |

# **APROVADA.**

E ela é aprovada pela razão certa, não por sorte de número: a **distância planejadora − gulosa**,
que o enunciado declarou como a única métrica que prova que o horizonte encurtou, **cai de 1,483
para 0,802 (−46%)**, e a caçadora dedicada da b1 perde 86% da sua vantagem sobre a gulosa
(0,146 → 0,021). O horizonte 9 virou horizonte 3, exatamente como a tese previa, sem uma ficha,
um mult ou uma carta a mais.

### As três ressalvas que eu registro junto com a aprovação, e que o critério declarado não pega

1. **A regra não é barata, só é neutra em mecânica.** Ela exige **+105% na curva de metas**.
   A falsificação nº 4 do próprio proponente ("razão sobe < +0,10") **falhou por 6×**. Quem
   comparar os quatro candidatos com o mesmo K vai ver a JANELA "ganhar" por inflação — o
   enunciado avisou disso e o aviso se materializou aqui, no meu candidato.
2. **O clímax deflaciona.** Cruzes por evento **0,701** (banda saudável declarada: 0,35–0,55);
   eventos por mesa caem de **2,22 para 1,18**; só **29,9%** dos eventos ainda são de uma linha
   só. A colheita simples quase desaparece. Não estoura o 0,75 declarado como falha, mas passa
   folgado da banda saudável, e **não há dial para trazê-la de volta** (5.3). Junto com isso, a
   razão pico/mediana cai de 15,64× para 10,39× (5.6b): o clímax fica maior em valor absoluto e
   menor em contraste.
3. **Planejar deixa de pagar.** Na BASE a planejadora tem razão 1,122 contra 0,825 da gulosa
   (**+36%**); com a janela e o K recalibrado, 0,660 contra 0,814 (**−19%**). A regra socializa a
   cruz e, junto com a recalibração que ela obriga, taxa quem a persegue de propósito.
   Nenhuma banda declarada captura isso, e é a coisa que eu mais recomendaria o painel olhar
   antes de aprovar.

### O que me surpreendeu

- **`turnos_segurando_4_5` na base é 0,000 exatos**, não "quase zero". A causa é que qualquer
  carta cabe em qualquer casa: uma linha em 4/5 é *sempre* fechável no turno seguinte. Isso torna
  o diagnóstico das três bancadas anteriores mais forte do que elas escreveram.
- **A janela é um laço de realimentação, não um bônus.** Ela não paga por esperar — ela cria o
  motivo para esperar, que cria mais estado para esperar. Por isso o antídoto condicionado
  (`só com perpendicular em 4/5`) devolve exatamente a base: ele exige o produto do laço como
  condição de partida do laço.
- **A CRUZ TOTAL cabe mesmo na mesa Grande e é o melhor jogo do PLACARD**: 17 células, 17
  posicionamentos, 88,2% de sucesso, razão pontos/meta **2,537** e **85,4% de vitória** — 3,07×
  a gulosa. A escada 9/13/17 é um sistema de dificuldade inteiro que já está nas regras.
- **O teto do mult (R15) morde de verdade e só na cruz**: 1,0% dos eventos na base, 28,8% das
  cruzes com janela, **78,5% das cruzes TOTAIS**. Se ele voltar, a escada colapsa em silêncio.
- **A leitura do multiplicador não muda a frequência** (J1_PROD: 0,817 contra 0,826), só o preço.
  Quarta confirmação independente de que preço não é o gargalo.

### O que NÃO funcionou (resumo)

`janela = 2` (m5 76,3%) · `janela = até o fim` (m5 77,8%, 1,000 evento por mesa na planejadora) ·
`só linhas que compartilham carta` (no-op, −1%) · `só a primeira madura da mesa` (no-op) ·
`só com perpendicular em 4/5` (desliga a regra: gulosa 0,098) · a previsão de interação com o
AVESSO (nula: `J1_SEMAV` ≈ `J1`) · a previsão de que o PULSO financia a montagem da cruz
(a planejadora tem 51,3% de turnos pagos contra 64,8% da gulosa na base, e seca p90 de 8).

### O que eu NÃO medi (e não vou fingir que medi)

Loja, selos, níveis de mão, modificadores de mesa: `null`. Legibilidade da linha madura na tela
— uma linha que fica cheia e **não some** precisa de um sinal visual que esta bancada é cega para
avaliar; se o jogador não entender que aquelas 5 cartas vão embora no próximo clique, a regra
some junto com a compreensão. E não medi se o jogador **grita** quando duas linhas colhem juntas:
0,826 por mesa é a frequência, não a emoção.
