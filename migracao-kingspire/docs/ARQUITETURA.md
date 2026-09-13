# Kingspire — arquitetura e dados

Data: 2026-09-12

> O bloco que mais protege a implementação de virar improviso.
> **80% do "tive que criar a arquitetura durante a obra" nasce do contrato de dados mal feito.**

---

## 1. A fronteira

Regra pura (testável, sem nó, `static func`) × apresentação (desenha e chama a regra).

| mora em | o quê |
|---|---|
| `scripts/regras/` | <o que decide alguma coisa> |
| `scripts/telas/` | <o que só desenha> |

Se um comportamento não dá para testar sem abrir o jogo, ele está no arquivo errado.

## 1b. O mapa em duas camadas ⚠️

A separação mais importante do projeto. **O layout é dado; o mundo 3D é desenho.**

```
LAYOUT  (dado puro)                    MUNDO 3D  (apresentação)
grade de células                  →    malha de terreno com penhasco
  nível 0/1/2                          degrau de verdade, com sombra dura
  penhasco · rampa · ponte        →    rampa esculpida, ponte de madeira
  caminho                         →    trilha de terra sobre a grama
  ponto de construção             →    marcação no chão, e a peça que o
                                       jogador põe em cima
  frente de inimigo               →    portal, ponte, ou boca de caverna
  água                            →    plano azul com as linhas desenhadas
```

| | layout | mundo 3D |
|---|---|---|
| roda na nuvem? | ✅ sim, sem editor | ❌ não, é local |
| dá para testar? | ✅ é `static func` pura | só por screenshot e olho |
| quem valida | `portao-plano.py` e o simulador | `godot-visual-check` na máquina do Joab |
| trocar o visual inteiro | **não toca no layout** | é aqui que muda |
| mudar a regra do mapa | é aqui que muda | **não quebra a arte** |

> **A imagem que o gerador produz hoje é esboço.** Grade colorida serve para provar que a
> lógica funciona, não para mostrar como o jogo vai ficar. O jogo de verdade nasce quando o
> mundo 3D for montado em cima — terreno, árvore, água, construção, sombra, luz e câmera —
> como no Thronefall.

## 2. Contrato de dados ⚠️

Decidido **antes** do código. Mudar depois é migração.

### Save

```
schema_version: <n>
<campo>: <tipo>   # <para quê>
```

Migração: <como a versão n-1 vira n> · Mesclagem entre as duas máquinas: <regra>
Partida em andamento: <guarda ou não guarda, e o que exatamente>

### Conteúdo

| dado | formato | onde mora |
|---|---|---|
| <fase / inimigo / item> | <.tres / JSON / tabela> | <caminho> |

**Número de ajuste × dado de conteúdo:** o que é balanceamento vive em
`scripts/regras/balanceamento.gd`; o que é conteúdo vive em <onde>.

## 3. Camada de intenção

O jogador não lê o teclado: ele age sobre intenções. O teclado escreve nelas — **e os testes
também**. É o que torna gameplay testável sem tela.

| intenção | tipo | quem escreve |
|---|---|---|
| `intencao_<nome>` | <tipo> | teclado, controle, e o bot de teste |

## 4. Determinismo

Semente explícita em tudo que sorteia. `RandomNumberGenerator` com `seed` setada, **nunca**
`randi()` global. Mesma semente, mesmo resultado — e isso vira teste.

O simulador roda **as mesmas funções** que a tela chama. Nunca uma segunda implementação.

## 5. Máquina de estados do jogo

`<bootando> → <menu> → <jogando> → <pausado> → <fim>`

| estado | o que continua rodando | o que para |
|---|---|---|
| pausado | <...> | <som, física, timers?> |

## 6. Onde mora o tempo

Escala de tempo: <como> · o que ignora a pausa: <o quê> · câmera lenta / hit-stop: <como>

## 7. Orçamento de desempenho

| sistema | ms por quadro (alvo) | medido com |
|---|---|---|
| <nome> | <ms> | <a cena cheia, no pior caso> |

Entidades vivas no pior caso: <n>

## 8. Decisões que não têm volta barata

| decisão | valor | por que congela |
|---|---|---|
| escala do mundo | <1 unidade = ...> | quebra câmera, colisão, asset e save de uma vez |
| origem das peças | <onde> | idem |
| GDScript ou C# | <qual> | muda export |
| renderizador | <qual> | escolhido antes da arte, não depois |
| co-op algum dia? | <sim / não / nunca> | se houver 10% de chance, a arquitetura é outra hoje |
| mods algum dia? | <sim / não / nunca> | idem |

---

## Está pronto quando

- [ ] o contrato de save tem `schema_version` e regra de migração
- [ ] toda intenção do jogador está nomeada
- [ ] o orçamento de ms está declarado, com o pior caso nomeado
- [ ] as decisões sem volta estão congeladas **com o valor exato**
