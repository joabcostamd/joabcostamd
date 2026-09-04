# Contrato de UI e Áudio — Tower Zero (Godot 4.4, GDScript)

Projeto: `/home/user/joabcostamd/torre-eterna`. **Toda a interface é construída em código.**
Nunca crie/edite `.tscn`, `.tres` ou `project.godot` — nem à mão nem por ferramenta.

## Verificação (rode SEMPRE antes de dizer que terminou)
```
cd /home/user/joabcostamd/torre-eterna
godot --headless --path . -s res://tools/verificar.gd
```
Só `===STATUS=== PASS` conta. Se der erro de concorrência, espere 10s e rode de novo (1 vez).

## Ver o resultado na tela (você CONSEGUE olhar a imagem com a ferramenta Read)
```
xvfb-run -a --server-args="-screen 0 1280x720x24" godot --path . --resolution 1280x720 \
  -- --shot=3 --painel=<nome-do-painel> --saida=/tmp/meu_painel.png
```
Depois `Read` em `/tmp/meu_painel.png`. Ajuste o layout até ficar bonito e legível.
Use um `--saida` com nome único (dois agentes rodam ao mesmo tempo).

## Como um painel é criado
`scripts/ui/panel_manager.gd` faz `Control.new()` + `set_script(...)` e adiciona à raiz da UI.
Portanto **todo painel começa com**:
```gdscript
extends "res://scripts/ui/panel_base.gd"
```
e implementa:
- `func configurar() -> void:` define `titulo_texto`, `titulo_icone`, `largura`, `altura`, `intervalo`
- `func montar(c: VBoxContainer) -> void:` monta o conteúdo dentro de `c`
- `func atualizar() -> void:` chamado a cada `intervalo` segundos (NÃO reconstrua a árvore aqui — só troque textos/valores)

Herda de `panel_base.gd`: `jogo` (autoload Jogo), `janela`, `corpo`, `fechar_painel()`,
`linha(icone, cor) -> {caixa, icone, textos, direita, linha}`, `custo_label(moeda, valor_log, tem)`,
`txt(dicionario, campo)` (texto bilíngue).

**LEIA E IMITE `scripts/ui/panel_upgrades.gd`** — é o painel-modelo. Mesmo nível de acabamento.

## Ferramentas de UI disponíveis
- `UI` (`scripts/ui/ui_kit.gd`): cores (`UI.ACENTO`, `UI.OURO`, `UI.VERDE`, `UI.VERMELHO`, `UI.TEXTO`,
  `UI.TEXTO2`, `UI.TEXTO3`, `UI.PAINEL`, `UI.PAINEL2`, `UI.BORDA`, `UI.RARIDADE_COR`, `UI.MOEDA_COR`),
  `UI.rotulo/titulo/botao/vbox/hbox/painel/barra/scroll/separador/espacador/caixa`,
  `UI.pulsar(control, cor)` e `UI.saltar(control, forca)` para feedback.
- `Icone` (`scripts/ui/icone.gd`): ícones VETORIAIS. **A fonte não tem emoji — nunca use emoji.**
  Nomes: ouro, gema, fragmento, nucleo, eter, poeira, espada, arvore, carta, prestigio, trofeu,
  engrenagem, livro, missao, desafio, reliquia, stats, coracao, escudo, alvo, velocidade, salvar,
  pausa, fechar, mais, cadeado, raio, fogo, gelo, veneno, vazio, orbe, nova, ampulheta, estrela,
  cura, balanca, foguete, torre. Use assim:
  ```gdscript
  var ic := Control.new()
  ic.set_script(load("res://scripts/ui/icone_control.gd"))
  algum_container.add_child(ic)
  ic.configurar("trofeu", UI.OURO, 22)   # (nome, cor, tamanho) — só DEPOIS de add_child
  ```
- `Fmt.big(v_log)`, `Fmt.num(v)`, `Fmt.pct(f)`, `Fmt.inteiro(n)`, `Ux.tempo_curto(s)`.

## Números gigantes
Ouro, dano, vida etc. são guardados em **log10** (classe `Big`). Nunca use `+`/`*` neles:
`Big.add/sub/mul/div/mul_f/div_f/gt/gte/lt/lte/is_zero/frac/to_f/from(n)/from_log(x)`.
Exibição: `Fmt.big(valor_log)`.

## Estado e ações (autoload `Jogo`, veja `scripts/sim/game.gd`)
`jogo.s` é o Dicionário de estado (`scripts/sim/game_state.gd` lista TODOS os campos).
`jogo.stats.n("chave")` = atributo numérico; `jogo.stats.b("chave")` = atributo em log10.
`jogo.esp` = especiais (slotsCartas, ondaInicial, desbloqueios…). `jogo.pas` = passivas.
Ações prontas: `comprar_upgrade(id, qtd)`, `comprar_talento(id)`, `comprar_no(id, qtd)`,
`comprar_reliquia(id, qtd)`, `melhorar_habilidade(id)`, `usar_habilidade(id)`,
`ascender()/colapsar()/transcender()`, `iniciar_desafio(id)`, `redistribuir_talentos()`,
`definir_mira(m)`, `definir_velocidade(v)`, `alternar_farm()`, `salvar()/exportar()/importar(txt)/apagar_tudo()`.
Módulos: `Prestigio`, `Saque` (cartas), `Progresso` (conquistas/missões/temporada), `Habilidades`, `Economia`.

## Dados (autoload estático `Dados`, veja `scripts/data/db.gd`)
`Dados.upgrades/talentos/ramos/habilidades/cartas/conjuntos/reliquias/conquistas/categorias_conquista/
missoes_diarias/missoes_semanais/temporada/eventos/desafios/eras/entradas_lore/capitulos_lore/dicas/
raridades/inimigos/chefes/elites/stat_defs/stat_grupos` + índices `*_por_id`.
Campos em PT com par em inglês (`nome`/`nomeEn`) — use `txt(def, "nome")`.

## Sinais (autoload `Bus`, veja `scripts/core/event_bus.gd`)
Escute o que precisar (`Bus.upgrade_comprado`, `Bus.nivel_subiu`, `Bus.carta_caiu`, …).
Avisos rápidos: `Bus.toast("texto", "bom"|"ruim"|"info"|"epico")`.

## Regras de qualidade (não negociáveis)
1. Nada de emoji, nada de imagem externa, nada de `.tscn`.
2. Tipos explícitos quando o valor vem de Dicionário/Variant: `var x: float = float(d["y"])`.
   GDScript não infere tipo de acesso a Dicionário — `var x := d["y"]` NÃO compila.
3. O painel deve caber em 1280×720 e rolar quando o conteúdo for maior (`UI.scroll()`).
4. `atualizar()` só troca textos/valores. Reconstruir a árvore a cada 0,2s trava o jogo.
5. Estados vazios sempre com texto amigável ("Nenhuma carta ainda — derrote um chefe.").
6. Tooltips (`tooltip_text`) explicando o que cada coisa faz, em PT-BR.
7. Feedback ao comprar/coletar: `UI.pulsar(...)` + `Bus.toast(...)`.
8. Cores por raridade/moeda vindas de `UI.RARIDADE_COR` / `UI.MOEDA_COR`.
