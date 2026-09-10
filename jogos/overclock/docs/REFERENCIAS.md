# Estudo do gênero — bullet heaven / survivors-like

Data da pesquisa: 2026-09-07 · Fase: planejamento (nenhuma decisão de implementação tomada aqui)

> Este documento existe para que as decisões de design saiam de **evidência**, não de intuição.
> Cada afirmação abaixo tem fonte. Onde é opinião minha, está escrito que é.

---

## 1. O mercado, em números

| fato | fonte |
|---|---|
| A Steam oficializou **"Bullet Heaven"** como tag de gênero em **18/05/2026** | listagens de gênero |
| *Vampire Survivors* (2022) criou a categoria; quatro anos depois ainda segura o topo | consenso das análises |
| **Megabonk** (solo dev, 18/09/2025, US$ 5,49) vendeu **1 milhão em duas semanas**, ~1,3 milhão total | Video Game Insights |
| Pico de **117.336 jogadores simultâneos** — passou o recorde histórico de *Hades II* (112.947) | Steam |
| Receita estimada: **~US$ 7 milhões** líquidos após a Valve | análises de mercado |
| O cenário roguelite indie está **saturado** em 2025-26 | consenso |

**A leitura que importa:** o gênero está lotado *e* um desenvolvedor solo faturou sete milhões de
dólares nele há um ano. Saturação não impede — impede ser mais um. O Megabonk não venceu por
gráfico (ele é feio de propósito, com humor de meme); venceu por **uma ideia mecânica que ninguém
tinha explorado**.

---

## 2. As referências, e o que cada uma ensina

### Megabonk — a mais importante para nós

É a prova de que **3D é onde o gênero ainda tem espaço**. O que ele fez:

- **Verticalidade real.** Pula, pula duplo/triplo/quádruplo com upgrades, escala penhasco, sobe em
  árvore. Altura de pulo e número de pulos são vantagem tática de verdade, para fugir e para
  explorar.
- **O terreno é jogo.** Subir morro e saltar por cima do inimigo faz o posicionamento pesar tanto
  quanto a build. Isso é o que 2D não consegue oferecer.
- **A partida é uma corrida, não uma espera.** Objetivo: sobreviver 10 minutos, explorar, achar
  baús e santuários, e encontrar o portal do chefe **antes do tempo acabar**.
- **Baú com preço crescente.** Cada baú aberto encarece o próximo, então juntar ouro vira decisão
  de risco/recompensa em vez de coleta automática.
- **Só dois mapas** (Floresta e Deserto), com variações de cor destravadas por chefe. Geração
  procedural muda pouco o traçado.
- Fórmula declarada: *Vampire Survivors* + *Risk of Rain 2*.

> **Conclusão para o OVERCLOCK:** dois mapas bem construídos bastam. O que precisa ser excelente é
> o **movimento** e o que o terreno permite fazer.

### Brotato — a resposta à "falta de decisão"

Baseado em **ondas**, com **pausa entre elas** para pensar e fazer conta. Sessenta e dois
personagens, partidas de vinte minutos. Os itens têm **força e fraqueza declaradas** — a perícia
está em saber o que combina com o quê.

> **Conclusão:** a pausa entre ondas é a solução mais simples e testada para o problema de agência.
> Custa pouco e muda muito. Precisa ser considerada seriamente.

### Halls of Torment — tensão por perda possível

Mistura bullet heaven com Diablo. O truque: você **acha equipamento na masmorra, mas precisa
extrair** para ficar com ele. Cria urgência porque você passa a ter algo a perder. Densidade de
conteúdo por preço altíssima (US$ 6,66).

### Death Must Die — o melhor "feel"

Enxertou o laço de auto-shooter num sistema de bênçãos estilo *Hades*, com dublagem e progressão
de equipamento. É o mais elogiado no **momento a momento** — a sensação de cada segundo.

> **Conclusão:** "feel" não é polimento final, é o que separa o jogo bom do esquecível. Entra no
> planejamento, não no fim da produção.

### Shape Shifter: Formations — a referência que você citou

Twin-stick de inimigos geométricos, 91% positivo em 269 análises. Vinte naves × vinte armas, 800
habilidades em árvores, 200+ upgrades empilháveis, co-op local de dois jogadores.

> **Conclusão:** contagem alta de conteúdo é um caminho válido, mas é o **mais caro** e o menos
> defensável para um solo. Vinte que conversam batem oitocentos que não.

---

## 3. A crítica do gênero — o que faz esses jogos falharem

Repetida em várias fontes independentes:

1. **Falta de agência.** "Não há essencialmente nenhuma decisão a tomar." É a queixa número um.
2. **Build que nunca parece forte.** Classes a um upgrade de distância umas das outras; nada
   marcante.
3. **Vitória inevitável.** Quando o fim de partida deixa de ter risco, vira tédio.
4. **Level design fraco.** Apontado como problema **histórico e não resolvido** do gênero.

O item 4 é o mais interessante para nós: é justamente onde o Megabonk atacou, e é justamente o
que o 3D permite resolver.

---

## 4. O que a pesquisa diz sobre a arquitetura técnica

- **MultiMesh é o caminho para a horda.** `MultiMeshInstance3D` desenha milhares de cópias numa
  única chamada de desenho, via transformações por instância.
- **Padrão híbrido recomendado:** `CharacterBody3D` para o jogador e para poucos NPCs importantes;
  **MultiMesh para horda, projétil e tudo que existe aos milhares.**
- **Object pooling** é obrigatório: criar tudo no início e reativar, em vez de instanciar e
  destruir a cada tiro.
- Godot 4 sustenta **10.000+ entidades** com essa abordagem.

⚠️ **Contraponto medido no nosso próprio ecossistema** (skill `nivel-3d`): para **cenário**,
700 peças em MultiMesh saíram **15% mais lentas** que como nós comuns — peça grande e variada
perde. MultiMesh ganha para *muitos iguais e pequenos*, não para tudo.
**Regra: medir antes de converter.**

---

## 5. Onde isso deixa o OVERCLOCK

A ideia do **Clock** (acelerar dá poder e aquece; a horda escala com o quanto você acelerou)
ataca diretamente a crítica nº 1 — falta de agência. Isso continua de pé.

Mas a pesquisa revelou uma segunda via, **mais provada comercialmente**: o Megabonk resolveu o
mesmo problema com **movimento 3D e exploração de mapa**, e vendeu 1,3 milhão.

As duas não se excluem — mas **não podem ser as duas o pilar principal**, porque cada uma puxa o
level design, a câmera e o ritmo da partida para um lado diferente. Essa é a primeira decisão
grande do projeto, e está no Bloco 1 do `PLANO.md`.

---

## Fontes

- [Megabonk — Wikipedia](https://en.wikipedia.org/wiki/Megabonk)
- [Megabonk supera 1 milhão de cópias](https://wnhub.io/news/stores-and-publishing/item-49000)
- [Megabonk — estudo de caso](https://devlandmarketing.com/megabonk-case-study)
- [Megabonk Review — Lords of Gaming](https://lordsofgaming.net/2025/10/megabonk-review-a-bonk-tastic-3d-bullet-heaven/)
- [Guia de mapas do Megabonk](https://megabonk.org/guides/maps/)
- [Vampire Survivors-like — Wikipedia](https://en.wikipedia.org/wiki/Vampire_Survivors%E2%80%93like)
- [Bullet Heavens — Rogueliker](https://rogueliker.com/bullet-heaven-games-like-vampire-survivors/)
- [Melhores bullet heavens — Soulbound](https://soulbound.game/blog/best-bullet-heaven-games/)
- [Shape Shifter: Formations](https://store.steampowered.com/app/2202590/Shape_Shifter_Formations/)
- [CharacterBody3D vs MultiMesh no Godot 4](https://www.slashskill.com/godot-4-characterbody3d-vs-multimesh-scaling-hundreds-of-units-without-killing-performance/)
- [Guia de otimização 3D no Godot (2026)](https://www.strayspark.studio/blog/godot-3d-optimization-guide-2026)
