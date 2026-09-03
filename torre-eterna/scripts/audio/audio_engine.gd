extends Node

## Audio (autoload) — motor de som procedural.
##
## Não existe um único arquivo de som no projeto: o catálogo inteiro nasce do
## `Synth` na primeira execução e fica em memória. A geração é FATIADA por
## quadro (orçamento em milissegundos), então nada trava a partida — no pior
## caso um efeito ainda não existe e simplesmente não toca por alguns segundos.
##
## Uso:
##   Audio.tocar("compra")
##   Audio.tocar("ouro", -3.0, 1.2)
##   Audio.tocar_em("morte", inimigo.pos)     # panorâmica pela tela
##
## O resto se liga sozinho aos sinais do `Bus`.

const VOZES := 24
const ORCAMENTO_JOGANDO_MS := 3.0
const ORCAMENTO_OCIOSO_MS := 12.0
const FATIA := 256            # amostras por passada da fábrica
const ESSENCIAIS := 8         # sons que nascem antes da trilha
const DIST_MAX := 3200.0

var catalogo: Dictionary = {}          # nome -> {camadas, db, var, taxa, pico}
var bancos: Dictionary = {}            # nome -> AudioStreamWAV (variante 0)
## nome -> Array[AudioStreamWAV]: as variantes de ruido do mesmo efeito.
var _variantes: Dictionary = {}
var _ultima_variante: Dictionary = {}
var musica: Musica
var ligado := true                     # false em headless: tudo vira no-op
var gerando := true

var _vozes: Array[AudioStreamPlayer2D] = []
var _inicio: Array[int] = []
var _ultimo: Dictionary = {}           # nome -> ticks_msec do último disparo
var _fila: Array = []                  # [["sfx"|"musica", nome], ...]
var _fabrica: Synth.Fabrica = null
var _item: Array = []
var _rng := RandomNumberGenerator.new()
var _combo := 0
var _jogo: Node = null
var _ms := 0

## ------------------------------------------------------------------ ciclo

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_ms = Time.get_ticks_msec()
	if DisplayServer.get_name() == "headless":
		ligado = false
		gerando = false
		set_process(false)
		return

	catalogo = Sfx.catalogo()
	musica = Musica.new(self)
	_montar_fila()
	_montar_efeitos()
	_criar_vozes()
	_ligar_sinais()

func _process(_dt: float) -> void:
	var agora := Time.get_ticks_msec()
	var dt := clampf(float(agora - _ms) / 1000.0, 0.0, 0.25)   # tempo real: turbo não acelera a trilha
	_ms = agora
	if not ligado:
		return
	if gerando:
		_gerar_fatia()
	if musica != null and musica.tocando:
		musica.atualizar(dt, _contexto())

## ------------------------------------------------------------- API pública

## Toca um som do catálogo, sem posição (centro da tela).
func tocar(nome: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	_disparar(nome, volume_db, pitch, _centro())

## Toca com panorâmica pela posição na tela.
func tocar_em(nome: String, posicao: Vector2, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	_disparar(nome, volume_db, pitch, posicao)

func parar_tudo() -> void:
	for p in _vozes:
		p.stop()
	if musica != null:
		musica.parar()

## Quanto do catálogo já existe (0..1) — a barra de "aquecendo" da trilha.
func progresso_geracao() -> float:
	# Conta VARIANTES, nao nomes: com quatro variantes de tiro a fila e maior que
	# a lista de nomes, e a barra de "aquecendo" chegava a 100% com metade do
	# catalogo por gerar.
	var total := 0.0
	for nome in Sfx.nomes():
		total += float(Sfx.variantes(str(nome)))
	if musica != null:
		total += float(musica.nomes_banco().size())
	if total <= 0.0:
		return 1.0
	return clampf(1.0 - float(_fila.size()) / total, 0.0, 1.0)

## Linha de depuração: o que a trilha está fazendo agora.
## Efeitos de barramento, montados em codigo.
##
## O layout tinha Master, SFX e Musica e NENHUM efeito: `grep AudioEffect` no
## repositorio inteiro nao devolvia nada. Duas consequencias audiveis: a Purga
## somando dezenas de vozes recortava no Master (distorcao suja, nao a boa), e
## os sons soavam colados no rosto — sem nenhuma cauda, o campo de batalha nao
## tinha tamanho.
##
## Montado aqui em vez de no `.tres` porque neste projeto os formatos da engine
## sao gerados pela engine, nunca editados como texto.
func _montar_efeitos() -> void:
	var master := AudioServer.get_bus_index("Master")
	if master >= 0 and AudioServer.get_bus_effect_count(master) == 0:
		var lim := AudioEffectLimiter.new()
		lim.ceiling_db = -1.0
		lim.threshold_db = -6.0
		lim.soft_clip_db = 2.0
		AudioServer.add_bus_effect(master, lim)
	var sfx := AudioServer.get_bus_index("SFX")
	if sfx >= 0 and AudioServer.get_bus_effect_count(sfx) == 0:
		# Cauda curta e discreta: da tamanho ao campo sem embolar o ataque, que
		# e o que faz um tiro soar preciso.
		var rev := AudioEffectReverb.new()
		rev.room_size = 0.55
		rev.wet = 0.16
		rev.dry = 1.0
		rev.damping = 0.6
		rev.spread = 0.7
		AudioServer.add_bus_effect(sfx, rev)

func _criar_vozes() -> void:
	for i in VOZES:
		var p := AudioStreamPlayer2D.new()
		p.name = "Voz%d" % i
		p.bus = "SFX"
		p.max_distance = DIST_MAX
		p.attenuation = 0.35
		p.panning_strength = 1.35
		add_child(p)
		_vozes.append(p)
		_inicio.append(0)

func _voz(agora: int) -> AudioStreamPlayer2D:
	var mais_velha := 0
	for i in _vozes.size():
		if not _vozes[i].playing:
			_inicio[i] = agora
			return _vozes[i]
		if _inicio[i] < _inicio[mais_velha]:
			mais_velha = i
	# todas ocupadas: rouba a mais antiga
	_inicio[mais_velha] = agora
	return _vozes[mais_velha]

func _centro() -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return Vector2(640, 360)
	return vp.get_visible_rect().size * 0.5

func _disparar(nome: String, db: float, pitch: float, pos: Vector2) -> void:
	if not ligado or _vozes.is_empty():
		return
	if bool(Cfg.get_v("mudo", false)):
		return
	var fluxo: AudioStreamWAV = _sortear_variante(nome)
	if fluxo == null:
		return                                  # ainda não gerado: silêncio, nunca travamento
	var e: Dictionary = catalogo.get(nome, {})
	var agora := Time.get_ticks_msec()
	var espera := int(float(e.get("taxa", 0.05)) * 1000.0)
	if agora - int(_ultimo.get(nome, -999999)) < espera:
		return                                  # limite de repetição: 20 tiros/s, não 200
	_ultimo[nome] = agora

	var p := _voz(agora)
	if not p.is_inside_tree():
		return
	p.stream = fluxo
	p.global_position = pos
	var variacao := float(e.get("var", 0.0))
	var tempero := 1.0 + _rng.randf_range(-variacao, variacao)
	p.pitch_scale = clampf(pitch * tempero, 0.05, 4.0)
	p.volume_db = float(e.get("db", -10.0)) + db
	p.play()

## Escolhe a variante do efeito, NUNCA repetindo a ultima. Repetir de vez em
## quando por sorteio puro e justamente o que se ouve — duas identicas seguidas
## chamam mais atencao do que quatro alternadas.
func _sortear_variante(nome: String) -> AudioStreamWAV:
	var lista: Array = _variantes.get(nome, [])
	if lista.size() <= 1:
		return bancos.get(nome, null)
	var anterior := int(_ultima_variante.get(nome, -1))
	var i := _rng.randi() % lista.size()
	if i == anterior:
		i = (i + 1) % lista.size()
	_ultima_variante[nome] = i
	return lista[i]

## -------------------------------------------------------------- geração

## A ordem importa: primeiro o punhado de sons que tocam a cada segundo, depois
## os instrumentos da trilha (para a música entrar cedo), e só então o resto.
func _montar_fila() -> void:
	var sons: Array = Sfx.nomes()
	for i in mini(ESSENCIAIS, sons.size()):
		_enfileirar_sfx(str(sons[i]))
	for nome in ["perc", "hat", "pad", "baixo_quadrada", "arpejo_quadrada"]:
		_fila.append(["musica", str(nome)])
	for i in range(ESSENCIAIS, sons.size()):
		_enfileirar_sfx(str(sons[i]))
	for nome in musica.nomes_banco():
		var chave: Array = ["musica", str(nome)]
		if not _fila.has(chave):
			_fila.append(chave)

## Gera o catálogo em fatias de poucas centenas de amostras. Enquanto o jogador
## está no título ou pausado o orçamento é maior; em partida, dois milissegundos
## por quadro e olhe lá. Nenhum som, por mais longo, custa um quadro inteiro.
func _gerar_fatia() -> void:
	if _fila.is_empty() and _fabrica == null:
		gerando = false
		if musica != null and not musica.tocando and musica.pronta():
			musica.iniciar()
		return
	var orcamento := ORCAMENTO_OCIOSO_MS if _ocioso() else ORCAMENTO_JOGANDO_MS
	var limite := Time.get_ticks_usec() + int(orcamento * 1000.0)
	while Time.get_ticks_usec() < limite:
		if _fabrica == null:
			if _fila.is_empty():
				break
			_item = _fila.pop_front()
			var r := _receita_do_item(_item)
			_fabrica = Synth.Fabrica.new(r.get("camadas", []), float(r.get("pico", 0.85)))
		if _fabrica.avancar(FATIA):
			_guardar(_item, _fabrica.resultado)
			_fabrica = null

## Enfileira todas as variantes de um efeito. Ver `Sfx.VARIANTES`.
func _enfileirar_sfx(nome: String) -> void:
	for v in Sfx.variantes(nome):
		_fila.append(["sfx", nome, v])

func _receita_do_item(item: Array) -> Dictionary:
	if str(item[0]) == "sfx":
		var e: Dictionary = catalogo.get(str(item[1]), {})
		var camadas: Array = e.get("camadas", [])
		var v := int(item[2]) if item.size() > 2 else 0
		if v > 0:
			camadas = _semear(camadas, v)
		return {"camadas": camadas, "pico": float(e.get("pico", 0.85))}
	return musica.receita_banco(str(item[1]))

## A variante `v` da mesma receita: outra semente de ruido e um empurrao minimo
## na duracao. O carater fica; o detalhe muda. Copia rasa por camada — as
## camadas do catalogo sao `const` de fato e nao podem ser tocadas.
func _semear(camadas: Array, v: int) -> Array:
	var saida: Array = []
	for item in camadas:
		var c: Dictionary = (item as Dictionary).duplicate()
		c["semente"] = int(c.get("semente", 20260903)) + v * 7919
		c["dur"] = float(c.get("dur", 0.1)) * (1.0 + float(v) * 0.013)
		saida.append(c)
	return saida

func _guardar(item: Array, fluxo: AudioStreamWAV) -> void:
	if fluxo == null:
		return
	if str(item[0]) == "sfx":
		var nome := str(item[1])
		var v := int(item[2]) if item.size() > 2 else 0
		if v == 0:
			bancos[nome] = fluxo
		var lista: Array = _variantes.get(nome, [])
		lista.append(fluxo)
		_variantes[nome] = lista
	else:
		musica.definir_banco(str(item[1]), fluxo)
		# a trilha entra assim que tem percussão e um baixo
		if not musica.tocando and musica.pronta():
			musica.iniciar()

func _ocioso() -> bool:
	var j := _obter_jogo()
	if j == null:
		return true
	return not bool(j.iniciado) or bool(j.pausado)

## ------------------------------------------------------------- contexto

func _obter_jogo() -> Node:
	if _jogo == null:
		_jogo = get_node_or_null("/root/Jogo")
	return _jogo

func _contexto() -> Dictionary:
	var j := _obter_jogo()
	if j == null or not bool(j.iniciado):
		return {"onda": 1, "inimigos": 0, "chefe": false, "vida": 1.0, "ativo": false}
	var s: Dictionary = j.s
	var t: Dictionary = s["torre"]
	return {
		"onda": int(s["onda"]),
		"inimigos": int(j.arena.vivos),
		"chefe": bool(s["em_chefe"]),
		"vida": Big.frac(t["vida"], t["vida_max"]),
		"ativo": not bool(j.pausado),
	}

## --------------------------------------------------------------- sinais

func _ligar_sinais() -> void:
	# combate
	Bus.torre_atirou.connect(_ao_atirar)
	Bus.inimigo_atingido.connect(_ao_atingir)
	Bus.inimigo_morreu.connect(_ao_morrer)
	Bus.chefe_surgiu.connect(func(e): tocar_em("alerta_chefe", _pos(e)))
	Bus.chefe_morreu.connect(func(e): tocar_em("morte_chefe", _pos(e)))
	Bus.torre_atingida.connect(_ao_apanhar)
	Bus.torre_caiu.connect(func(): tocar("torre_destruida"))
	Bus.torre_renasceu.connect(func(): tocar("prestigio", -6.0, 1.25))
	Bus.combo_mudou.connect(func(v): _combo = int(v))
	Bus.combo_quebrou.connect(func(): _combo = 0)

	# economia
	Bus.ouro_ganho.connect(_ao_ouro)
	Bus.moeda_ganha.connect(_ao_moeda)
	Bus.upgrade_comprado.connect(func(_id, _q, nivel): tocar("compra", 0.0, 1.0 + minf(float(nivel), 30.0) * 0.006))
	Bus.talento_comprado.connect(func(_id, _n): tocar("compra", 0.0, 1.18))
	Bus.carta_caiu.connect(_ao_carta)

	# progressão
	Bus.onda_iniciou.connect(func(_n, chefe): tocar("onda", 0.0, 0.92 if chefe else 1.0))
	# Estes quatro eram MUDOS. Fechar uma onda e o batimento do jogo e nao tinha
	# som; o overkill, que e o abate mais satisfatorio que existe, tambem nao;
	# a virada de fase de um chefe acontecia em silencio; e perder uma onda —
	# a unica coisa ruim que acontece — nao soava diferente de ganhar.
	Bus.onda_limpa.connect(func(_n, _t): tocar("onda", -3.0, 1.28))
	Bus.onda_antecipada.connect(func(_n, b): tocar("onda", 0.0, 1.05 + minf(float(b) - 1.0, 0.6) * 0.4))
	Bus.overkill.connect(_ao_overkill)
	Bus.chefe_fase.connect(func(e, _f): tocar_em("alerta_chefe", _pos(e), -2.0, 1.22))
	Bus.onda_falhou.connect(func(_n): tocar("erro", 0.0, 0.72))
	Bus.carta_equipada.connect(func(_uid, _slot): tocar("clique", -2.0, 1.3))
	Bus.nivel_subiu.connect(func(_n, _p): tocar("nivel"))
	Bus.conquista_desbloqueada.connect(func(_id): tocar("conquista"))
	Bus.missao_concluida.connect(func(_id): tocar("missao"))
	Bus.desbloqueio.connect(func(_c): tocar("conquista", -4.0, 1.1))
	Bus.prestigio_feito.connect(_ao_prestigio)

	# habilidades
	Bus.habilidade_usada.connect(func(id, _nv): tocar(Sfx.som_habilidade(str(id))))
	Bus.purga_usada.connect(_ao_purga)
	Bus.habilidade_pronta.connect(func(id):
		if str(id) == "purga" and musica != null:
			musica.marcar_purga_pronta())
	Bus.habilidade_pronta.connect(func(_id): tocar("hab_pronta"))

	# interface
	Bus.painel_aberto.connect(func(_nome): tocar("abrir"))
	Bus.aviso.connect(_ao_aviso)
	Bus.config_mudou.connect(_ao_config)
	Bus.jogo_pronto.connect(func(): _jogo = get_node_or_null("/root/Jogo"))
	get_tree().node_added.connect(_ao_nascer_no)

## Clique e fechamento sem tocar em nenhum painel: o motor escuta a árvore.
func _ao_nascer_no(n: Node) -> void:
	if n is BaseButton:
		var b := n as BaseButton
		if not b.pressed.is_connected(_ao_clicar):
			b.pressed.connect(_ao_clicar)
	elif n.has_meta("gerente"):                       # é um painel do GerentePaineis
		n.tree_exiting.connect(_ao_fechar_painel)

func _ao_clicar() -> void:
	tocar("clique")

func _ao_fechar_painel() -> void:
	tocar("fechar")

func _ao_aviso(_texto: String, tipo: String, _icone: String) -> void:
	# `bloqueado` era gerado e nunca tocado: existia no catálogo, tinha teste
	# exigindo que existisse, e nenhum chamador. Os avisos de "não dá para fazer
	# isso" (requisito faltando, já no máximo, nada para desfazer) saíam mudos
	# ou com o mesmo tom de qualquer informação.
	match tipo:
		"ruim": tocar("erro")
		"bloqueado": tocar("bloqueado")

func _ao_config(chave: String, _valor) -> void:
	if chave.begins_with("vol"):
		tocar("clique")

func _pos(e) -> Vector2:
	if e != null and e is Inimigo:
		return (e as Inimigo).pos
	return _centro()

func _ao_atirar(angulo: float, quantidade: int) -> void:
	# a panorâmica segue o cano da torre
	var pos := _centro() + Vector2.from_angle(angulo) * 210.0
	tocar_em("tiro", pos, 0.0, 1.0 - minf(float(quantidade - 1), 4.0) * 0.03)

func _ao_atingir(e, _dano: float, critico: bool, _elemento: String, dot: bool = false) -> void:
	# Tique de queimadura e veneno NAO toca. Sao ~6.000 emissoes por segundo com
	# a arena cheia; deixar passar entupia o limitador de taxa e o tiro de
	# verdade — o unico som que o jogador precisa ouvir para saber que a torre
	# esta funcionando — virava parte de um chiado continuo.
	if dot:
		return
	if critico:
		tocar_em("tiro_critico", _pos(e), 0.0, 1.0)
	else:
		tocar_em("impacto", _pos(e))

func _ao_morrer(e, _ouro: float) -> void:
	var pitch := 1.0
	if e != null and e is Inimigo:
		pitch = clampf(26.0 / maxf(9.0, (e as Inimigo).raio), 0.72, 1.45)
	tocar_em("morte", _pos(e), 0.0, pitch)

func _ao_apanhar(_dano: float, vida: float, vida_max: float) -> void:
	var f := Big.frac(vida, vida_max)
	tocar("torre_dano", 0.0, 0.85 + f * 0.25)

## A ESCADA DO COMBO EM SEMITONS, nao em fracao linear.
##
## Era `1,0 + combo * 0,019`: uma reta na RAZAO de frequencia. O ouvido nao ouve
## razao linear, ouve intervalo — e cada degrau caia entre duas notas, num tom a
## cada vez diferente do anterior. Contra uma trilha afinada, isso e desafinacao
## pura: o jogo tocava microtons por cima da propria musica.
##
## Agora sobe por uma pentatonica maior de duas oitavas, um degrau a cada quatro
## pontos de combo. Cada moeda cai numa nota que existe na escala, e a subida
## soa como subida.
const ESCADA_COMBO := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]

static func _passo_do_combo(combo: int) -> float:
	var i := clampi(combo / 4, 0, ESCADA_COMBO.size() - 1)
	return pow(2.0, float(ESCADA_COMBO[i]) / 12.0)

## O tom sobe com o combo: cada moeda soa um degrau acima da anterior.
## A PURGA SOA COMO ELA FOI. A qualidade (0,18 a 1,0) decide o som, o tom e o
## volume — e a perfeita e outro som, com sino, nao o mesmo mais alto.
func _ao_purga(qualidade: float, perfeita: bool) -> void:
	var q := clampf(qualidade, 0.0, 1.0)
	if perfeita:
		tocar("hab_purga_perfeita", 0.0, 1.0)
	else:
		# Estourada soa MAIS GRAVE e mais baixa: o ouvido lê "murchou".
		tocar("hab_purga", -8.0 + 8.0 * q, 0.82 + 0.2 * q)
	if musica != null:
		musica.marcar_purga(q)

func _ao_ouro(_valor: float, fonte: String) -> void:
	if fonte != "coleta" and fonte != "abate":
		return
	tocar("ouro", 0.0, _passo_do_combo(_combo))

func _ao_moeda(chave: String, _valor: float, _fonte: String) -> void:
	if chave == "ouro":
		return
	tocar("moeda", 0.0, 1.0 if chave == "fragmentos" else (0.88 if chave == "nucleos" else 1.12))

## O tom sobe com o exagero do abate: quanto mais dano acima do necessario, mais
## agudo o estalo. E o ouvido aprende a medir o proprio poder sem ler numero.
func _ao_overkill(_e, fracao: float) -> void:
	var f := clampf(fracao, 0.0, 12.0)
	tocar("impacto", -2.0 + minf(f, 6.0) * 0.5, 1.15 + minf(f, 8.0) * 0.09)

func _ao_carta(inst) -> void:
	var d: Dictionary = inst if inst is Dictionary else {}
	var r := str(d.get("raridade", "comum"))
	if r == "lendario" or r == "mitico":
		tocar("lendario")
	else:
		tocar("carta", 0.0, 1.0 if r == "comum" else 1.09)

func _ao_prestigio(camada: String, _ganho: float) -> void:
	var pitch := 1.0
	match camada:
		"singularidade": pitch = 0.92
		"transcendencia": pitch = 0.84
	tocar("prestigio", 0.0, pitch)
