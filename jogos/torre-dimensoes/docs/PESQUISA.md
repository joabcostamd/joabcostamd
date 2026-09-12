# Torre entre Dimensões — pesquisa de mercado

Data da pesquisa: 2026-09-12 · Fase: planejamento · Régua v1

> **Nada aqui sai da cabeça.** Toda afirmação tem fonte. Onde for opinião do agente, está
> escrito que é opinião.

⚠️ **Limite desta pesquisa, dito agora:** a loja da Steam está bloqueada pelo proxy de saída da
nuvem (`store.steampowered.com` → EGRESS_BLOCKED). Preço exato, número de análises e nota dos
concorrentes **não foram lidos na fonte primária** — só pelo que a busca devolveu. Confirmar na
máquina local antes de decidir preço.

---

## 1. Esse jogo já existe?

**Sim. Pelo menos três vezes, e uma delas na Steam agora.**

| jogo | o que é | onde |
|---|---|---|
| **Lone Tower** | *"roguelite survivor onde cada run transforma uma única Torre numa monstruosidade"* — perks, cartas, e fazenda entre partidas | Steam (app 4238180) **e Google Play** |
| **One Tower Defense** | roguelike TD de uma torre só: junta recurso, compra arma e melhoria, ondas infinitas. Tem multijogador | Steam (app 4138190) |
| **Tower One** | defesa de uma torre | Steam (app 3194970) |
| Only One Tower · One Tower · Mobile Tower | quatro variações da mesma ideia | itch.io |

Adjacentes e relevantes: **Rogue Tower**, **Tower Survivors**, **Towers and Survivors**.

> **A leitura dura:** "uma torre só, resistindo a ondas" **não é o diferencial** — é o ponto de
> partida de pelo menos meia dúzia de jogos. Se o nosso projeto se apoiar nisso para ser
> diferente, ele nasce sendo mais um.
>
> **O que ainda está aberto:** quase todos esses são **2D ou pixel art**, e o Lone Tower é
> claramente de origem mobile. **3D de verdade, com direção de arte forte, é a brecha.**

## 2. Os números do gênero

| fato | fonte |
|---|---|
| **4.741 jogos** com a tag *tower defense* na Steam, somando **US$ 120+ milhões** de receita líquida | Steam Marketing Tool |
| A Steam roda um **Tower Defense Fest** próprio (desde 09/03/2026) — o gênero tem vitrine oficial | GameGrin |
| 20.282 jogos lançados na Steam em 2025; só **608 passaram de mil análises** — 2,99% | VoxBooster / Steam Page Analyzer |
| **10 a 20%** dos indies cobrem o custo de um dev solo (US$ 30–50 mil). Só **5 a 10%** viram renda em tempo integral | Steam Page Analyzer |
| Mediana de vendas de indie: **500 a 2.000 cópias** | Steam Page Analyzer |
| Indies geraram US$ 4,4 bi de US$ 17,7 bi na Steam em 2025 — um quarto do mercado | Game World Observer |

**A leitura que importa:** o gênero é gigante e lotado, com vitrine própria. A mediana é
brutal — 500 a 2.000 cópias. **Não dá para vencer por ser mais um tower defense.** Só dá para
vencer sendo reconhecível em 10 segundos de vídeo.

## 3. As referências

### Lone Tower — o concorrente direto

| o que copiar | o que o público reclama | o que a gente corrige |
|---|---|---|
| a torre única como fantasia de poder: cada run vira "monstruosidade" | origem mobile aparece — ritmo e visual de jogo de celular | 3D autoral, feito para monitor, não para telefone |
| progressão por perks e cartas, com sinergia | meta de fazenda/mineração entre runs dilui o assunto do jogo | meta-progressão que abre **variedade**, não poder |

> **Conclusão para o nosso jogo:** a fantasia "uma torre absurda" está provada e vende. O que
> ele deixa na mesa é **apresentação** — e é exatamente onde temos vantagem.

### Orcs Must Die! — como o gênero ganhou agência

O giro: *"você também está no meio da ação, controlando um avatar"*. E a regra que define o
design: **é impossível vencer uma fase só com armadilhas ou só com magia — precisa das duas.**

Mais acessível que o Dungeon Defenders justamente por focar em ação, com menos planejamento e
sem aleatoriedade.

> **Conclusão para o nosso jogo:** a saída clássica para "tower defense é passivo" é dar ao
> jogador um corpo no mundo. **Mas isso briga com "uma torre só"** — se ele tem um avatar, a
> torre deixa de ser o assunto. É a primeira decisão grande do projeto.

### Dungeon Defenders — o caminho caro

RPG com 12 classes de herói, muito mais conteúdo e profundidade, com fim de jogo muito mais
difícil.

> **Conclusão para o nosso jogo:** contagem alta de conteúdo é caminho válido e é o **mais caro
> e menos defensável** para um projeto solo. Recusar isso é decisão, não limitação.

### Repel the Rifts (30/11/2025) e Monsters are Coming! (24/11/2025)

Roguelite TD com terreno revelado a cada onda; e "Tower-Survivor" protegendo uma cidade que se
move.

> **Conclusão para o nosso jogo:** dois lançamentos recentes fundindo TD com survivor. O nicho
> está **quente e disputado agora**, não daqui a dois anos.

## 4. As mecânicas que FUNCIONARAM

O **porquê** é o que se reaproveita; a mecânica em si pode nem servir.

| mecânica | onde funcionou | por que funciona |
|---|---|---|
| avatar no meio da ação | Orcs Must Die! | mata a passividade — o jogador age no segundo, não só entre ondas |
| duas ferramentas obrigatórias | Orcs Must Die! | proíbe a estratégia única: tem que combinar, não otimizar um número |
| perks com sinergia por run | Lone Tower | a build é a história da partida; duas runs não se parecem |
| terreno revelado a cada onda | Repel the Rifts | transforma o mapa em decisão contínua em vez de cenário |
| base que se move | Monsters are Coming! | tira o jogador da poltrona: a defesa vira problema espacial vivo |
| sem aleatoriedade | Orcs Must Die! | derrota vira culpa do jogador, e culpa do jogador é o que ensina |

## 5. As mecânicas que FRACASSARAM

A metade mais valiosa. Estas viram, quase de graça, a lista "o que NÃO tem" do `CONCEITO.md`.

| mecânica | onde falhou | por que falhou |
|---|---|---|
| torre dominante no fim de jogo | Tower Defense Simulator | *"todas as opções de fim de jogo giram em torno de uma torre: Accelerator"* — mata a variedade |
| pouca variedade de inimigo e torre | genérico, citado em várias análises | *"fica repetitivo muito rápido"* — a queixa nº 1 |
| mapa único com objetivo repetido | genérico | *"um mapa só com objetivo repetido diminui muito a experiência"* |
| meta de fazenda/mineração entre runs | Lone Tower (opinião do agente) | rouba o assunto do jogo; o jogador passa a jogar planilha |
| progressão que exige tempo de jogo, não perícia | Tower Defense Simulator | força o jogador a moer em vez de aprender |

## 6. A crítica repetida do gênero

Aparece em várias fontes independentes. Não são bugs: são defeitos estruturais.

1. ⚠️ **Repetitivo.** *"O gênero é inerentemente repetitivo, e geralmente sem força narrativa."*
2. ⚠️ **Passivo.** *"Tower defense pode parecer passivo — o design precisa dar ao jogador coisas
   para fazer ou pensar que o façam se sentir ativo."*
3. **Raso.** Falta de variedade de inimigos, torres e missões.
4. **Meta homogêneo.** Uma opção domina, e todas as builds convergem para ela.

**A que este jogo ataca de frente:** ainda não escolhida. Vai sair do bloco B3 (ação central).
As candidatas reais são a **2 (passividade)** e a **1 (repetição)** — e elas pedem respostas
diferentes.

## 7. Preço, duração e conteúdo dos comparáveis

⚠️ **Não confirmado na fonte** (Steam bloqueada aqui). Conferir na máquina local.

| jogo | preço | volume |
|---|---|---|
| Lone Tower | <conferir> | perks + cartas + meta de fazenda |
| One Tower Defense | <conferir> | ondas infinitas + multijogador |
| Rogue Tower | <conferir> | — |

**Onde isso nos coloca:** faixa provável de US$ 5 a 10, pelo padrão do nicho roguelite indie
(o *Megabonk* lançou a US$ 5,49). **Decidir só com o dado conferido.**

## 8. O contraponto medido

| a pesquisa diz | nós medimos | regra que fica |
|---|---|---|
| MultiMesh é o caminho para desenhar muitos objetos | a skill `nivel-3d`: **700 peças de cenário em MultiMesh saíram 15% mais lentas** que nós comuns | MultiMesh ganha para *muitos iguais e pequenos* — horda e projétil. Cenário, não. **Meça antes de converter** |
| pesquisa externa sobre desempenho 3D | `godot-visual-check`: `editor_screenshot(source="game")` com janela minimizada devolve `stale_frame: true` | nunca medir nem julgar nada visual com a janela minimizada |

## 9. Onde isso deixa o nosso jogo

A pesquisa mudou uma coisa importante na ideia original:

> **"Uma torre só" não é o diferencial.** Já existe na Steam, pelo menos três vezes, e em quatro
> versões no itch.io. É o **ponto de partida** do nicho, não a novidade.

O que sobrou de vantagem real, e que nenhum concorrente ocupa bem:

1. **3D autoral de verdade** — os concorrentes são 2D, pixel, ou de origem mobile
2. **O tema dimensional** — nenhum deles usa dimensões como mecânica, só como cenário
3. **Arte e som 100% gerados por IA** — permite volume visual que um solo não teria

E a pesquisa deixa **uma decisão grande na mesa**, que é a próxima:

> O jogo ataca a **passividade** (dando ao jogador um corpo ou uma ação por segundo, caminho do
> Orcs Must Die) ou a **repetição** (fazendo cada run ser diferente, caminho do Lone Tower)?
>
> **Não dá para ser as duas como pilar principal** — elas puxam a câmera, o controle e o ritmo
> para lados diferentes. É o bloco B3.

---

## Fontes

- [Top Tower Defense Games by sales and revenue on Steam](https://games-stats.com/steam/?tag=tower-defense)
- [Steam Tower Defense Fest 2026 Top Sellers — GameGrin](https://www.gamegrin.com/news/steam-tower-defense-fest-2026-top-sellers/)
- [Lone Tower on Steam](https://store.steampowered.com/app/4238180/Lone_Tower/)
- [One Tower Defense on Steam](https://store.steampowered.com/app/4138190/One_Tower_Defense/)
- [Siege of Centauri Dev Journal: What Makes A Good Tower Defense Game?](https://www.stardock.com/games/article/495008/siege-of-centauri-dev-journal-what-makes-a-good-tower-defense-game)
- [Orcs Must Die! — Metacritic](https://www.metacritic.com/game/orcs-must-die/)
- [Dungeon Defenders vs Orcs Must Die — Steam Community](https://steamcommunity.com/app/65800/discussions/0/613938693119956670/)
- [Is TDS getting boring and dry? — Tower Defense Simulator Wiki](https://tds.fandom.com/f/p/4400000000000199128)
- [Indie Game Sales Statistics 2026 — Steam Page Analyzer](https://www.steampageanalyzer.com/blog/indie-game-sales-statistics)
- [Indie Game Statistics 2026 — VoxBooster](https://voxbooster.com/blog/indie-game-statistics-2026/)
- [Indie projects generated a quarter of Steam revenue — Game World Observer](https://gameworldobserver.com/2025/12/22/indie-projects-generated-a-quarter-of-the-total-game-revenue-on-steam-by-the-end-of-2025-analytics)
