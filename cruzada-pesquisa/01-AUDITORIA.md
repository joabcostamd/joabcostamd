# AUDITORIA FINAL — CRUZADA

Li a sonda com meus próprios olhos, conferi o número que sustenta cada leitura dos analistas, e
rodei um **experimento novo** (1.200 mesas, política gulosa, Godot headless) para *medir* as
correções propostas em vez de acreditar nelas. Meu controle reproduziu a sonda dentro de 1 ponto
(14,3% × 14,1%; Tear 2 × 2; razão pontos/meta 0,442 × 0,428; vitória 10,4% × 11,0%), então os
números de correção abaixo são comparáveis aos da sonda.

---

## 1. VEREDITO EM TRÊS LINHAS

**Simples de aprender?** A REGRA sim, o JOGO não. Dois jogadores frios entenderam a frase em 10 s e
15 s e a devolveram com as próprias palavras — isso é o mais difícil de acertar em design e você
acertou. Mas a jogada não é a regra: mediana de **100 jogadas legais por turno** (m1).

**Simples de jogar, turno a turno?** Não — mas não pelo motivo que o documento supõe. A decisão
**parece** pesadíssima (100 opções) e **é levíssima** de consequência: a 2ª melhor jogada fica a
**1,49%** do score da melhor (m6) e jogar sempre o óbvio custa **1,4 ponto percentual** de vitória
(10,95% × 12,35%). O jogador paga o preço mental integral de uma decisão de 100 vias para ganhar
1,5%. Isso é fadiga sem retorno.

**Viciante? Dopamina infinita?** **Não, como está.** Em **85,9% dos turnos nenhuma** das ~100
jogadas produz um ponto (m2), a recompensa sai a cada 6 posicionamentos (m3), e o evento que dá nome
ao jogo acontece em **0,00% das mesas** (m8). **Mas eu medi o conserto e ele funciona:** com duas
mudanças de regra, os turnos com recompensa vão de **14,3% para 65,3%** e a seca mediana cai de
**7 turnos para 2**. O jogo que você pediu está a três regras do jogo escrito.

---

## 2. OS NÚMEROS QUE IMPORTAM

Política gulosa (jogador competente), 2.000 mesas, núcleo sem loja.

| Medida | Medido | Bom seria | Veredito |
|---|---|---|---|
| m2 — turnos em que alguma jogada pontua | **14,1%** | ≥ 60% | Reprova. Balatro: 100%. |
| m3 — turnos entre recompensas | **6** (p90 9, máx 15) | 1–2 | Reprova. 24 s a 4 s/turno. |
| m9 — maior seca por mesa | **7** turnos (28 s) | ≤ 5 | Reprova a própria §16.2 (25 s). |
| m8 — cruzadas por mesa | **0,00**; 100% das mesas sem | 1–2 (§8.11) | Reprova. Especialista: 0,14. |
| m10 — Tear ao fim da mesa | **2** (máx 3) | 8 (R39) | Reprova. Teto real: 4/3/4. |
| m12 — derrota decidida aos 2/3 | **72,5%** das derrotas | ≤ 25% | Reprova. Último terço morto. |
| razão pontos/meta (mesa mediana) | **0,428** | ~1,0 | Reprova. Modo fácil (×0,70) → 0,61. |
| m6 — margem da 2ª melhor jogada | **1,49%** score / 5,06% pontos | — | **Aprova.** Intuição não é punida. |
| m5 — jogada óbvia = jogada certa | **58,76%** | 55–70% | **Aprova.** Profundidade calibrada. |
| m4 — fator de explosão do prêmio | **8,7×** (12,9× na profunda) | ≥ 8× | **Aprova.** Cauda longa certa. |
| custo de caçar a cruzada | **0,1 pp** (10,85% × 10,95%) | ≤ 2 pp | **Aprova.** Viável — só invisível. |

**Duas correções aos analistas, porque mudam a leitura:**

1. A defesa diz que 85,9% é o pior caso e que o novato vê mais turnos vivos (aleatória: 39,58%).
**Leitura errada.** A aleatória tem mais turnos "pontuáveis" porque **deixa linhas paradas em 4/5
sem colher** — é fila acumulada, não recompensa entregue. Ela entrega **1,1 evento/mesa** (contra
2,3), **13 turnos** entre colheitas (contra 6) e **0,0% de vitória**. O novato vê menos dopamina.
2. "O descarte não faz nada" está errado: o 0,0 citado é da aleatória, que por construção nunca
descarta. A gulosa usa **mediana 3 de 2–3 disponíveis** — esgota o recurso. Pagar pontos por
descarte resolveria um problema que não existe.

---

## 3. O QUE O JOGO REALMENTE É

**Como está escrito hoje, o CRUZADA é um quebra-cabeça de território excelente e exigente. Não é
uma máquina de dopamina. São motores diferentes e você pediu o segundo.**

A diferença, sem jargão: numa **máquina de dopamina** (Balatro, caça-níquel) **toda ação paga** —
100% das vezes o número sobe e o som toca, e o prazer vem da frequência. Num **quebra-cabeça** (Into
the Breach) **a ação não paga, a solução paga** — o prazer vem de *achar* a jogada, e acontece na
sua cabeça, não na tela.

No CRUZADA você não joga uma mão. Você **assenta um tijolo**, e o muro só paga no 5º. Medido:
**1 recompensa a cada 6 tijolos**, e em **6 de cada 7 turnos a tela não devolve nada** — nem número,
nem som, nem partícula. Numa mesa de 17 turnos você toma 17 decisões de 100 opções e recebe **2,3
respostas**; dessas, só o decil superior tem margem que muda algo (m6 p90 = 63,9%). O jogo cobra 17
decisões de aparência pesada e entrega **~0,24 decisão visivelmente importante por mesa**.

E o clímax não acontece. A cruzada — que dá nome ao jogo, que o tutorial mostra aos 30 s, que a
§8.11 pede 1–2 por mesa — ocorre em **0,00%** das mesas com jogador competente, **1,45%** com busca
de dois níveis, e **86,1%** das mesas terminam sem nenhuma mesmo com a política especialista escrita
só para caçá-la. Caçá-la é grátis (0,1 pp), então o problema não é a regra proibir: é a habilidade
que ela exige — **recusar pontos agora e segurar uma linha em 4/5 por 2 a 4 turnos**. Nenhum novato
faz isso por acidente. Você promete na capa um momento que 100% dos seus jogadores nunca verão
sozinhos.

**O que o jogo tem de viciante é real, mas é de outra família.** m5 = 58,76%: a jogada óbvia está
certa 3 vezes em 5 e errada 2 em 5. Os dois jogadores frios, sem tabela de pontos e sem tutorial,
chegaram à **mesma** jogada certa (9♦ em C3) por caminhos diferentes e relataram o arrepio do
"achei". Isso é o vício do Into the Breach: otimização e descoberta. É legítimo, é bom, e não é o
que você pediu.

**A boa notícia é grande: a forma do prêmio já está certa, falta a frequência.** Explosão **8,7×**
(máximo 2.052 sobre mediana 236) é exatamente o perfil de retorno variável de cauda longa de um
caça-níquel. Você não precisa redesenhar o pagamento — precisa fazê-lo disparar mais vezes.

---

## 4. OS PROBLEMAS FATAIS E GRAVES

**[FATAL 1] Cadência 6× mais lenta que o alvo, com teto aritmético.** O máximo **possível** é 3
eventos por mesa: cada evento consome 5 cartas que nunca voltam (R04b) contra 15/17/19
posicionamentos (R09). **Nenhum número da §5.1 muda isso** — é conservação, não balanceamento.
A §8.11 pede 3–5 colheitas por mesa; o núcleo entrega 2,3. *Correção medida: §5.1.*

**[FATAL 2] O clímax acontece em 0,00% das mesas** (m8). A banda 2 da §7.4 (mediana 1,5–2,5) é
matematicamente impossível na mesa Grande — 17 cartas disponíveis contra 18 necessárias (C02).
*Correção: sinalizar (§5.3) e trocar a banda por "≥1 cruzada em ≥60% das Pequenas e Chefes, ≥35% das
Grandes" (tetos teóricos 2/1/2).*

**[FATAL 3] Em 72,5% das derrotas o último terço é jogado já perdido** — ~5,7 turnos por mesa, e
mudos (seca mediana 7 turnos = 28 s, acima da barreira de 25 s da própria §16.2). A R41 existe para
isso e é a regra mais importante do documento para "não frustrante", mas dispara por **prova de
impossibilidade matemática**, que com eventos de até 3.042 pontos só é obtenível nos 2–3 últimos
turnos. *Correção: trocar o gatilho para `pontos + p95_empírico(rodada, tipo, posicionamentos
restantes) < meta` — 18 inteiros em `dados/rodadas.json`, o critério que a sonda já usa em m12.
Mesmo texto, mesmo botão, um limiar trocado.*

**[GRAVE 4] O número mais destacado da tela sobe duas vezes e para.** A R39 dá ao Tear teto 8 e o
chama de "o único número que sobe a mesa inteira". Medido: mediana **2**, máximo **3** em 8.000
mesas, zero com 4+; o teto alcançável pela aritmética das regras é 4/3/4. "Tear 5" nunca dispara, os
dois jogadores frios o apontaram como o pior buraco da tela, e nenhum dos 7 passos do tutorial o
menciona. *Correção medida: §5.2, mediana 2 → 6.*

**[GRAVE 5] O modo fácil não alcança o jogador.** O slider de Metas para em ×0,70 e a mesa mediana
faz **0,428** da meta: com o alívio máximo ela termina em **61%** — ainda derrota (o equilíbrio
exigiria ×0,43). A arquitetura da §7.1 é exemplar e não muda; a **faixa numérica** foi calibrada
para um jogo que chega a 70% da meta, e o jogo chega a 43%.

**[GRAVE 6] A banda 7 da §7.4 é inalcançável por construção.** Exige que a gulosa vença **≥12 pontos
percentuais** mais que "anel1", reprovando abaixo de 4. A maior diferença entre **quaisquer** duas
políticas competentes medidas é **1,4 pp** — a banda pede um abismo 8,6× maior que o maior que
existe. Não é o build que vai reprovar; é o teste que está errado.

---

## 5. AS TRÊS MUDANÇAS QUE MAIS AUMENTAM A DOPAMINA

Nenhuma toca a mecânica-núcleo (dupla pertinência, colheita destrutiva, cruzada). As duas primeiras
eu **medi**; a terceira não, e digo isso com todas as letras.

**5.1 PULSO DE LINHA (nova R11b) — a maior mudança por esforço.** Quando um posicionamento leva uma
linha viva a 3/5 ou a 4/5, pague na hora `floor(fichas_presentes × (mult da categoria garantida +
Tear) × F)`, F entre 0,15 e 0,25, máximo 2 pulsos por linha por mesa. **Não gasta posicionamento,
não remove carta, não sobe o Tear.** Anime como T1 Brilho (140 ms), que a §11 já tem.

| | base | com pulso (F = 0,35) |
|---|---|---|
| turnos com recompensa | 14,3% | **65,1%** |
| turnos entre recompensas (mediana) | 6 | **1** |
| seca mediana / p90 | 7 / 9 | **2 / 4** |
| pulsos por mesa (mediana) | — | 9 |
| razão pontos/meta | 0,442 | 0,598 |

**5.2 TIQUE DO TEAR — +1 a cada 4 posicionamentos**, além do +1 por linha colhida.

| | base | tique/3 | **tique/4** |
|---|---|---|---|
| Tear ao fim (mediana / máx) | 2 / 3 | 8 / 8 (satura) | **6 / 7** |
| razão pontos/meta | 0,442 | 0,794 | 0,709 |

Use **a cada 4**: com 3, o Tear encosta no teto 8 em metade das mesas e volta a ficar parado. Com 4
ele sobe 5 vezes por mesa, "Tear 5" passa a disparar, o teto 8 vira alcançável mas não garantido, e
o jogador ganha um evento audiovisual a cada ~16 s que não custa carta nem turno.

**Combinadas (pulso F = 0,15 + tique/4):** turnos com recompensa **65,3%**, intervalo mediano **1**,
seca mediana **2**, Tear mediano **6**, razão pontos/meta **0,814**, vitória **30,3%** (R1 84% /
R2 58% / R3 29%). **Obrigatório depois:** rodar a descida coordenada da §7.4 sobre a base da R21 —
os pontos por mesa quase dobram (mediana 707 → 1.209). As rodadas 5–6 seguem em 0% **porque o núcleo
não tem loja** (ressalva D11): isso é escopo, não defeito.

**5.3 "CRUZADA ARMADA" — tornar visível a habilidade que ninguém deduz.** Quando uma linha está em
4/5 **e** a perpendicular daquela casa ainda alcança 5 dentro do orçamento, a casa de cruzamento
recebe halo em cruz e o rótulo "CRUZADA ARMADA" (2 palavras, dentro do teto da §13): 1 varredura das
12 linhas por turno, já feita para os rótulos. **Evidência de que é acessível:** caçar cruzada custa
**0,1 pp** de vitória. **Honestidade: não medi o efeito da sinalização** — não se simula intenção
humana. E há um custo medido: a política caçadora tem seca p90 de **13** turnos contra 9 da gulosa.
Caçar cruzada piora o ritmo, **por isso a 5.3 só é segura depois da 5.1.**

---

## 6. O QUE ESTÁ GENUINAMENTE BOM (não mexa)

- **O gancho de uma frase**, **a profundidade** (m5 = 58,76%) e **a forma do prêmio** (8,7×).
- **O perdão**: m6 = 1,49%; o instinto custa 1,4 pp. Sua maior ansiedade — "o jogo pune quem não
  calcula" — **não se confirma na medição**. É a melhor notícia daqui.
- **A tensão espacial**: a linha quer valor, a coluna quer naipe, toda casa boa é conflito. Não é
  reskin, e produz o quase-acerto ("tenho o 9 certo no naipe errado") de graça pela geometria — o
  único gatilho de caça-níquel que o jogo já tem e não mostra. Mostre-o: estampa de 700 ms após a
  colheita, com a contagem de outs que a R04b já calcula.
- **A camada de apresentação (§11)**: quando os eventos acontecerem, a festa já está escrita.
- **R16 + R40 + separação temporal** ("paga inteiro primeiro, desmorona depois"): a dúvida que
  travou os dois jogadores frios já tem resposta correta — falta **dizê-la na tela**. E **a §7.1 e a
  R37**, em que só a faixa numérica do slider precisa abrir (piso de ×0,70 para ×0,45).
- **A colheita final é naturalmente generosa com quem joga mal**: paga mediana **199** para a
  aleatória contra **106** para a gulosa. Ninguém notou, e é anti-frustração de graça.

---

## 7. RECOMENDAÇÃO

### **(B) Ajustar 3 pontos de regra, remedir na sonda, e construir.**

**Não (A):** você gastaria semanas materializando um quebra-cabeça que não pediu — clímax em 0% das
mesas, multiplicador-vitrine que sobe duas vezes e para, 6 de cada 7 turnos mudos. Custo: zero
agora, meses depois da F2.

**Não (C):** a mecânica-núcleo está **provada boa** por medição — m5, m6, a explosão 8,7×, dois
jogadores frios convergindo na jogada certa sem tutorial, e um eixo de decisão que o gênero não tem.
Trocá-la é jogar fora a única parte que passou no teste, para recomeçar do zero sem garantia.

**Custo de (B):** as duas mudanças que medi são **três linhas de regra** — escrever a R11b, mudar a
R39, e reabrir a faixa da base da R21 na §7.4 de [1,36..1,46] para [1,20..1,46] (a atual não tem
alcance para corrigir o colapso de fator 4 entre as rodadas 2 e 3). Mais o gatilho da R41, que é um
limiar. **Estimativa: uma semana**, a maior parte remedição na sonda que já existe.

**A ordem importa:**
1. Pulso (R11b) + tique do Tear a cada 4. Remedir exigindo m2 ≥ 60%, m3 mediana ≤ 2, m9 mediana ≤ 4,
   m10 mediana 5–7.
2. Descida da base da R21 até a razão pontos/meta voltar a ~0,95–1,05 **com a loja aproximada**, não
   sem ela. E corrigir a banda 1: hoje **17 das 18 células** rodada×tipo reprovam a banda que o
   próprio documento escreveu.
3. Gatilho da R41 por p95 empírico, "CRUZADA ARMADA", estampa do quase-acerto, e 5 strings (Tear
   "+1 por linha colhida"; "Paga primeiro. Some depois."; "RESTAM 11 DE 19"; "COLHEITAS 1"; faixa
   CRUZADA na prévia com a conta literal da R15 — somar os painéis separados subestima o clímax em
   42,6%).
4. **Só então** UI, e antes da Etapa 11, 5 pessoas × 3 mesas num mock de papel com Receituário e
   prévia, cronometrando o turno. O ponto de ruptura é **5,77 s por turno** (acima disso a run
   estoura os 38 min do seu próprio `--exigir`); escreva esse número na §6.1, porque hoje o 4,2 s é
   "requisito" sem uma única medição atrás dele.

**Última honestidade.** A defesa está certa num ponto: os 120–240 s dos jogadores frios foram
medidos numa tela **sem** Receituário e **sem** prévia, e as duas queixas nº 1 deles já estão
especificadas. Não conte esses 240 s contra o jogo. Mas conte isto: a prévia só resolve os 14,1% de
turnos em que ela tem número para mostrar; nos outros 85,9% ela diz zero para as 100 casas. **Por
isso o pulso de linha é a primeira mudança e não a terceira: ele é, ao mesmo tempo, o conserto da
dopamina e o conserto da interface.**

**Construa. Depois dessas três regras, não antes.**
