# AGENT-STATE.md

> Arquivo **gerado** por `agent_verify.gd`. Nao edite fora do bloco LOCAL no fim.
> Versione este arquivo no git.

## Ambiente

| item | valor |
|---|---|
| engine | 4.7.2-stable (official) |
| kit | 1.5.2 |
| binario | `/usr/local/bin/godot` |
| instalado em | 2026-09-03T09:27:05 |
| metodo de deteccao | reload |
| deteccao — detalhe | GDScript.reload(true) devolve erro em script quebrado |

## Contagem

- scripts: 85
- cenas: 1
- recursos: 1
- modelos3d: 0
- strings_auditadas: 41

## Inventario do projeto

_A IA deve consultar esta secao antes de criar qualquer coisa nova, para nao reimplementar o que ja existe._

### Autoloads (5)

- `Bus`
- `Cfg`
- `SaveSys`
- `Audio`
- `Jogo`

### Acoes de input (115)

- `ui_accept`
- `ui_select`
- `ui_cancel`
- `ui_close_dialog`
- `ui_close_dialog.macos`
- `ui_focus_next`
- `ui_focus_prev`
- `ui_left`
- `ui_right`
- `ui_up`
- `ui_down`
- `ui_page_up`
- `ui_page_down`
- `ui_home`
- `ui_end`
- `ui_accessibility_drag_and_drop`
- `ui_cut`
- `ui_copy`
- `ui_focus_mode`
- `ui_paste`
- `ui_undo`
- `ui_redo`
- `ui_text_completion_query`
- `ui_text_completion_accept`
- `ui_text_completion_replace`
- `ui_text_newline`
- `ui_text_newline_blank`
- `ui_text_newline_above`
- `ui_text_indent`
- `ui_text_dedent`
- `ui_text_backspace`
- `ui_text_backspace_word`
- `ui_text_backspace_word.macos`
- `ui_text_backspace_all_to_left`
- `ui_text_backspace_all_to_left.macos`
- `ui_text_delete`
- `ui_text_delete_word`
- `ui_text_delete_word.macos`
- `ui_text_delete_all_to_right`
- `ui_text_delete_all_to_right.macos`
- `ui_text_caret_left`
- `ui_text_caret_word_left`
- `ui_text_caret_word_left.macos`
- `ui_text_caret_right`
- `ui_text_caret_word_right`
- `ui_text_caret_word_right.macos`
- `ui_text_caret_up`
- `ui_text_caret_down`
- `ui_text_caret_line_start`
- `ui_text_caret_line_start.macos`
- `ui_text_caret_line_end`
- `ui_text_caret_line_end.macos`
- `ui_text_caret_page_up`
- `ui_text_caret_page_down`
- `ui_text_caret_document_start`
- `ui_text_caret_document_start.macos`
- `ui_text_caret_document_end`
- `ui_text_caret_document_end.macos`
- `ui_text_caret_add_below`
- `ui_text_caret_add_below.macos`
- `ui_text_caret_add_above`
- `ui_text_caret_add_above.macos`
- `ui_text_scroll_up`
- `ui_text_scroll_up.macos`
- `ui_text_scroll_down`
- `ui_text_scroll_down.macos`
- `ui_text_select_all`
- `ui_text_select_word_under_caret`
- `ui_text_select_word_under_caret.macos`
- `ui_text_add_selection_for_next_occurrence`
- `ui_text_skip_selection_for_next_occurrence`
- `ui_text_clear_carets_and_selection`
- `ui_text_toggle_insert_mode`
- `ui_menu`
- `ui_text_submit`
- `ui_unicode_start`
- `ui_graph_duplicate`
- `ui_graph_delete`
- `ui_graph_follow_left`
- `ui_graph_follow_left.macos`
- `ui_graph_follow_right`
- `ui_graph_follow_right.macos`
- `ui_filedialog_delete`
- `ui_filedialog_up_one_level`
- `ui_filedialog_refresh`
- `ui_filedialog_show_hidden`
- `ui_filedialog_find`
- `ui_filedialog_focus_path`
- `ui_filedialog_focus_path.macos`
- `ui_swap_input_direction`
- `ui_colorpicker_delete_preset`
- `ui_pausa`
- `hab_1`
- `hab_2`
- `hab_3`
- `hab_4`
- `hab_5`
- `hab_6`
- `hab_7`
- `hab_8`
- `hab_9`
- `hab_0`
- `painel_upgrades`
- `painel_talentos`
- `painel_cartas`
- `painel_prestigio`
- `painel_conquistas`
- `painel_config`
- `comprar_max`
- `turbo`
- `alternar_auto`
- `salvar_agora`
- `tela_cheia`
- `debug_toggle`
- `purga`

### Classes globais (class_name) (37)

- `Arena  (res://scripts/sim/arena.gd)`
- `ArteFundo  (res://scripts/render/art_bg.gd)`
- `ArteInimigo  (res://scripts/render/art_enemy.gd)`
- `ArteTorre  (res://scripts/render/art_tower.gd)`
- `Bal  (res://scripts/data/balance.gd)`
- `Big  (res://scripts/core/big.gd)`
- `Coletavel  (res://scripts/sim/coletavel.gd)`
- `Combate  (res://scripts/sim/combat.gd)`
- `Dados  (res://scripts/data/db.gd)`
- `Diretor  (res://scripts/sim/waves.gd)`
- `Economia  (res://scripts/sim/economy.gd)`
- `EnemyAI  (res://scripts/sim/enemy_ai.gd)`
- `Eventos  (res://scripts/sim/events_sim.gd)`
- `Fmt  (res://scripts/core/fmt.gd)`
- `GameState  (res://scripts/sim/game_state.gd)`
- `Habilidades  (res://scripts/sim/abilities_sim.gd)`
- `Icone  (res://scripts/ui/icone.gd)`
- `Inimigo  (res://scripts/sim/inimigo.gd)`
- `Juice  (res://scripts/render/juice.gd)`
- `Mecanicas  (res://scripts/sim/mecanicas.gd)`
- `Mods  (res://scripts/sim/modifiers.gd)`
- `Musica  (res://scripts/audio/music.gd)`
- `NumerosDeDano  (res://scripts/render/damage_numbers.gd)`
- `Offline  (res://scripts/sim/offline.gd)`
- `Particulas  (res://scripts/render/particles.gd)`
- `Prestigio  (res://scripts/sim/prestige.gd)`
- `Progresso  (res://scripts/sim/progress.gd)`
- `Projetil  (res://scripts/sim/projetil.gd)`
- `RngX  (res://scripts/core/rngx.gd)`
- `Saque  (res://scripts/sim/loot.gd)`
- `Sfx  (res://scripts/audio/sfx.gd)`
- `StatEngine  (res://scripts/sim/stat_engine.gd)`
- `Synth  (res://scripts/audio/synth.gd)`
- `TorreSim  (res://scripts/sim/tower.gd)`
- `Txt  (res://scripts/core/textos.gd)`
- `UI  (res://scripts/ui/ui_kit.gd)`
- `Ux  (res://scripts/core/ux.gd)`

### Sinais declarados (59)

- `inimigo_surgiu  (res://scripts/core/event_bus.gd)`
- `inimigo_atingido  (res://scripts/core/event_bus.gd)`
- `inimigo_morreu  (res://scripts/core/event_bus.gd)`
- `banner_cinematico  (res://scripts/core/event_bus.gd)`
- `sequencia_diaria  (res://scripts/core/event_bus.gd)`
- `save_ilegivel  (res://scripts/core/event_bus.gd)`
- `inimigo_chegou  (res://scripts/core/event_bus.gd)`
- `chefe_surgiu  (res://scripts/core/event_bus.gd)`
- `chefe_morreu  (res://scripts/core/event_bus.gd)`
- `chefe_fase  (res://scripts/core/event_bus.gd)`
- `torre_atirou  (res://scripts/core/event_bus.gd)`
- `torre_atingida  (res://scripts/core/event_bus.gd)`
- `torre_caiu  (res://scripts/core/event_bus.gd)`
- `torre_renasceu  (res://scripts/core/event_bus.gd)`
- `combo_mudou  (res://scripts/core/event_bus.gd)`
- `combo_quebrou  (res://scripts/core/event_bus.gd)`
- `overkill  (res://scripts/core/event_bus.gd)`
- `ouro_ganho  (res://scripts/core/event_bus.gd)`
- `moeda_ganha  (res://scripts/core/event_bus.gd)`
- `upgrade_comprado  (res://scripts/core/event_bus.gd)`
- `talento_comprado  (res://scripts/core/event_bus.gd)`
- `carta_caiu  (res://scripts/core/event_bus.gd)`
- `carta_equipada  (res://scripts/core/event_bus.gd)`
- `onda_iniciou  (res://scripts/core/event_bus.gd)`
- `onda_limpa  (res://scripts/core/event_bus.gd)`
- `onda_falhou  (res://scripts/core/event_bus.gd)`
- `nivel_subiu  (res://scripts/core/event_bus.gd)`
- `conquista_desbloqueada  (res://scripts/core/event_bus.gd)`
- `missao_concluida  (res://scripts/core/event_bus.gd)`
- `prestigio_feito  (res://scripts/core/event_bus.gd)`
- `era_mudou  (res://scripts/core/event_bus.gd)`
- `desafio_iniciado  (res://scripts/core/event_bus.gd)`
- `desafio_concluido  (res://scripts/core/event_bus.gd)`
- `evento_sorteado  (res://scripts/core/event_bus.gd)`
- `desbloqueio  (res://scripts/core/event_bus.gd)`
- `habilidade_usada  (res://scripts/core/event_bus.gd)`
- `habilidade_pronta  (res://scripts/core/event_bus.gd)`
- `tremor_pedido  (res://scripts/core/event_bus.gd)`
- `hitstop_pedido  (res://scripts/core/event_bus.gd)`
- `flash_pedido  (res://scripts/core/event_bus.gd)`
- `zoom_pedido  (res://scripts/core/event_bus.gd)`
- `camera_lenta  (res://scripts/core/event_bus.gd)`
- `celebracao  (res://scripts/core/event_bus.gd)`
- `numero_dano  (res://scripts/core/event_bus.gd)`
- `particulas  (res://scripts/core/event_bus.gd)`
- `jogo_pronto  (res://scripts/core/event_bus.gd)`
- `ui_atualizar  (res://scripts/core/event_bus.gd)`
- `aviso  (res://scripts/core/event_bus.gd)`
- `tela_mudou  (res://scripts/core/event_bus.gd)`
- `painel_aberto  (res://scripts/core/event_bus.gd)`
- `config_mudou  (res://scripts/core/event_bus.gd)`
- `jogo_salvo  (res://scripts/core/event_bus.gd)`
- `relatorio_offline  (res://scripts/core/event_bus.gd)`
- `tutorial_passo  (res://scripts/core/event_bus.gd)`
- `painel_pedido  (res://scripts/ui/hud.gd)`
- `jogar  (res://scripts/ui/tela_titulo.gd)`
- `apagar_e_jogar  (res://scripts/ui/tela_titulo.gd)`
- `retomar  (res://scripts/ui/tela_pausa.gd)`
- `abrir_painel  (res://scripts/ui/tela_pausa.gd)`

### Grupos usados (0)

_nenhum_

## Falhas conhecidas (baseline)

_Isto e a foto do que ja falhava. Nao alarma. So mudanca em relacao a isto alarma._

<!-- BASELINE-JSON-START -->
```json
{
  "baseline": {},
  "meta": {
    "binario": "/usr/local/bin/godot",
    "engine": "4.7.2-stable (official)",
    "instalado_em": "2026-09-03T09:27:05",
    "kit_version": "1.5.2",
    "probe": {
      "detalhe": "GDScript.reload(true) devolve erro em script quebrado",
      "metodo": "reload"
    }
  }
}
```
<!-- BASELINE-JSON-END -->

## Local

<!-- LOCAL -->
_Espaco livre. Escreva aqui o que for especifico deste projeto._
_Este bloco nunca e sobrescrito._
<!-- /LOCAL -->
