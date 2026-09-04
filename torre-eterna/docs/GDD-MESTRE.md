# TOWER ZERO — o que o jogo é, e onde cada ideia mora

Uma torre no centro. Inimigos vêm das bordas. Eles morrem, deixam ouro, o ouro
compra melhoria, a melhoria mata mais rápido. Isso é o gênero inteiro, e não é
o que sustenta ninguém depois da segunda hora.

O que sustenta são as decisões abaixo. Cada uma tem um endereço: o arquivo onde
ela vive de verdade. Onde este texto e o código discordarem, **o código está
certo** — este documento descreve a intenção, e é `tools/validar_dados.gd` e a
suíte de testes que fazem a intenção valer.

> O projeto original está em `docs/projeto-original/` e descreve uma
> implementação em JavaScript que nunca foi construída. Não use aqueles
> arquivos como referência: leia `docs/projeto-original/LEIA-ANTES.md`.

## Os doze pilares

| # | Pilar | O que decide | Onde mora |
|---|---|---|---|
| 1 | **A torre nunca é só um número** | Ela respira, racha, sangra e cai desenhada em código — nenhuma imagem no repositório | `scripts/render/` |
| 2 | **A PURGA é a única ação obrigatória** | Carga que enche sozinha, janela perfeita perto do topo, estouro que atordoa. A automação existe e é **de propósito** pior | `scripts/sim/mecanicas.gd` |
| 3 | **O ÁLBUM DE ECOS registra a carta ao ser VISTA** | Duplicata vira progresso permanente, imune a todo prestígio. Ninguém tem medo de reciclar | `scripts/sim/mecanicas.gd`, `scripts/sim/loot.gd` |
| 4 | **A RETOMADA** | Depois do prestígio, o jogo reconstrói o império em segundos com o fantasma da run anterior sendo ultrapassado ao vivo. O reset deixa de ser anticlímax | `scripts/sim/mecanicas.gd` |
| 5 | **A CAIXA DA VIGÍLIA** | O loot offline chega **lacrado**, para ser aberto uma carta por vez. Devolve o momento de abrir que o progresso offline costuma matar | `scripts/sim/offline.gd` |
| 6 | **Um caminho de código, três usos** | A mesma simulação roda o progresso offline, a prévia de prestígio e o portão de balanceamento do CI | `scripts/sim/game.gd`, `tools/sim_balance.gd` |
| 7 | **Os tetos de desempenho SÃO a economia** | Quanto mais inimigos vivos, mais ouro cada um vale (Aglomeração). O jogador *persegue* o limite em vez de esbarrar nele | `scripts/sim/economy.gd` |
| 8 | **A ADAPTAÇÃO DO ENXAME** | O mundo cria resistência ao elemento mais usado. A build ótima muda sozinha, e ninguém chega ao "já resolvi" | `scripts/sim/mecanicas.gd` |
| 9 | **O prestígio troca REGRA, não número** | As camadas mudam **como** se joga, não quanto rende. É o que sustenta a hora 40 sem produzir conteúdo novo | `scripts/sim/prestige.gd`, `data/prestige.json` |
| 10 | **O PANTEÃO destrói de verdade** | Consagrar um conjunto completo apaga aquelas cartas para sempre por um multiplicador eterno. O único lugar onde se perde algo de verdade | `scripts/sim/mecanicas.gd` |
| 11 | **O PEREGRINO** | Muito ouro se matar; lore e um requisito de final se poupar. O jogo nunca diz qual é a certa — só conta, para sempre | `scripts/sim/mecanicas.gd`, `scripts/ui/tela_final.gd` |
| 12 | **A ESTRATIGRAFIA** | Cada Transcendência grava uma faixa no chão da arena, com marcas dos chefes derrotados e dos Peregrinos poupados | `scripts/render/view_campo.gd` |

## Como o jogo está montado

```
scripts/
  core/      Big (log10), Fmt, Txt (i18n), Cfg, SaveSys, EventBus, Ux
  data/      balance.gd (todo número de balanceamento), db.gd (carrega data/*.json)
  sim/       a simulação inteira — não desenha nada, não sabe que existe tela
  render/    _draw() puro: campo, torre, inimigos, partículas, filtros
  ui/        HUD e painéis, montados em código a partir de ui_kit.gd
  audio/     PCM sintetizado em tempo de execução; nenhum arquivo de som
data/        conteúdo, com contrato aplicado por tools/validar_dados.gd
tools/       os portões (ver AGENTS.md)
```

Duas regras que explicam quase todo o resto:

- **Número grande é `log10` num `float` de 64 bits.** Multiplicar vira somar, e
  o jogo vai a 1e300 sem estourar. `scripts/core/big.gd`.
- **A simulação não conhece a tela.** Ela emite sinais no `Bus`; quem desenha
  ouve. É por isso que a mesma simulação roda headless no CI por horas.

## O que não é negociável

1. Nenhum arquivo de imagem, nenhum arquivo de som. Tudo desenhado e
   sintetizado em código — e há portão conferindo.
2. Todo texto que a pessoa lê existe em português e inglês, com portão.
3. Todo número de balanceamento mora em `scripts/data/balance.gd`, não espalhado.
4. Portão não se contorna. Portão errado é informação: conserta-se o portão.

*Onde este documento e o código discordarem, o código está certo.*
