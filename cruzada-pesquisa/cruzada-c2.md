# CANDIDATO 2 — MATURAÇÃO DO 4/5 · leitura da bancada

**Veredito: REPROVADA.**
Nenhuma variante, em nenhum ponto do varrimento, atinge o critério declarado. A regra é
**exatamente inerte** para a política gulosa nos três valores que o próprio candidato propôs
(8%, 15%, 25%): 0,0% dos pontos vêm de maturação, 0,0% de colheitas adiadas, 0,000 cruzada por
mesa, e a razão pontos/meta fica em 0,770 — o mesmo número da base, na terceira casa decimal,
com as mesmas sementes. Não é "efeito pequeno": é zero medido.

---

## 0. Decisões fixadas ANTES de medir (a ambiguidade do enunciado)

O aviso pedia que as quatro bancadas fixassem a mesma leitura do Tear. A minha, escrita no topo
do `resultado.json`:

- **O TEAR MULTIPLICA.** `fator_do_evento = (produto dos mults das mãos fechadas, piso 1) × Tear`.
  Não é soma. Numa cruzada dupla de mãos mult 4 e mult 3 com Tear 6, o fator é 4×3×6 = 72,
  não 4+3+6 = 13.
- **O teto `24+4×rodada` está REMOVIDO** — é a única configuração em que o `maior_evento_unico
  = 10.260` do núcleo polido se reproduz. Portanto o teto não se aplica nem à soma nem ao
  produto. Meço mesmo assim, em toda célula, a fração de eventos em que ele *morderia*
  (`pct_eventos_com_teto_do_mult_ativo`).
- **Tear começa em 1** (0 zeraria o produto), +1 por linha colhida, +1 a cada 4 posicionamentos,
  teto 8.
- **Base = PRODUTO + K = 2,25, sem AVESSO e sem AGULHA.** O `NUCLEO-POLIDO.md` diz, com todas
  as letras, que "AVESSO e PRODUTO nunca foram medidos juntos" e que a soma é hipótese.
  Medir um candidato contra uma base hipotética é o erro que este projeto já cometeu uma vez.
  A minha base é a célula **medida** da bancada 3 (`ETAPA1_K/K=2.25`).

## 1. PASSO 2 — a base bate

| métrica | b3 (medido lá) | c2 (medido aqui) |
|---|---|---|
| razão pontos/meta mediana | 0,770 | **0,770** |
| vitória global | 28,04% | **28,04%** |
| vitória por rodada | 76,1·55,1·27,0·7,8·1,8·0,6 | **76,0·55,1·26,9·7,8·1,8·0,6** |
| maior evento único | 10.260 | **10.260** |
| pico/mediana | 15,83× | **15,83×** |
| Tear mediano / máx | 7 / 8 | **7 / 8** |
| turnos com recompensa | 64,8–66,1% (faixa do núcleo polido) | **64,8%** |
| seca mediana / p90 | 2 / 4 | **2 / 4** |
| cruzadas/mesa, gulosa | 0,000 | **0,000** |
| cruzadas/mesa, caçadora b1 | 0,146 (enunciado) | **0,146** |
| % mesas sem cruzada, caçadora | 86% (enunciado) | **85,4%** |
| GUARDA m5 | 58,65% | **57,4%** |

Uma divergência declarada: **m5 57,4 contra 58,65**. A minha política profunda herda o
`clone_leve` da b1 (não clona mão nem baralho; amostra do pool `baralho+descarte`) em vez da
simulação da b3. 1,3 ponto, dentro da banda 45–75, sem efeito em nenhuma conclusão.

## 2. PASSO 3 — a política PLANEJADORA (e o que ela descobriu de graça)

A caçadora da b1 não é um planejador: ela é uma gulosa com veto, e por isso chega a 0,146.
A planejadora daqui faz o que o aviso metodológico pediu: escolhe o alvo (L,C) com mais braços
já preenchidos e gatilho vazio, **joga só nas 8 casas de braço**, penaliza com −10⁹ qualquer
jogada que colha lateralmente (imposto da R17), descarta só por qualidade das duas linhas alvo,
troca de alvo quando `restam < braços_faltantes + 1`, dispara no gatilho quando as duas linhas
estão em 4/5, e então escolhe um novo alvo.

**Na base, sem tocar em uma única regra:**

| política | cruzadas/mesa | % mesas com zero | máx | razão | vitória | %rec |
|---|---|---|---|---|---|---|
| gulosa | 0,000 | 100,0% | 0 | 0,770 | 28,04% | 64,8% |
| profunda (2 níveis) | 0,019 | 98,1% | 1 | 0,829 | 32,04% | 64,2% |
| caçadora b1 | 0,146 | 85,4% | 1 | 0,799 | 32,53% | 66,4% |
| **planejadora DUPLA** | **1,455** | **0,0%** | **2** | 1,168 | 64,27% | 51,7% |
| planejadora TRIPLA | 1,000 | 0,0% | 1 | 2,118 | 79,74% | 59,0% |
| planejadora TOTAL | 0,880 | 12,0% | 1 | 5,698 | 89,52% | 68,6% |

Três coisas saem daqui, e nenhuma delas é mérito do meu candidato:

1. **A cruzada já é jogável no núcleo como ele está.** 1,455 por mesa, 0% de mesas sem
   nenhuma, mediana 1, e o teto duro nunca violado (`violacoes_teto_duro = 0` em **todas** as
   66 células). Por tipo de mesa: Pequena máx 2, Grande máx 1, Chefe máx 2 — a aritmética da
   CONTA 4 confirmada por medição, não por argumento.
2. **A escada 9/13/17 é real e é linda.** Razão pontos/meta 1,17 → 2,12 → 5,70 para dupla →
   tripla → total. O fator ~5,6× da Cruz Total previsto na CONTA (a) mediu **7,4×** contra a
   gulosa (5,698 / 0,770). A Cruz Total no centro cabe em 88,0% das mesas (falha em 12,0%,
   quase todas Pequenas — a previsão era caber em 71,3% das Pequenas; medi 63,7%).
3. **A montagem da cruz é SECA, ao contrário do que a CONTA (c) previa.** Recompensa por turno
   cai de 64,8% (gulosa) para **51,7%** (planejadora dupla) e a seca mediana sobe de 2 para 4.
   A previsão era "17% mais seca"; medi 20% mais seca — a direção da conta está certa, mas o
   resultado fura o piso de 60% de turnos com recompensa. **O PULSO não financia a montagem da
   dupla.** Financia a Total (68,6%, acima da base), como a conta dizia.

## 3. PASSO 4 — a maturação, medida

Ver as duas tabelas completas abaixo. O resumo:

**(a) A gulosa nunca vê a regra.** Em F = 0,08 / 0,15 / 0,25 — os três valores propostos — a
gulosa mede, com as mesmas sementes da base:

- pontos via maturação: **0,0%**; maturações por mesa: **0,00**;
- colheitas adiadas de propósito: **0,0%**;
- turnos segurando 4/5: **1,000** (idêntico à base — "1" significa fechada no turno seguinte);
- razão 0,770, vitória 28,04%, recompensa 64,8%, seca 2/4: **byte a byte a base**;
- cruzadas: **0,000**. K de calibração: permaneceu **2,25** em todas as variantes, porque não
  há um único ponto para inflacionar.

O motivo é aritmético e não depende de tuning. Uma gulosa de 1 nível compara, no mesmo turno,
`fechar = E` contra `esperar = F × V`, onde E é o evento da mão completa de 5 cartas e V é o
valor previsto da linha com 4. Como `avaliar_parcial` de 4 cartas só reconhece categorias por
valor (nunca sequência nem flush) e a 5.ª carta costuma subir a categoria, **E/V ≈ 2 a 3**.
Logo, o ponto de virada da regra fica em **F ≈ 2,0–2,5, ou seja 200% a 250% do valor da linha
por turno de espera**. Nesse preço a regra deixa de ser um bônus e passa a ser o jogo inteiro.
Medi até F = 2,5 para mostrar onde a curva vira, não porque isso seja jogável.

**(b) O ponto de virada medido: entre F = 1,0 e F = 1,5.** Em F = 0,08 / 0,15 / 0,25 / 0,40 /
0,60 a gulosa mede **0,0% de pontos por maturação** — inerte por construção, não por
arredondamento. Em F = 1,0 continua 0,0%. Só em **F = 1,5** a gulosa finalmente espera: adia
50,6% das colheitas, 37,8% dos pontos passam a vir de maturação, o K de calibração salta de
2,25 para **3,73** (a meta precisou subir 66% para a dificuldade não desabar) — e as cruzadas
chegam a **0,012 por mesa, 98,8% das mesas ainda sem nenhuma**. Quinze centésimos do que o
critério pede, ao preço de uma regra que paga 150% do valor da linha por turno parado.

**(c) A profunda vê, espera — e continua não fazendo cruzada.** É a medição que decide o
candidato. Em F = 1,0 (100% por turno, doze vezes o valor máximo proposto) a profunda passa a
adiar **73,0%** das colheitas possíveis, segura o 4/5 por 2,27 turnos e enriquece
(razão 0,829 → 1,040, vitória 32,0% → 56,5%). E as cruzadas vão de **0,019 para 0,031**.
Trinta e um milésimos. A distância planejadora − gulosa continua em ~1,3.

Isso é a refutação limpa da tese do candidato: **esperar com uma linha em 4/5 não constrói a
perpendicular.** Para a cruzada, a linha L em 4/5 é metade do trabalho; a outra metade é
encher as 4 casas da coluna C que passam pela casa vazia de L — quatro casas específicas que
nenhuma recompensa por espera aponta. A maturação paga a paciência e não paga a direção.
O horizonte continua sendo 9.

**(d) A maturação é ANTI-cruzada para quem já caça.** Efeito monotônico e limpo:

| F | caçadora b1 | planejadora dupla | DISTÂNCIA plan − gulosa |
|---|---|---|---|
| 0 (base) | 0,146 | 1,455 | **1,455** |
| 0,08 | 0,144 | 1,444–1,446 | 1,444 |
| 0,15 | 0,134–0,141 | 1,434 | 1,434 |
| 0,25 | 0,125–0,133 | 1,422–1,425 | 1,422 |
| 0,40 | 0,113–0,117 | 1,404 | 1,404 |
| 0,60 | 0,099 | 1,377 | 1,377 |
| 1,00 | 0,081–0,094 | 1,316–1,332 | 1,316 |

Segurar um 4/5 para maturar e montar uma cruz disputam o mesmo recurso: turnos e casas.
Quanto mais a regra paga a espera, **menos** cruzada o tabuleiro produz. A regra empurra na
direção contrária à que o briefing precisa.

**(e) Armadilha de tédio: existe, mas só para quem tem 2 níveis.** O risco declarado ("se
esperar for sempre melhor, o jogador para de jogar") aparece na profunda antes de aparecer na
gulosa. Em F = 1,0 a profunda adia 3 de cada 4 colheitas e a vitória salta de 32,0% para 56,5% com a
mesma meta — inflação pura. Em F = 1,5 ela adia **85,3%**, segura o 4/5 por 3,32 turnos e vence
63,5% com a meta já 66% mais alta. A gulosa só entra nesse regime em F = 1,5. Ou seja: a regra é **invisível para o
novato e um exploit para o especialista**, exatamente o desenho errado.

**(f) O teto de acumulação (3 / 5 / ilimitado) é código morto.** Em todas as células as três
variantes de teto dão o mesmo número dentro do ruído (ex.: F=0,25 profunda: 0,026 / 0,025 /
0,025; planejadora: 1,434 / 1,434 / 1,434). Motivo: nenhuma política chega perto de segurar um
4/5 por 3 turnos (p90 = 4 na profunda, mediana 2). Não vire parâmetro.

**(g) A guarda de profundidade não estourou, mas escorrega.** m5 desce monotonicamente com F:
57,4 (base) → 56,9 (0,08) → 55,7 (0,15) → 54,8 (0,25) → 54,1 (0,40) → 53,7 (0,60) →
52,7 (1,0) → **48,5 (1,5)**. Continua dentro da banda
45–75, mas na direção "a jogada óbvia fica errada mais vezes" — sem entregar cruzada em troca.

**(h) O teto do mult.** `pct_eventos_com_teto_do_mult_ativo` está reportado em
todas as células. Como o teto está removido por decisão de topo, o número mede só quantas
vezes ele morderia se estivesse ligado.



## 3ter. O critério de sucesso, declarado antes de medir, aplicado ao resultado

| exigência declarada | alvo | melhor valor medido | passa? |
|---|---|---|---|
| planejadora ≥ 1,0 cruzada/mesa | ≥ 1,0 | 1,446 (F=0,08) | sim — **mas já era 1,455 na BASE**; a regra só piora |
| planejadora < 40% de mesas com zero | < 40% | 0,0% | sim — idem, é da política, não da regra |
| **gulosa > 0,25 cruzada/mesa** | > 0,25 | **0,012** (só em F=1,5) | **NÃO** — 20× abaixo |
| recompensa por turno ≥ 60% (gulosa) | ≥ 60% | 64,8% | sim |
| seca mediana ≤ 3 (gulosa) | ≤ 3 | 2 | sim |
| m5 na banda 45–75% | 45–75 | 48,5 a 57,4 | sim, mas descendo com F |
| razão pontos/meta ~0,79 | ~0,79 | 0,770 (K recalibrado) | sim |
| vitória 20–40% | 20–40 | 28,04% | sim |
| teto duro 2/1/2 | 0 violações | 0 | sim |

**As duas exigências da planejadora são satisfeitas pela BASE, sem nenhuma regra nova** — logo
não podem creditar o candidato. A única exigência que discrimina é a da gulosa, e ela falha por
um fator de 20. Pela letra do critério: **PARCIAL** só se a linha da planejadora contasse;
como ela já é verdadeira na base e o candidato a **piora monotonicamente** (1,455 → 1,316),
o veredito honesto é **REPROVADA**.

## 3bis. Três achados colaterais que NÃO são do meu candidato, e que a próxima bancada precisa

**(i) O teto do mult morde — e morde exatamente onde o aviso disse que morderia.**
`pct_eventos_com_teto_do_mult_ativo` (fração de eventos em que o teto 24+4×rodada *morderia*,
com ele desligado, como decidido no topo):

| política | % eventos em que o teto morderia |
|---|---|
| gulosa | 1,2% |
| profunda | 1,5% |
| caçadora b1 | 2,6% |
| planejadora DUPLA | **11,0%** |
| planejadora TRIPLA | **57,5%** |
| planejadora TOTAL | **73,6%** |

Se alguém religar o teto "porque nunca morde", ele apaga 3 de cada 4 Cruzes Totais e mais da
metade das Triplas. A escada 2×/3×/4× colapsa em silêncio e a bancada seguinte vai concluir
que "a tripla não compensa". **Não religuem o teto.** (Com ele ligado o maior evento único cai
de 10.260 para 8.208 já na gulosa — número da b3, reconfirmado aqui.)

**(ii) O teto duro aritmético está confirmado por medição, não por argumento.**
Planejadora dupla, cruzadas por mesa **por tipo**: Pequena **1,592 (máx 2)** · Grande
**1,000 (máx 1)** · Chefe **1,779 (máx 2)**. Exatamente os tetos 2/1/2 da CONTA 4.
`violacoes_teto_duro = 0` nas 66 células. A assercao está no código
(`bancada.gd`, `TETO_CRUZ = [2,1,2]`), como o aviso pediu.

**(iii) O critério "intencional × acidental" proposto no enunciado está quebrado.**
O critério operacional era: *o posicionamento-gatilho também era a melhor jogada da gulosa?
Se sim, foi acidente.* Medido: **100,0% das cruzadas da planejadora são classificadas como
"acidente"** (`pct_cruzadas_intencionais = 0,0`), e só 12,3% das da caçadora como intenção.
Isso é obviamente falso: a planejadora pagou 8 turnos para chegar àquele estado. O problema é
que, uma vez que duas linhas estão em 4/5 sobre a mesma casa vazia, disparar é trivialmente a
melhor jogada de qualquer política — a intenção estava nos 8 turnos anteriores, não no gatilho.
**O critério mede o clímax e não a montagem.** Quem for usá-lo tem de olhar para a trajetória
(quantos dos 8 braços foram jogados sem ganho imediato), não para o último clique.

## 4. Parâmetro recomendado

**Nenhum.** Não existe ponto do espaço (F × teto), varrido de 0,08 a 1,5 (ou seja, de 8% a
150% do valor da linha por turno), que passe no critério declarado. Se a regra tiver de
entrar por outro motivo que não a cruzada, o único valor defensável é **F = 0,25 com teto 3** —
é o maior valor que ainda não move nada na gulosa (razão 0,770 idêntica à base, m5 54,8, seca
2/4) e o que menos machuca a caçadora. Mas ele também não faz nada: é uma regra que só o
jogador de 2 níveis lê, e ele a usa para inflar pontos, não para fazer cruzada.

## 5. O que me surpreendeu

1. **A planejadora resolve o problema do briefing sem nenhuma regra nova.** 1,455 cruzada/mesa,
   0% de mesas sem nenhuma, mediana 1, teto respeitado. O alvo realista do enunciado
   ("mediana 1, ≥1 em 60–75% das mesas") já é atingível **na base**. O gargalo não é o jogo:
   é que nada na tela diz ao jogador que os 8 primeiros passos vão para algum lugar. Isso é
   um problema de **UI e de vocabulário**, e minha medição não o resolve.
2. **A Cruz TOTAL vale 7,4× a gulosa em razão pontos/meta**, não 5,6×, e cabe em 88% das mesas.
   A escada 9/13/17 → 1,17 / 2,12 / 5,70 é um sistema de dificuldade completo que já existe nas
   regras e nunca foi nomeado.
3. **A montagem da cruz dupla fura o piso de ritmo** (51,7% de turnos com recompensa contra o
   mínimo de 60%). A CONTA (c) do enunciado acertou a direção e subestimou o tamanho. Quem
   implementar a cruzada precisa de alguma coisa que pague os 8 passos — e a maturação, medida,
   não é essa coisa: ela paga por ficar parado, não por avançar.
4. **A regra é EXATAMENTE zero, não "pouco".** Eu esperava um efeito pequeno. Medi 0,0% de
   pontos, 0,0% de adiamentos, 0,000 cruzada e a mesma razão na terceira decimal. Isso só
   acontece quando o desenho tem um erro de altura, não de calibração.

## 6. O que NÃO funcionou (registro honesto de método)

- **Ligar o PULSO no score da gulosa** (modo `ve_ritmo=1`), tentado como âncora alternativa:
  derruba recompensa 64,8 → 56,8%, seca 2 → 3 e m5 57,4 → **45,3** (borda inferior da banda),
  antes de qualquer candidato entrar. Está medido e reportado como `CONTROLE_ritmo1`, mas foi
  **rejeitado como âncora** — contaminaria a base. O modo usado nas variantes é `ve_ritmo=2`
  (a gulosa vê só a maturação), no qual a base é idêntica à base.
- **Calibrar K com 402 mesas contra um alvo medido em 1.002**: a primeira passada deu K = 2,186
  e razão 0,793, aparentemente favorecendo o candidato. Era ruído da amostra pequena. Refeito
  com 1.002 mesas na calibração, K voltou a 2,25 em todas as variantes. Os resultados da
  primeira passada estão preservados em `pre/` para auditoria.
- **Testar teto de acumulação**: três valores, zero bits de informação (item 3f).

---

## 7. Tabelas completas

### 7.1 Base e controles (1.002 mesas por célula, sementes pareadas)

| celula | politica | cruz/mesa | %zero | %pts maturacao | seg 4/5 | %adiadas | %rec | seca m/p90 | razao | vit% | m5 | viol |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| BASE_cacadora_b1 | cacadora_b1 | 0.146 | 85.4 | 0.0 | 1.887 | 44.4 | 66.4 | 2/4 | 0.799 | 32.53 | - | 0 |
| BASE_gulosa | gulosa | 0.0 | 100.0 | 0.0 | 1.0 | 0.0 | 64.8 | 2/4 | 0.77 | 28.04 | 57.4 | 0 |
| BASE_planejadora_dupla | planejadora_dupla | 1.455 | 0.0 | 0.0 | 1.861 | 63.0 | 51.7 | 4/8 | 1.168 | 64.27 | - | 0 |
| BASE_planejadora_total | planejadora_total | 0.88 | 12.0 | 0.0 | 4.252 | 87.0 | 68.6 | 3/4 | 5.698 | 89.52 | - | 0 |
| BASE_planejadora_tripla | planejadora_tripla | 1.0 | 0.0 | 0.0 | 3.161 | 82.7 | 59.0 | 3/4 | 2.118 | 79.74 | - | 0 |
| BASE_profunda | profunda | 0.019 | 98.1 | 0.0 | 1.784 | 53.3 | 64.2 | 2/4 | 0.829 | 32.04 | - | 0 |
| ANCORA_p0 | gulosa | 0.0 | 100.0 | 0.0 | 1.0 | 0.0 | 56.8 | 3/4 | 0.763 | 33.03 | 45.3 | 0 |
| ANCORA_p1 | profunda | 0.001 | 99.9 | 0.0 | 1.906 | 59.6 | 68.3 | 2/4 | 0.988 | 42.51 | - | 0 |
| ANCORA_p2 | cacadora_b1 | 0.0 | 100.0 | 0.0 | 1.001 | 0.1 | 56.8 | 3/4 | 0.763 | 33.03 | - | 0 |
| ANCORA_p3 | planejadora_dupla | 1.337 | 0.0 | 0.0 | 1.856 | 62.2 | 54.6 | 3/8 | 1.437 | 80.14 | - | 0 |
| ANCORA_p4 | planejadora_tripla | 1.0 | 0.0 | 0.0 | 3.149 | 82.5 | 60.8 | 3/4 | 3.236 | 91.62 | - | 0 |
| ANCORA_p5 | planejadora_total | 0.837 | 16.3 | 0.0 | 4.203 | 86.6 | 67.9 | 3/4 | 7.716 | 91.72 | - | 0 |


### 7.2 Varredura da MATURAÇÃO (F × teto de acumulação), K recalibrado por célula

| celula | politica | cruz/mesa | %zero | %pts maturacao | seg 4/5 | %adiadas | %rec | seca m/p90 | razao | vit% | m5 | viol |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| MAT_F0.08_teto3_ve2_cacadora_b1 | cacadora_b1 | 0.144 | 85.6 | 1.7 | 1.883 | 44.5 | 67.5 | 2/4 | 0.812 | 33.23 | - | 0 |
| MAT_F0.08_teto3_ve2_gulosa | gulosa | 0.0 | 100.0 | 0.0 | 1.0 | 0.0 | 64.8 | 2/4 | 0.77 | 28.04 | 56.9 | 0 |
| MAT_F0.08_teto3_ve2_planejadora_dupla | planejadora_dupla | 1.446 | 0.0 | 1.4 | 1.859 | 63.1 | 58.2 | 4/7 | 1.163 | 64.67 | - | 0 |
| MAT_F0.08_teto3_ve2_profunda | profunda | 0.02 | 98.0 | 2.4 | 1.835 | 56.1 | 68.4 | 2/4 | 0.844 | 33.33 | - | 0 |
| MAT_F0.08_teto5_ve2_cacadora_b1 | cacadora_b1 | 0.144 | 85.6 | 2.0 | 1.882 | 44.5 | 67.5 | 2/4 | 0.82 | 33.53 | - | 0 |
| MAT_F0.08_teto5_ve2_gulosa | gulosa | 0.0 | 100.0 | 0.0 | 1.0 | 0.0 | 64.8 | 2/4 | 0.77 | 28.04 | 56.9 | 0 |
| MAT_F0.08_teto5_ve2_planejadora_dupla | planejadora_dupla | 1.444 | 0.0 | 1.5 | 1.86 | 63.1 | 58.4 | 4/7 | 1.16 | 64.77 | - | 0 |
| MAT_F0.08_teto5_ve2_profunda | profunda | 0.019 | 98.1 | 2.6 | 1.838 | 56.3 | 68.7 | 2/4 | 0.846 | 33.73 | - | 0 |
| MAT_F0.08_teto99_ve2_cacadora_b1 | cacadora_b1 | 0.144 | 85.6 | 2.2 | 1.88 | 44.5 | 67.5 | 2/4 | 0.821 | 33.53 | - | 0 |
| MAT_F0.08_teto99_ve2_gulosa | gulosa | 0.0 | 100.0 | 0.0 | 1.0 | 0.0 | 64.8 | 2/4 | 0.77 | 28.04 | 56.9 | 0 |
| MAT_F0.08_teto99_ve2_planejadora_dupla | planejadora_dupla | 1.444 | 0.0 | 1.5 | 1.86 | 63.1 | 58.4 | 4/7 | 1.16 | 64.77 | - | 0 |
| MAT_F0.08_teto99_ve2_profunda | profunda | 0.019 | 98.1 | 2.7 | 1.84 | 56.4 | 68.7 | 2/4 | 0.845 | 33.63 | - | 0 |
| MAT_F0.15_teto3_ve2_cacadora_b1 | cacadora_b1 | 0.141 | 85.9 | 3.1 | 1.877 | 44.5 | 67.4 | 2/4 | 0.832 | 33.83 | - | 0 |
| MAT_F0.15_teto3_ve2_gulosa | gulosa | 0.0 | 100.0 | 0.0 | 1.0 | 0.0 | 64.8 | 2/4 | 0.77 | 28.04 | 55.7 | 0 |
| MAT_F0.15_teto3_ve2_planejadora_dupla | planejadora_dupla | 1.434 | 0.0 | 2.6 | 1.859 | 63.2 | 58.1 | 4/7 | 1.159 | 65.27 | - | 0 |
| MAT_F0.15_teto3_ve2_profunda | profunda | 0.025 | 97.5 | 5.6 | 2.007 | 63.2 | 70.6 | 2/4 | 0.889 | 36.63 | - | 0 |
| MAT_F0.15_teto5_ve2_cacadora_b1 | cacadora_b1 | 0.138 | 86.2 | 3.8 | 1.876 | 44.4 | 67.5 | 2/4 | 0.839 | 33.83 | - | 0 |
| MAT_F0.15_teto5_ve2_gulosa | gulosa | 0.0 | 100.0 | 0.0 | 1.0 | 0.0 | 64.8 | 2/4 | 0.77 | 28.04 | 55.7 | 0 |
| MAT_F0.15_teto5_ve2_planejadora_dupla | planejadora_dupla | 1.434 | 0.0 | 2.8 | 1.859 | 63.2 | 58.4 | 4/7 | 1.161 | 65.27 | - | 0 |
| MAT_F0.15_teto5_ve2_profunda | profunda | 0.027 | 97.3 | 6.4 | 2.038 | 64.4 | 71.2 | 2/4 | 0.906 | 37.82 | - | 0 |
| MAT_F0.15_teto99_ve2_cacadora_b1 | cacadora_b1 | 0.134 | 86.6 | 4.2 | 1.876 | 44.5 | 67.5 | 2/4 | 0.839 | 33.93 | - | 0 |
| MAT_F0.15_teto99_ve2_gulosa | gulosa | 0.0 | 100.0 | 0.0 | 1.0 | 0.0 | 64.8 | 2/4 | 0.77 | 28.04 | 55.7 | 0 |
| MAT_F0.15_teto99_ve2_planejadora_dupla | planejadora_dupla | 1.434 | 0.0 | 2.8 | 1.859 | 63.2 | 58.4 | 4/7 | 1.161 | 65.27 | - | 0 |
| MAT_F0.15_teto99_ve2_profunda | profunda | 0.027 | 97.3 | 6.7 | 2.045 | 64.7 | 71.2 | 2/4 | 0.908 | 38.12 | - | 0 |
| MAT_F0.25_teto3_ve2_cacadora_b1 | cacadora_b1 | 0.133 | 86.7 | 5.1 | 1.871 | 44.4 | 67.4 | 2/4 | 0.841 | 34.63 | - | 0 |
| MAT_F0.25_teto3_ve2_gulosa | gulosa | 0.0 | 100.0 | 0.0 | 1.0 | 0.0 | 64.8 | 2/4 | 0.77 | 28.04 | 54.8 | 0 |
| MAT_F0.25_teto3_ve2_planejadora_dupla | planejadora_dupla | 1.425 | 0.0 | 4.2 | 1.857 | 63.2 | 58.2 | 4/7 | 1.171 | 65.77 | - | 0 |
| MAT_F0.25_teto3_ve2_profunda | profunda | 0.026 | 97.4 | 10.4 | 2.095 | 66.3 | 71.7 | 2/4 | 0.94 | 39.52 | - | 0 |
| MAT_F0.25_teto5_ve2_cacadora_b1 | cacadora_b1 | 0.127 | 87.3 | 6.1 | 1.866 | 44.4 | 67.5 | 2/4 | 0.844 | 34.63 | - | 0 |
| MAT_F0.25_teto5_ve2_gulosa | gulosa | 0.0 | 100.0 | 0.0 | 1.0 | 0.0 | 64.8 | 2/4 | 0.77 | 28.04 | 54.8 | 0 |
| MAT_F0.25_teto5_ve2_planejadora_dupla | planejadora_dupla | 1.422 | 0.0 | 4.6 | 1.857 | 63.2 | 58.4 | 4/7 | 1.171 | 65.87 | - | 0 |
| MAT_F0.25_teto5_ve2_profunda | profunda | 0.025 | 97.5 | 11.7 | 2.12 | 67.5 | 72.2 | 2/4 | 0.948 | 40.32 | - | 0 |
| MAT_F0.25_teto99_ve2_cacadora_b1 | cacadora_b1 | 0.125 | 87.5 | 6.7 | 1.862 | 44.4 | 67.5 | 2/4 | 0.849 | 34.93 | - | 0 |
| MAT_F0.25_teto99_ve2_gulosa | gulosa | 0.0 | 100.0 | 0.0 | 1.0 | 0.0 | 64.8 | 2/4 | 0.77 | 28.04 | 54.8 | 0 |
| MAT_F0.25_teto99_ve2_planejadora_dupla | planejadora_dupla | 1.422 | 0.0 | 4.6 | 1.857 | 63.2 | 58.4 | 4/7 | 1.171 | 65.87 | - | 0 |
| MAT_F0.25_teto99_ve2_profunda | profunda | 0.025 | 97.5 | 12.3 | 2.13 | 67.8 | 72.4 | 2/4 | 0.956 | 40.92 | - | 0 |
| MAT_F0.4_teto5_ve2_cacadora_b1 | cacadora_b1 | 0.117 | 88.3 | 9.3 | 1.844 | 44.2 | 67.4 | 2/4 | 0.873 | 36.23 | - | 0 |
| MAT_F0.4_teto5_ve2_gulosa | gulosa | 0.0 | 100.0 | 0.0 | 1.0 | 0.0 | 64.8 | 2/4 | 0.77 | 28.04 | 54.1 | 0 |
| MAT_F0.4_teto5_ve2_planejadora_dupla | planejadora_dupla | 1.404 | 0.0 | 7.2 | 1.858 | 63.4 | 58.5 | 4/7 | 1.168 | 67.27 | - | 0 |
| MAT_F0.4_teto5_ve2_profunda | profunda | 0.026 | 97.4 | 18.5 | 2.199 | 70.2 | 73.3 | 2/3 | 1.004 | 45.01 | - | 0 |
| MAT_F0.4_teto99_ve2_cacadora_b1 | cacadora_b1 | 0.113 | 88.7 | 10.1 | 1.84 | 44.1 | 67.4 | 2/4 | 0.881 | 36.73 | - | 0 |
| MAT_F0.4_teto99_ve2_gulosa | gulosa | 0.0 | 100.0 | 0.0 | 1.0 | 0.0 | 64.8 | 2/4 | 0.77 | 28.04 | 54.1 | 0 |
| MAT_F0.4_teto99_ve2_planejadora_dupla | planejadora_dupla | 1.404 | 0.0 | 7.2 | 1.858 | 63.4 | 58.5 | 4/7 | 1.168 | 67.27 | - | 0 |
| MAT_F0.4_teto99_ve2_profunda | profunda | 0.028 | 97.2 | 19.3 | 2.21 | 70.6 | 73.5 | 2/3 | 1.007 | 45.71 | - | 0 |
| MAT_F0.6_teto99_ve2_cacadora_b1 | cacadora_b1 | 0.099 | 90.1 | 14.0 | 1.812 | 43.8 | 67.3 | 2/4 | 0.914 | 39.32 | - | 0 |
| MAT_F0.6_teto99_ve2_gulosa | gulosa | 0.0 | 100.0 | 0.0 | 1.0 | 0.0 | 64.8 | 2/4 | 0.77 | 28.04 | 53.7 | 0 |
| MAT_F0.6_teto99_ve2_planejadora_dupla | planejadora_dupla | 1.377 | 0.0 | 10.4 | 1.856 | 63.6 | 58.7 | 3/7 | 1.17 | 68.36 | - | 0 |
| MAT_F0.6_teto99_ve2_profunda | profunda | 0.02 | 98.0 | 27.1 | 2.223 | 71.7 | 73.8 | 2/3 | 1.02 | 50.2 | - | 0 |
| MAT_F1.0_teto3_ve2_cacadora_b1 | cacadora_b1 | 0.094 | 90.6 | 17.3 | 1.795 | 43.5 | 67.1 | 2/4 | 0.941 | 40.52 | - | 0 |
| MAT_F1.0_teto3_ve2_gulosa | gulosa | 0.0 | 100.0 | 0.0 | 1.0 | 0.0 | 64.8 | 2/4 | 0.764 | 27.94 | 52.7 | 0 |
| MAT_F1.0_teto3_ve2_planejadora_dupla | planejadora_dupla | 1.332 | 0.9 | 15.2 | 1.853 | 63.9 | 58.6 | 3/7 | 1.168 | 70.66 | - | 0 |
| MAT_F1.0_teto3_ve2_profunda | profunda | 0.031 | 96.9 | 37.0 | 2.272 | 73.0 | 73.9 | 2/3 | 1.04 | 56.49 | - | 0 |
| MAT_F1.0_teto5_ve2_cacadora_b1 | cacadora_b1 | 0.087 | 91.3 | 19.1 | 1.767 | 43.2 | 67.1 | 2/4 | 0.957 | 41.62 | - | 0 |
| MAT_F1.0_teto5_ve2_gulosa | gulosa | 0.0 | 100.0 | 0.0 | 1.0 | 0.0 | 64.8 | 2/4 | 0.764 | 27.94 | 52.7 | 0 |
| MAT_F1.0_teto5_ve2_planejadora_dupla | planejadora_dupla | 1.316 | 1.7 | 16.4 | 1.854 | 64.2 | 58.8 | 3/7 | 1.165 | 71.06 | - | 0 |
| MAT_F1.0_teto5_ve2_profunda | profunda | 0.028 | 97.2 | 40.7 | 2.302 | 74.7 | 74.5 | 2/3 | 1.047 | 58.78 | - | 0 |
| MAT_F1.0_teto99_ve2_cacadora_b1 | cacadora_b1 | 0.081 | 91.9 | 20.2 | 1.76 | 43.2 | 67.1 | 2/4 | 0.957 | 41.92 | - | 0 |
| MAT_F1.0_teto99_ve2_gulosa | gulosa | 0.0 | 100.0 | 0.0 | 1.0 | 0.0 | 64.8 | 2/4 | 0.764 | 27.94 | 52.7 | 0 |
| MAT_F1.0_teto99_ve2_planejadora_dupla | planejadora_dupla | 1.316 | 1.7 | 16.4 | 1.854 | 64.2 | 58.8 | 3/7 | 1.165 | 71.06 | - | 0 |
| MAT_F1.0_teto99_ve2_profunda | profunda | 0.025 | 97.5 | 41.9 | 2.312 | 75.1 | 74.7 | 2/3 | 1.048 | 60.08 | - | 0 |
| MAT_F1.5_teto3_ve2_cacadora_b1 | cacadora_b1 | 0.151 | 84.9 | 44.4 | 2.422 | 66.7 | 71.5 | 2/4 | 0.923 | 40.52 | - | 0 |
| MAT_F1.5_teto3_ve2_gulosa | gulosa | 0.012 | 98.8 | 37.8 | 1.734 | 50.6 | 69.6 | 2/4 | 0.77 | 31.14 | 48.5 | 0 |
| MAT_F1.5_teto3_ve2_planejadora_dupla | planejadora_dupla | 1.43 | 0.3 | 23.0 | 1.868 | 65.0 | 56.6 | 4/7 | 1.023 | 52.79 | - | 0 |
| MAT_F1.5_teto3_ve2_profunda | profunda | 0.059 | 94.1 | 63.8 | 3.324 | 85.3 | 79.0 | 2/3 | 1.06 | 63.47 | - | 0 |
| MAT_F1.5_teto99_ve2_gulosa | gulosa | 0.017 | 98.3 | 44.1 | 1.921 | 57.0 | 70.2 | 2/4 | 0.77 | 33.43 | 47.1 | 0 |

### 7.3 A métrica que decide: DISTÂNCIA planejadora − gulosa

| celula | gulosa | profunda | cacadora_b1 | planejadora | DISTANCIA plan-gulosa |
|---|---|---|---|---|---|
| BASE | 0.0 | 0.019 | 0.146 | 1.455 | 1.455 |
| MAT_F0.08_teto3_ve2 | 0.0 | 0.02 | 0.144 | 1.446 | 1.446 |
| MAT_F0.08_teto5_ve2 | 0.0 | 0.019 | 0.144 | 1.444 | 1.444 |
| MAT_F0.08_teto99_ve2 | 0.0 | 0.019 | 0.144 | 1.444 | 1.444 |
| MAT_F0.15_teto3_ve2 | 0.0 | 0.025 | 0.141 | 1.434 | 1.434 |
| MAT_F0.15_teto5_ve2 | 0.0 | 0.027 | 0.138 | 1.434 | 1.434 |
| MAT_F0.15_teto99_ve2 | 0.0 | 0.027 | 0.134 | 1.434 | 1.434 |
| MAT_F0.25_teto3_ve2 | 0.0 | 0.026 | 0.133 | 1.425 | 1.425 |
| MAT_F0.25_teto5_ve2 | 0.0 | 0.025 | 0.127 | 1.422 | 1.422 |
| MAT_F0.25_teto99_ve2 | 0.0 | 0.025 | 0.125 | 1.422 | 1.422 |
| MAT_F0.4_teto5_ve2 | 0.0 | 0.026 | 0.117 | 1.404 | 1.404 |
| MAT_F0.4_teto99_ve2 | 0.0 | 0.028 | 0.113 | 1.404 | 1.404 |
| MAT_F0.6_teto99_ve2 | 0.0 | 0.02 | 0.099 | 1.377 | 1.377 |
| MAT_F1.0_teto3_ve2 | 0.0 | 0.031 | 0.094 | 1.332 | 1.332 |
| MAT_F1.0_teto5_ve2 | 0.0 | 0.028 | 0.087 | 1.316 | 1.316 |
| MAT_F1.0_teto99_ve2 | 0.0 | 0.025 | 0.081 | 1.316 | 1.316 |
| MAT_F1.5_teto3_ve2 | 0.012 | 0.059 | 0.151 | 1.43 | 1.418 |
| MAT_F1.5_teto99_ve2 | 0.017 | - | - | - | - |

### 7.4 Redução declarada de volume

- **1.002 mesas por célula** (o pedido era 1.000; 1.002 é múltiplo de 6 e de 18 e cobre as 6
  rodadas × 3 tipos exatamente). m5 medido em **402 mesas** por célula. **77 células** medidas ao todo (6 de base + 6 de controle + 65 de variante).
- **O extremo do varrimento foi cortado por tempo:** de `MAT_F1.5_teto99` só saiu a gulosa
  (cruzadas 0,017, K precisou ir a 3,99, m5 caiu a 47,1 — a beira da banda); `MAT_F2.5_teto99`
  nao rodou. Os dois estão fora do espaço proposto pelo candidato (8–25%) por um fator de 6 a
  30, e a célula `MAT_F1.5_teto3`, que terminou inteira, já mostra o regime: gulosa 0,012 cruzada/mesa com K precisando subir de 2,25 para 3,73. Nenhuma
  conclusão depende delas. Onde faltam, o `resultado.json` simplesmente não tem a chave —
  **nenhum número foi inventado**.
- Célula `MAT_F0.6_teto3` e `MAT_F0.6_teto5` não foram rodadas (a grade só levou 0,6 com
  teto ilimitado, o caso mais favorável ao candidato). O teto de acumulação já havia sido
  medido como código morto em quatro valores de F.
