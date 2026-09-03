class_name Musica
extends RefCounted

## Trilha adaptativa gerada em tempo real. Não existe faixa gravada: existe um
## relógio de compasso, a escala da era atual e um punhado de instrumentos
## sintetizados uma única vez e transpostos por `pitch_scale`.
##
## Camadas (entram conforme a intensidade sobe):
##   0 baixo · 1 percussão · 2 arpejo · 3 pad · 4 contracanto
## Em luta de chefe o modo muda: mais rápido, mais grave, com um trítono fixo
## rondando o baixo. É de propósito que incomode.

const VOZES_PAD := 3
const VOZES_LIVRES := 7
const REF_BAIXO := 36.0
const REF_PAD := 48.0
const REF_ARPEJO := 72.0
const TIMBRES := ["senoide", "quadrada", "dente", "triangulo"]

var host: Node
var bancos: Dictionary = {}          # nome -> AudioStreamWAV
var tocando := false

var _vozes: Array[AudioStreamPlayer] = []
var _prox_livre := 0
var _pad_i := 0
var _t := 0.0
var _passo := 0
var _rng := RandomNumberGenerator.new()

# --- era corrente (o que o relógio realmente usa) ---
var _era_idx := -1
var _escala: Array = [0, 3, 5, 7, 10]
var _bpm := 76.0
var _timbre := "quadrada"
var _camadas_max := 2
var _raiz := 36

# --- transição / mistura ---
var _ganho := 0.0
var _ganho_alvo := 1.0
var _era_pendente := -1
var _intensidade := 0.0
var _dt_ctx := 0.016
var _chefe := false
## Ultimo compasso que semeou o gerador — ver `_tocar_passo`.
var _compasso_semeado := -1
## Abafamento momentaneo depois de uma Purga (0..1) e o brilho que vem depois.
var _duck := 0.0
var _brilho_purga := 0.0
## A janela dourada da Purga esta aberta? A trilha sustenta uma quinta em cima.
var _purga_pronta := false

func _init(no_host: Node) -> void:
	host = no_host
	_rng.seed = 90210

## ------------------------------------------------------------ instrumentos

## Nomes dos bancos, na ordem de geração (o essencial primeiro).
func nomes_banco() -> Array:
	var out: Array = ["perc", "hat", "pad"]
	for t in TIMBRES:
		out.append("baixo_" + str(t))
		out.append("arpejo_" + str(t))
	return out

## Guarda um banco já sintetizado (o motor gera em fatias e entrega aqui).
func definir_banco(nome: String, fluxo: AudioStreamWAV) -> void:
	if fluxo != null:
		bancos[nome] = fluxo

## Caminho simples, sem fatiar — usado por testes e ferramentas.
func gerar_banco(nome: String) -> void:
	if bancos.has(nome):
		return
	var r := receita_banco(nome)
	bancos[nome] = Synth.som(r.get("camadas", []), float(r.get("pico", 0.85)))

## Receita de um instrumento: camadas + normalização. Tudo em uma oitava de
## referência; o resto é `pitch_scale`.
func receita_banco(nome: String) -> Dictionary:
	if nome == "perc":
		return _r([
			{"onda": "senoide", "f0": 150.0, "f1": 46.0, "curva": 0.5, "dur": 0.24,
			 "atk": 0.001, "dec": 0.18, "rel": 0.05, "sat": 0.35, "vol": 0.9},
			{"onda": "ruido", "dur": 0.045, "atk": 0.0005, "dec": 0.035, "rel": 0.008,
			 "lp0": 3200.0, "lp1": 800.0, "vol": 0.3},
		], 0.9)
	if nome == "hat":
		return _r([
			{"onda": "ruido", "dur": 0.05, "atk": 0.0008, "dec": 0.038, "rel": 0.01,
			 "lp0": 13000.0, "lp1": 6000.0, "vol": 0.5},
		], 0.6)
	if nome == "pad":
		return _r([
			{"onda": "triangulo", "f0": Synth.freq(REF_PAD), "dur": 3.0, "vozes": 3,
			 "detune": 0.17, "atk": 0.8, "dec": 0.7, "sus": 0.55, "rel": 1.3,
			 "lp0": 900.0, "lp1": 1800.0, "vol": 0.6},
			{"onda": "senoide", "f0": Synth.freq(REF_PAD + 12.0), "dur": 3.0,
			 "atk": 1.1, "dec": 0.6, "sus": 0.3, "rel": 1.3, "vol": 0.25},
		], 0.75)

	var partes: PackedStringArray = nome.split("_")
	var papel := str(partes[0])
	var timbre: String = str(partes[1]) if partes.size() > 1 else "senoide"
	if papel == "baixo":
		return _r([
			{"onda": timbre, "f0": Synth.freq(REF_BAIXO), "dur": 0.55, "vozes": 2,
			 "detune": 0.09, "atk": 0.006, "dec": 0.3, "sus": 0.35, "rel": 0.2,
			 "lp0": 1100.0, "lp1": 380.0, "sat": 0.35, "vol": 0.85},
			{"onda": "senoide", "f0": Synth.freq(REF_BAIXO - 12.0), "dur": 0.5,
			 "atk": 0.004, "dec": 0.28, "sus": 0.25, "rel": 0.18, "vol": 0.5},
		], 0.85)
	return _r([
		{"onda": timbre, "f0": Synth.freq(REF_ARPEJO), "dur": 0.32, "atk": 0.003,
		 "dec": 0.2, "sus": 0.1, "rel": 0.11, "lp0": 5200.0, "lp1": 2600.0, "vol": 0.6},
	], 0.7)

static func _r(camadas: Array, pico: float) -> Dictionary:
	return {"camadas": camadas, "pico": pico}

## O banco do timbre da era, ou o que já existir — a trilha nunca espera.
func banco(papel: String) -> String:
	var alvo := papel + "_" + _timbre
	if bancos.has(alvo):
		return alvo
	for t in TIMBRES:
		var alt: String = papel + "_" + str(t)
		if bancos.has(alt):
			return alt
	return ""

func pronta() -> bool:
	return bancos.has("perc") and banco("baixo") != ""

## ------------------------------------------------------------------ vozes

func iniciar() -> void:
	if tocando or host == null:
		return
	for i in VOZES_PAD + VOZES_LIVRES:
		var p := AudioStreamPlayer.new()
		p.bus = "Musica"
		p.name = "Musica%d" % i
		host.add_child(p)
		_vozes.append(p)
	tocando = true
	_ganho = 0.0
	_ganho_alvo = 1.0

func parar() -> void:
	for p in _vozes:
		p.stop()
	tocando = false

## ------------------------------------------------------------------ relógio

## `ctx`: {onda, inimigos, chefe, vida (0..1), ativo}
func atualizar(dt: float, ctx: Dictionary) -> void:
	if not tocando or not pronta():
		return

	_dt_ctx = dt
	_aplicar_contexto(ctx)

	var alvo: float = _ganho_alvo if bool(ctx.get("ativo", true)) else _ganho_alvo * 0.45
	alvo *= 1.0 - _duck * 0.62
	_ganho = move_toward(_ganho, alvo, dt * 1.4)
	if _era_pendente >= 0 and _ganho <= 0.06:
		_trocar_era(_era_pendente)
		_era_pendente = -1
		_ganho_alvo = 1.0

	var dur_passo := 30.0 / maxf(20.0, _bpm * (1.15 if _chefe else 1.0))
	_t += dt
	var guarda := 0
	while _t >= dur_passo and guarda < 8:
		_t -= dur_passo
		guarda += 1
		_tocar_passo(_passo)
		_passo += 1

func _aplicar_contexto(ctx: Dictionary) -> void:
	# a intensidade sobe e desce em segundos, não em quadros
	var onda: int = int(ctx.get("onda", 1))
	var idx: int = Dados.era_da_onda(onda)
	if idx != _era_idx and _era_pendente < 0:
		if _era_idx < 0:
			_trocar_era(idx)            # primeira era: entra direto
		else:
			_era_pendente = idx         # some devagar e volta na era nova
			_ganho_alvo = 0.0

	_chefe = bool(ctx.get("chefe", false))
	var inimigos: float = float(ctx.get("inimigos", 0))
	var vida: float = clampf(float(ctx.get("vida", 1.0)), 0.0, 1.0)
	var bruta := clampf(inimigos / 16.0, 0.0, 1.0) * 0.55
	if _chefe:
		bruta += 0.32
	# A VIDA ERA UM DEGRAU: abaixo de 35% somava 0,18 e pronto. Cinco por cento
	# de vida e cem por cento soavam exatamente igual desde que os dois
	# estivessem do mesmo lado do degrau. Agora e continuo, e o ultimo quarto
	# pesa o dobro — e quando a torre esta para cair a trilha esta no talo.
	bruta += (1.0 - vida) * 0.30
	if vida < 0.25:
		bruta += (0.25 - vida) * 1.2
	_intensidade = lerpf(_intensidade, clampf(bruta, 0.0, 1.0), clampf(_dt_ctx * 2.5, 0.0, 1.0))
	# A Purga abre um buraco na trilha e devolve com brilho. Sem isto a mecanica
	# assinatura do jogo passava sem que a musica percebesse.
	_duck = maxf(0.0, _duck - _dt_ctx * 2.6)
	_brilho_purga = maxf(0.0, _brilho_purga - _dt_ctx * 0.5)

func _trocar_era(idx: int) -> void:
	_era_idx = idx
	var era: Dictionary = Dados.eras[idx] if idx >= 0 and idx < Dados.eras.size() else {}
	var m: Dictionary = era.get("musica", {})
	var esc: Array = m.get("escala", [0, 3, 5, 7, 10])
	_escala = esc if not esc.is_empty() else [0, 3, 5, 7, 10]
	_bpm = float(m.get("bpm", 76))
	_timbre = str(m.get("timbre", "quadrada"))
	if not TIMBRES.has(_timbre):
		_timbre = "quadrada"
	_camadas_max = clampi(int(m.get("camadas", 2)), 1, 5)
	_raiz = 33 + (idx * 5) % 12
	_passo = 0
	_t = 0.0

## A PURGA CHEGA NA TRILHA. Chamado quando a Purga dispara: abre um buraco
## curto (a musica sai da frente do estouro) e devolve com brilho proporcional a
## qualidade. Purga perfeita abre mais fundo e brilha mais tempo.
func marcar_purga(qualidade: float) -> void:
	var q := clampf(qualidade, 0.0, 1.0)
	_duck = maxf(_duck, 0.45 + 0.55 * q)
	_brilho_purga = maxf(_brilho_purga, 0.5 + 0.5 * q)
	_purga_pronta = false

## A janela dourada abriu: a trilha sustenta uma quinta acima ate a Purga sair.
func marcar_purga_pronta() -> void:
	_purga_pronta = true

## Quantas camadas estão no ar agora.
func camadas_ativas() -> int:
	var extra := int(round(_intensidade * float(_camadas_max - 1)))
	return clampi(1 + extra, 1, _camadas_max)

## ----------------------------------------------------------------- compasso

func _tocar_passo(p: int) -> void:
	if _ganho <= 0.02:
		return
	var no_compasso := p % 16
	var compasso := int(p / 16)
	var camadas := camadas_ativas()
	# UMA SEMENTE POR COMPASSO, nao por passo. Isto estava DENTRO do laco de
	# passo: os dezesseis passos de um compasso resemeavam o gerador com o MESMO
	# numero, entao toda decisao "aleatoria" do compasso (o swing do chimbau, o
	# floreio do arpejo) saia identica dezesseis vezes seguidas. A variacao que a
	# trilha foi escrita para ter simplesmente nao acontecia.
	if compasso != _compasso_semeado:
		_compasso_semeado = compasso
		_rng.seed = 7717 * (compasso + 1) + _era_idx * 131

	# --- baixo: a fundação, sempre presente ---
	var bate_baixo := no_compasso % 8 == 0
	if _chefe:
		bate_baixo = no_compasso % 4 == 0
	if bate_baixo:
		var grau: int = 0 if no_compasso == 0 else int(_escala[(compasso + no_compasso / 8) % _escala.size()])
		_nota(banco("baixo"), REF_BAIXO, float(_raiz + grau), -9.0, 1.0)
		if _chefe and no_compasso == 8:
			# trítono do baixo: a dissonância que avisa que hoje é diferente
			_nota(banco("baixo"), REF_BAIXO, float(_raiz + 6), -14.0, 1.0)

	# --- percussão ---
	if camadas >= 2:
		if no_compasso % 8 == 0 or (_chefe and no_compasso % 4 == 0):
			_nota("perc", 0.0, 0.0, -11.0, 1.0)
		if no_compasso % 2 == 1:
			_nota("hat", 0.0, 0.0, -24.0 + (2.0 if _chefe else 0.0), _rng.randf_range(0.92, 1.1))

	# --- arpejo ---
	if camadas >= 3:
		var passa := no_compasso % 2 == 0 or _intensidade > 0.5
		if passa:
			var i: int = (no_compasso + compasso) % _escala.size()
			var oitava: int = 12 if (no_compasso % 8) == 6 else 0
			_nota(banco("arpejo"), REF_ARPEJO, float(_raiz + 24 + int(_escala[i]) + oitava), -17.0, 1.0)

	# --- pad: um acorde por compasso ---
	if camadas >= 4 and no_compasso == 0:
		var terca: int = int(_escala[mini(1, _escala.size() - 1)])
		var quinta: int = int(_escala[mini(3, _escala.size() - 1)])
		_pad(float(_raiz + 12), -19.0)
		_pad(float(_raiz + 12 + terca), -22.0)
		_pad(float(_raiz + 12 + (6 if _chefe else quinta)), -22.0)

	# --- contracanto: só quando o campo está cheio ---
	# A JANELA DOURADA DA PURGA soa: uma quinta acima da tonica, no primeiro
	# tempo, enquanto a carga estiver cheia. O jogador aprende a ouvir a janela
	# antes de olhar para o botao.
	if _purga_pronta and no_compasso == 0:
		_nota(banco("arpejo"), REF_ARPEJO, float(_raiz + 19), -15.0, 1.0)
	# ...e o brilho que sobra depois de uma Purga boa: uma oitava acima, curta.
	if _brilho_purga > 0.05 and no_compasso % 4 == 2:
		_nota(banco("arpejo"), REF_ARPEJO, float(_raiz + 24), -22.0 + 8.0 * _brilho_purga, 1.0)
	if camadas >= 5 and (no_compasso == 4 or no_compasso == 11) and _rng.randf() < 0.7:
		var g: int = int(_escala[_rng.randi() % _escala.size()])
		_nota(banco("arpejo"), REF_ARPEJO, float(_raiz + 36 + g), -21.0, 1.0)

func _nota(banco: String, ref_midi: float, midi: float, db: float, tempero: float) -> void:
	var fluxo: AudioStreamWAV = bancos.get(banco, null)
	if fluxo == null:
		return
	var p := _voz_livre()
	if p == null or not p.is_inside_tree():
		return
	p.stream = fluxo
	p.pitch_scale = clampf(pow(2.0, (midi - ref_midi) / 12.0) * tempero, 0.05, 4.0) if ref_midi > 0.0 else clampf(tempero, 0.05, 4.0)
	p.volume_db = db + linear_to_db(clampf(_ganho, 0.001, 1.0))
	p.play()

func _pad(midi: float, db: float) -> void:
	var fluxo: AudioStreamWAV = bancos.get("pad", null)
	if fluxo == null:
		return
	var p: AudioStreamPlayer = _vozes[_prox_pad()]
	if not p.is_inside_tree():
		return
	p.stream = fluxo
	p.pitch_scale = clampf(pow(2.0, (midi - REF_PAD) / 12.0), 0.1, 3.0)
	p.volume_db = db + linear_to_db(clampf(_ganho, 0.001, 1.0))
	p.play()

func _prox_pad() -> int:
	_pad_i = (_pad_i + 1) % VOZES_PAD
	return _pad_i

func _voz_livre() -> AudioStreamPlayer:
	if _vozes.size() <= VOZES_PAD:
		return null
	for i in VOZES_LIVRES:
		var idx := VOZES_PAD + (_prox_livre + i) % VOZES_LIVRES
		var p: AudioStreamPlayer = _vozes[idx]
		if not p.playing:
			_prox_livre = (idx - VOZES_PAD + 1) % VOZES_LIVRES
			return p
	var q: AudioStreamPlayer = _vozes[VOZES_PAD + _prox_livre]
	_prox_livre = (_prox_livre + 1) % VOZES_LIVRES
	return q

## Descrição curta do que está tocando — útil para depuração e para o painel.
func descricao() -> String:
	if not tocando:
		return "silêncio"
	var nome := "?"
	if _era_idx >= 0 and _era_idx < Dados.eras.size():
		nome = str(Dados.eras[_era_idx].get("nome", "?"))
	return "%s · %d BPM · %s · %d camada(s)%s" % [
		nome, int(_bpm), _timbre, camadas_ativas(), " · CHEFE" if _chefe else ""]
