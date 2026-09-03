class_name Synth
extends RefCounted

## Sintetizador procedural. Este jogo não tem um único arquivo de som:
## tudo aqui vira PCM de 16 bits gerado na memória.
##
## Uma RECEITA é um Dicionário. Nada é obrigatório — o que faltar vira padrão.
##   dur         duração em segundos
##   onda        "senoide" | "quadrada" | "dente" | "triangulo" | "ruido"
##   f0, f1      frequência inicial e final (varredura); f1 omitido = sem varredura
##   curva       exponente da varredura (1 = linear no tempo, >1 = cai no fim)
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
## Fluxo normal: `Synth.som([receita, receita, ...])` -> AudioStreamWAV.
## Gere UMA vez, guarde, toque mil vezes.

const TAXA := 44100
const LA_MIDI := 69.0

## ------------------------------------------------------------ osciladores

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

## ------------------------------------------------------------- envelopes

## ADSR normalizado: `t` e `dur` em segundos, `sus` é o nível do sustento.
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

## Frequência de uma nota MIDI (60 = dó central).
static func freq(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - LA_MIDI) / 12.0)

## ---------------------------------------------------------------- render

## Uma receita -> amostras mono em ponto flutuante.
static func render(r: Dictionary) -> PackedFloat32Array:
	var dur: float = maxf(0.005, float(r.get("dur", 0.2)))
	var n: int = int(dur * float(TAXA))
	var buf := PackedFloat32Array()
	buf.resize(n)
	if n <= 0:
		return buf

	var forma: String = str(r.get("onda", "senoide"))
	var f0: float = float(r.get("f0", 440.0))
	var f1: float = float(r.get("f1", f0))
	var curva: float = float(r.get("curva", 1.0))
	var vozes: int = clampi(int(r.get("vozes", 1)), 1, 8)
	var detune: float = float(r.get("detune", 0.0))
	var mix_ruido: float = clampf(float(r.get("ruido", 0.0)), 0.0, 1.0)
	var vib_hz: float = float(r.get("vibrato_hz", 0.0))
	var vib: float = float(r.get("vibrato", 0.0))
	var atk: float = float(r.get("atk", 0.004))
	var dec: float = float(r.get("dec", 0.06))
	var sus: float = float(r.get("sus", 0.0))
	var rel: float = float(r.get("rel", 0.02))
	var vol: float = float(r.get("vol", 1.0))
	var fm_ratio: float = float(r.get("fm_ratio", 0.0))
	var fm_index: float = float(r.get("fm_index", 0.0))
	var fm_decai: float = float(r.get("fm_decai", 3.0))
	var lp0: float = float(r.get("lp0", 18000.0))
	var lp1: float = float(r.get("lp1", lp0))
	var sat: float = float(r.get("sat", 0.0))

	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.get("semente", 20260903))

	var fases := PackedFloat32Array()
	var desafinos := PackedFloat32Array()
	fases.resize(vozes)
	desafinos.resize(vozes)
	for i in vozes:
		fases[i] = float(i) * 0.137
		desafinos[i] = 0.0 if vozes == 1 else lerpf(-detune, detune, float(i) / float(vozes - 1))

	var passo := 1.0 / float(TAXA)
	var lp_fixo := absf(lp0 - lp1) < 1.0
	var a_fixo := _coef_lp(lp0, passo)
	var tem_fm := fm_index > 0.0 and fm_ratio > 0.0
	var fase_fm := 0.0
	var lp_y := 0.0

	for i in n:
		var t := float(i) * passo
		var t01 := t / dur
		var f := varredura(t01, f0, f1, curva)
		if vib_hz > 0.0:
			f *= 1.0 + vib * sin(TAU * vib_hz * t)

		var desvio := 0.0
		if tem_fm:
			fase_fm += f * fm_ratio * passo
			desvio = sin(fase_fm * TAU) * fm_index * exp(-fm_decai * t)

		var v := 0.0
		for k in vozes:
			fases[k] += f * pow(2.0, desafinos[k] / 12.0) * passo
			v += osc(forma, fases[k] + desvio, rng)
		v /= float(vozes)
		if mix_ruido > 0.0:
			v = lerpf(v, rng.randf() * 2.0 - 1.0, mix_ruido)

		var a := a_fixo if lp_fixo else _coef_lp(lerpf(lp0, lp1, t01), passo)
		lp_y += a * (v - lp_y)
		v = lp_y

		if sat > 0.0:
			v = saturar(v, sat)
		buf[i] = v * env_adsr(t, dur, atk, dec, sus, rel) * vol
	return buf

static func _coef_lp(fc: float, passo: float) -> float:
	return clampf(1.0 - exp(-TAU * clampf(fc, 20.0, 19000.0) * passo), 0.0, 1.0)

## ---------------------------------------------------------------- mistura

## Soma várias receitas, cada uma no seu `atraso`.
static func mixar(camadas: Array) -> PackedFloat32Array:
	var partes: Array = []
	var total := 0
	for item in camadas:
		var r: Dictionary = item
		var b := render(r)
		var off: int = int(maxf(0.0, float(r.get("atraso", 0.0))) * float(TAXA))
		partes.append([b, off])
		total = maxi(total, off + b.size())
	var out := PackedFloat32Array()
	out.resize(total)
	for p in partes:
		var par: Array = p
		var b: PackedFloat32Array = par[0]
		var off: int = int(par[1])
		for i in b.size():
			out[off + i] += b[i]
	return out

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

## ------------------------------------------------------------------- wav

## Amostras -> AudioStreamWAV (16 bits, mono, normalizado, com fade anti-clique).
static func wav(buf: PackedFloat32Array, pico: float = 0.85) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = TAXA
	w.stereo = false
	w.loop_mode = AudioStreamWAV.LOOP_DISABLED
	var n := buf.size()
	if n <= 0:
		w.data = PackedByteArray()
		return w

	var maxv := 0.0
	for i in n:
		maxv = maxf(maxv, absf(buf[i]))
	var g: float = 1.0 if maxv <= 0.0001 else pico / maxv
	var fade: int = maxi(1, mini(n, int(0.004 * float(TAXA))))
	var ini: int = maxi(1, mini(n, int(0.001 * float(TAXA))))

	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var v := buf[i] * g
		if i < ini:
			v *= float(i) / float(ini)
		if i >= n - fade:
			v *= float(n - i) / float(fade)
		bytes.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	w.data = bytes
	return w

## Atalho: lista de receitas -> AudioStreamWAV pronto.
static func som(camadas: Array, pico: float = 0.85) -> AudioStreamWAV:
	return wav(mixar(camadas), pico)
