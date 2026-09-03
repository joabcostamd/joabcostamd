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
}

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
	Bus.prestigio_feito.connect(func(_c, _g): fila.clear(); atual = {}; queue_redraw())
	set_process(true)

func _ao_celebrar(tipo: String, dados: Dictionary) -> void:
	var receita: Dictionary = RECEITAS.get(tipo, {})
	if receita.is_empty():
		return
	# Fila curta de propósito: se sete coisas épicas acontecem juntas, mostrar
	# as sete em sequência vira fila de banco, não celebração.
	if fila.size() >= 3:
		return
	fila.append({"tipo": tipo, "receita": receita, "dados": dados})

func _process(dt: float) -> void:
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
	if atual.is_empty():
		return
	var receita: Dictionary = atual["receita"]
	var cor := Color.html(str(receita.get("cor", "#ffffff")))
	var peso := float(receita.get("peso", 1.0))
	var tam := size
	var centro := tam * 0.5

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
	var titulo := Txt.t(str(receita.get("titulo", "")))
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
		var ls := fonte.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		var ps := centro + Vector2(-ls * 0.5, raio + 92.0)
		var cs := Color(0.92, 0.95, 1.0, 0.86 * a)
		draw_string(fonte, ps + Vector2(1, 1), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0, 0, 0, 0.7 * a))
		draw_string(fonte, ps, sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, cs)

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
	return ""
