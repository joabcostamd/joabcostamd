---
name: auditar-jogo
description: "Use quando o pedido for auditar um jogo inteiro — 'audita o jogo', 'está pronto?', 'o que falta para lançar', 'me dá uma nota', 'revisa tudo', 'posso publicar?', 'o que preciso corrigir antes de vender', checklist de release, análise de qualidade, 'esse jogo aguenta a Steam?'. Coleta evidência automática em 0,3 s, dá nota nos 872 itens de AUDITORIA.md, entrega relatório com nota final e veredito, monta plano de correção priorizado passo a passo e executa as correções. Para UMA cena use godot-scene-doctor; para checagem estrutural isolada use o portão (agent_verify)."
---

# Auditar um jogo inteiro

> `agent_verify` responde "o projeto está íntegro?". `godot-scene-doctor` responde "esta cena
> está sã?". Esta skill responde "**este jogo está pronto para ser vendido?**" — e depois
> conserta o que não está.

A régua é o `AUDITORIA.md` da raiz do repositório: **872 itens, 55 blocos (A → BB)**, com
pesos, nota mínima por fase e reprovações automáticas nos blocos BC/BD/BE.

## Regras que não se negociam

1. **Nota sem evidência é zero** (item BE7). Toda nota carrega o fato que a sustenta.
2. **O coletor dá pista, não veredito.** `grep` produz falso positivo — em picross, `legenda`
   é rótulo de UI, não legenda de acessibilidade. Confirme abrindo o arquivo antes de pontuar.
3. **Não invente medição.** Item que exige o editor, playtest humano ou hardware real:
   marque `LOCAL` e não dê nota. Auditoria honesta vale mais que auditoria completa.
4. **Não despeje os 872 itens no chat.** Eles vão para o arquivo. O chat recebe o resumo.
5. **O plano é o produto.** Auditoria que não vira passo executável é texto bonito.

---

## Fase 0 — Escopo (3 perguntas, no máximo)

| Pergunta | Se o usuário não responder |
|---|---|
| Qual jogo? | o único `ATIVO` no `PORTFOLIO.md`; se houver vários, pergunte |
| Qual fase alvo — `P` protótipo, `A` alpha, `B` beta, `G` gold? | a próxima acima do estado atual |
| O que é `N/A`? | deduza da coleta: sem `.glb` → bloco Q e R são N/A; single player → AQ; só Steam → AY |

A fase alvo escolhe a coluna da tabela de pesos (bloco BC). É ela que decide o que é
**bloqueio** e o que é **melhoria**.

---

## Fase 1 — Coleta (roda em segundos, só fato)

```bash
ferramentas/auditar.sh <caminho-do-jogo>    # 0,3 s — evidência estrutural, sem opinião
cd <jogo> && ./testar.sh                    # portão frio + suíte — OBRIGATÓRIO
./simular.sh                                # se existir — alertas de balanceamento
```

Guarde a saída em `docs/auditoria/coleta-<AAAA-MM-DD>.txt`. Toda nota depois cita essa saída.

| A coleta **prova** | A coleta só **sugere** | A coleta **não vê** |
|---|---|---|
| autoload, cena principal, `.uid`, `.import`, `.gitignore` | opção de menu existir (grep pode errar) | se é divertido |
| contagem de cena, script, asset, linha | acessibilidade implementada | se a arte está bonita |
| ações de input map e se têm gamepad | tela de pausa existir | performance real |
| chaves de tradução e células vazias | qualidade do código | se o áudio está mixado |
| existência de teste, simulador, export preset | | qualquer coisa visual |

O que a coleta não vê fica com `LOCAL` ou com nota vinda de outra evidência (screenshot do
`godot-visual-check`, log do `godot-playtest-loop`, tabela do `./simular.sh`).

---

## Fase 2 — Dar as notas

Percorra o `AUDITORIA.md` bloco a bloco, nesta ordem — do barato para o caro:

1. **Objetivos, a coleta já respondeu:** C, E, F, M, AE, AF, AI, AK, AX
2. **Exigem ler código:** D, G, H, L, O, AU
3. **Exigem rodar:** AG, AH, AJ (use `godot-playtest-loop`, `simular-partidas`)
4. **Exigem ver ou jogar:** P, Q, R, S, T, U, V, Z, AA, AB, W, X, Y → na nuvem, `LOCAL`
5. **Exigem gente ou processo:** A, B, AJ, AN, AO, AV, BB → pergunte ou marque desconhecido

Para cada item, uma linha: `A1 8/10 — high concept está no DESIGN.md:3, uma frase.`
Item `N/A` sai da média. Item `LOCAL` sai da média e entra na lista "a medir na máquina".

---

## Fase 3 — Relatório: `docs/auditoria/RELATORIO-<data>.md`

Estrutura fixa:

```markdown
# Auditoria — <jogo> — <data>
Fase alvo: <P/A/B/G>   ·   Nota final: <x,x>/10   ·   Veredito: <BE5>

## Reprovações automáticas (BD)
<lista, ou "nenhuma">

## Notas por bloco
| Bloco | Nota | Mínimo da fase | Situação | Itens abaixo de 5 |
(Situação: OK · ABAIXO · LOCAL · N/A)

## Os 10 piores — maior (peso × distância do mínimo)

## Não medido nesta sessão (LOCAL)
<item + o que precisa para medir>

## Notas item a item
<os 872, com evidência>
```

Bloco abaixo do mínimo da fase **reprova a fase**, mesmo com média alta (BE3).

---

## Fase 4 — Plano: `docs/auditoria/PLANO-<data>.md`

Ordem de prioridade, nesta sequência e não em outra:

1. **Onda 0 — sangramento:** toda reprovação automática do bloco BD
2. **Onda 1 — bloqueio da fase:** todo bloco abaixo do mínimo da fase alvo
3. **Onda 2 — maior retorno:** ordene por `peso × (mínimo − nota) ÷ esforço`
4. **Onda 3 — polimento:** o resto, do maior peso para o menor

Cada passo, sem exceção:

```markdown
### [ ] P-07 · Input map sem gamepad  (bloco M, itens M6 M8 M19 M20)
**O que muda para o jogador:** o jogo passa a ser jogável de ponta a ponta no controle.
**Arquivos:** project.godot, scripts/telas/opcoes.gd, cenas/opcoes.tscn
**Skill:** godot-input
**Prova:** coleta mostra `acoes_com_gamepad` > 0 · `./testar.sh` verde · playtest local navega o menu só com o controle
**Esforço:** M   ·   **Depende de:** —
```

Regra: **nenhum passo maior que um commit.** Passo grande demais vira dois passos.
Passo que precisa de decisão sua (arte, preço, escopo) entra como `[?]` e para a onda.

---

## Fase 5 — Executar

Loop, um passo por vez, na ordem do plano:

1. **Teste que falha primeiro** — bug vira teste antes da correção (regra 6 do `CLAUDE.md`)
2. **Mude o mínimo** — só o que o passo pede, sem alargar
3. **Prove** — `./testar.sh` verde **e** a prova específica escrita no passo
4. **Commit** em português, no imperativo, dizendo o que mudou para o jogador
5. **Marque `[x]`** no PLANO e vá para o próximo

Ao fim de cada onda, rode `ferramentas/auditar.sh` de novo e **atualize as notas dos blocos
tocados** — o número tem que se mexer, senão o passo não fez nada.

**Pare e reporte** quando: duas tentativas falharem no mesmo passo · o passo exigir decisão
de design · a correção só for possível com o editor aberto (marque `LOCAL` e siga o próximo).

---

## Qual skill usa em cada bloco

| Blocos | Skill |
|---|---|
| A, B | `game-design-conceito`, `game-design-document` |
| C, AX | `godot-project-scaffold`, `godot-agent-verify`, `novo-jogo` |
| D, E | `godot-spec-driven`, `godot-api-guard` |
| G, I, J | `godot-prototype`, `godot-tilemap-levels`, `nivel-3d` |
| H | `simular-partidas`, `godot-balance-sim` |
| K, L | `godot-procgen`, `godot-ia-inimigos` |
| M | `godot-input` |
| N, O | `godot-camera`, `godot-fisica` |
| P, Q | `importar-assets-2d`, `importar-assets-3d`, `blender-3d-art-director` |
| R, S, T | `godot-3d`, `godot-visuais`, `godot-shaders-2d`, `godot-particles` |
| U, V | `godot-animacao`, `godot-game-feel` |
| W, X, Y | `godot-audio`, `godot-audio-procedural`, `musica-autoral` |
| Z, AA, AB, AC | `godot-ui-hud` |
| AD | `godot-ui-hud` + `godot-localization` |
| AE | `godot-localization` |
| AF | `godot-save-system` |
| AG, AH | `godot-performance`, `godot-runtime-debug`, `systematic-debugging` |
| AI | `godot-testing`, `godot-playtest-loop`, `godot-visual-check` |
| AJ | `telemetria`, `playtest-com-gente` |
| AK, AL, AM | `godot-export`, `godot-steam`, `publicar-itch` |
| AN, BB | `pagina-de-loja` |
| AT, AU | `game-design-document`, `domain-modeling` |

## O que não roda na nuvem

Todo bloco visual (P–V, Z–AB) e tudo que depende do MCP `godot-ai` ou do editor aberto.
Na nuvem eles saem como `LOCAL` com a instrução de como medir na máquina do Joab.
Nunca finja que rodou (seção 2 do `CLAUDE.md`).
