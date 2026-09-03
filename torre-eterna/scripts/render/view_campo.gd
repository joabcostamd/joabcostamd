extends Node2D

## Camada do campo de batalha: inimigos, torre, projéteis, coletáveis,
## partículas e números de dano. Um único _draw() para tudo (rápido e coeso).

var jogo: Node
var particulas := Particulas.new()
var numeros := NumerosDeDano.new()
var juice := Juice.new()
var t := 0.0
var mostrar_alcance := true

func _ready() -> void:
	z_index = 0
	jogo = get_node_or_null("/root/Jogo")
	_conectar()
	_aplicar_config()
	Bus.config_mudou.connect(func(_k, _v): _aplicar_config())

func _aplicar_config() -> void:
	particulas.densidade = Cfg.densidade_particulas()
	numeros.densidade = particulas.densidade
	numeros.modo = int(Cfg.get_v("numeros_dano", 0))

func _conectar() -> void:
	Bus.inimigo_atingido.connect(_ao_atingir)
	Bus.inimigo_morreu.connect(_ao_morrer)
	Bus.torre_atingida.connect(_ao_torre_atingida)
	Bus.torre_caiu.connect(_ao_torre_cair)
	Bus.particulas.connect(_ao_particulas)
	Bus.tremor_pedido.connect(func(a, d): juice.tremer(a, d))
	Bus.camera_lenta.connect(func(e, ms): juice.camera_lenta(e, ms))
	Bus.flash_pedido.connect(func(c, f): juice.flash(c, f))
	Bus.zoom_pedido.connect(func(f): juice.zoom_punch(f))
	Bus.onda_iniciou.connect(_ao_onda)
	Bus.combo_mudou.connect(_ao_combo)
	Bus.prestigio_feito.connect(func(_c, _g): particulas.limpar(); numeros.limpar())

func _ao_atingir(e, dano_log: float, critico: bool, elemento: String) -> void:
	var cor := Color.WHITE
	if critico:
		cor = Color("#fde047")
	elif elemento != "":
		cor = Color.html(str(Bal.ELEMENTOS.get(elemento, {}).get("cor", "#ffffff")))
	numeros.adicionar(e.pos + Vector2(0, -e.raio), Fmt.big(dano_log), cor, critico, 1.0 + (0.25 if e.chefe else 0.0))
	if critico:
		juice.tremer(2.6, 0.09)

func _ao_morrer(e, _ouro: float) -> void:
	particulas.morte(e.pos, e.cor, e.escala, e.chefe)
	if e.chefe:
		juice.tremer(20.0, 0.6)
		juice.flash(Color(1, 1, 1), 0.3)
		juice.zoom_punch(0.05)
	elif e.dourado:
		particulas.anel(e.pos, Color("#fcd34d"), 70.0, 0.5, 4.0)
		juice.tremer(4.0, 0.15)

func _ao_torre_atingida(dano: float, vida: float, vida_max: float) -> void:
	if dano <= 0.0:
		return
	var frac := dano / maxf(1.0, vida_max)
	juice.tremer(clampf(4.0 + frac * 90.0, 3.0, 22.0), 0.22)
	juice.flash(Color(1, 0.25, 0.25), clampf(frac * 2.2, 0.06, 0.32))
	particulas.faisca(jogo.arena.centro, Color("#f87171"), 8, 160.0)
	if vida / maxf(1.0, vida_max) < 0.25:
		juice.flash(Color(1, 0.1, 0.1), 0.18)

func _ao_torre_cair() -> void:
	juice.tremer(34.0, 1.1)
	juice.flash(Color(1, 0.2, 0.2), 0.5)
	particulas.explosao(jogo.arena.centro, 220.0, Color("#f87171"))
	juice.camera_lenta(0.35, 900.0)

func _ao_onda(_n: int, eh_chefe: bool) -> void:
	if eh_chefe:
		juice.flash(Color("#f43f5e"), 0.22)
		juice.tremer(9.0, 0.4)

func _ao_combo(v: int) -> void:
	if v > 0 and v % 25 == 0:
		juice.zoom_punch(0.02)

## Aceita cor como Color ou como string "#rrggbb".
static func _para_cor(v) -> Color:
	if v is Color:
		return v
	var s := str(v)
	if s.begins_with("#") or s.length() in [6, 8]:
		return Color.html(s if s.begins_with("#") else "#" + s)
	return Color.WHITE

func _ao_particulas(tipo: String, pos: Vector2, dados: Dictionary) -> void:
	var cor := _para_cor(dados.get("cor", "#ffffff"))
	match tipo:
		"impacto":
			particulas.impacto(pos, float(dados.get("ang", 0.0)), cor, bool(dados.get("crit", false)))
		"explosao":
			particulas.explosao(pos, float(dados.get("raio", 60.0)), cor)
			juice.tremer(clampf(float(dados.get("raio", 60.0)) * 0.05, 2.0, 12.0), 0.2)
		"pulso":
			particulas.anel(pos, cor, float(dados.get("raio", 80.0)), 0.5, 3.0)
		"faisca":
			particulas.faisca(pos, cor, 5, 110.0)
		"feixe":
			particulas.feixe(pos, dados.get("para", pos), cor, 0.12)
		"raio":
			particulas.raio_linha(dados.get("pontos", []), cor, 0.22)
		"nova":
			particulas.nova(pos, float(dados.get("raio", 600.0)), cor)
			juice.flash(cor, 0.35)
			juice.zoom_punch(0.06)
		"aura":
			particulas.anel(pos, cor, 120.0, 0.6, 5.0)
		"congelar":
			juice.flash(Color("#67e8f9"), 0.25)
			particulas.anel(pos, Color("#67e8f9"), 700.0, 0.7, 6.0)
		"julgamento":
			juice.flash(Color("#f43f5e"), 0.5)
			for i in 8:
				particulas.anel(pos, Color("#f43f5e"), 200.0 + float(i) * 90.0, 0.5 + float(i) * 0.06, 5.0)
		"fissura":
			particulas.anel(pos, cor, 130.0, 0.6, 4.0)
		"coleta":
			particulas.coleta(pos, Color("#fbbf24"))

func _process(delta: float) -> void:
	t += delta
	particulas.atualizar(delta)
	numeros.atualizar(delta)
	juice.atualizar(delta, jogo.velocidade if jogo else 1.0)
	position = juice.offset
	scale = Vector2.ONE * juice.zoom
	pivot_offset_hack()
	queue_redraw()

func pivot_offset_hack() -> void:
	# escala a partir do centro da tela
	var c := get_viewport_rect().size * 0.5
	position = juice.offset + c - c * juice.zoom

func _draw() -> void:
	if jogo == null or not jogo.iniciado:
		return
	var det := _detalhe()
	ArteTorre.desenhar(self, jogo, t, det)
	ArteTorre.desenhar_coletaveis(self, jogo, t)
	for item in jogo.arena.inimigos:
		var e: Inimigo = item
		if e.ativo:
			ArteInimigo.desenhar(self, e, t, det)
	ArteTorre.desenhar_projeteis(self, jogo, t, det)
	ArteTorre.desenhar_orbes(self, jogo, t)
	_desenhar_buraco_negro()
	particulas.desenhar(self)
	numeros.desenhar(self)

func _desenhar_buraco_negro() -> void:
	var bn = jogo.buraco_negro
	if not (bn is Dictionary):
		return
	var p: Vector2 = bn["pos"]
	var r := float(bn["raio"])
	draw_circle(p, r, Color(0.35, 0.1, 0.6, 0.10))
	draw_circle(p, r * 0.35, Color(0.02, 0.0, 0.05, 0.92))
	for i in 4:
		var a := t * (2.0 + float(i)) + float(i)
		draw_arc(p, r * (0.4 + float(i) * 0.16), a, a + PI * 1.3, 28, Color(0.68, 0.42, 1.0, 0.45), 2.5, true)

func _detalhe() -> float:
	return [0.3, 0.6, 1.0, 1.0][clampi(int(Cfg.get_v("qualidade", 2)), 0, 3)]
