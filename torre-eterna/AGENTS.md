# AGENTS.md — Torre Eterna (Godot 4.4+, GDScript)

Este arquivo é o contrato de trabalho de quem (humano ou IA) mexe neste projeto.
As regras genéricas do **KIT-GODOT-V1** valem aqui; abaixo estão as **regras deste projeto**.

---

## Portões — rode todos antes de dizer que terminou

```bash
cd torre-eterna
godot --headless --path . -s res://tools/verificar.gd       # todo script compila, dados presentes
godot --headless --path . -s res://tools/lint.gd            # convenções do projeto
godot --headless --path . -s res://tools/validar_dados.gd   # conteúdo obedece ao contrato
godot --headless --path . -s res://tools/testes.gd          # 257 testes da simulação
godot --headless --path . -s res://tools/perf.gd -- 400      # custo de um passo com a arena cheia
godot --headless --path . -s res://agent_verify.gd          # verificação estrutural do kit

# E o portão que os testes não cobrem: uma hora de jogo de verdade, com a
# automação ligada, procurando erro em tempo de execução. Os testes chamam
# funções isoladas; só o simulador roda o laço inteiro por horas.
godot --headless --path . -s res://tools/sim_balance.gd -- 1 auto 2>&1 | grep -c "SCRIPT ERROR"   # tem que dar 0
```

Só `===STATUS=== PASS` conta. Ignore o código de saída do processo — o bloco é o contrato.
Se um portão falhar em algo que você não tocou, isso é **regressão real**: investigue antes de seguir.

O portão de desempenho é o único que depende da máquina, então ele mede a
máquina antes de julgar o jogo: uma conta fixa roda no começo e no fim do laço,
e o orçamento de 4000 us estica na mesma proporção (piso 1,0x, teto 3,0x). Ao
comparar duas medidas, use a linha **normalizado**, não o custo bruto — o bruto
muda com quem mais está usando a CPU, o normalizado não.

Antes de mexer em balanceamento, tire uma medida de base:
```bash
godot --headless --path . -s res://tools/sim_balance.gd -- 1
```
E compare depois. Se o tempo até a onda 25 / 50 mudar muito, foi você.

---

## Invariantes — nunca viole

1. **Nunca edite `.tscn`, `.tres` ou `project.godot` como texto.**
   `project.godot` é escrito por `tools/bootstrap.gd`; `scenes/main.tscn` por `tools/build_scene.gd`.
   Mudou uma configuração ou um autoload? Edite a ferramenta e rode a ferramenta.
2. **Nenhuma imagem, nenhum arquivo de som.** Toda arte é `_draw()`; todo som é PCM gerado.
   Se você precisou de um asset, o desenho é que está faltando.
3. **Nenhum emoji em texto de interface.** A fonte padrão não tem glifo — vira retângulo.
   Use `Icone` (`scripts/ui/icone.gd`); se o ícone não existe, desenhe um novo lá.
4. **Números gigantes são `log10`.** Ouro, dano, vida, XP e moedas passam por `Big`.
   `a + b` num valor desses é **bug silencioso** — use `Big.add`. Exiba com `Fmt.big`.
5. **Conteúdo em `data/*.json`, nunca no código.** Novo inimigo, carta, conquista ou era
   é um objeto no JSON; o código só ganha um `case` quando surge um comportamento novo.
6. **`.uid` acompanha o `.gd`.** Ao mover ou renomear script, o `.uid` vai junto.
6b. **Ferramenta `-s` não cita classe do jogo.** O Godot compila o script de entrada
   *antes* de registrar os autoloads, então uma classe que use `Bus`/`Cfg` falha a
   compilar — e falha de forma intermitente, que é pior. A entrada em `tools/` fica
   magra; o corpo mora em `tools/suites/` e é carregado dentro de `_initialize()`.
   O linter cobra isso.
6c. **Nenhuma string de interface escrita no código.** Sempre `Txt.t("chave")`.
   Chave nova vai em `data/i18n/<arquivo>.json` (um arquivo por painel), com `pt` e
   `en`. O linter recusa chave sem tradução e o validador recusa `pt` sem `en`.
7. **`.godot/` nunca vai para o git.**
8. **Nunca desative um teste, um portão ou um aviso para fazer algo passar.**
   Portão errado é informação: conserte o portão, não o contorne.

---

## Arquitetura — leia antes de escrever

**Fluxo:** `Jogo` (autoload) é dono do estado e do laço. Ele chama os módulos de simulação
(`Combate`, `EnemyAI`, `TorreSim`, `Diretor`, `Economia`, `Habilidades`, `Saque`, `Progresso`).
Quem simula **emite sinal** no `Bus`; quem apresenta (render, áudio, UI) **escuta**.
A simulação nunca conhece a interface.

**Estado:** um Dicionário puro em `scripts/sim/game_state.gd`, serializável em JSON.
Campo novo entra no `novo()` e é mesclado automaticamente em saves antigos por `mesclar()`.
Nada de função, nó ou referência circular dentro do estado.

**Atributos:** `StatEngine` agrega `(base + Σflat) × (1 + Σpct) × Πmult`. `Mods.recalcular()`
percorre todas as fontes. Isso roda quando algo muda (`jogo.marcar_sujo()`), **não a cada frame**.
Um `multiplicador × 0` anula o atributo de propósito — cartas de trade-off dependem disso.

**Simulação:** passo fixo em `_physics_process` (60 Hz). Aceleração e câmera lenta usam
`Engine.time_scale`. Hitstop pula o passo. A arena usa pooling e grade espacial — não crie
nós por inimigo.

**Interface:** construída em código, herdando de `scripts/ui/panel_base.gd`.
`atualizar()` só troca textos e valores; **reconstruir a árvore a cada tick trava o jogo**.

---

## GDScript — as três armadilhas deste projeto

1. **Acesso a Dicionário é `Variant`.** `var x := d["y"]` **não compila**.
   Sempre `var x: float = float(d["y"])`, `var e: Inimigo = lista[i]`, etc.
2. **Chamada em objeto sem tipo também é `Variant`.** `var v := jogo.stats.n("dano")` não compila;
   use `var v: float = jogo.stats.n("dano")`.
3. **`set_anchors_preset` não move o Control** — ele recalcula os offsets para *manter* o retângulo
   atual (que costuma ser 0×0). Use `set_anchors_and_offsets_preset`, ou defina âncoras e offsets
   você mesmo.

---

## Ao adicionar conteúdo

| Quero... | Edite | E confira |
|---|---|---|
| um inimigo | `data/enemies.json` | a `forma` precisa existir em `ArteInimigo.desenhar` |
| um chefe | `data/enemies.json` | a `mecanica` precisa ter um `case` em `Jogo.atualizar_chefe` |
| uma melhoria | `data/upgrades.json` | o `stat` precisa existir em `data/stats.json` |
| uma carta / relíquia | `data/cards.json`, `data/relics.json` | efeito segue `{stat, tipo, valor}` |
| uma conquista / missão / lore | `data/*.json` | `cond.tipo` precisa existir em `Progresso.valor_cond` |
| uma era | `data/eras.json` | `ceu.tipo` e `chao.tipo` precisam existir em `ArteFundo.desenhar` |
| uma habilidade | `data/abilities.json` | `tipo` precisa ter um `case` em `Habilidades.usar` |

`tools/validar_dados.gd` verifica **todas** essas amarrações. Rode-o.

---

## Relato

Cole a saída crua dos portões em bloco de código. Nada de "✅ tudo certo" ou de resumo
inventado. Falha se reporta como falha. `PASS` é integridade estrutural — não quer dizer
que o jogo ficou divertido. Isso só o jogador diz.
