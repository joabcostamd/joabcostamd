class_name Sfx
extends RefCounted

## Catálogo de efeitos sonoros. Cada entrada é uma lista de receitas do `Synth`
## somadas em camadas — sem um único byte de arquivo de som no projeto.
##
## Entrada do catálogo:
##   camadas   Array de receitas (ver Synth)
##   db        volume base, em decibéis
##   var       variação aleatória de tom a cada disparo (fração; 0.08 = ±8%)
##   taxa      intervalo mínimo entre dois disparos, em segundos
##   pico      normalização (0..1) — quanto o som "enche" antes do barramento
##
## A ordem de `nomes()` é a ordem de geração: o que toca mais nasce primeiro.

const PADRAO_DB := -10.0
const PADRAO_VAR := 0.05
const PADRAO_TAXA := 0.05

static func _e(camadas: Array, db: float = PADRAO_DB, variacao: float = PADRAO_VAR,
		taxa: float = PADRAO_TAXA, pico: float = 0.85) -> Dictionary:
	return {"camadas": camadas, "db": db, "var": variacao, "taxa": taxa, "pico": pico}

## UM WAV POR NOME VIRA BRITADEIRA.
##
## Cada efeito tinha exatamente uma forma de onda, gerada uma vez. Com vinte
## tiros por segundo, o transiente de ruido — a parte que o ouvido usa para
## separar um golpe do outro — era rigorosamente identico vinte vezes por
## segundo. Variar so o tom (que e o que `var` faz) nao resolve: o ouvido junta
## repeticoes identicas numa textura continua, e o combate virava chiado.
##
## Aqui ficam quantas VARIANTES cada nome tem. Cada variante e a mesma receita
## com outra semente de ruido, entao o carater e o mesmo e o detalhe muda —
## exatamente como dois tiros da mesma arma. So os sons que tocam muitas vezes
## por segundo pagam a memoria; o resto continua com um.
const VARIANTES := {
	"tiro": 4, "impacto": 4, "morte": 3, "tiro_critico": 3, "torre_dano": 2,
	"ouro": 3, "clique": 2,
}

static func variantes(nome: String) -> int:
	return int(VARIANTES.get(nome, 1))

## Nomes na ordem em que devem ser gerados (mais tocados primeiro).
static func nomes() -> Array:
	return [
		"tiro", "impacto", "morte", "ouro", "clique", "tiro_critico",
		"compra", "bloqueado", "abrir", "fechar", "erro", "hab_pronta", "hab_purga",
		"hab_sobrecarga", "hab_chuva_ouro", "hab_escudo", "hab_sentinelas",
		"hab_purga_perfeita",
		"torre_dano", "onda", "nivel", "carta", "missao", "moeda",
		"alerta_chefe", "morte_chefe", "conquista", "lendario",
		"hab_generica", "hab_nova", "hab_congelar", "hab_cura",
		"hab_misseis", "hab_buraco_negro", "hab_julgamento",
		"prestigio", "torre_destruida",
	]

## Som de uma habilidade, por tipo/id (ver data/abilities.json).
## O som diz QUAL habilidade foi usada. Cair no genérico é o mesmo som para
## cinco ações diferentes — e a Purga, que é a mecânica-assinatura do jogo,
## caía nele. A suíte cobra que nenhuma habilidade do conteúdo caia no fallback.
static func som_habilidade(id: String) -> String:
	match id:
		"purga": return "hab_purga"
		"sobrecarga": return "hab_sobrecarga"
		"chuva_ouro": return "hab_chuva_ouro"
		"escudo_absoluto": return "hab_escudo"
		"sentinelas": return "hab_sentinelas"
		"nova": return "hab_nova"
		"tempo": return "hab_congelar"
		"reparo": return "hab_cura"
		"misseis": return "hab_misseis"
		"buraco_negro": return "hab_buraco_negro"
		"julgamento": return "hab_julgamento"
	return "hab_generica"

## ------------------------------------------------------------- o catálogo

static func catalogo() -> Dictionary:
	var c := {}

	# --- combate ------------------------------------------------------
	c["tiro"] = _e([
		{"onda": "quadrada", "f0": 760.0, "f1": 230.0, "curva": 0.55, "dur": 0.075,
		 "atk": 0.001, "dec": 0.05, "rel": 0.02, "lp0": 5200.0, "lp1": 1500.0,
		 "sat": 0.35, "vol": 0.8},
		{"onda": "ruido", "dur": 0.035, "atk": 0.0005, "dec": 0.028, "rel": 0.006,
		 "lp0": 6000.0, "lp1": 2000.0, "vol": 0.35},
	], -13.0, 0.09, 0.048)

	c["tiro_critico"] = _e([
		{"onda": "dente", "f0": 1250.0, "f1": 330.0, "curva": 0.5, "dur": 0.13,
		 "atk": 0.001, "dec": 0.1, "rel": 0.03, "fm_ratio": 2.5, "fm_index": 1.4,
		 "fm_decai": 16.0, "lp0": 8000.0, "lp1": 1800.0, "sat": 0.5, "vol": 0.85},
		{"onda": "quadrada", "f0": 2400.0, "f1": 900.0, "dur": 0.06, "atk": 0.001,
		 "dec": 0.05, "rel": 0.01, "vol": 0.3},
	], -10.0, 0.06, 0.055)

	c["impacto"] = _e([
		{"onda": "ruido", "dur": 0.06, "atk": 0.0005, "dec": 0.05, "rel": 0.01,
		 "lp0": 4200.0, "lp1": 700.0, "vol": 0.7},
		{"onda": "senoide", "f0": 300.0, "f1": 110.0, "curva": 0.6, "dur": 0.08,
		 "atk": 0.001, "dec": 0.06, "rel": 0.015, "vol": 0.55},
	], -16.0, 0.12, 0.045)

	c["morte"] = _e([
		{"onda": "quadrada", "f0": 440.0, "f1": 85.0, "curva": 0.7, "dur": 0.17,
		 "atk": 0.001, "dec": 0.12, "rel": 0.04, "lp0": 3200.0, "lp1": 600.0,
		 "sat": 0.4, "vol": 0.7},
		{"onda": "ruido", "dur": 0.1, "atk": 0.001, "dec": 0.08, "rel": 0.02,
		 "lp0": 5000.0, "lp1": 900.0, "vol": 0.4},
	], -13.0, 0.12, 0.05)

	# O chefe cai como um prédio: sub grave, destroços e uma queda de tom longa.
	c["morte_chefe"] = _e([
		{"onda": "dente", "f0": 260.0, "f1": 42.0, "curva": 1.5, "dur": 1.3,
		 "vozes": 3, "detune": 0.35, "atk": 0.004, "dec": 0.45, "sus": 0.1,
		 "rel": 0.7, "lp0": 3000.0, "lp1": 260.0, "sat": 0.5, "vol": 0.85},
		{"onda": "ruido", "dur": 1.0, "atk": 0.002, "dec": 0.4, "sus": 0.07,
		 "rel": 0.5, "lp0": 2600.0, "lp1": 180.0, "vol": 0.55},
		{"onda": "senoide", "f0": 120.0, "f1": 28.0, "curva": 1.2, "dur": 1.7,
		 "atk": 0.01, "dec": 0.6, "sus": 0.09, "rel": 1.0, "vol": 0.9},
		{"onda": "quadrada", "f0": 900.0, "f1": 180.0, "dur": 0.25, "atraso": 0.02,
		 "atk": 0.001, "dec": 0.2, "rel": 0.05, "lp0": 6000.0, "lp1": 1200.0, "vol": 0.35},
	], -4.0, 0.03, 0.4, 0.95)

	# "EU APANHEI" NAO PODE SER "EU MACHUQUEI" TRANSPOSTO.
	#
	# `impacto` e `torre_dano` eram a mesma receita — ruido curto mais uma
	# senoide descendo — separados so pela altura. Nos dois sons mais frequentes
	# do jogo, um deles significa "esta funcionando" e o outro "voce esta
	# perdendo": o jogador precisa saber qual e sem olhar para a barra de vida.
	#
	# O golpe recebido agora e METAL RACHANDO, nao um baque: um tritono batido
	# (a distancia que o ouvido le como errado), FM inarmonico curto para dar a
	# rachadura, e a cauda desce em vez de cortar. E mais longo e mais escuro de
	# proposito — ocupa espaco, como uma coisa ruim deve ocupar.
	c["torre_dano"] = _e([
		{"onda": "ruido", "dur": 0.26, "atk": 0.001, "dec": 0.2, "sus": 0.05,
		 "rel": 0.08, "lp0": 1800.0, "lp1": 220.0, "vol": 0.65},
		{"onda": "quadrada", "f0": 233.0, "f1": 96.0, "curva": 0.9, "dur": 0.3,
		 "atk": 0.001, "dec": 0.2, "sus": 0.06, "rel": 0.09, "sat": 0.55,
		 "fm_ratio": 1.414, "fm_index": 2.6, "fm_decai": 11.0, "vol": 0.75},
		{"onda": "quadrada", "f0": 329.6, "f1": 140.0, "dur": 0.24, "atraso": 0.008,
		 "atk": 0.001, "dec": 0.17, "rel": 0.06, "lp0": 1500.0, "sat": 0.4, "vol": 0.4},
		{"onda": "senoide", "f0": 62.0, "f1": 41.0, "curva": 1.1, "dur": 0.42,
		 "atk": 0.004, "dec": 0.28, "sus": 0.08, "rel": 0.12, "vol": 0.7},
	], -9.0, 0.08, 0.09)

	c["torre_destruida"] = _e([
		{"onda": "ruido", "dur": 1.5, "atk": 0.005, "dec": 0.5, "sus": 0.06,
		 "rel": 0.9, "lp0": 3200.0, "lp1": 110.0, "vol": 0.8},
		{"onda": "senoide", "f0": 95.0, "f1": 22.0, "curva": 1.3, "dur": 1.9,
		 "atk": 0.01, "dec": 0.65, "sus": 0.06, "rel": 1.15, "vol": 1.0},
		{"onda": "dente", "f0": 320.0, "f1": 34.0, "curva": 1.7, "dur": 1.2,
		 "vozes": 3, "detune": 0.4, "atk": 0.004, "dec": 0.4, "sus": 0.07,
		 "rel": 0.7, "lp0": 2400.0, "lp1": 180.0, "sat": 0.5, "vol": 0.6},
	], -3.0, 0.01, 1.0, 0.95)

	# --- economia -----------------------------------------------------
	# Sino curto: o tom sobe com o combo (o motor manda o pitch).
	# SINO PRECISA DE RAZAO INARMONICA. Com `fm_ratio` inteiro (3,0 aqui e 2,0 no
	# `moeda`) os parciais caem todos em harmonicos da fundamental e o resultado
	# e timbre de orgao, nao de metal: e exatamente a diferenca entre "nota" e
	# "tim". 2,76 e a razao classica de Chowning para sino; 3,51 e a segunda.
	c["ouro"] = _e([
		{"onda": "senoide", "f0": 1320.0, "f1": 1480.0, "curva": 0.4, "dur": 0.11,
		 "atk": 0.001, "dec": 0.09, "rel": 0.02, "fm_ratio": 2.76, "fm_index": 0.62,
		 "fm_decai": 30.0, "vol": 0.7},
		{"onda": "triangulo", "f0": 1980.0, "dur": 0.07, "atraso": 0.012,
		 "atk": 0.001, "dec": 0.06, "rel": 0.01, "vol": 0.3},
	], -17.0, 0.03, 0.045)

	c["moeda"] = _e([
		{"onda": "senoide", "f0": 880.0, "f1": 1320.0, "curva": 0.5, "dur": 0.45,
		 "atk": 0.004, "dec": 0.35, "sus": 0.1, "rel": 0.1, "fm_ratio": 3.51,
		 "fm_index": 1.05, "fm_decai": 8.0, "vol": 0.7},
		{"onda": "triangulo", "f0": 1760.0, "dur": 0.3, "atraso": 0.06,
		 "atk": 0.003, "dec": 0.25, "rel": 0.05, "vol": 0.25},
	], -12.0, 0.04, 0.12)

	# NOVE EFEITOS ERAM O MESMO TRIANGULO TRANSPOSTO.
	#
	# compra, nivel, carta, missao, conquista, prestigio: todos `Synth.sequencia`
	# de onda triangular, diferentes so na nota de partida e nos intervalos. Ou
	# seja: o jogo tinha um instrumento so tocando notas diferentes, e o jogador
	# nao conseguia dizer, de ouvido, se tinha comprado, subido de nivel ou
	# completado uma missao. Timbre e o que separa evento de evento; altura so
	# separa nota de nota.
	#
	# A regra da correcao: diferenciar por EXCITACAO, nao por transposicao. Cada
	# um destes agora e um objeto fisico diferente — trava, papel, marca de
	# caneta, sino de trofeu — e o triangulo cantado fica so onde ele e a coisa
	# certa: subir de nivel.
	#
	# COMPRA: uma trava de maquina fechando. Percussivo, seco, curto — a mao
	# sente o clique. Sem intervalo cantado nenhum.
	c["compra"] = _e([
		{"onda": "quadrada", "f0": 1400.0, "f1": 620.0, "curva": 0.35, "dur": 0.045,
		 "atk": 0.0005, "dec": 0.035, "rel": 0.008, "lp0": 7000.0, "lp1": 2200.0,
		 "sat": 0.45, "vol": 0.55},
		{"onda": "ruido", "dur": 0.05, "atk": 0.0004, "dec": 0.04, "rel": 0.008,
		 "lp0": 5200.0, "lp1": 1100.0, "vol": 0.42},
		{"onda": "senoide", "f0": 196.0, "f1": 150.0, "dur": 0.11, "atraso": 0.006,
		 "atk": 0.001, "dec": 0.085, "rel": 0.02, "vol": 0.5},
	], -12.0, 0.05, 0.05)

	c["bloqueado"] = _e([
		{"onda": "quadrada", "f0": 190.0, "f1": 150.0, "dur": 0.12, "atk": 0.002,
		 "dec": 0.09, "sus": 0.3, "rel": 0.03, "lp0": 1300.0, "sat": 0.55, "vol": 0.6},
		{"onda": "quadrada", "f0": 150.0, "f1": 118.0, "dur": 0.1, "atraso": 0.11,
		 "atk": 0.002, "dec": 0.08, "rel": 0.02, "lp0": 1100.0, "sat": 0.55, "vol": 0.55},
	], -13.0, 0.03, 0.15)

	# --- progressão ---------------------------------------------------
	c["nivel"] = _e(Synth.sequencia(
		{"onda": "triangulo", "f0": 523.25, "dur": 0.3, "vozes": 2, "detune": 0.08,
		 "atk": 0.003, "dec": 0.22, "sus": 0.15, "rel": 0.08, "lp0": 7000.0,
		 "vol": 0.7}, [0, 4, 7, 12], 0.085, 1.0) + [
		{"onda": "senoide", "f0": 130.8, "dur": 0.6, "atk": 0.01, "dec": 0.4,
		 "sus": 0.15, "rel": 0.18, "vol": 0.5},
	], -9.0, 0.02, 0.2)

	c["onda"] = _e([
		{"onda": "dente", "f0": 120.0, "f1": 300.0, "curva": 1.6, "dur": 0.6,
		 "vozes": 3, "detune": 0.14, "atk": 0.12, "dec": 0.3, "sus": 0.5,
		 "rel": 0.16, "lp0": 500.0, "lp1": 3200.0, "sat": 0.25, "vol": 0.7},
		{"onda": "ruido", "dur": 0.5, "atk": 0.3, "dec": 0.15, "sus": 0.4,
		 "rel": 0.12, "lp0": 600.0, "lp1": 5200.0, "vol": 0.3},
	], -13.0, 0.03, 0.3)

	# Duas buzinas dissonantes e um sub: alguém grande está chegando.
	c["alerta_chefe"] = _e([
		{"onda": "quadrada", "f0": 175.0, "dur": 0.36, "vozes": 2, "detune": 0.2,
		 "atk": 0.02, "dec": 0.1, "sus": 0.75, "rel": 0.1, "vibrato_hz": 6.5,
		 "vibrato": 0.02, "lp0": 900.0, "sat": 0.5, "vol": 0.8},
		{"onda": "quadrada", "f0": 185.0, "dur": 0.42, "atraso": 0.42, "vozes": 2,
		 "detune": 0.24, "atk": 0.02, "dec": 0.12, "sus": 0.7, "rel": 0.14,
		 "vibrato_hz": 6.5, "vibrato": 0.03, "lp0": 900.0, "sat": 0.5, "vol": 0.8},
		{"onda": "senoide", "f0": 58.0, "dur": 1.1, "atk": 0.02, "dec": 0.6,
		 "sus": 0.2, "rel": 0.35, "vol": 0.7},
	], -7.0, 0.02, 0.5)

	# PRESTIGIO: o unico que continua sendo um acorde — mas em DENTE com vozes
	# desafinadas e filtro abrindo, nao no mesmo triangulo dos outros cinco. E o
	# momento mais raro do jogo e tem que soar como orgao de catedral, nao como
	# a compra de uma melhoria em outra oitava.
	c["prestigio"] = _e(Synth.sequencia(
		{"onda": "dente", "f0": 261.63, "dur": 0.85, "vozes": 3, "detune": 0.16,
		 "atk": 0.02, "dec": 0.3, "sus": 0.26, "rel": 0.55, "lp0": 1200.0,
		 "lp1": 7000.0, "sat": 0.3, "vol": 0.5}, [0, 7, 12, 16, 19, 24], 0.13, 0.9) + [
		{"onda": "senoide", "f0": 65.4, "dur": 1.7, "atk": 0.02, "dec": 0.6,
		 "sus": 0.22, "rel": 0.95, "vol": 0.7},
		{"onda": "senoide", "f0": 1046.5, "f1": 1568.0, "curva": 0.6, "dur": 1.2,
		 "atraso": 0.5, "atk": 0.25, "dec": 0.5, "sus": 0.2, "rel": 0.45,
		 "fm_ratio": 2.0, "fm_index": 0.6, "fm_decai": 2.0, "vol": 0.3},
	], -6.0, 0.01, 0.5, 0.92)

	c["lendario"] = _e(Synth.sequencia(
		{"onda": "senoide", "f0": 880.0, "dur": 0.8, "atk": 0.002, "dec": 0.5,
		 "sus": 0.12, "rel": 0.28, "fm_ratio": 3.5, "fm_index": 2.2,
		 "fm_decai": 7.0, "vol": 0.6}, [0, 7, 12, 19], 0.1, 0.85) + [
		{"onda": "triangulo", "f0": 220.0, "dur": 1.0, "vozes": 2, "detune": 0.12,
		 "atk": 0.01, "dec": 0.6, "sus": 0.15, "rel": 0.35, "vol": 0.4},
	], -8.0, 0.02, 0.3)

	# CARTA: papel deslizando. Ruido filtrado subindo (o atrito), e so no fim um
	# toque de corda soltando — a carta assentando na mesa.
	c["carta"] = _e([
		{"onda": "ruido", "dur": 0.2, "atk": 0.02, "dec": 0.12, "sus": 0.2,
		 "rel": 0.06, "lp0": 900.0, "lp1": 7000.0, "vol": 0.5},
		{"onda": "triangulo", "f0": 1244.5, "f1": 980.0, "curva": 0.4, "dur": 0.13,
		 "atraso": 0.11, "atk": 0.001, "dec": 0.1, "rel": 0.03, "vol": 0.4},
	], -13.0, 0.04, 0.15)

	# CONQUISTA: sino de trofeu. Metal batido de verdade — parciais inarmonicos
	# (2,76 e 5,4, as razoes de Chowning) com cauda longa, nao um arpejo cantado.
	c["conquista"] = _e([
		{"onda": "senoide", "f0": 659.25, "dur": 1.1, "atk": 0.002, "dec": 0.35,
		 "sus": 0.18, "rel": 0.6, "fm_ratio": 2.76, "fm_index": 3.0,
		 "fm_decai": 5.5, "vol": 0.65},
		{"onda": "senoide", "f0": 988.0, "dur": 0.85, "atraso": 0.03, "atk": 0.002,
		 "dec": 0.3, "sus": 0.12, "rel": 0.45, "fm_ratio": 5.4, "fm_index": 1.7,
		 "fm_decai": 7.0, "vol": 0.34},
		{"onda": "ruido", "dur": 0.04, "atk": 0.0005, "dec": 0.032, "rel": 0.006,
		 "lp0": 9000.0, "lp1": 3000.0, "vol": 0.3},
		{"onda": "senoide", "f0": 164.8, "dur": 0.9, "atk": 0.01, "dec": 0.5,
		 "sus": 0.15, "rel": 0.35, "vol": 0.45},
	], -9.0, 0.02, 0.25)

	# MISSAO: a marca de caneta no papel. Dois riscos curtos de ruido, o segundo
	# mais agudo — o som de um tique sendo feito, nao de uma nota sendo tocada.
	c["missao"] = _e([
		{"onda": "ruido", "dur": 0.055, "atk": 0.001, "dec": 0.045, "rel": 0.008,
		 "lp0": 2600.0, "lp1": 6500.0, "vol": 0.5},
		{"onda": "ruido", "dur": 0.08, "atraso": 0.075, "atk": 0.001, "dec": 0.06,
		 "rel": 0.015, "lp0": 3800.0, "lp1": 9000.0, "vol": 0.55},
		{"onda": "senoide", "f0": 880.0, "dur": 0.16, "atraso": 0.075, "atk": 0.002,
		 "dec": 0.12, "rel": 0.03, "fm_ratio": 2.76, "fm_index": 0.5,
		 "fm_decai": 22.0, "vol": 0.3},
	], -13.0, 0.03, 0.2)

	# --- habilidades ---------------------------------------------------
	c["hab_nova"] = _e([
		{"onda": "ruido", "dur": 0.7, "atk": 0.002, "dec": 0.5, "sus": 0.08,
		 "rel": 0.2, "lp0": 9000.0, "lp1": 400.0, "vol": 0.75},
		{"onda": "dente", "f0": 900.0, "f1": 70.0, "curva": 1.4, "dur": 0.6,
		 "atk": 0.001, "dec": 0.42, "sus": 0.05, "rel": 0.16, "sat": 0.6,
		 "lp0": 6000.0, "lp1": 600.0, "vol": 0.7},
		{"onda": "senoide", "f0": 150.0, "f1": 40.0, "dur": 0.8, "atk": 0.004,
		 "dec": 0.5, "sus": 0.08, "rel": 0.28, "vol": 0.8},
	], -7.0, 0.04, 0.15)

	c["hab_congelar"] = _e([
		{"onda": "senoide", "f0": 2600.0, "f1": 1100.0, "curva": 1.2, "dur": 0.9,
		 "atk": 0.004, "dec": 0.6, "sus": 0.1, "rel": 0.28, "fm_ratio": 7.0,
		 "fm_index": 1.1, "fm_decai": 3.5, "vol": 0.55},
		{"onda": "ruido", "dur": 0.75, "atk": 0.01, "dec": 0.55, "sus": 0.06,
		 "rel": 0.2, "lp0": 7000.0, "lp1": 1400.0, "vol": 0.35},
		{"onda": "triangulo", "f0": 330.0, "f1": 247.0, "dur": 0.9, "vozes": 2,
		 "detune": 0.2, "atk": 0.02, "dec": 0.6, "sus": 0.12, "rel": 0.28, "vol": 0.4},
	], -9.0, 0.03, 0.15)

	c["hab_cura"] = _e(Synth.sequencia(
		{"onda": "triangulo", "f0": 392.0, "dur": 0.55, "vozes": 2, "detune": 0.06,
		 "atk": 0.05, "dec": 0.35, "sus": 0.2, "rel": 0.18, "lp0": 5200.0,
		 "vol": 0.6}, [0, 7, 12], 0.1, 1.0) + [
		{"onda": "senoide", "f0": 196.0, "dur": 0.8, "atk": 0.08, "dec": 0.4,
		 "sus": 0.2, "rel": 0.3, "vol": 0.4},
	], -10.0, 0.03, 0.2)

	c["hab_misseis"] = _e([
		{"onda": "ruido", "dur": 0.3, "atk": 0.02, "dec": 0.2, "sus": 0.15,
		 "rel": 0.09, "lp0": 700.0, "lp1": 4200.0, "vol": 0.5},
		{"onda": "ruido", "dur": 0.3, "atraso": 0.09, "atk": 0.02, "dec": 0.2,
		 "sus": 0.15, "rel": 0.09, "lp0": 800.0, "lp1": 4600.0, "vol": 0.5},
		{"onda": "ruido", "dur": 0.3, "atraso": 0.18, "atk": 0.02, "dec": 0.2,
		 "sus": 0.15, "rel": 0.09, "lp0": 900.0, "lp1": 5000.0, "vol": 0.5},
		{"onda": "quadrada", "f0": 180.0, "f1": 900.0, "curva": 1.8, "dur": 0.35,
		 "atk": 0.01, "dec": 0.25, "rel": 0.08, "lp0": 2500.0, "sat": 0.4, "vol": 0.4},
	], -10.0, 0.05, 0.2)

	c["hab_buraco_negro"] = _e([
		{"onda": "senoide", "f0": 52.0, "f1": 26.0, "curva": 0.8, "dur": 1.6,
		 "atk": 0.9, "dec": 0.4, "sus": 0.5, "rel": 0.3, "vol": 0.9},
		{"onda": "ruido", "dur": 1.5, "atk": 1.0, "dec": 0.3, "sus": 0.4,
		 "rel": 0.2, "lp0": 300.0, "lp1": 2600.0, "vol": 0.4},
		{"onda": "dente", "f0": 110.0, "f1": 55.0, "dur": 1.4, "vozes": 4,
		 "detune": 0.5, "atk": 0.7, "dec": 0.4, "sus": 0.35, "rel": 0.3,
		 "lp0": 900.0, "lp1": 300.0, "vibrato_hz": 3.0, "vibrato": 0.06,
		 "sat": 0.3, "vol": 0.5},
	], -7.0, 0.02, 0.3)

	c["hab_julgamento"] = _e([
		{"onda": "ruido", "dur": 0.9, "atk": 0.003, "dec": 0.6, "sus": 0.08,
		 "rel": 0.25, "lp0": 11000.0, "lp1": 700.0, "vol": 0.8},
		{"onda": "dente", "f0": 90.0, "dur": 1.0, "vozes": 4, "detune": 0.35,
		 "atk": 0.006, "dec": 0.65, "sus": 0.12, "rel": 0.3, "lp0": 400.0,
		 "lp1": 5200.0, "sat": 0.55, "vol": 0.7},
		{"onda": "senoide", "f0": 1568.0, "f1": 523.0, "curva": 1.1, "dur": 0.5,
		 "atk": 0.002, "dec": 0.35, "rel": 0.12, "vol": 0.35},
	], -6.0, 0.03, 0.25)

	# A Purga: carga que descarrega. Grave que sobe e estoura, ruído filtrado
	# abrindo, e uma cauda longa — precisa soar diferente de tudo, porque é a
	# única ação que o jogo pede o tempo todo.
	c["hab_purga"] = _e([
		{"onda": "senoide", "f0": 55.0, "f1": 320.0, "curva": 2.2, "dur": 1.0,
		 "atk": 0.006, "dec": 0.7, "sus": 0.12, "rel": 0.3, "sat": 0.5, "vol": 0.9},
		{"onda": "ruido", "dur": 0.9, "atk": 0.004, "dec": 0.6, "sus": 0.07,
		 "rel": 0.26, "lp0": 500.0, "lp1": 11000.0, "vol": 0.55},
		{"onda": "dente", "f0": 220.0, "f1": 1760.0, "curva": 1.8, "dur": 0.55,
		 "vozes": 3, "detune": 0.25, "atk": 0.002, "dec": 0.4, "sus": 0.05,
		 "rel": 0.14, "sat": 0.7, "lp0": 2400.0, "lp1": 9000.0, "vol": 0.6},
	], -5.0, 0.03, 0.12)

	# PURGA PERFEITA: outro som, nao o mesmo mais alto.
	#
	# A qualidade da Purga vai de 0,18 (estourou a carga) a 1,0 (janela dourada)
	# — o jogo CALCULA esse numero, usa no dano, nas particulas, no tremor e no
	# hitstop, e jogava fora no audio: acertar a janela no milesimo e estourar
	# feio faziam exatamente o mesmo barulho. A recompensa mais fina do jogo era
	# muda.
	#
	# A perfeita tem sino: dois parciais inarmonicos (2,76 e 5,4 da fundamental,
	# as razoes de Chowning) subindo por cima do estouro, e uma cauda longa que
	# a estourada nao tem. Da para reconhecer de olhos fechados.
	c["hab_purga_perfeita"] = _e([
		{"onda": "senoide", "f0": 55.0, "f1": 420.0, "curva": 2.4, "dur": 1.25,
		 "atk": 0.004, "dec": 0.8, "sus": 0.14, "rel": 0.42, "sat": 0.55, "vol": 0.95},
		{"onda": "ruido", "dur": 1.0, "atk": 0.003, "dec": 0.62, "sus": 0.08,
		 "rel": 0.3, "lp0": 600.0, "lp1": 14000.0, "vol": 0.5},
		{"onda": "dente", "f0": 260.0, "f1": 2100.0, "curva": 1.9, "dur": 0.6,
		 "vozes": 3, "detune": 0.22, "atk": 0.002, "dec": 0.44, "sus": 0.05,
		 "rel": 0.16, "sat": 0.7, "lp0": 2600.0, "lp1": 11000.0, "vol": 0.55},
		{"onda": "senoide", "f0": 880.0, "dur": 1.6, "atraso": 0.06, "atk": 0.002,
		 "dec": 0.5, "sus": 0.22, "rel": 0.9, "fm_ratio": 2.76, "fm_index": 2.4,
		 "fm_decai": 3.2, "vol": 0.5},
		{"onda": "senoide", "f0": 1320.0, "dur": 1.3, "atraso": 0.1, "atk": 0.002,
		 "dec": 0.42, "sus": 0.16, "rel": 0.75, "fm_ratio": 5.4, "fm_index": 1.5,
		 "fm_decai": 4.0, "vol": 0.3},
	], -3.0, 0.015, 0.12, 0.95)

	# Sobrecarga: a torre acelera. Serra subindo, com voz dupla batendo.
	c["hab_sobrecarga"] = _e([
		{"onda": "dente", "f0": 180.0, "f1": 1200.0, "curva": 1.6, "dur": 0.5,
		 "vozes": 2, "detune": 0.35, "atk": 0.004, "dec": 0.34, "sus": 0.12,
		 "rel": 0.12, "sat": 0.55, "lp0": 1800.0, "lp1": 8000.0, "vol": 0.7},
		{"onda": "quadrada", "f0": 90.0, "f1": 180.0, "dur": 0.4, "atk": 0.002,
		 "dec": 0.26, "sus": 0.1, "rel": 0.1, "vol": 0.35},
	], -9.0, 0.04, 0.13)

	# Chuva de Ouro: metal caindo. Agudo brilhante, muitas vozes, cauda curta.
	c["hab_chuva_ouro"] = _e([
		{"onda": "senoide", "f0": 1800.0, "f1": 2600.0, "curva": 0.6, "dur": 0.6,
		 "vozes": 3, "detune": 0.5, "atk": 0.002, "dec": 0.4, "sus": 0.08,
		 "rel": 0.18, "fm_ratio": 3.5, "fm_index": 0.8, "fm_decai": 5.0, "vol": 0.5},
		{"onda": "ruido", "dur": 0.45, "atk": 0.002, "dec": 0.3, "sus": 0.05,
		 "rel": 0.12, "lp0": 6000.0, "lp1": 12000.0, "vol": 0.3},
	], -10.0, 0.03, 0.11)

	# Escudo Absoluto: algo fecha. Ataque seco, corpo grave, sem brilho nenhum.
	c["hab_escudo"] = _e([
		{"onda": "senoide", "f0": 420.0, "f1": 120.0, "curva": 1.5, "dur": 0.7,
		 "atk": 0.001, "dec": 0.45, "sus": 0.14, "rel": 0.24, "vol": 0.75},
		{"onda": "triangulo", "f0": 210.0, "f1": 210.0, "dur": 0.75, "vozes": 2,
		 "detune": 0.08, "atk": 0.02, "dec": 0.5, "sus": 0.16, "rel": 0.24,
		 "lp0": 3000.0, "lp1": 900.0, "vol": 0.45},
	], -8.0, 0.03, 0.12)

	# Sentinelas: três coisas nascem. Sequência de três notas subindo.
	c["hab_sentinelas"] = _e(Synth.sequencia(
		{"onda": "triangulo", "f0": 520.0, "dur": 0.16, "atk": 0.003, "dec": 0.12,
		 "rel": 0.05, "lp0": 7000.0, "vozes": 2, "detune": 0.12, "vol": 0.55},
		[0, 4, 9], 0.085, 1.0),
		-10.0, 0.04, 0.12)

	c["hab_generica"] = _e([
		{"onda": "triangulo", "f0": 440.0, "f1": 880.0, "curva": 0.7, "dur": 0.35,
		 "vozes": 2, "detune": 0.1, "atk": 0.006, "dec": 0.24, "sus": 0.15,
		 "rel": 0.1, "lp0": 2000.0, "lp1": 6000.0, "vol": 0.6},
		{"onda": "ruido", "dur": 0.2, "atk": 0.005, "dec": 0.15, "rel": 0.05,
		 "lp0": 1200.0, "lp1": 4000.0, "vol": 0.25},
	], -11.0, 0.05, 0.12)

	c["hab_pronta"] = _e(Synth.sequencia(
		{"onda": "triangulo", "f0": 880.0, "dur": 0.13, "atk": 0.002, "dec": 0.1,
		 "rel": 0.03, "lp0": 9000.0, "vol": 0.5}, [0, 7], 0.075, 1.0),
		-17.0, 0.03, 0.15)

	# --- interface ------------------------------------------------------
	c["clique"] = _e([
		{"onda": "quadrada", "f0": 1000.0, "f1": 700.0, "dur": 0.032,
		 "atk": 0.0008, "dec": 0.024, "rel": 0.006, "lp0": 5200.0, "lp1": 2200.0,
		 "vol": 0.4},
	], -20.0, 0.07, 0.04)

	c["abrir"] = _e([
		{"onda": "triangulo", "f0": 420.0, "f1": 940.0, "curva": 0.6, "dur": 0.13,
		 "atk": 0.002, "dec": 0.1, "rel": 0.03, "lp0": 7000.0, "vol": 0.5},
		{"onda": "ruido", "dur": 0.07, "atk": 0.002, "dec": 0.05, "rel": 0.015,
		 "lp0": 1400.0, "lp1": 4200.0, "vol": 0.18},
	], -17.0, 0.04, 0.08)

	c["fechar"] = _e([
		{"onda": "triangulo", "f0": 940.0, "f1": 400.0, "curva": 0.6, "dur": 0.13,
		 "atk": 0.002, "dec": 0.1, "rel": 0.03, "lp0": 7000.0, "vol": 0.5},
		{"onda": "ruido", "dur": 0.07, "atk": 0.002, "dec": 0.05, "rel": 0.015,
		 "lp0": 4200.0, "lp1": 1200.0, "vol": 0.18},
	], -17.0, 0.04, 0.08)

	c["erro"] = _e([
		{"onda": "quadrada", "f0": 320.0, "f1": 210.0, "curva": 0.8, "dur": 0.2,
		 "atk": 0.002, "dec": 0.14, "sus": 0.25, "rel": 0.05, "lp0": 1600.0,
		 "vibrato_hz": 18.0, "vibrato": 0.05, "sat": 0.55, "vol": 0.6},
	], -13.0, 0.03, 0.2)

	return c
