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
	# A QUEDA TINHA TUDO E A VOLTA NAO TINHA NADA.
	#
	# `torre_caiu` da tremor 34, clarao, explosao de 220 px e camera lenta de
	# 900 ms. `torre_renasceu` tinha um unico ouvinte no repositorio inteiro: o
	# motor de audio. Depois dos tres segundos de espera anunciados no aviso, a
	# torre voltava a atirar em silencio visual completo — quem estivesse
	# olhando outra coisa nao tinha marca nenhuma do instante. E um arco que o
	# jogo abre com forca e nao fecha.
	Bus.torre_renasceu.connect(_ao_torre_renascer)
	Bus.particulas.connect(_ao_particulas)
	Bus.tremor_pedido.connect(func(a, d): juice.tremer(a, d))
	Bus.camera_lenta.connect(func(e, ms): juice.camera_lenta(e, ms))
	Bus.flash_pedido.connect(func(c, f): juice.flash(c, f))
	Bus.zoom_pedido.connect(func(f): juice.zoom_punch(f))
	Bus.onda_iniciou.connect(_ao_onda)
	Bus.onda_limpa.connect(_ao_onda_limpa)
	Bus.combo_mudou.connect(_ao_combo)
	# Eventos que estavam MUDOS: nenhum deles tinha uma linha em scripts/render/.
	# `overkill` e o mais gritante — matar com dano muito acima do necessario e
	# das coisas mais satisfatorias do genero, e o jogo nao dizia nada. `chefe_morreu`
	# tinha som e nenhum visual proprio, entao um chefe caia igual a um grunhido.
	Bus.overkill.connect(_ao_overkill)
	Bus.chefe_morreu.connect(_ao_chefe_morreu)
	Bus.chefe_fase.connect(_ao_chefe_fase)
	Bus.nivel_subiu.connect(_ao_nivel)
	Bus.conquista_desbloqueada.connect(func(_id): _celebrar(Color("#fbbf24"), 0.16, 5.0, 0.02))
	Bus.missao_concluida.connect(func(_id): _celebrar(Color("#4ade80"), 0.12, 4.0, 0.015))
	Bus.carta_caiu.connect(_ao_carta)
	Bus.onda_falhou.connect(_ao_onda_falhou)
	Bus.combo_quebrou.connect(_ao_combo_quebrou)
	Bus.onda_antecipada.connect(func(_n, b):
		_celebrar(Color("#fbbf24"), 0.10 + minf(float(b) - 1.0, 0.6) * 0.12, 3.0, 0.018))
	# O juice mexe no tempo por FATOR, e quem multiplica os fatores e o Jogo.
	juice.dono = jogo
	Bus.prestigio_feito.connect(func(_c, _g): particulas.limpar(); numeros.limpar())

func _ao_atingir(e, dano_log: float, critico: bool, elemento: String, dot: bool = false) -> void:
	var cor := Color.WHITE
	if critico:
		cor = Color("#fde047")
	elif elemento != "":
		cor = Color.html(str(Bal.ELEMENTOS.get(elemento, {}).get("cor", "#ffffff")))
	# O tique de dano por tempo entra menor e sem tremor: ele conta, mas nao pode
	# competir com o golpe. Antes fogo e veneno enchiam o pool de numeros a 60 Hz
	# por inimigo e empurravam para fora justamente o numero do tiro.
	var escala := 1.0 + (0.25 if e.chefe else 0.0)
	if dot:
		escala *= 0.7
	numeros.adicionar(e.pos + Vector2(0, -e.raio), Fmt.big(dano_log), cor, critico and not dot, escala, dano_log)
	if critico and not dot:
		juice.tremer(2.6, 0.09)

func _ao_morrer(e, _ouro: float) -> void:
	particulas.morte(e.pos, e.cor, e.escala, e.chefe)
	# clarão branco no instante exato do abate: o golpe "conecta"
	particulas.anel(e.pos, Color(1, 1, 1, 0.85), e.raio * 2.4, 0.14, 3.0)
	if e.chefe:
		juice.tremer(20.0, 0.6)
		juice.flash(Color(1, 1, 1), 0.3)
		juice.zoom_punch(0.05)
	elif e.dourado:
		particulas.anel(e.pos, Color("#fcd34d"), 70.0, 0.5, 4.0)
		juice.tremer(4.0, 0.15)

func _ao_torre_atingida(dano: float, vida: float, vida_max: float) -> void:
	if Big.is_zero(dano):
		return
	var frac := Big.frac(dano, vida_max)
	juice.tremer(clampf(4.0 + frac * 90.0, 3.0, 22.0), 0.22)
	juice.flash(Color(1, 0.25, 0.25), clampf(frac * 2.2, 0.06, 0.32))
	particulas.faisca(jogo.arena.centro, Color("#f87171"), 8, 160.0)
	if Big.frac(vida, vida_max) < 0.25:
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

func _ao_onda_limpa(_n: int, _tempo: float) -> void:
	var c: Vector2 = jogo.arena.centro
	particulas.anel(c, Color("#4ade80"), 260.0, 0.55, 4.0)
	particulas.anel(c, Color(1, 1, 1, 0.6), 150.0, 0.35, 2.0)
	juice.zoom_punch(0.012)

func _ao_combo(v: int) -> void:
	if v > 0 and v % 25 == 0:
		juice.zoom_punch(0.02)

## Overkill: o excesso de dano vira estilhaco e um anel que cresce com o exagero.
## O sinal existia, era emitido pela simulacao, e ninguem escutava.
func _ao_overkill(e, fracao: float) -> void:
	# A FAIXA QUE CHEGA AQUI E ESTREITA, E A CONTA ESPERAVA UMA LARGA.
	#
	# `Combate.matar` so emite quando a fracao passa de 0,25 e a limita a
	# `Bal.OVERKILL_TETO` = 0,5. Ou seja, `fracao` esta SEMPRE em (0,25 .. 0,50].
	# Dividir por 6 dava no maximo 0,083, e o piso de 0,15 do `clampf` vencia em
	# 100% dos casos: `forca` era a constante 0,15, os dois ramos abaixo (`>
	# 0,45` e `> 0,8`) nunca rodavam, e a contagem de estilhacos era sempre 9.
	# Matar com mil vezes o dano necessario produzia exatamente a mesma imagem
	# que matar com 26% de sobra — o exagero estava desligado sem parecer
	# desligado. O `clampf(fracao, 0.0, 12.0)` original mostra que a conta foi
	# escrita esperando valores ate 12, que nunca existiram.
	#
	# Agora a faixa real e esticada sobre 0..1, com um piso pequeno para o
	# overkill mais fraco ainda ler como alguma coisa.
	var f := clampf(fracao, 0.0, Bal.OVERKILL_TETO)
	var forca := clampf((f - 0.25) * 4.0, 0.12, 1.0)
	particulas.estilhaco(e.pos, e.cor, int(6.0 + forca * 22.0), 220.0 + forca * 420.0)
	particulas.anel(e.pos, Color(1, 0.95, 0.75, 0.9), e.raio * (3.0 + forca * 5.0), 0.2, 3.5)
	if forca > 0.45:
		juice.tremer(3.0 + forca * 7.0, 0.12)
	if forca > 0.8:
		juice.zoom_punch(0.02)

## Um chefe caindo tinha som e nenhum visual proprio. Agora ele para o tempo.
func _ao_chefe_morreu(e) -> void:
	juice.camera_lenta(0.25, 800.0)
	juice.flash(Color(1, 1, 1), 0.45)
	juice.tremer(26.0, 0.8)
	juice.zoom_punch(0.075)
	particulas.explosao(e.pos, 240.0, e.cor)
	for i in 4:
		particulas.anel(e.pos, Color(1, 1, 1, 0.7 - float(i) * 0.13),
			90.0 + float(i) * 110.0, 0.35 + float(i) * 0.14, 3.0)
	particulas.estilhaco(e.pos, e.cor, 40, 520.0)

## Virada de fase: o chefe muda de comportamento e a tela precisa avisar.
func _ao_chefe_fase(e, _fase: int) -> void:
	juice.flash(e.cor, 0.3)
	juice.tremer(12.0, 0.35)
	particulas.anel(e.pos, e.cor, e.raio * 5.0, 0.45, 4.0)
	particulas.faisca(e.pos, e.cor, 18, 260.0)

func _ao_nivel(_nivel: int, _pontos: int) -> void:
	_celebrar(Color("#a78bfa"), 0.18, 5.0, 0.025)

func _ao_carta(_inst) -> void:
	_celebrar(Color("#38bdf8"), 0.14, 3.5, 0.015)

## Perder o combo era mudo E invisivel: o unico ouvinte no repositorio inteiro
## era `_combo = 0` no motor de audio, que so servia para o sino do ouro voltar
## ao tom grave. O jogador via o multiplicador sumir do HUD sem nada marcando o
## momento — e perder algo que se estava construindo e justamente o que precisa
## ser sentido, senao nao ha por que proteger.
func _ao_combo_quebrou() -> void:
	var c: Vector2 = jogo.arena.centro
	particulas.estilhaco(c, Color("#f43f5e"), 14, 260.0)
	particulas.anel(c, Color(0.55, 0.25, 0.32, 0.75), 60.0, 0.3, 2.0)
	juice.tremer(5.0, 0.18)

func _ao_onda_falhou(_n: int) -> void:
	juice.flash(Color("#f43f5e"), 0.26)
	juice.tremer(14.0, 0.45)

## Comemoracao curta na torre: anel + faisca + um empurrao de camera. Serve a
## conquista, missao, nivel e carta — eventos diferentes, mesma gramatica visual,
## para o jogador aprender a ler "ganhei algo" sem precisar de texto.
## A torre volta: anel verde, faiscas e um pulso curto. Deliberadamente MENOR
## que a queda — voltar e alivio, nao catastrofe.
func _ao_torre_renascer() -> void:
	_celebrar(Color("#4ade80"), 0.12, 4.0, 0.02)

func _celebrar(cor: Color, flash_forca: float, tremor: float, zoom: float) -> void:
	var c: Vector2 = jogo.arena.centro
	particulas.anel(c, cor, 200.0, 0.5, 3.5)
	particulas.faisca(c, cor, 16, 240.0)
	juice.flash(cor, flash_forca)
	juice.tremer(tremor, 0.2)
	juice.zoom_punch(zoom)

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
			# TREMER SO NO QUE E EVENTO, NAO NO QUE E ROTINA.
			#
			# Todo projetil com area emitia "explosao", e o `clampf` tem PISO
			# 2,0: mesmo a Carga Explosiva de nivel 1 tremia. Com cadencia alta
			# a janela de 0,2 s era reposta antes de expirar e a tela tremia
			# SEM PARAR, num jogo que se olha por horas. Pior: a guarda
			# `amplitude <= tremor_amp * 0.6` do `Juice.tremer` descarta o que
			# for menor que o tremor em curso — com area alta, o tremor do
			# critico (2,6) e o da morte de dourado (4,0) paravam de acontecer.
			# Os dois unicos tremores que diziam "aconteceu algo especial"
			# sumiam, trocados por um chacoalho de fundo que nao informa nada.
			if bool(dados.get("tremor", true)):
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
	_desenhar_anel_purga()
	_desenhar_anel_combo()
	particulas.desenhar(self)
	numeros.desenhar(self)
	_desenhar_indicadores()

## Anel da PURGA: enche sozinho; a faixa dourada é a janela perfeita.
func _desenhar_anel_purga() -> void:
	var p: Dictionary = Mecanicas.estado_purga(jogo.s)
	var carga := clampf(float(p["carga"]), 0.0, 1.0)
	var c: Vector2 = jogo.arena.centro
	var raio := Bal.RAIO_TORRE * 2.35
	var inicio := -PI * 0.5

	# trilho
	draw_arc(c, raio, 0, TAU, 64, Color(0.12, 0.16, 0.26, 0.75), 5.0, true)
	# faixa perfeita
	var a0 := inicio + TAU * Mecanicas.PURGA_JANELA_PERFEITA
	draw_arc(c, raio, a0, inicio + TAU, 16, Color(0.99, 0.83, 0.24, 0.55), 7.0, true)
	# carga
	var na_janela := carga >= Mecanicas.PURGA_JANELA_PERFEITA
	var cor := Color("#38bdf8")
	if na_janela:
		cor = Color("#fde047")
	elif carga >= Mecanicas.PURGA_JANELA_BOA:
		cor = Color("#4ade80")
	if carga > 0.001:
		draw_arc(c, raio, inicio, inicio + TAU * carga, 64, cor, 5.0, true)
	# ponteiro
	var ang := inicio + TAU * carga
	var pt := c + Vector2(cos(ang), sin(ang)) * raio
	draw_circle(pt, 4.0 + (2.0 if na_janela else 0.0), Color(1, 1, 1, 0.95))
	if na_janela:
		var pulso := 0.5 + sin(t * 12.0) * 0.5
		draw_arc(c, raio + 7.0, 0, TAU, 64, Color(0.99, 0.88, 0.35, 0.20 + pulso * 0.35), 2.5, true)
		draw_circle(pt, 9.0 + pulso * 4.0, Color(1, 0.95, 0.5, 0.35))
	# brilho pós-disparo
	var brilho := float(p["brilho"])
	if brilho > 0.0:
		draw_arc(c, raio + 14.0 * (1.0 - brilho), 0, TAU, 64, Color(1, 1, 1, brilho * 0.5), 3.0, true)

## A TECLA P NAO E TRATADA AQUI, de proposito.
##
## Ela era, com `set_input_as_handled()` incondicional — e como este no e filho
## de Main e a entrada nao tratada anda em ordem inversa, o handler de main.gd
## nunca via a tecla. Consequencia: o aviso "o nucleo ainda esta vazio", que
## esta escrito e pronto em main.gd, era CODIGO MORTO; e a guarda de tela modal
## que main.gd faz tambem era pulada, entao dava para queimar 26 segundos de
## carga contra uma arena parada com o menu de Pausa aberto.
##
## Aqui fica so o clique na torre, que e um gesto do campo e nao existe em
## main.gd. Ele passa pelo mesmo caminho unico de disparo.
func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		if jogo.pausado:
			return
		if evento.position.distance_to(jogo.arena.centro) < Bal.RAIO_TORRE * 2.6:
			jogo.purgar()
			get_viewport().set_input_as_handled()

## Anel de combo em volta da torre: quanto maior a sequência, mais quente e rápido.
func _desenhar_anel_combo() -> void:
	var combo := int(jogo.s["combo"]["atual"])
	if combo < 5:
		return
	var teto := maxf(50.0, float(jogo.esp.get("comboTeto", 250)))
	var k := clampf(float(combo) / teto, 0.0, 1.0)
	var c: Vector2 = jogo.arena.centro
	var raio := Bal.RAIO_TORRE * 1.95 + k * 10.0
	var cor := Color("#fbbf24").lerp(Color("#f43f5e"), k)
	var giro := t * (1.2 + k * 5.0)
	var arco := lerpf(0.35, TAU, k)
	draw_arc(c, raio, giro, giro + arco, 48, Color(cor.r, cor.g, cor.b, 0.55 + k * 0.35), 2.5 + k * 2.5, true)
	var restante := clampf(float(jogo.s["combo"]["timer"]) / Bal.COMBO_JANELA, 0.0, 1.0)
	draw_arc(c, raio + 5.0, -PI * 0.5, -PI * 0.5 + TAU * restante, 40, Color(1, 1, 1, 0.28), 1.5, true)

## Setas na borda apontando os inimigos que ainda não entraram na tela.
func _desenhar_indicadores() -> void:
	var tam := get_viewport_rect().size
	var margem := 26.0
	var mostrados := 0
	for item in jogo.arena.inimigos:
		var e: Inimigo = item
		if not e.vivo():
			continue
		var p := e.pos
		if p.x > -10.0 and p.y > -10.0 and p.x < tam.x + 10.0 and p.y < tam.y + 10.0:
			continue
		if mostrados >= 14 and not e.chefe:
			continue
		mostrados += 1
		var c := tam * 0.5
		var dir := (p - c).normalized()
		var borda := Vector2(
			clampf(p.x, margem, tam.x - margem),
			clampf(p.y, margem, tam.y - margem))
		var cor := e.cor
		var escala := 1.0 + (0.8 if e.chefe else 0.0)
		var pulso := 1.0 + sin(t * 6.0 + float(e.id)) * 0.12
		var r := 7.0 * escala * pulso
		var ang := dir.angle()
		draw_colored_polygon(PackedVector2Array([
			borda + Vector2(cos(ang), sin(ang)) * r * 1.5,
			borda + Vector2(cos(ang + 2.4), sin(ang + 2.4)) * r,
			borda + Vector2(cos(ang - 2.4), sin(ang - 2.4)) * r,
		]), Color(cor.r, cor.g, cor.b, 0.75))
		if e.chefe:
			draw_arc(borda, r * 2.0, 0, TAU, 20, Color(cor.r, cor.g, cor.b, 0.5), 2.0, true)

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
