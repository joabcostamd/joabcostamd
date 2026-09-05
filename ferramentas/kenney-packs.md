# Acervo Kenney — como trazer para cá

Tudo do Kenney é **CC0**: usa, modifica e vende sem pedir nada. Fonte:
<https://kenney.nl/assets>.

## O problema da nuvem, e a saída

`kenney.nl` está **bloqueado pelo proxy de saída** das sessões de nuvem. Então:

| Onde você está | Como trazer |
|---|---|
| Máquina local do Joab | `.claude/scripts/baixar-assets.sh <slug> <destino> --pixel` |
| Sessão na nuvem | **Actions → Trazer assets → Run workflow** — o runner do GitHub baixa, configura e commita num branch `assets/<id>`; aí a nuvem lê por git |

Depois de trazer, o catálogo é regerado sozinho em `assets/CATALOGO.md`.
**Consulte o catálogo antes de escrever qualquer caminho de asset** — nome inventado
não dá erro nenhum, a textura só não aparece.

## Slugs que valem a pena

### 2D
| slug | o que tem |
|---|---|
| `pixel-platformer` | tiles, personagens e itens de plataforma, 18×18 |
| `platformer-art-deluxe` | plataforma vetorial, personagem animado |
| `top-down-shooter` | personagens e armas vistos de cima |
| `tiny-dungeon` | roguelike 16×16 |
| `tiny-town` | vila 16×16, combina com o tiny-dungeon |
| `simplified-platformer-pack` | formas limpas, ótimo para protótipo |
| `puzzle-pack` | peças de quebra-cabeça, blocos |
| `board-game-icons` | ícones de baralho, dado, peça |

### Interface e efeito
| slug | o que tem |
|---|---|
| `ui-pack` | botão, painel, cursor, barra |
| `ui-pack-rpg-expansion` | moldura de RPG, inventário |
| `game-icons` | 200+ ícones de ação |
| `particle-pack` | fumaça, faísca, magia |
| `input-prompts` | teclas e botões de controle (Xbox, PS, teclado) |

### Som
| slug | o que tem |
|---|---|
| `interface-sounds` | clique, confirmação, erro |
| `digital-audio` | bipes e efeitos retrô |
| `impact-sounds` | batida, quebra, explosão |
| `music-jingles` | vinhetas curtas de vitória e derrota |

### 3D
| slug | o que tem |
|---|---|
| `mini-dungeon` | kit modular de masmorra |
| `platformer-kit` | plataforma 3D modular |
| `city-kit-commercial` | prédios de cidade |
| `nature-kit` | árvore, pedra, terreno |
| `castle-kit` | muralha, torre, portão |

Lista completa e atualizada: <https://kenney.nl/assets>.
Qualquer outra fonte CC0 funciona igual — passe a URL do `.zip` em vez do slug.

## Antes de commitar binário grande

Descomente o bloco LFS do `.gitattributes` **antes**. Depois que o binário entra no
histórico, o conserto é `git filter-repo` e reescreve tudo. O workflow `assets.yml`
faz isso sozinho quando você deixa a opção LFS marcada.
