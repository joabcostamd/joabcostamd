class_name Synth
extends RefCounted

## Sintetizador procedural. Este jogo não tem um único arquivo de som:
## tudo aqui vira PCM de 16 bits gerado na memória.
##
## Uma RECEITA é um Dicionário. Nada é obrigatório — o que faltar vira padrão.
##   dur         duração em segundos
##   onda        "senoide" | "quadrada" | "dente" | "triangulo" | "ruido"
##   f0, f1      frequência inicial e final (varredura); f1 omitido = sem varredura
##   curva       exponente da varredura (1 = linear no tempo, >1 = cai só no fim)
##   vozes       cópias empilhadas (2..8) para engrossar
##   detune      desafinação entre as vozes, em semitons
##   ruido       0..1 de ruído misturado ao oscilador
##   vibrato_hz, vibrato   modulação lenta de frequência
##   atk, dec, sus, rel    envelope ADSR (sus é NÍVEL, não tempo)
##   fm_ratio, fm_index, fm_decai   FM simples (modulador senoidal que decai)
##   lp0, lp1    corte do passa-baixa de 1 polo, em Hz (varre de lp0 a lp1)
##   sat         0..1 de saturação suave
##   vol         ganho da camada
##   atraso      deslocamento em segundos dentro de uma mistura
##   semente     ruído determinístico (o mesmo som sai igual toda vez)
##
## Duas formas de usar:
##   Synth.som([receita, ...])            -> AudioStreamWAV de uma vez
##   Synth.Fabrica.new([receita, ...])    -> a mesma coisa, fatiada por quadro
## O motor usa a Fábrica: gerar um som de dois segundos custa mais que um quadro,
## e a partida não pode gaguejar por causa de som nenhum.
##
## Nota de implementação: frequência, corte do filtro e envelope de FM são
## recalculados a cada BLOCO de amostras (taxa de controle, como num sintetizador
## de verdade) e interpolados no meio. Isso derruba o custo por amostra sem que
## se ouça diferença.

const TAXA := 44100
const BLOCO := 32
const LA_MIDI := 69.0

## ------------------------------------------------------- peças componíveis

static func osc(forma: String, fase: float, rng: RandomNumberGenerator) -> float:
	match forma:
		"senoide":
			return sin(fase * TAU)
		"quadrada":
			return 1.0 if fposmod(fase, 1.0) < 0.5 else -1.0
		"dente":
			return fposmod(fase, 1.0) * 2.0 - 1.0
		"triangulo":
			return absf(fposmod(fase, 1.0) * 4.0 - 2.0) - 1.0
		"ruido":
			return rng.randf() * 2.0 - 1.0
	return sin(fase * TAU)

static func codigo_onda(forma: String) -> int:
	match forma:
		"senoide": return 0
		"quadrada": return 1
		"dente": return 2
		"triangulo": return 3
		"ruido": return 4
	return 0

## ADSR normalizado: `t` e `dur` em segundos, `sus` é o NÍVEL do sustento.
static func env_adsr(t: float, dur: float, atk: float, dec: float, sus: float, rel: float) -> float:
	if t < atk:
		return clampf(t / maxf(atk, 1e-6), 0.0, 1.0)
	if t < atk + dec:
		return lerpf(1.0, sus, (t - atk) / maxf(dec, 1e-6))
	if t < dur - rel:
		return sus
	return sus * clampf((dur - t) / maxf(rel, 1e-6), 0.0, 1.0)

## Varredura de frequência: exponencial quando as duas pontas são positivas.
static func varredura(t01: float, f0: float, f1: float, curva: float) -> float:
	var k := pow(clampf(t01, 0.0, 1.0), maxf(0.05, curva))
	if f0 <= 1.0 or f1 <= 1.0:
		return lerpf(f0, f1, k)
	return f0 * pow(f1 / f0, k)

## Saturação suave — arredonda o pico em vez de cortar quadrado.
static func saturar(x: float, k: float) -> float:
	var g := 1.0 + k * 5.0
	return (x * g) / (1.0 + absf(x * g))

## Coeficiente do passa-baixa de 1 polo para um corte em Hz.
static func coef_lp(fc: float, passo: float) -> float:
	return clampf(1.0 - exp(-TAU * clampf(fc, 20.0, 19000.0) * passo), 0.0, 1.0)

## Frequência de uma nota MIDI (60 = dó central).
static func freq(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - LA_MIDI) / 12.0)

## ---------------------------------------------------------------- receitas

## Uma receita repetida em vários semitons — arpejos e fanfarras.
static func sequencia(base: Dictionary, semitons: Array, passo: float, ganho_fim: float = 0.75) -> Array:
	var camadas: Array = []
	var f0: float = float(base.get("f0", 440.0))
	var f1: float = float(base.get("f1", f0))
	var vol: float = float(base.get("vol", 1.0))
	var atraso0: float = float(base.get("atraso", 0.0))
	var ultimo := maxf(1.0, float(semitons.size() - 1))
	for i in semitons.size():
		var r: Dictionary = base.duplicate(true)
		var razao: float = pow(2.0, float(semitons[i]) / 12.0)
		r["f0"] = f0 * razao
		r["f1"] = f1 * razao
		r["atraso"] = atraso0 + float(i) * passo
		r["vol"] = vol * lerpf(1.0, ganho_fim, float(i) / ultimo)
		camadas.append(r)
	return camadas

## ------------------------------------------------------------ render (uma vez)

## Quantas amostras uma mistura ocupa (a camada que termina mais tarde manda).
static func amostras_totais(camadas: Array) -> int:
	var total := 0
	for item in camadas:
		var r: Dictionary = item
		var off: int = int(maxf(0.0, float(r.get("atraso", 0.0))) * float(TAXA))
		total = maxi(total, off + maxi(1, int(maxf(0.005, float(r.get("dur", 0.2))) * float(TAXA))))
	return total

## Uma receita -> amostras mono em ponto flutuante.
static func render(r: Dictionary) -> PackedFloat32Array:
	var st := preparar(r)
	avancar(st, int(st["n"]))
	return st["buf"]

## Soma várias receitas, cada uma no seu `atraso`, num buffer só.
static func mixar(camadas: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(amostras_totais(camadas))
	for item in camadas:
		var r: Dictionary = item
		var off: int = int(maxf(0.0, float(r.get("atraso", 0.0))) * float(TAXA))
		var st := preparar(r, out, off)
		avancar(st, int(st["n"]))
	return out

## Atalho: lista de receitas -> AudioStreamWAV pronto.
static func som(camadas: Array, pico: float = 0.85) -> AudioStreamWAV:
	return wav(mixar(camadas), pico)

## ------------------------------------------------------- render (fatiado)

## Estado de render de UMA receita. `avancar` come pedaços dele.
## `saida`/`deslocamento` deixam a camada escrever direto na mistura final —
## assim não existe passe extra de soma no fim.
static func preparar(r: Dictionary, saida: PackedFloat32Array = PackedFloat32Array(),
		deslocamento: int = 0) -> Dictionary:
	var dur: float = maxf(0.005, float(r.get("dur", 0.2)))
	var n: int = maxi(1, int(dur * float(TAXA)))
	var buf := saida
	var off := deslocamento
	if buf.size() < off + n:
		buf = PackedFloat32Array()
		buf.resize(n)
		off = 0

	var vozes: int = clampi(int(r.get("vozes", 1)), 1, 8)
	var detune: float = float(r.get("detune", 0.0))
	var razoes := PackedFloat32Array()
	var fases := PackedFloat32Array()
	razoes.resize(vozes)
	fases.resize(vozes)
	for i in vozes:
		var d: float = 0.0 if vozes == 1 else lerpf(-detune, detune, float(i) / float(vozes - 1))
		razoes[i] = pow(2.0, d / 12.0)
		fases[i] = fposmod(float(i) * 0.137, 1.0)

	var f0: float = float(r.get("f0", 440.0))
	var atk: float = float(r.get("atk", 0.004))
	var dec: float = float(r.get("dec", 0.06))
	var rel: float = float(r.get("rel", 0.02))
	var passo := 1.0 / float(TAXA)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.get("semente", 20260903))

	return {
		"buf": buf, "off": off, "n": n, "i": 0, "dur": dur, "passo": passo,
		"codigo": codigo_onda(str(r.get("onda", "senoide"))),
		"f0": f0, "f1": float(r.get("f1", f0)), "curva": float(r.get("curva", 1.0)),
		"vozes": vozes, "razoes": razoes, "fases": fases,
		"ruido": clampf(float(r.get("ruido", 0.0)), 0.0, 1.0),
		"vib_hz": float(r.get("vibrato_hz", 0.0)), "vib": float(r.get("vibrato", 0.0)),
		"sus": float(r.get("sus", 0.0)), "vol": float(r.get("vol", 1.0)),
		"i_atk": maxi(1, int(atk * float(TAXA))),
		"i_dec": maxi(2, int((atk + dec) * float(TAXA))),
		"i_rel": maxi(1, n - int(rel * float(TAXA))),
		"fm_ratio": float(r.get("fm_ratio", 0.0)), "fm_index": float(r.get("fm_index", 0.0)),
		"fm_dk": exp(-float(r.get("fm_decai", 3.0)) * passo),
		"fm_env": float(r.get("fm_index", 0.0)), "fase_fm": 0.0,
		"lp0": float(r.get("lp0", 18000.0)), "lp1": float(r.get("lp1", float(r.get("lp0", 18000.0)))),
		"sat": float(r.get("sat", 0.0)), "lp_y": 0.0, "rng": rng,
	}

## Renderiza no máximo `quantas` amostras. Devolve true quando a receita acabou.
static func avancar(st: Dictionary, quantas: int) -> bool:
	var i: int = int(st["i"])
	var n: int = int(st["n"])
	if i >= n:
		return true
	var fim: int = mini(n, i + maxi(BLOCO, quantas))

	var buf: PackedFloat32Array = st["buf"]
	var off: int = int(st["off"])
	var fases: PackedFloat32Array = st["fases"]
	var razoes: PackedFloat32Array = st["razoes"]
	var rng: RandomNumberGenerator = st["rng"]
	var codigo: int = int(st["codigo"])
	var vozes: int = int(st["vozes"])
	var passo: float = float(st["passo"])
	var f0: float = float(st["f0"])
	var f1: float = float(st["f1"])
	var curva: float = float(st["curva"])
	var vib_hz: float = float(st["vib_hz"])
	var vib: float = float(st["vib"])
	var mix_ruido: float = float(st["ruido"])
	var sus: float = float(st["sus"])
	var vol: float = float(st["vol"])
	var i_atk: int = int(st["i_atk"])
	var i_dec: int = int(st["i_dec"])
	var i_rel: int = int(st["i_rel"])
	var lp0: float = float(st["lp0"])
	var lp1: float = float(st["lp1"])
	var sat: float = float(st["sat"])
	var fm_ratio: float = float(st["fm_ratio"])
	var fm_dk: float = float(st["fm_dk"])
	var tem_fm: bool = float(st["fm_index"]) > 0.0 and fm_ratio > 0.0
	var fm_env: float = float(st["fm_env"])
	var fase_fm: float = float(st["fase_fm"])
	var lp_y: float = float(st["lp_y"])
	var nf := float(n)

	var f := f0
	var df := 0.0
	var a_lp := 1.0
	var fase := fases[0]
	var primeira := true

	while i < fim:
		# --- taxa de controle: uma vez a cada BLOCO amostras ---
		if primeira or i % BLOCO == 0:
			primeira = false
			var t01 := float(i) / nf
			var t01b := minf(1.0, float(i + BLOCO) / nf)
			var fa := varredura(t01, f0, f1, curva)
			var fb := varredura(t01b, f0, f1, curva)
			if vib_hz > 0.0:
				fa *= 1.0 + vib * sin(TAU * vib_hz * float(i) * passo)
				fb *= 1.0 + vib * sin(TAU * vib_hz * float(i + BLOCO) * passo)
			f = fa
			df = (fb - fa) / float(BLOCO)
			a_lp = coef_lp(lerpf(lp0, lp1, t01), passo)

		# --- envelope ---
		var env := 0.0
		if i < i_atk:
			env = float(i) / float(i_atk)
		elif i < i_dec:
			env = lerpf(1.0, sus, float(i - i_atk) / float(i_dec - i_atk))
		elif i < i_rel:
			env = sus
		else:
			env = sus * float(n - i) / maxf(1.0, float(n - i_rel))

		# --- FM ---
		var desvio := 0.0
		if tem_fm:
			fase_fm += f * fm_ratio * passo
			if fase_fm >= 1.0:
				fase_fm -= floor(fase_fm)
			desvio = sin(fase_fm * TAU) * fm_env
			fm_env *= fm_dk

		# --- osciladores ---
		var v := 0.0
		if vozes == 1:
			fase += f * passo
			if fase >= 1.0:
				fase -= floor(fase)
			v = _amostra(codigo, fase + desvio, rng)
		else:
			for k in vozes:
				var ph: float = fases[k] + f * razoes[k] * passo
				if ph >= 1.0:
					ph -= floor(ph)
				fases[k] = ph
				v += _amostra(codigo, ph + desvio, rng)
			v /= float(vozes)

		if mix_ruido > 0.0:
			v = lerpf(v, rng.randf() * 2.0 - 1.0, mix_ruido)

		lp_y += a_lp * (v - lp_y)
		v = lp_y
		if sat > 0.0:
			var g := 1.0 + sat * 5.0
			v = (v * g) / (1.0 + absf(v * g))

		buf[off + i] += v * env * vol
		f += df
		i += 1

	if vozes == 1:
		fases[0] = fase
	st["i"] = i
	st["lp_y"] = lp_y
	st["fm_env"] = fm_env
	st["fase_fm"] = fase_fm
	return i >= n

static func _amostra(codigo: int, fase: float, rng: RandomNumberGenerator) -> float:
	match codigo:
		0:
			return sin(fase * TAU)
		1:
			return 1.0 if fposmod(fase, 1.0) < 0.5 else -1.0
		2:
			return fposmod(fase, 1.0) * 2.0 - 1.0
		3:
			return absf(fposmod(fase, 1.0) * 4.0 - 2.0) - 1.0
	return rng.randf() * 2.0 - 1.0

## ------------------------------------------------------------------- wav

## Amostras -> AudioStreamWAV (16 bits, mono, normalizado, com fade anti-clique).
static func wav(buf: PackedFloat32Array, pico: float = 0.85) -> AudioStreamWAV:
	var n := buf.size()
	var maxv := 0.0
	for i in n:
		maxv = maxf(maxv, absf(buf[i]))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var g: float = 1.0 if maxv <= 0.0001 else pico / maxv
	codificar(buf, bytes, 0, n, g)
	return montar(bytes)

## Converte um trecho de amostras em bytes de 16 bits, com fade nas pontas.
static func codificar(buf: PackedFloat32Array, bytes: PackedByteArray, de: int, ate: int, ganho: float) -> void:
	var n := buf.size()
	var fade: int = maxi(1, mini(n, int(0.004 * float(TAXA))))
	var ini: int = maxi(1, mini(n, int(0.001 * float(TAXA))))
	for i in range(de, mini(ate, n)):
		var v := buf[i] * ganho
		if i < ini:
			v *= float(i) / float(ini)
		if i >= n - fade:
			v *= float(n - i) / float(fade)
		bytes.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))

static func montar(bytes: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = TAXA
	w.stereo = false
	w.loop_mode = AudioStreamWAV.LOOP_DISABLED
	w.data = bytes
	return w

## ---------------------------------------------------------------- fábrica

## Gera um som em fatias, dentro de um orçamento de milissegundos por quadro.
## Nenhuma etapa — render, normalização ou escrita — roda inteira de uma vez,
## então nem um som de dois segundos custa um quadro perdido.
class Fabrica extends RefCounted:
	enum { RENDER, PICO, ESCRITA, FIM }

	var pico: float
	var buf := PackedFloat32Array()
	var bytes := PackedByteArray()
	var estados: Array = []
	var camada := 0
	var fase := RENDER
	var cursor := 0
	var maxv := 0.0
	var ganho := 1.0
	var n := 0
	var pronto := false
	var resultado: AudioStreamWAV = null

	func _init(camadas: Array, pico_norm: float = 0.85) -> void:
		pico = pico_norm
		n = Synth.amostras_totais(camadas)
		buf.resize(n)
		for item in camadas:
			var r: Dictionary = item
			var off: int = int(maxf(0.0, float(r.get("atraso", 0.0))) * float(Synth.TAXA))
			estados.append(Synth.preparar(r, buf, off))

	## Trabalha ~`amostras` amostras. Devolve true quando o WAV ficou pronto.
	func avancar(amostras: int) -> bool:
		var quantas := maxi(64, amostras)
		match fase:
			RENDER:
				if camada >= estados.size():
					fase = PICO
					return false
				var st: Dictionary = estados[camada]
				if Synth.avancar(st, quantas):
					camada += 1
					if camada >= estados.size():
						fase = PICO
						cursor = 0
			PICO:
				var ate: int = mini(n, cursor + quantas * 6)
				while cursor < ate:
					maxv = maxf(maxv, absf(buf[cursor]))
					cursor += 1
				if cursor >= n:
					ganho = 1.0 if maxv <= 0.0001 else pico / maxv
					bytes.resize(n * 2)
					cursor = 0
					fase = ESCRITA
			ESCRITA:
				var ate2: int = mini(n, cursor + quantas * 4)
				Synth.codificar(buf, bytes, cursor, ate2, ganho)
				cursor = ate2
				if cursor >= n:
					resultado = Synth.montar(bytes)
					pronto = true
					fase = FIM
					estados.clear()
					buf = PackedFloat32Array()
		return pronto
