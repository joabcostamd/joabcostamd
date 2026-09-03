class_name Inimigo
extends RefCounted

## Um inimigo. Objeto reciclado por pool — `limpar()` devolve ao estado neutro.
## Valores de vida/ouro/xp estão em log10 (ver Big).

var ativo := false
var id := 0
var tipo := ""
var def: Dictionary = {}

var pos := Vector2.ZERO
var vel_res := Vector2.ZERO          # impulso residual (empurrões)
var dir_ang := 0.0
var ang := 0.0
var raio := 12.0
var escala := 1.0
var altura := 0.0                    # salto visual

var hp := 0.0
var hp_max := 0.0
var armadura := 0.0
var velocidade := 30.0
var vel_base := 30.0
var ouro := 0.0
var xp := 0.0

var chefe := false
var super_chefe := false
var elite := false
var dourado := false
var elite_mod := ""
var segmento := false
var dividido := false
var peregrino := false
var saiu := false

var fase := 0
var fase_prox := 0.0

# --- status ---
var queimadura := 0
var queimadura_dano := 0.0
var queimadura_t := 0.0
var veneno := 0
var veneno_dano := 0.0
var veneno_t := 0.0
var gelo := 0.0
var gelo_forca := 0.0
var fissura := 0.0
var fissura_forca := 0.0
var atordoado := 0.0
var marcado := 0.0
var intangivel := 0.0
var revelado := false

## Escudo em log10, igual ao HP. Era linear: com hp_max acima de 1e308 o
## `Big.to_f` virava INF e o escudo nunca mais caia.
var escudo := Big.ZERO
var escudo_max := Big.ZERO
var sem_dano_t := 0.0

# --- comportamento ---
var t := 0.0
var cd := 0.0
## Recarga do golpe de contato. Inimigo comum morre ao encostar, mas o chefe
## fica — e sem isto ele batia a cada passo de fisica, 60 vezes por segundo.
var cd_contato := 0.0
var estado := 0
var fase_anim := 0.0
var grudado := false
var ang_grude := 0.0
var mutacao := 0
var vagueio := 0.0
var piscou := 0.0

# --- visual ---
var flash := 0.0
var tremor := 0.0
var morrendo := 0.0
var entrada := 0.0
var cor: Color = Color.WHITE
var cor2: Color = Color.BLACK
var forma := "circulo"
var mov := "direto"
var hab := ""

func limpar() -> void:
	ativo = false
	chefe = false
	super_chefe = false
	elite = false
	dourado = false
	segmento = false
	dividido = false
	peregrino = false
	saiu = false
	elite_mod = ""
	def = {}
	queimadura = 0
	veneno = 0
	gelo = 0.0
	fissura = 0.0
	atordoado = 0.0
	marcado = 0.0
	intangivel = 0.0
	revelado = false
	escudo = Big.ZERO
	escudo_max = Big.ZERO
	flash = 0.0
	tremor = 0.0
	morrendo = 0.0
	entrada = 0.0
	altura = 0.0
	t = 0.0
	cd = 0.0
	cd_contato = 0.0
	estado = 0
	fase = 0
	grudado = false
	mutacao = 0
	vagueio = 0.0
	piscou = 0.0
	sem_dano_t = 0.0
	vel_res = Vector2.ZERO

func vivo() -> bool:
	return ativo and morrendo <= 0.0

func frac_vida() -> float:
	return Big.frac(hp, hp_max)
