extends Control

## Camada de comemoração — o momento em que o jogo para tudo e diz "isso foi
## grande".
##
## Existe porque `Bus.celebracao` era emitido em sete lugares (Purga perfeita,
## Panteão consagrado, carta lendária, Fênix, nível de temporada, Retomada) e
## NINGUÉM escutava. O jogo tinha as conquistas mais raras acontecendo em
## silêncio absoluto.
##
## Regras de projeto:
## - uma comemoração por vez; a próxima entra na fila e espera a sua vez
## - nunca bloqueia o clique: é `MOUSE_FILTER_IGNORE` inteiro
## - respeita "movimento reduzido" (sem tremor de escala) e "flashes"
## - tudo desenhado, nada de asset

## Quanto o rodape (fileira de habilidades + botoes de painel) ocupa embaixo.
## A comemoracao sobe metade disso para nao escrever em cima deles.
const ALTURA_RODAPE := 180.0

const DUR_ENTRADA := 0.34
const DUR_SEGURA := 1.5
const DUR_SAIDA := 0.5

## tipo -> {titulo, cor, icone, som, peso}
## `peso` alto = evento mais raro = comemoração maior.
## `som` sai do catálogo de `scripts/audio/sfx.gd` — nada de nome inventado.
const RECEITAS := {
	"purga_perfeita": {"titulo": "cel_purga", "cor": "#fde047", "icone": "nova", "som": "morte_chefe", "peso": 1.0},
	"panteao":        {"titulo": "cel_panteao", "cor": "#a855f7", "icone": "reliquia", "som": "prestigio", "peso": 1.25},
	"lendario":       {"titulo": "cel_lendario", "cor": "#f59e0b", "icone": "carta", "som": "lendario", "peso": 1.0},
	"fenix":          {"titulo": "cel_fenix", "cor": "#fb7185", "icone": "coracao", "som": "hab_cura", "peso": 1.15},
	"temporada":      {"titulo": "cel_temporada", "cor": "#38bdf8", "icone": "estrela", "som": "conquista", "peso": 0.85},
	"retomada":       {"titulo": "cel_retomada", "cor": "#f97316", "icone": "alvo", "som": "alerta_chefe", "peso": 0.8},
	"retomada_superada": {"titulo": "cel_retomada_ok", "cor": "#4ade80", "icone": "trofeu", "som": "conquista", "peso": 1.0},
	# ASCENDER PESAVA MENOS NA TELA QUE UMA PURGA. A decisao mais dificil do
	# jogo — largar tudo o que voce construiu — dava um banner de 2,6 s com o
	# identificador cru escrito nele, enquanto uma Purga bem cronometrada (que
	# acontece a cada poucos minutos) ganhava a camada inteira de comemoracao.
	# Peso 1,6: e o maior do catalogo, e e para ser.
	"prestigio":      {"titulo": "", "cor": "#a855f7", "icone": "prestigio", "som": "prestigio", "peso": 1.6},
	# AS DEZ ERAS NUNCA DIZIAM O NOME. `Bus.era_mudou` tinha um unico ouvinte, o
	# pintor de fundo: o mundo mudava de cor e ninguem explicava por que. Cada
	# era traz `nome` e `regra.texto` escritos e revisados nos dois idiomas, e
	# nenhum dos dois chegava aos olhos de quem joga.
	"era":            {"titulo": "", "cor": "#38bdf8", "icone": "nova", "som": "conquista", "peso": 1.35},
	# O marco de melhoria acontece dezenas de vezes por corrida: peso baixo de
	# proposito, para ser um aceno e nao uma interrupcao.
	"marco":          {"titulo": "cel_marco", "cor": "#fbbf24", "icone": "estrela", "som": "nivel", "peso": 0.7},
}

## Quem manda os painéis. `main.gd` entrega no momento da montagem — caminho de
## nó escrito na mão apodrece na primeira vez que alguém renomeia um nó.
var gerente: Node

var fila: Array = []
var atual: Dictionary = {}
var t := 0.0
var raios: Array = []

func _ready() -> void:
	name = "Celebracao"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Bus.celebracao.connect(_ao_celebrar)
	# A ordem importa: o prestigio limpa a fila (as comemoracoes da corrida que
	# acabou nao fazem mais sentido) e SO ENTAO entra a dele.
	Bus.prestigio_feito.connect(_ao_prestigio)
	Bus.era_mudou.connect(_ao_era)
	Bus.banner_cinematico.connect(func(seg: float): _banner_ate = maxf(_banner_ate, float(seg)))
	set_process(true)

func _ao_prestigio(camada: String, ganho: float) -> void:
	fila.clear()
	atual = {}
	queue_redraw()
	var def: Dictionary = {}
	for c in Dados.camadas_prestigio:
		if str((c as Dictionary).get("id", "")) == camada:
			def = c
			break
	_ao_celebrar("prestigio", {"camada": camada, "ganho": ganho, "def": def})

func _ao_era(_indice: int, era: Dictionary) -> void:
	if era.is_empty():
		return
	_ao_celebrar("era", {"era": era})

func _ao_celebrar(tipo: String, dados: Dictionary) -> void:
	var receita: Dictionary = RECEITAS.get(tipo, {})
	if receita.is_empty():
		return
	# Fila curta de propósito: se sete coisas épicas acontecem juntas, mostrar
	# as sete em sequência vira fila de banco, não celebração.
	if fila.size() >= 3:
		return
	fila.append({"tipo": tipo, "receita": receita, "dados": dados})

## Com um painel aberto a comemoração espera. Ela é desenhada acima de tudo (a
## camada de UI inteira) e, sem esta guarda, cobria o painel que o jogador
## estava lendo — o oposto do que uma comemoração deve fazer.
## Quanto tempo ainda resta de banner cinematografico na tela.
var _banner_ate := 0.0

func _ocupado() -> bool:
	if gerente != null and is_instance_valid(gerente) and str(gerente.atual) != "":
		return true
	# O BANNER DO CHEFE E A COMEMORACAO DISPUTAM A MESMA FAIXA DA TELA.
	#
	# O banner ocupa de 26% a 26%+74px da altura; a comemoracao desenha um veu
	# de tela cheia, catorze raios e dois aneis em volta do centro, cobrindo
	# essa faixa de ponta a ponta. E o encontro nao e raro: `waves.gd` emite
	# `era_mudou` uma linha antes de `onda_iniciou`, e as eras comecam em ondas
	# multiplas de 10 — que sao ondas de chefe. Nessas ondas o nome do chefe e a
	# dica dele, unica orientacao tatica que o jogo da na hora que serve, saiam
	# por baixo dos raios. O marco de melhoria cai na mesma armadilha sempre que
	# a pessoa gasta ouro no comeco de uma onda de chefe.
	#
	# Os avisos de rodape ja aprenderam a fugir do banner do mesmo jeito (ver
	# `panel_manager`); a comemoracao so nao tinha sido ensinada.
	if _banner_ate > 0.0:
		return true
	return get_tree().paused

## Estava ocupado no quadro anterior? Serve só para limpar o desenho UMA vez
## quando o painel abre, em vez de pedir redesenho a cada quadro parado.
var _estava_ocupado := false

func _process(dt: float) -> void:
	# A GUARDA VALE PARA A COMEMORAÇÃO EM ANDAMENTO, NÃO SÓ PARA A PRÓXIMA.
	#
	# A guarda só impedia de COMEÇAR. Uma comemoração que já estava rodando
	# continuava desenhando por cima do painel que abrisse no meio dela — e é
	# fácil cair nisso, porque virar de era e abrir o painel de melhorias para
	# gastar o ouro da onda é a sequência mais natural do jogo. Nas capturas de
	# tela o nome da era ficou escrito atravessado em cima da lista de
	# melhorias, das cartas e da árvore de talentos.
	#
	# Agora ela CONGELA: para de contar o tempo e some da tela enquanto o painel
	# estiver aberto, e volta de onde parou quando ele fechar. Deixar o relógio
	# correndo escondido seria pior — a pessoa perderia a comemoração inteira
	# sem nunca vê-la.
	if _banner_ate > 0.0:
		_banner_ate = maxf(0.0, _banner_ate - dt)
	var ocupado := _ocupado()
	if ocupado:
		if not _estava_ocupado:
			_estava_ocupado = true
			queue_redraw()
		return
	if _estava_ocupado:
		_estava_ocupado = false
		queue_redraw()
	if atual.is_empty():
		if fila.is_empty():
			return
		atual = fila.pop_front()
		t = 0.0
		_semear_raios()
		Audio.tocar(str(atual["receita"].get("som", "conquista")), 1.5)
		return
	t += dt
	if t >= DUR_ENTRADA + DUR_SEGURA + DUR_SAIDA:
		atual = {}
	queue_redraw()

## Raios de luz saindo do centro, com ângulos fixos por comemoração — sorteados
## uma vez e não a cada quadro, senão a imagem "ferve".
func _semear_raios() -> void:
	raios.clear()
	var n := 14
	for i in n:
		raios.append({
			"ang": TAU * float(i) / float(n) + randf_range(-0.09, 0.09),
			"comp": randf_range(0.45, 1.0),
			"larg": randf_range(2.0, 7.0),
		})

func _draw() -> void:
	# Nada na tela enquanto houver painel aberto ou o jogo pausado: é a mesma
	# guarda do `_process`, aplicada onde a tinta acontece.
	if _ocupado():
		return
	if atual.is_empty():
		return
	var receita: Dictionary = atual["receita"]
	var cor := _cor_do_momento(receita)
	var peso := float(receita.get("peso", 1.0))
	var tam := size
	# O CENTRO DA COMEMORACAO NAO E O CENTRO DA TELA.
	#
	# O titulo sai `raio + 62` abaixo do centro e o subtitulo mais 23 por linha:
	# numa tela de 720 isso caia em cima da barra de habilidades e do rodape de
	# botoes, e as duas coisas ficavam ilegiveis ao mesmo tempo — a comemoracao
	# e a barra que ela cobria. O rodape ocupa os ultimos `UI.RODAPE_FOLGA` mais
	# a fileira de habilidades; subir o bloco inteiro resolve sem encolher
	# nenhuma letra.
	var centro := Vector2(tam.x * 0.5, tam.y * 0.5 - ALTURA_RODAPE * 0.5)

	# curva: entra rápido, segura, sai suave
	var a := 0.0
	var pop := 0.0
	if t < DUR_ENTRADA:
		var k := t / DUR_ENTRADA
		a = k
		pop = Ux.ease_out_back(k)
	elif t < DUR_ENTRADA + DUR_SEGURA:
		a = 1.0
		pop = 1.0
	else:
		var k := (t - DUR_ENTRADA - DUR_SEGURA) / DUR_SAIDA
		a = 1.0 - k * k
		pop = 1.0 + k * 0.12

	var reduzido := bool(Cfg.get_v("movimento_reduzido", false))
	if reduzido:
		pop = 1.0

	# véu escuro: dá contraste ao texto sem esconder o campo
	draw_rect(Rect2(Vector2.ZERO, tam), Color(0.02, 0.03, 0.06, 0.34 * a))

	# Raios: cunhas que afinam para fora, não linhas de espessura constante.
	# Linha reta com a mesma largura nas duas pontas lê como graveto; a cunha
	# lê como luz saindo de dentro.
	if bool(Cfg.get_v("flashes", true)):
		var alcance := maxf(tam.x, tam.y) * 0.62
		for r in raios:
			var ang := float(r["ang"]) + t * 0.35
			var comp := alcance * float(r["comp"]) * pop
			var dir := Vector2(cos(ang), sin(ang))
			var perp := Vector2(-dir.y, dir.x)
			var meia := float(r["larg"]) * 0.5
			var c := cor
			c.a = 0.20 * a
			draw_colored_polygon(PackedVector2Array([
				centro + perp * meia,
				centro - perp * meia,
				centro + dir * comp,
			]), c)

	# anel pulsando
	var raio := 92.0 * pop
	var anel := cor
	anel.a = 0.85 * a
	draw_arc(centro, raio, 0.0, TAU, 64, anel, 3.0, true)
	anel.a = 0.22 * a
	draw_arc(centro, raio * 1.28, 0.0, TAU, 64, anel, 10.0, true)

	# ícone no meio do anel
	var ic := cor
	ic.a = a
	Icone.desenhar(self, str(receita.get("icone", "estrela")), centro, 46.0 * pop, ic)

	# título
	var fonte := ThemeDB.fallback_font
	var titulo := _titulo()
	var tam_fonte := int(round((34.0 + 10.0 * peso) * (1.0 if reduzido else pop)))
	var larg := fonte.get_string_size(titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_fonte).x
	var pos_t := centro + Vector2(-larg * 0.5, raio + 62.0)
	var sombra := Color(0, 0, 0, 0.75 * a)
	for off in [Vector2(2, 2), Vector2(-2, 2), Vector2(2, -2), Vector2(-2, -2)]:
		draw_string(fonte, pos_t + off, titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_fonte, sombra)
	var ct := cor
	ct.a = a
	draw_string(fonte, pos_t, titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_fonte, ct)

	# subtítulo: o detalhe concreto do que acabou de acontecer
	var sub := _subtitulo()
	if sub != "":
		# A REGRA DA ERA E UMA FRASE INTEIRA, nao um numero. O subtitulo era uma
		# linha so, centrada e sem limite: numa janela estreita ela saia pelos
		# dois lados da tela. Quebra em ate tres linhas dentro da largura util.
		var util := minf(tam.x - 80.0, 760.0)
		var linhas_sub := _quebrar(sub, fonte, 17, util, 3)
		var cs := Color(0.92, 0.95, 1.0, 0.86 * a)
		var y := raio + 92.0
		for linha_s in linhas_sub:
			var ls := fonte.get_string_size(linha_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
			var ps := centro + Vector2(-ls * 0.5, y)
			draw_string(fonte, ps + Vector2(1, 1), linha_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0, 0, 0, 0.7 * a))
			draw_string(fonte, ps, linha_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, cs)
			y += 23.0

## Quebra por palavra dentro de `largura`, no maximo `maxlin` linhas. A ultima
## linha ganha reticencias se sobrar texto — melhor cortar do que vazar.
static func _quebrar(texto: String, fonte: Font, tamanho: int, largura: float, maxlin: int) -> Array:
	var saida: Array = []
	var atual_l := ""
	for palavra in texto.split(" ", false):
		var tentativa := palavra if atual_l == "" else atual_l + " " + palavra
		if fonte.get_string_size(tentativa, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x <= largura:
			atual_l = tentativa
			continue
		if atual_l != "":
			saida.append(atual_l)
		atual_l = palavra
		if saida.size() >= maxlin:
			break
	if atual_l != "" and saida.size() < maxlin:
		saida.append(atual_l)
	if saida.size() >= maxlin and not saida.is_empty():
		var ultima := str(saida[saida.size() - 1])
		if not texto.ends_with(ultima):
			saida[saida.size() - 1] = ultima + "…"
	return saida

## O título: fixo por receita, ou o nome que vem no evento (era, camada de
## prestígio). Cor também: a era e a camada trazem a sua.
func _titulo() -> String:
	var d: Dictionary = atual.get("dados", {})
	match str(atual.get("tipo", "")):
		"era":
			return Ux.txt(d.get("era", {}), "nome", Cfg.ingles()).to_upper()
		"prestigio":
			var def: Dictionary = d.get("def", {})
			if def.is_empty():
				return str(d.get("camada", "")).to_upper()
			return Ux.txt(def, "nome", Cfg.ingles()).to_upper()
	return Txt.t(str((atual.get("receita", {}) as Dictionary).get("titulo", "")))

func _cor_do_momento(receita: Dictionary) -> Color:
	var d: Dictionary = atual.get("dados", {})
	match str(atual.get("tipo", "")):
		"era":
			var era: Dictionary = d.get("era", {})
			var pal: Dictionary = era.get("paleta", {})
			if pal.has("acento2"):
				return Color.html(str(pal["acento2"]))
		"prestigio":
			var def: Dictionary = d.get("def", {})
			if def.has("cor"):
				return Color.html(str(def["cor"]))
	return Color.html(str(receita.get("cor", "#ffffff")))

## O número que dá peso ao momento. Sem ele a celebração é genérica.
func _subtitulo() -> String:
	var d: Dictionary = atual.get("dados", {})
	match str(atual.get("tipo", "")):
		"purga_perfeita":
			return Txt.f("cel_purga_sub", {"n": int(d.get("mortos", 0))})
		"panteao":
			return Txt.f("cel_panteao_sub", {"n": int(d.get("nivel", 1))})
		"lendario":
			var carta = d.get("carta", null)
			if carta is Dictionary:
				var def: Dictionary = Dados.carta_por_id.get(str(carta.get("id", "")), {})
				if not def.is_empty():
					return Ux.txt(def, "nome", Cfg.ingles())
			return ""
		"temporada":
			return Txt.f("cel_temporada_sub", {"n": int(d.get("nivel", 1))})
		"retomada":
			return Txt.f("cel_retomada_sub", {"n": int(d.get("alvo", 0))})
		"retomada_superada":
			return Txt.f("cel_retomada_ok_sub", {"n": int(d.get("onda", 0))})
		"prestigio":
			var def: Dictionary = d.get("def", {})
			var moeda := str(def.get("moeda", ""))
			var nome_moeda := Txt.t("m_" + moeda) if moeda != "" else ""
			return "+%s %s" % [Fmt.big(float(d.get("ganho", Big.ZERO))), nome_moeda]
		"marco":
			var def_u: Dictionary = d.get("upgrade", {})
			return Txt.f("cel_marco_sub", {
				"u": Ux.txt(def_u, "nome", Cfg.ingles()), "n": int(d.get("nivel", 0))})
		"era":
			# A REGRA da era, que e a unica coisa que muda o jogo. Se a era nao
			# tiver regra (a primeira nao tem), fica a descricao.
			var era: Dictionary = d.get("era", {})
			var regra: Dictionary = era.get("regra", {})
			var t_regra := Ux.txt(regra, "texto", Cfg.ingles()) if not regra.is_empty() else ""
			return t_regra if t_regra != "" else Ux.txt(era, "descricao", Cfg.ingles())
	return ""
