# OVERCLOCK — mapa de decisões do planejamento

Data: 2026-09-07 · **Fase: planejamento. Nenhuma linha de gameplay será escrita antes de este
documento estar fechado.**

---

## Por que este documento existe

Arquitetura decidida durante a implementação é arquitetura decidida com pressa. O custo aparece
três meses depois, quando mudar a câmera significa refazer o level design, e mudar o formato dos
dados significa refazer o save.

Aqui ficam **todas as decisões que precisam existir antes do código**, cada uma com estado:

- 🔴 **ABERTA** — ninguém decidiu ainda
- 🟡 **PROPOSTA** — tenho uma recomendação, falta o Joab bater o martelo
- 🟢 **FECHADA** — decidida, com a razão registrada

Decisão fechada só reabre com motivo escrito. É isso que impede o projeto de andar em círculo.

---

## Estado geral

| bloco | assunto | estado |
|---|---|---|
| 0 | Identidade: gênero, tema, alvo | 🟢 fechado |
| 1 | Câmera, espaço e movimento | 🔴 **em discussão agora** |
| 2 | Estrutura da partida | 🔴 aberto |
| 3 | Combate e mira | 🔴 aberto |
| 4 | Progressão dentro da partida | 🔴 aberto |
| 5 | Meta-progressão | 🔴 aberto |
| 6 | Mapas e level design | 🔴 aberto |
| 7 | Inimigos e diretor de horda | 🔴 aberto |
| 8 | Telas e fluxo de interface | 🔴 aberto |
| 9 | Arquitetura de código e dados | 🔴 aberto |
| 10 | Produção, Steam e lançamento | 🔴 aberto |

---

## Bloco 0 — Identidade 🟢

Fechado com o Joab em 07/09/2026:

| decisão | valor |
|---|---|
| gênero | bullet heaven / survivors-like |
| dimensão | mundo **3D** |
| tema | neon cyberpunk |
| arte | construída pelo agente, sem artista humano; acervo local pode ser usado |
| alvo comercial | **Steam** é o foco; outras lojas são detalhe |
| ambição | jogo completo, polido, robusto e viciante — não um protótipo |
| ritmo | 40 h/semana |
| referências | *Shape Shifter: Formations* como base, mas **não** como referência única — ver `REFERENCIAS.md` |

---

## Bloco 1 — Câmera, espaço e movimento 🔴

**É a decisão mais cara de mudar depois.** Ela determina level design, direção de arte,
orçamento de performance, esquema de controle e até o formato do trailer.

Questões abertas:

1. **Qual câmera?** top-down fixa · isométrica · terceira pessoa atrás do jogador · orbital com
   controle do jogador
2. **Perspectiva ou ortográfica?**
3. **O jogador pula?** É a pergunta-Megabonk. Verticalidade foi o diferencial dele.
4. **Tem dash/esquiva?** Muda a curva de habilidade e a sensação de controle.
5. **Arena fechada ou mapa aberto para explorar?**
6. **O terreno afeta o movimento** (rampa, penhasco, altura) ou o chão é plano?

Depende de: nada. **É por onde começa.**
Trava: Blocos 2, 3, 6, 7 e 9.

---

## Bloco 2 — Estrutura da partida 🔴

- Duração: 10 min (Megabonk) · 20 min (Vampire Survivors, Brotato) · outra
- Condição de vitória: sobreviver ao relógio · achar e matar o chefe · outra
- **Tem pausa entre ondas?** (o modelo Brotato, que é a solução mais testada para dar agência)
- O que acontece ao morrer, e em quanto tempo o jogador está na próxima partida

---

## Bloco 3 — Combate e mira 🔴

- Auto-ataque total (Vampire Survivors) ou mira manual twin-stick (Shape Shifter)
- Como cada arma escolhe alvo: mais próximo · direção do movimento · aleatório · por tipo
- Existe habilidade ativa com recarga, ou tudo é automático
- Como o dano é comunicado sem poluir a tela

---

## Bloco 4 — Progressão dentro da partida 🔴

- XP e nível (VS) · ouro e loja entre ondas (Brotato) · os dois
- Quantas opções por escolha; existe re-sorteio (reroll); existe banimento
- Limite de armas e passivas equipadas
- Existe evolução/fusão de armas
- Existem baús e santuários no mapa; o preço cresce a cada um (Megabonk)

---

## Bloco 5 — Meta-progressão 🔴

**Pergunta direta do Joab: tem ou não tem?**

- Se tem: destrava **variedade** (personagens, armas, mapas) ou concede **poder permanente**?
- Poder permanente resolve a partida pelo jogador e mata a curva de habilidade — o risco declarado
- Quantos personagens no lançamento, e o quanto eles diferem de verdade

---

## Bloco 6 — Mapas e level design 🔴

- Autoral, procedural, ou híbrido (Megabonk usa procedural com variação pequena)
- Quantos mapas no lançamento
- Como o terreno participa da mecânica
- Como o jogador se orienta: minimapa, bússola, marcação do chefe

---

## Bloco 7 — Inimigos e diretor de horda 🔴

- Quantos tipos, e qual **papel mecânico** de cada um (não basta "um mais forte")
- Como a dificuldade escala: tempo · nível do jogador · área do mapa · misto
- Chefes: quantos, quando, e como são anunciados
- Orçamento: quantos inimigos vivos ao mesmo tempo, no pior caso

---

## Bloco 8 — Telas e fluxo de interface 🔴

**Pergunta direta do Joab: quantas telas o jogo vai ter?**

Precisa da lista exata e do diagrama de navegação. Candidatas: abertura, menu principal, seleção
de personagem, seleção de mapa, jogo, subida de nível, pausa, fim de partida, meta-progressão,
conquistas, opções (vídeo/áudio/controles/acessibilidade), créditos.

---

## Bloco 9 — Arquitetura de código e dados 🔴

O bloco que mais protege a implementação de virar improviso:

- Fronteira entre **regras puras** (testáveis, sem nó) e **apresentação** — regra do `CLAUDE.md`
- Nós comuns × MultiMesh × Servers API, e **onde cada um** (com a ressalva medida: MultiMesh saiu
  15% mais lento para cenário de 700 peças)
- Object pooling: o que entra no pool e qual o teto de cada um
- **Determinismo**: a mesma semente dá a mesma partida, e o simulador roda as mesmas funções que a
  tela chama — nunca uma segunda implementação
- Formato dos dados de conteúdo: `Resource .tres` × JSON × tabela
- Save: versão de esquema, mesclagem entre as duas máquinas, o que persiste
- **Orçamento de quadro**: ms por sistema, com a horda cheia, medido desde o começo

---

## Bloco 10 — Produção, Steam e lançamento 🔴

- Marcos e ordem (o que é provado antes do quê)
- Demo e Steam Next Fest: quando, e o que entra nela
- Preço (o Megabonk lançou a US$ 5,49)
- Página da loja, capsule, trailer
- Conquistas, ranking, nuvem
- Localização, acessibilidade, classificação etária
