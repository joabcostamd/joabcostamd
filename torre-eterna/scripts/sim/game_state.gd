class_name GameState
extends RefCounted

## Estado canônico do jogo — um Dicionário puro, serializável em JSON.
##
## Valores gigantes (ouro, dano, vida) são guardados em log10 (ver Big).
## Entidades voláteis (inimigos, projéteis, partículas) NÃO moram aqui.

const SLOTS_CARTAS_BASE := 3

static func novo() -> Dictionary:
	return {
		"versao": SaveSys.VERSAO,
		"criado_em": 0,
		"salvo_em": 0,
		"tick_em": 0,

		"moedas": {
			"ouro": Big.ZERO,
			"gemas": Big.ZERO,
			"fragmentos": Big.ZERO,
			"nucleos": Big.ZERO,
			"eter": Big.ZERO,
			"poeira": Big.ZERO,
		},

		"onda": 1,
		"onda_maxima": 1,
		"onda_maxima_global": 1,
		"mortos_na_onda": 0,
		"necessarios": 10,
		"em_chefe": false,
		"tempo_na_onda": 0.0,
		"modo_farm": false,
		"onda_farm": 1,

		"nivel": 1,
		"xp": Big.ZERO,
		"pontos_talento": 0,
		"pontos_talento_gastos": 0,

		# vida/escudo em log10 (Big), como todo valor que pode explodir
		"torre": {
			"vida": Big.from(100.0),
			"vida_max": Big.from(100.0),
			"escudo": Big.ZERO,
			"escudo_max": Big.ZERO,
			"viva": true,
			"tempo_morta": 0.0,
			"mira": "proximo",
		},

		"upgrades": {},          # id -> nivel
		"talentos": {},          # id -> nivel
		"relicas": {},           # id -> nivel
		"habilidades": {},       # id -> {desbloqueada, nivel, cd, cd_max, usos}

		"cartas": {
			"inventario": [],    # [{uid, id, raridade, nivel}]
			"equipadas": [],     # [uid|""]
			"novas": [],
			"proximo_uid": 1,
		},

		"conquistas": {},        # id -> timestamp
		"conquistas_vistas": [],
		"codex": {"inimigos": {}, "chefes": {}, "lore": {}},
		"missoes": {
			"diarias": [], "semanais": [],
			"reset_diario": 0, "reset_semanal": 0, "sequencia": 0, "ultimo_dia": 0,
		},
		"desafios": {"ativo": "", "completos": {}, "tentativas": {}},
		"eventos": {"ativo": "", "historico": [], "proximo_em": 180.0},
		"temporada": {"id": 0, "xp": 0, "nivel": 0, "coletadas": []},

		"prestigio": {
			"ascensoes": 0,
			"ultima_onda_asc": 0,
			"melhor_ascensao": 0,
			"singularidades": 0,
			"transcendencias": 0,
			"arvore_fragmentos": {},
			"arvore_nucleos": {},
			"arvore_eter": {},
			"auto_ascender": false,
			"auto_ascender_onda": 0,
		},

		"era": 0,
		"eras_vistas": [0],

		"auto": {
			"comprar": false,
			"comprar_modo": "barato",
			"habilidades": false,
			"reciclar": false,
			"velocidade": 1.0,
		},

		"stats": {
			"tempo_total": 0.0,
			"tempo_sessao": 0.0,
			"tempo_offline": 0.0,
			"mortos": 0,
			"chefes_mortos": 0,
			"dano_total": Big.ZERO,
			"dano_maximo": Big.ZERO,
			"ouro_total": Big.ZERO,
			"ouro_gasto": Big.ZERO,
			"criticos": 0,
			"tiros": 0,
			"mortes": 0,
			"combo_maximo": 0,
			"ondas_completas": 0,
			"cartas_obtidas": 0,
			"lendarios": 0,
			"habilidades_usadas": 0,
			"dourados": 0,
			"por_inimigo": {},
			"historico": [],
		},

		"desbloqueios": {},
		"tutorial": {"passo": 0, "completo": false, "vistas": []},

		# --- coleções eternas: sobrevivem a TODOS os prestígios ---
		# Estavam sendo criadas na marra por Mecanicas (`if not s.has(...)`), o que
		# funcionava até a Transcendência montar um estado novo e apagar as duas.
		# O Panteão é o único sistema onde o jogador destrói cartas de verdade —
		# perder isso num prestígio é o pior tipo de bug que existe.
		"album": {},             # id da carta -> quando foi vista pela primeira vez
		"panteao": {},           # id do conjunto -> quantas vezes foi consagrado
		"peregrinos_mortos": 0,
		"novidades": {},

		"buffs": [],             # [{id, stat, tipo, valor, restante, fonte, icone, cor}]
		"combo": {"atual": 0, "melhor": 0, "timer": 0.0},
		"pity": {"lendaria": 0, "dourado": 0},
	}

## Mescla um save carregado sobre o estado padrão (campos novos entram sozinhos).
static func mesclar(base: Dictionary, salvo: Dictionary) -> Dictionary:
	for k in base.keys():
		if not salvo.has(k):
			continue
		var b = base[k]
		var s = salvo[k]
		if b is Dictionary and s is Dictionary:
			# dicionários "livres" (upgrades, conquistas) copiam inteiro
			if b.is_empty():
				base[k] = s.duplicate(true)
			else:
				base[k] = mesclar(b, s)
		elif b is Array and s is Array:
			base[k] = s.duplicate(true)
		elif b is float and (s is float or s is int):
			base[k] = float(s)
		elif b is int and (s is int or s is float):
			base[k] = int(s)
		elif b is bool and s is bool:
			base[k] = s
		elif b is String and s is String:
			base[k] = s
		elif s != null:
			base[k] = s
	# chaves extras do save que não existem no padrão (dados de versões futuras)
	for k in salvo.keys():
		if not base.has(k):
			base[k] = salvo[k]
	return base

## Estado de uma habilidade (cria sob demanda).
static func hab(s: Dictionary, id: String) -> Dictionary:
	if not s["habilidades"].has(id):
		s["habilidades"][id] = {"desbloqueada": false, "nivel": 1, "cd": 0.0, "cd_max": 0.0, "usos": 0}
	return s["habilidades"][id]
