# BANCADA CANDIDATO 3 — SEMEAR MAIS O TABULEIRO

**VEREDITO: REPROVADA.**

Motor: `nucleo.gd` da sonda (avaliador de 5 cartas **intocado**) + `mesa2.gd` da b1 (PULSO 0,35,
TIQUE 4, AVESSO) + o PRODUTO/K do núcleo polido + semeadura parametrizada. Políticas:
gulosa, profunda (2 níveis), caçadora (a da b1, reaproveitada sem mudar) e **PLANEJADORA**
(nova, escrita aqui). 1.000 mesas por célula **por política**, m5 em 500, sementes pareadas
com a base (`31337 + t·7919`, rodada `t%6+1`, tipo `(t/6)%3`), 6 rodadas × 3 tipos em todas
as células. 30 células de varredura + base + escada. Nenhum número aqui é estimado.

---

## 0. AS DECISÕES QUE TIVERAM DE SER FIXADAS ANTES DE MEDIR

**A ambiguidade do TEAR.** Fixado: `fator_do_evento = (PRODUTO dos mults das mãos fechadas) ×
Tear`; o teto `24+4×rodada` **sai** (E3); Tear começa em 1, +1 por linha colhida, +1 a cada 4
posicionamentos, teto 8; o PULSO e a colheita final usam `max(1,mult) × Tear`. **Não é escolha
estética: é a única leitura que reproduz os números declarados da base** — maior evento único
**10.260** e pico/mediana **15,64×**. A leitura aditiva (`soma_mult + Tear`) dá 2.394 e 7,2×,
que são os números pré-produto da b1. Consequência que precisa ir para o texto do jogo: sob
essa leitura uma cruzada dupla **não** vale 2× — vale `mult1 × mult2 × Tear`, e a escada medida
na seção 4 é 1× / 3,1× / 7,3×, não 2×/3×/4×.

**Colisão de semeadura.** Decidido antes de rodar: linha que nasce cheia é colhida antes do
turno 1, pontua normal, sobe o Tear, forja Avesso, e é contada em `eventos_fantasma_por_mesa` /
`cruzadas_fantasma_por_mesa` — **fora** de `cruzadas_por_mesa`. Cascatas resolvidas em laço.
Medido: fantasmas ≈ 0,003/mesa no pior caso (S=12 aleatório) — o problema previsto no aviso
não apareceu neste desenho porque o viés de cruz nunca enche uma linha e o aleatório raramente.

**Material.** Cada S foi medido em dois modos: **conserva** (posicionamentos reduzidos em S,
cartas/mesa constantes: Pequena 18, Grande 17, Chefe 19 — a única comparação honesta) e
**solto** (orçamento intacto, material cresce — medido só para exibir o falso positivo).
`cruzadas_por_carta` está em todas as células.

**K recalibrado por célula** até a razão pontos/meta da gulosa voltar a ~0,79, antes de
qualquer comparação. K da base = **2,173**; K das variantes vai de 0,764 a 3,893.

**Teto duro no código.** `cruzadas <= floor((posic + sementes)/9)` com `push_error`.
`violacoes_teto_duro == 0` em **todas** as 136 células-política medidas (30 células × 4 políticas + base × 4 + escada 4 × 3).

---

## 1. A BASE, REPRODUZIDA (K=2,173)

| métrica | declarado | medido aqui | ok |
|---|---|---|---|
| cruzadas/mesa gulosa | 0,000 | **0,000** | ✔ |
| cruzadas/mesa caçadora (b1) | 0,146 | **0,144** | ✔ |
| mesas com zero (caçadora) | 86% | **85,6%** | ✔ |
| turnos com recompensa | 65,7% | **64,8%** | ✔ |
| seca mediana / p90 | 2 / 4 | **2 / 4** | ✔ |
| razão pontos/meta | 0,79 | **0,799** | ✔ |
| vitória global | 28,8% | **31,1%** (banda 20–40) | ✔ |
| m5 (guarda de profundidade) | 58,8% | **59,0%** | ✔ |
| Tear mediano / máx | 8 | **7 / 8** | ✔ |
| maior evento único | 10.260 | **10.260** | ✔ |
| pico/mediana | 15,8× | **15,64×** | ✔ |

Onze pontos, onze acertos. A base está reproduzida e a comparação vale.

## 2. A PLANEJADORA — e a primeira surpresa, que não é sobre o meu candidato

Escrita como o aviso metodológico exige: escolhe o alvo de cruz (L,C) de **menor custo restante
que ainda cabe no orçamento**, com penalidade para braços cuja perpendicular já está em 4/5
(o imposto da R17); só joga nas 8 casas de braço; **nunca fecha nada durante a montagem**;
dispara na interseção; desiste do alvo quando `custo > posicionamentos restantes`; descarta só
por qualidade das duas linhas alvo. Ela é um planejador de verdade, não a gulosa-com-veto da b1.

**Na BASE, sem semear coisa nenhuma:**

| política | cruz/mesa | mesas com zero | máx | Pequena | Grande | Chefe |
|---|---|---|---|---|---|---|
| gulosa | 0,000 | 100% | 0 | 0,000 | 0,000 | 0,000 |
| profunda (2 níveis) | 0,005 | 99,5% | 1 | 0,003 | 0,003 | 0,009 |
| caçadora (b1) | 0,144 | 85,6% | 1 | 0,226 | 0,084 | 0,121 |
| **planejadora** | **1,437** | **0,0%** | **2** | **1,563** | **1,000** | **1,752** |

A Grande dá **exatamente 1,000 cruzada por mesa, em 100% das mesas** — o teto aritmético
declarado (Grande = 1), batido na casa decimal, por 334 mesas independentes. Isso é a
confirmação empírica da CONTA 1/CONTA 4 do briefing e a validação mais forte que consegui do
meu próprio planejador.

**E é o resultado que redefine o problema: o núcleo já suporta 1,44 cruzadas por mesa e 100%
de cobertura, hoje, sem uma linha de regra nova.** A cruzada não é inalcançável — ela é
invisível. Isso significa que o meu candidato entra num tabuleiro que já está no teto: não há
o que semear que aumente o número da planejadora, só o que estragar.

Termômetros novos, na base: `turnos_segurando_4_5` = **0,94** na gulosa (p90 = 1: ela nunca
espera) contra **1,82** (p90 4) na planejadora; `pct_colheitas_adiadas_de_proposito` = **0,0%**
na gulosa contra **62,6%** na planejadora. A doença tem termômetro agora.

## 3. A VARREDURA — 30 células, e o candidato não move a gulosa

Modo **conserva** (cartas/mesa constantes). Bandas avaliadas na gulosa.

| célula | K | gulosa | profunda | caçadora | planejadora | rec% | seca | m5 | vit% | veredito |
|---|---|---|---|---|---|---|---|---|---|---|
| **BASE (S=3 hoje)** | 2,173 | **0,000** | 0,005 | 0,144 | **1,437** | 64,8 | 2/4 | 59,0 | 31,1 | (PARCIAL) |
| S3 aleatório | 2,136 | 0,000 | 0,018 | 0,202 | 1,455 | 73,4 | 2/3 | 64,5 | 30,2 | PARCIAL |
| S6 aleatório | 1,746 | 0,000 | 0,042 | 0,311 | 1,438 | 83,9 | 1/2 | 60,2 | 28,7 | PARCIAL |
| S8 aleatório | 1,402 | 0,000 | 0,031 | 0,285 | 1,372 | 87,6 | 1/2 | 55,9 | 26,5 | PARCIAL |
| S10 aleatório | 1,092 | 0,001 | 0,029 | 0,321 | 1,192 | 92,0 | 0/1 | 52,3 | 29,4 | PARCIAL |
| S12 aleatório | 0,860 | 0,017 | 0,046 | 0,300 | 1,036 | 94,5 | 0/1 | 49,8 | 25,0 | PARCIAL |
| S3 cruz | 2,190 | 0,000 | 0,024 | 0,164 | 1,469 | 73,0 | 2/3 | 62,6 | 28,2 | PARCIAL |
| S6 cruz | 1,540 | 0,000 | 0,085 | 0,438 | 1,593 | 76,8 | 1/3 | 56,0 | 30,7 | PARCIAL |
| **S8 cruz** | 1,247 | **1,000** | 0,976 | 1,001 | 1,594 | **58,9** | 2/4 | 58,3 | 29,0 | REPROVADA (rec) |
| **S10 cruz** | 1,085 | **1,000** | 0,931 | 1,000 | 1,584 | 71,9 | 1/2 | 68,5 | 29,6 | (fabricada) |
| **S12 cruz** | 0,820 | **0,986** | 0,762 | 1,005 | 1,547 | 82,7 | 1/2 | 64,6 | 31,8 | (fabricada) |
| S3 diagonais | 1,888 | 0,000 | 0,018 | 0,160 | 1,425 | 73,0 | 2/3 | 60,1 | 31,1 | PARCIAL |
| S6 diagonais | 1,458 | 0,000 | 0,083 | 0,553 | 1,368 | 78,5 | 1/3 | 55,7 | 32,9 | PARCIAL |
| **S8 diagonais** | 1,074 | **1,000** | 0,914 | 1,000 | 1,315 | **59,0** | 2/3 | 59,6 | 31,3 | REPROVADA (rec) |
| S10 diagonais | 0,985 | 0,000 | 0,000 | 0,001 | **0,620** | **59,8** | 2/3 | 64,5 | 29,5 | REPROVADA |
| S12 diagonais | 0,764 | 0,000 | 0,000 | 0,002 | **0,462** | 71,0 | 1/2 | **73,8** | 29,7 | REPROVADA |

(As 15 células do modo **solto** estão em `resultado.json`; todas sobem por inflação de
material — S12 cruz solto chega a 2,653 cruzadas/mesa e **máx 3**, que não é bug: com 27 cartas
na Pequena o teto aritmético sobe legitimamente para 3. É exatamente o falso positivo (i) do
briefing e por isso o modo solto não decide nada.)

### 3.1 O número que mata o candidato

Nas quatro células em que a gulosa passa de 0,25 — e só nelas — o jogador **pagou 1,00 das 9
casas da figura**:

| célula | gulosa cruz/mesa | braços pagos pelo jogador (de 9) | cruzadas com ≥8 pagas |
|---|---|---|---|
| S8 cruz | 1,000 | **1,00** | **0,0%** |
| S10 cruz | 1,000 | **1,00** | 0,0% |
| S12 cruz | 0,986 | **1,00** | 0,0% |
| S8 diagonais | 1,000 | **1,00** | 0,0% |
| — BASE, planejadora | 1,437 | **8,34** | **76,6%** |

Com 8 sementes enviesadas para uma cruz, a semeadura **põe os 8 braços** e a cruzada é o
primeiro clique do turno 1, em 100% das mesas. Isso não é o jogo encurtando o horizonte; é a
bancada medindo a própria semeadura. O briefing previu esse falso positivo com precisão e ele
apareceu exatamente onde disse que apareceria.

E o efeito é gradual e destrutivo mesmo onde não é grosseiro: os braços pagos **pela
planejadora** caem de 8,34 (base) para 7,10 (S3 aleat.), 4,83 (S8 aleat.), 3,27 (S12 aleat.),
2,41 (S12 cruz). Quanto mais eu semeio, menos do evento é do jogador.

### 3.2 O experimento limpo do horizonte — e a notícia útil para as outras bancadas

**S6 cruz** é o teste que o critério 1 do briefing pede, sem fabricar a resposta: 6 dos 8
braços vêm semeados, então a cruzada está a **3 turnos** de distância (2 braços + gatilho),
com o alvo já desenhado no tabuleiro.

**Gulosa: 0,000. Profunda de 2 níveis: 0,085** (contra 0,005 na base).

Encurtar o horizonte de 9 para 3 **com material** não conserta nada. Os 3 degraus continuam
pagando zero, e um otimizador local continua sem subir uma escada de zeros, mesmo que ela agora
tenha 3 degraus em vez de 9. **O horizonte só vira 1 quando a semeadura entrega a cruz pronta.**
Corolário que eu entrego para os candidatos 2 e 4: reduzir a contagem de turnos é necessário e
não é suficiente — os degraus intermediários precisam **pagar**, não apenas ser poucos.

### 3.3 O que a semeadura estraga

- **O Tear desaba**: 7/8 na base → 6/7 (S6) → 5/6 (S10) → **4/5** (S12), porque o tique é por
  posicionamento e o modo conserva tira posicionamentos. A mesa de S=12 tem 6 a 7 turnos.
- **O ritmo vira ruído**: recompensa 64,8% → **94,5%**, seca mediana 2 → **0**. Parece bom e não
  é: quase todo turno paga um trocado porque o tabuleiro já está denso, e o PULSO perde o papel
  de sinal.
- **A guarda de profundidade anda para os dois lados**: cai a 49,8% (S12 aleatório, a 5 pontos
  do piso) e sobe a **73,8%** (S12 diagonais, a 1,2 ponto do teto de 75). As duas pontas da
  banda são tocadas pelo mesmo candidato, com parâmetros diferentes.
- **O viés diagonal é o pior de todos**: com S≥10 a planejadora **cai** para 0,62 e 0,46, com
  38% e 54% de mesas em zero. As sementes ocupam casas que pertencem às cruzes de linha/coluna
  e pagam 60%; elas atrapalham mais do que ajudam.

## 4. A ESCADA 9/13/17 — medida pela primeira vez (bônus, na BASE)

Três planejadores puros, um por figura, 1.000 mesas cada, K recalibrado.

| figura | posic. | cruz/mesa | mesas com zero | evento mediano | maior evento | razão/meta | vitória | casas pagas |
|---|---|---|---|---|---|---|---|---|
| colheita simples (gulosa) | 5 | — | — | 656 | 10.260 | 0,799 | 31,1% | — |
| **DUPLA** | 9 | 1,437 | 0,0% | **2.484** | 30.240 | 1,18 | 64,7% | 8,34 / 9 |
| **TRIPLA** | 13 | 1,000 | 0,0% | **7.603** | 80.774 | 2,22 | 80,1% | 12,13 / 13 |
| **CRUZ TOTAL** | 17 | 0,877 | 12,3% | **18.201** | 190.208 | 5,55 | 88,3% | 16,41 / 17 |

A Cruz Total cabe mesmo numa Grande e a planejadora dedicada a monta em **87,7% das mesas**,
pagando 16,41 das 17 casas. A escada existe, é jogável, e ninguém tinha medido.

**Mas ela está desregulada, e o culpado é a leitura do TEAR fixada na seção 0.** A escada de
valor medida, em evento mediano, é: colheita simples 656 → dupla **3,8×** → tripla **11,6×** →
Cruz Total **27,7×**. Entre as figuras da escada isso é **1× / 3,1× / 7,3×**, não 2×/3×/4×,
porque o produto de 3 e 4 mults explode. Razão pontos/meta 5,55 na Cruz Total significa que a mesa
inteira é ganha 5 vezes por um único evento — isso não é clímax, é botão de vitória.

**E o aviso do teto se confirmou com força.** Com o teto `24+4×rodada` de volta, ele morderia
**11,4% das duplas, 56,1% das triplas e 73,5% das cruzes totais** (contra 1,0% dos eventos da
gulosa). Quem reintroduzir o teto vai colapsar silenciosamente a tripla e a total e concluir
que "a tripla não compensa" quando o que aconteceu foi o teto. O núcleo polido acerta ao
remover o teto, e a escada precisa ser reequilibrada pela **soma** de mults (2×/3×/4×) e não
pelo produto, ou por um amortecimento explícito.

## 5. VEREDITO

**REPROVADA**, pelo critério declarado antes de medir.

1. A **base já é PARCIAL** por esse critério (planejadora 1,437 · 0,0% de zeros · gulosa 0,000).
   Para o candidato valer alguma coisa ele tinha de virar **APROVADA**, isto é, mover a gulosa
   acima de 0,25. Com semeadura aleatória e material constante, a gulosa fica entre **0,000 e
   0,017** em todos os S de 3 a 12. Ele não move a gulosa.
2. As únicas células em que a gulosa passa de 0,25 têm **1,00 de 9 casas pagas pelo jogador** e
   **0,0%** de cruzadas com ≥8 braços pagos. É o resultado comprado, não produzido.
3. Bandas estouradas: recompensa < 60% em S8 cruz (58,9) e S10 diagonais (59,8); m5 a 73,8%
   em S12 diagonais e a 49,8% em S12 aleatório; Tear 4/5 e seca 0/1 nos S altos.
4. A distância planejadora−gulosa — a métrica que o briefing manda ler — **não encolhe por
   mérito em nenhuma célula honesta**: 1,437 na base, 1,438 (S6 aleat.), 1,469 (S3 cruz),
   1,593 (S6 cruz). Ela só encolhe (0,59) nas células fabricadas, e lá encolhe porque a gulosa
   subiu de graça.

**Parâmetro recomendado: NENHUM. Manter 3 sementes na Pequena e 0 nas outras.** Se alguém
insistir em mexer, **S=6 aleatório, modo conserva** é a única célula que não fabrica nada e não
estoura banda nenhuma (profunda 0,005 → 0,042; caçadora 0,144 → 0,311; gulosa 0,000 → 0,000;
planejadora 1,437 → 1,438). Isso não justifica uma regra.

## 6. O QUE ME SURPREENDEU

- **A cruzada não precisa de regra nova.** Uma planejadora honesta satura o teto aritmético na
  base atual: 1,437/mesa, 100% de cobertura, **exatamente 1,000 na Grande**. Todo o gargalo é
  de visibilidade e de gradiente, nenhum é de geometria ou de material. Isso muda o alvo dos
  outros três candidatos: eles não precisam **permitir** a cruzada, precisam **ensiná-la**.
- **Horizonte 3 ainda é invisível** (S6 cruz: gulosa 0,000, profunda 0,085). Eu esperava que o
  critério "≤ 3 turnos" fosse suficiente. Não é, se os 3 turnos pagam zero.
- **O critério intencional × acidental do briefing é degenerado.** ~100% das cruzadas saem
  marcadas como "acidentais" em todas as políticas, inclusive na planejadora que passou 8 turnos
  montando a coisa — porque fechar 2 linhas é sempre o maior ganho imediato do turno, logo o
  gatilho é sempre a jogada gulosa. A intenção mora nos 8 turnos anteriores. Troquem esse
  critério por `pct_colheitas_adiadas_de_proposito` (0,0% gulosa · 41,9% caçadora · 62,6%
  planejadora) e por braços pagos.
- **A hipótese do colateral continua falsa**, como o briefing disse — mas o motivo prático é
  outro: a planejadora simplesmente **se recusa a fechar** (62,6% de colheitas adiadas), e é
  essa recusa, não a geometria, que segura a montagem.

## 7. O QUE NÃO FUNCIONOU

- **O candidato inteiro**, na sua forma honesta. Semear aleatoriamente 3, 6, 8, 10 ou 12 cartas
  com material constante: gulosa 0,000 em todas.
- **O viés diagonal**: com S≥10 ele **derruba** a planejadora (1,437 → 0,62 → 0,46) e enche
  38–54% das mesas de zero. Ocupar as diagonais atrapalha as cruzes de linha × coluna.
- **Semear muito**: com S≥10 em modo conserva a mesa tem 5 a 7 posicionamentos, o Tear não sobe,
  e a partida deixa de ser uma partida. O risco declarado no enunciado ("encurtar demais a
  mesa") está confirmado com número: turnos por mesa medianos caem de **17** (base) para 12 / 10 / 8 / **6** em S=6 / 8 / 10 / 12, e para 5 em S12 cruz.
- **O modo solto** (semear sem tirar posicionamentos) sobe tudo — gulosa, caçadora, planejadora,
  vitória — e não conserta nada. `cruzadas_por_carta` denuncia: planejadora **0,0799** na base, **0,0762** em S8 aleatório
  conserva e **0,0576** em S12 aleatório conserva — normalizado por material, o candidato
  *piora*. No modo solto o mesmo S8 sobe para 0,0864 só porque ganhou cartas. Quem comparar
  por mesa vai achar que funcionou.

---

Arquivos: `resultado.json` (todas as medições, com `decisoes_fixadas` e `veredito_final`),
`bancada.gd` (planejadora + escada + métricas), `mesa2.gd` (PRODUTO/K + semeadura + colheita
fantasma), `run_c3.gd` (runner), `montar.py` (pós-processamento), `progresso.log` (log cru),
`r_base.json` / `r_sweep_1..5.json` / `r_escada.json` (saídas cruas do Godot).
