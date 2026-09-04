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
		## Modo Infinito: as ondas deixam de ter intervalo e a contagem de
		## inimigos deixa de ter teto. É o desbloqueio do topo da árvore de Éter
		## (nó "Vazio Infinito"), que prometia isso e não tinha nada por trás.
		"modo_infinito": false,

		## A torre poupa o Peregrino? Sem isto a "escolha" que o jogo anuncia
		## se resolvia sozinha: nao havia como nao atirar nele.
		"poupar_peregrino": false,

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
		# Ver `scripts/sim/editos.gd`. Vive ate a Singularidade.
		"editos": {"ativos": [], "oferta": [], "vistos": 0},
		"missoes": {
			"diarias": [], "semanais": [],
			"reset_diario": 0, "reset_semanal": 0, "sequencia": 0, "ultimo_dia": 0,
			"rerrolagens_usadas": 0,
		},
		"desafios": {"ativo": "", "completos": {}, "tentativas": {}},
		# `unicos_vistos` precisa viver FORA do histórico: o histórico é rolante
		# (corta em 60) e era ele que servia de memória do "já vi". Os três
		# eventos de lore da torre voltavam ao sorteio assim que saíam da
		# janela — e como são os de maior peso do arquivo, voltavam logo.
		"eventos": {"ativo": "", "historico": [], "proximo_em": 180.0, "unicos_vistos": []},
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

		# Bônus permanentes ganhos de missões, conquistas e desafios. As 61
		# recompensas do tipo "stat" caíam num `_: pass` e sumiam em silêncio:
		# o jogador cumpria a missão, via o texto do prêmio e não ganhava nada.
		# Guardadas aqui, entram no cálculo de atributos como qualquer bônus.
		"bonus_permanentes": [],   # [{stat, tipoEfeito, valor, fonte}]

		"desbloqueios": {},
		"tutorial": {"passo": 0, "completo": false, "vistas": []},

		# --- coleções eternas: sobrevivem a TODOS os prestígios ---
		# Estavam sendo criadas na marra por Mecanicas (`if not s.has(...)`), o que
		# funcionava até a Transcendência montar um estado novo e apagar as duas.
		# O Panteão é o único sistema onde o jogador destrói cartas de verdade —
		# perder isso num prestígio é o pior tipo de bug que existe.
		"album": {},             # id da carta -> quando foi vista pela primeira vez
		"panteao": {},           # id do conjunto -> quantas vezes foi consagrado
		# O placar do Peregrino é o que decide o Fim Verdadeiro. Estava sendo
		# criado na marra por Mecanicas, então a Transcendência montava um estado
		# novo sem ele e a tela final sempre lia 0 × 0 — a única pergunta que o
		# jogo faz ao jogador, respondida com silêncio.
		"peregrinos_mortos": 0,
		"peregrinos_poupados": 0,
		"peregrino_onda": 0,
		"missoes_completas": 0,

		# --- estado de mecânica criado em tempo de execução ---
		# Estavam todos vindo à existência dentro de `Mecanicas`. Declarados aqui
		# eles ganham valor padrão, entram no save e param de sumir num reset.
		"caixa": {"seladas": 0, "abertas": 0},
		"purga": {"carga": 0.0, "auto": false, "usos": 0, "perfeitas": 0, "estourou": 0, "brilho": 0.0},
		"adaptacao": {},
		"retomada": {},
		"seg_por_onda_media": 18.0,
		# `versao_vista` guarda a ultima versao cuja tela de novidades ja subiu.
		# Ver `PanelManager._talvez_novidades`.
		"novidades": {"versao_vista": ""},

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
			# NaN e INF entram por save adulterado ou por bug antigo já gravado;
			# se passassem, o número contaminaria a simulação inteira e o próximo
			# `JSON.stringify` geraria arquivo inválido.
			var f := float(s)
			base[k] = f if is_finite(f) else b
		elif b is int and (s is int or s is float):
			var fi := float(s)
			base[k] = int(fi) if is_finite(fi) else b
		elif b is bool and s is bool:
			base[k] = s
		elif b is String and s is String:
			base[k] = s
		else:
			# Tipo trocado: MANTÉM o padrão. Antes qualquer coisa não-nula era
			# aceita, então um save em JSON perfeitamente válido mas com
			# `"onda": {}` fazia o `int(s["onda"])` estourar em todo quadro — e,
			# como o save é recarregado no boot, o jogo travava para sempre sem
			# jeito de sair a não ser apagando o arquivo na mão.
			push_warning("[save] campo '%s' com tipo trocado (%d, esperado %d) — padrão mantido" % [
				str(k), typeof(s), typeof(b)])
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

## Troca todo float não-finito do estado por um número são, e devolve quantos
## trocou.
##
## `SaveSys.salvar` já RECUSA gravar um estado que vira JSON inválido, e essa
## recusa é a última defesa — mas recusar para sempre, a cada vinte segundos,
## também custa a partida de quem joga. Um NaN que já entrou no estado só sai
## se alguém o tirar. Chamado antes de gravar: a recusa continua lá, agora só
## para o que este varredor não conseguiu consertar.
static func sanear(o) -> int:
	var trocas := 0
	if o is Dictionary:
		for k in o.keys():
			var v = o[k]
			if v is float and not is_finite(v):
				o[k] = Big.TETO_F if v > 0.0 else 0.0
				trocas += 1
			else:
				trocas += sanear(v)
	elif o is Array:
		for i in o.size():
			var v = o[i]
			if v is float and not is_finite(v):
				o[i] = Big.TETO_F if v > 0.0 else 0.0
				trocas += 1
			else:
				trocas += sanear(v)
	return trocas
