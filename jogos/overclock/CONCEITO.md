# OVERCLOCK — conceito

Data: 2026-09-07
Gênero: bullet heaven (survivors-like) 3D · Ambientação: neon cyberpunk · Alvo: Steam

---

## O jogo em uma frase

Você pilota um núcleo de processamento dentro de uma rede hostil e decide, **a cada segundo**,
o quanto acelerar o próprio clock — porque acelerar mata mais rápido e também te mata mais rápido.

## O problema que este jogo resolve

Bullet heaven tem um defeito estrutural conhecido, e é a crítica que o gênero leva desde
*Vampire Survivors*: **o jogador só anda.** As armas atiram sozinhas, e a única decisão real
acontece no menu de nível, uma vez a cada trinta segundos. Entre um menu e outro não existe
escolha nenhuma. É por isso que o fim de partida vira fogos de artifício sem tensão — a tela
está cheia, e não há nada para decidir.

**A resposta do OVERCLOCK é dar ao jogador um botão que ele segura, e que sempre custa caro.**

## A mecânica central — o Clock

Segurar o gatilho acelera **tudo que é seu**: cadência de tiro, velocidade de movimento e
ganho de experiência. E aquece o núcleo.

- O calor sobe enquanto você acelera e cai enquanto você anda no clock normal.
- Estourar o calor causa **travamento**: 2 segundos parado. Numa horda, 2 segundos é a morte.
- E o fecho que faz o sistema virar jogo: **a horda lê o seu clock.** Quanto mais você acelera,
  mais rápido ela nasce e mais forte ela vem. Você não está apenas arriscando superaquecer —
  você está construindo o inimigo que vai te matar.

Isso troca a pergunta do gênero. Deixa de ser *"qual número eu escolho no menu"* e passa a ser
**"quanto eu aguento forçar agora, sabendo que estou pagando isso daqui a um minuto"**.

## Loop principal

1. Você anda e desvia; as armas atiram sozinhas (o contrato do gênero, mantido).
2. Você decide **acelerar** para matar mais e subir de nível mais rápido — e aquece.
3. Sobe de nível, escolhe um módulo, a build cresce.
4. A horda escala com o clock que você **acumulou**, então acelerar fica mais caro a cada vez.
5. A cada 5 minutos vem um chefe que só cai se você aceitar aquecer. Volta ao passo 1.

## Uma partida dura

20 minutos, com chefe final aos 20. Derrota é comum e rápida de reiniciar (menos de 5 segundos
até a próxima partida).

## O que NÃO tem

Esta é a seção mais importante do documento. É ela que impede o escopo de crescer sozinho.

- **sem multijogador online.** Co-op local é candidato a DLC pós-lançamento, nunca ao lançamento.
- **sem mundo aberto.** Arenas fechadas, cada uma com uma regra espacial própria.
- **sem história com cutscene.** O mundo se conta pelo ambiente e pelos nomes dos módulos.
- **sem crafting, sem inventário, sem loot de equipamento.**
- **sem 20 naves no lançamento.** Começa com 4 realmente diferentes, não 20 quase iguais.
- **sem árvore de 800 habilidades.** A profundidade sai da interação entre poucos módulos, não
  da quantidade deles. Vinte módulos que conversam batem oitocentos que não.
- **sem arte dependente de artista humano.** A direção é geometria emissiva, gerada e configurada
  por código — ver `ARTE.md`. É escolha estética, não remendo.
- **sem dano por número flutuante gigante na tela.** Legibilidade acima de espetáculo.

## Como sei que está bom

Critérios observáveis, todos medidos por `./simular.sh` — nenhum deles é opinião:

| # | Critério | Medida |
|---|---|---|
| 1 | O Clock é uma decisão de verdade | a política **boa** passa 40–60% da partida acelerada. Se der 0%, o sistema é inútil; se der 100%, não há escolha. |
| 2 | Habilidade importa | política **ruim** morre antes dos 10 min; política **boa** passa dos 20 em ≥ 70% das partidas. |
| 3 | Nenhuma arma domina | nenhum módulo aparece em mais de 60% das builds vencedoras. |
| 4 | Nenhuma arma é lixo | nenhum módulo aparece em menos de 10%. |
| 5 | O ensino funciona | jogador novo entende o Clock **sem texto**, em menos de 60 segundos (medido em playtest com gente, não por simulação). |
| 6 | O fim de partida ainda tem tensão | a taxa de travamento por superaquecimento nos minutos 15–20 não cai a zero. |

Se o critério 1 falhar, o jogo é um bullet heaven comum e o projeto perdeu a razão de existir.
Ele é o primeiro a ser medido, e é medido antes de qualquer arte.
