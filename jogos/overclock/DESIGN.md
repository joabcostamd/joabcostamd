# OVERCLOCK — documento de design

Data: 2026-09-07 · Engine: Godot 4.7.2 · Alvo: Steam (Windows + Linux) · Ritmo: 40 h/semana

Leia antes: `CONCEITO.md` (o que o jogo é e o que ele recusa) e `ARTE.md` (a direção visual).
Este documento é o **como**.

---

## 1. Os três pilares

Três promessas inegociáveis. Toda feature proposta é medida contra elas, e o que não servir a
nenhuma é cortado sem discussão.

1. **A decisão nunca para.** O jogador escolhe alguma coisa a cada segundo, não a cada nível.
2. **Forçar sempre cobra.** Todo ganho de poder tem um preço que chega depois, não na hora.
3. **A tela nunca mente.** Se algo te mata, dava para ver. Legibilidade acima de espetáculo.

---

## 2. O sistema de Clock — a peça central

### Os números iniciais (chute honesto, a ser corrigido por simulação)

| grandeza | valor de partida |
|---|---|
| calor máximo | 100 |
| ganho de calor acelerado | 22 /s |
| perda de calor normal | 14 /s |
| atraso antes de começar a esfriar | 0,6 s |
| multiplicador de cadência acelerado | ×2,0 |
| multiplicador de movimento acelerado | ×1,35 |
| multiplicador de XP acelerado | ×1,6 |
| travamento ao estourar | 2,0 s parado |
| escala da horda por clock acumulado | +1% de densidade por 10 s acelerados |

> **Nenhum destes números é decisão de design ainda.** São o ponto de partida do
> `./simular.sh`. O critério 1 do `CONCEITO.md` — política boa entre 40 % e 60 % do tempo
> acelerada — é quem decide os valores finais. Mexer aqui sem rodar o simulador é opinião.

### Por que o travamento é 2 segundos

Curto demais e superaquecer não assusta, então o jogador segura o gatilho a partida inteira e a
decisão some. Longo demais e vira morte garantida, então o jogador nunca acelera e a decisão
some do outro lado. Dois segundos é a hipótese inicial; a medida que importa é o critério 6 —
a taxa de travamento nos minutos 15–20 não pode cair a zero.

---

## 3. Módulos — dezoito que conversam, não oitocentos que não

A referência tem 800 habilidades. Este jogo tem 18, e a aposta é que **profundidade vem da
interação, não da contagem.** Todo módulo tem uma relação declarada com o Clock — é o que
impede a lista de virar "escolha o número maior".

### 3.1 Armas (6) — atiram sozinhas; o overclock muda o *comportamento*, não só a velocidade

| arma | normal | acelerado |
|---|---|---|
| **Pulso** | tiro reto na direção do movimento | leque de 3 |
| **Órbita** | drones giram em volta de você | raio maior + rastro que causa dano |
| **Ricochete** | bala quica entre inimigos | +2 quiques |
| **Purga** | converte calor em dano em área | **quanto mais quente, mais forte** |
| **Torre** | planta uma torre estática | a torre acelera junto |
| **Corrente** | arco elétrico que salta | salta mais longe e mais vezes |

A **Purga** é a peça que fecha o sistema: é a arma que transforma o recurso perigoso em recurso
útil. Sem ela, calor é só punição; com ela, calor é munição.

### 3.2 Módulos térmicos (6) — onde mora a build de verdade

| módulo | efeito |
|---|---|
| **Dissipador** | o calor cai mais rápido enquanto você está parado |
| **Radiador** | o calor cai também andando, mas −10 % de velocidade |
| **Contenção** | travamento dura menos, porém o calor máximo cai |
| **Núcleo frio** | cada chefe derrotado zera o calor |
| **Termorregulador** | o dano do overclock aumenta o teto de calor |
| **Ponto de fusão** | **estourar causa dano enorme em área** |

**Ponto de fusão** é o módulo mais importante do jogo. Ele converte a punição em ferramenta: com
ele na build, o jogador *quer* estourar, e passa a procurar o momento certo de fazer isso no meio
da horda. Uma linha de regra que reescreve como a partida inteira é jogada — é exatamente o tipo
de profundidade que a contagem de habilidades não compra.

### 3.3 Passivas (6)

Ímã (raio de coleta) · Casco (vida) · Ventilação (velocidade) · Amplificador (dano) ·
Cadência (frequência) · Recuperação (regeneração lenta).

Deliberadamente sem graça. Elas existem para dar respiro entre escolhas grandes e para o
jogador poder consertar uma build torta — não para competir com as duas listas de cima.

### 3.4 Regra de escopo

Módulo novo só entra se **mudar uma decisão** que já existe. Módulo que só aumenta um número é
recusado, por mais barato que seja implementar. É assim que a lista fica em 18 em vez de 800.

---

## 4. Inimigos — a horda também é sobre calor

| inimigo | forma | comportamento |
|---|---|---|
| **Bit** | tetraedro | rápido, fraco, em bando |
| **Bloco** | cubo | lento, resistente, empurra |
| **Sentinela** | octaedro | fica longe e atira âmbar |
| **Enxame** | tetraedro | divide em dois ao morrer |
| **Parasita** | cubo pequeno | gruda e **aquece você** |
| **Refrigerador** | octaedro | **resfria a área em volta**, e cura os outros |

Os dois últimos são os que fazem a horda participar do sistema em vez de só andar na sua direção:

- O **Parasita** ataca o seu *recurso*, não a sua vida. Ignorá-lo custa a próxima aceleração.
- O **Refrigerador** cria uma zona onde acelerar é seguro — e cura tudo em volta. Ir até lá é
  ganhar fôlego e alimentar o problema ao mesmo tempo. Uma decisão espacial de verdade,
  construída com uma regra só.

---

## 5. Chefes — um a cada 5 minutos

| minuto | chefe | ideia |
|---|---|---|
| 5 | **Firewall** | paredes giratórias; obriga a acelerar para escapar da janela |
| 10 | **Compilador** | invoca cópias suas que repetem seu movimento de 3 s atrás |
| 15 | **Governador** | **prende seu clock no máximo** — você não pode desacelerar |
| 20 | **Kernel** | icosaedro que se subdivide a cada 25 % de vida perdida |

O **Governador** existe para provar o sistema pelo avesso: por quinze minutos o jogo ensinou o
jogador a administrar calor, e então tira dele o controle. É o teste de se a build aguenta o que
o jogador vinha evitando.

---

## 6. Arenas (4)

**Setor de Memória** (grade aberta, a de aprender) · **Barramento** (corredores que abrem e
fecham) · **Núcleo Térmico** (o calor sobe sozinho o tempo todo) · **Vazio** (sem paredes; sair
da borda mata).

Cada arena muda **uma** regra do sistema de calor. Nenhuma muda duas.

---

## 7. Meta-progressão — de propósito modesta

Fragmentos caídos na partida compram, entre partidas: novos núcleos (4 no total), novos módulos
no sorteio, e melhorias permanentes **pequenas** (teto de +15 % no total).

A razão de ser modesta: se a meta-progressão resolve a partida, a habilidade deixa de importar e
o critério 2 morre — política ruim passaria dos 20 minutos por acúmulo. Meta-progressão aqui
abre **variedade**, não poder.

---

## 8. Produção — 16 semanas a 40 h

A ordem não é negociável num ponto: **o Clock é provado antes de existir arte.** Se o critério 1
falhar, o que muda é o design, e arte feita antes disso é trabalho jogado fora.

| # | semanas | entrega | prova de que terminou |
|---|---|---|---|
| M1 | 1–2 | Clock + horda + uma arma, tudo em caixa cinza | `./simular.sh` mostra a política boa entre 40–60 % acelerada |
| M2 | 3–4 | os 18 módulos + tela de nível | critérios 3 e 4: nenhum módulo acima de 60 % nem abaixo de 10 % |
| M3 | 5–6 | os 6 inimigos + os 4 chefes | critério 2: ruim morre < 10 min, boa passa dos 20 |
| M4 | 7–8 | direção de arte aplicada (`ARTE.md`) | ms por quadro com horda cheia; silhuetas legíveis em quadro parado |
| M5 | 9–10 | 4 arenas, meta-progressão, save | portão verde + save mesclando entre as duas máquinas |
| M6 | 11–12 | áudio, game feel, acessibilidade, pt/en/es | simulação de daltonismo gravada em `AUDITORIA.md` |
| M7 | 13–14 | página da Steam, demo, telemetria | `auditar-completo` sem bloqueador |
| M8 | 15–16 | playtest com gente, correção, lançamento | critério 5: novato entende o Clock em < 60 s sem texto |

### O que roda onde

Metade deste trabalho não roda na nuvem, e vale registrar antes de começar para ninguém fingir
que rodou:

| aqui (nuvem) | só na máquina local |
|---|---|
| regras puras, simulador, testes, save, tradução | tudo que é visual: materiais, shader, luz, pós-processamento |
| estrutura de projeto, CI, documentação, balanceamento | screenshot, playtest visual, MCP `godot-ai` |
| escrever `.tscn` e provar pelo portão | julgar se ficou bonito |

O portão frio (`./testar.sh`) prova que **nada está quebrado**. Ele não prova que está bom — isso
é `godot-visual-check` e `godot-playtest-loop`, na sua máquina.

---

## 9. Os riscos, ditos agora

| risco | por que é real | o que fazemos |
|---|---|---|
| **O Clock não ser divertido** | é uma hipótese, não um fato. Pode virar peso em vez de escolha. | M1 existe só para isso. Se o critério 1 falhar em duas semanas, o design muda ali, não no mês 4. |
| **Gênero saturado** | bullet heaven é um dos mais lotados da Steam | o Clock é a resposta, e ele precisa aparecer nos 10 primeiros segundos do trailer |
| **Parecer asset flip** | acervo CC0 é reconhecível | material original é sempre descartado (`ARTE.md` §4) |
| **Desempenho com 300+ inimigos** | é onde este gênero morre | orçamento de ms medido desde M3, com a horda cheia, nunca com a cena parada |
| **Escopo crescendo** | 18 módulos viram 80 sem ninguém perceber | a seção "O que NÃO tem" do `CONCEITO.md`, e a regra de escopo do §3.4 |

---

## 10. A primeira coisa a fazer

M1, e nada além dele: caixa cinza, um retângulo que anda, uma arma, uma horda burra, o medidor
de calor e o simulador medindo o critério 1.

Sem arte. Sem menu. Sem som. Só a pergunta que decide o projeto inteiro:
**segurar esse gatilho é uma decisão interessante?**
