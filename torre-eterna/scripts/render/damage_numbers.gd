class_name NumerosDeDano
extends RefCounted

## Números de dano flutuantes — pool fixo, com curva de subida e "pop" no crítico.
##
## Golpes que caem no mesmo lugar em sequência SOMAM num número só, em vez de
## empilhar três textos ilegíveis um em cima do outro. É o que faz a diferença
## entre "está batendo forte" e "tem números demais na tela".

const MAX := 160
const RAIO_FUNDIR := 30.0    ## distância em que um golpe novo entra no número que já está lá
const JANELA_FUNDIR := 0.55  ## por quanto tempo um número aceita somar

var pool: Array = []
var fonte: Font
var densidade := 1.0
var modo := 0            # 0 todos · 1 só críticos · 2 nenhum

func _init() -> void:
	fonte = ThemeDB.fallback_font
	for i in MAX:
		pool.append({"ativo": false})

func limpar() -> void:
	for p in pool:
		p["ativo"] = false

## `valor_log` é o dano em log10 (o mesmo `Big` do resto do jogo); `texto` é ele
## já formatado. Passar os dois evita ter que formatar de novo a cada soma.
func adicionar(pos: Vector2, texto: String, cor: Color, critico: bool = false, escala: float = 1.0, valor_log: float = Big.ZERO) -> void:
	if modo == 2 or (modo == 1 and not critico):
		return

	# golpe novo em cima de um número recente: soma nele e dá outro "pop"
	if valor_log > Big.LIMIAR_ZERO:
		var perto := _fundir_em(pos, critico)
		if not perto.is_empty():
			perto["valor"] = Big.add(float(perto["valor"]), valor_log)
			perto["texto"] = Fmt.big(float(perto["valor"]))
			perto["vida"] = float(perto["vida_max"])
			perto["somas"] = int(perto["somas"]) + 1
			if critico:
				perto["crit"] = true
				perto["cor"] = cor
			return

	var alvo: Dictionary = {}
	for p in pool:
		if not bool(p["ativo"]):
			alvo = p
			break
	if alvo.is_empty():
		alvo = pool[0]
	alvo["ativo"] = true
	alvo["valor"] = valor_log
	alvo["somas"] = 0
	alvo["nascido"] = 0.0
	# Espalha mais na horizontal do que na vertical: os números sobem, então é
	# na largura que eles deixam de se cobrir.
	alvo["pos"] = pos + Vector2(randf_range(-26.0, 26.0), randf_range(-6.0, 2.0))
	alvo["vel"] = Vector2(randf_range(-22.0, 22.0), -62.0 - (34.0 if critico else 0.0))
	alvo["texto"] = texto
	alvo["cor"] = cor
	alvo["crit"] = critico
	alvo["vida"] = 0.85 if not critico else 1.15
	alvo["vida_max"] = alvo["vida"]
	alvo["escala"] = escala

## O número mais próximo que ainda aceita soma. Crítico só funde com crítico:
## o "pop" amarelo grande é informação, não pode ser diluído num número comum.
func _fundir_em(pos: Vector2, critico: bool) -> Dictionary:
	var melhor: Dictionary = {}
	var melhor_d := RAIO_FUNDIR * RAIO_FUNDIR
	for p in pool:
		if not bool(p["ativo"]) or not p.has("valor"):
			continue
		if float(p["nascido"]) > JANELA_FUNDIR:
			continue
		if bool(p["crit"]) != critico:
			continue
		if float(p["valor"]) <= Big.LIMIAR_ZERO:
			continue
		var d: float = (pos - (p["pos"] as Vector2)).length_squared()
		if d < melhor_d:
			melhor_d = d
			melhor = p
	return melhor

func atualizar(dt: float) -> void:
	for p in pool:
		if not bool(p["ativo"]):
			continue
		p["nascido"] = float(p.get("nascido", 0.0)) + dt
		p["vida"] = float(p["vida"]) - dt
		if float(p["vida"]) <= 0.0:
			p["ativo"] = false
			continue
		var v: Vector2 = p["vel"]
		v.y += 118.0 * dt
		v.x *= pow(0.25, dt)
		p["vel"] = v
		p["pos"] = (p["pos"] as Vector2) + v * dt

func desenhar(ci: CanvasItem) -> void:
	for p in pool:
		if not bool(p["ativo"]):
			continue
		var k := clampf(float(p["vida"]) / maxf(0.001, float(p["vida_max"])), 0.0, 1.0)
		var crit := bool(p["crit"])
		var idade := 1.0 - k
		var pop := 1.0
		if idade < 0.18:
			pop = 1.0 + Ux.ease_out_back(idade / 0.18) * (0.55 if crit else 0.25)
		else:
			pop = 1.0 + (0.55 if crit else 0.25)
			pop = lerpf(pop, 1.0, clampf((idade - 0.18) / 0.3, 0.0, 1.0))
		var tam := int(round((16.0 if crit else 13.0) * pop * float(p["escala"])))
		var cor: Color = p["cor"]
		cor.a = clampf(k * 1.6, 0.0, 1.0)
		var texto := str(p["texto"])
		var pos: Vector2 = p["pos"]
		var largura := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		var canto := pos - Vector2(largura * 0.5, 0)
		# contorno escuro para legibilidade em qualquer fundo
		var sombra := Color(0, 0, 0, cor.a * 0.8)
		for off in [Vector2(1.2, 0), Vector2(-1.2, 0), Vector2(0, 1.2), Vector2(0, -1.2)]:
			ci.draw_string(fonte, canto + off, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, sombra)
		ci.draw_string(fonte, canto, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, cor)
