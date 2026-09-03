class_name NumerosDeDano
extends RefCounted

## Números de dano flutuantes — pool fixo, com curva de subida e "pop" no crítico.
##
## Golpes que caem no mesmo lugar em sequência SOMAM num número só, em vez de
## empilhar três textos ilegíveis um em cima do outro. É o que faz a diferença
## entre "está batendo forte" e "tem números demais na tela".

const MAX := 160
const RAIO_FUNDIR := 44.0    ## distância em que um golpe novo entra no número que já está lá
const RAIO_SEPARAR := 30.0   ## abaixo disto dois números viram um borrão ilegível
const TENTATIVAS_SEPARAR := 16
const ANGULO_AUREO := 2.39996323   ## espalha sem nunca repetir direção
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
	var slot := 0
	for i in pool.size():
		var p: Dictionary = pool[i]
		if not bool(p["ativo"]):
			alvo = p
			slot = i
			break
	if alvo.is_empty():
		alvo = pool[0]
		slot = 0
	alvo["slot"] = slot
	alvo["ativo"] = true
	alvo["valor"] = valor_log
	alvo["somas"] = 0
	alvo["nascido"] = 0.0
	# Espalha mais na horizontal do que na vertical: os números sobem, então é
	# na largura que eles deixam de se cobrir. Só que jitter aleatório não
	# resolve densidade: com muitos golpes por segundo, dois números caem quase
	# no mesmo pixel e se leem como um número só — "82" em cima de "1.229" vira
	# "821.229", que é pior do que não mostrar nada. E fundir não cobre o caso:
	# crítico não funde com comum de propósito, e é justo esse par que mais se
	# encontra. Então, depois do jitter, o número é EMPURRADO para longe do
	# vizinho mais próximo até caber.
	alvo["pos"] = _posicao_livre(pos, alvo)
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

## Onde colocar mais um número sem que ele cubra os que já estão ali.
##
## Empurrar do vizinho mais próximo não basta quando são muitos: o número foge
## de um e cai em cima de outro. Aqui a vaga é escolhida em espiral — o ângulo
## áureo espalha pontos sem nunca repetir direção, e o raio cresce com a raiz do
## número de vizinhos, que é o que mantém a densidade constante em vez de
## crescer. Depois disso, algumas rodadas de empurrão acertam o que sobrou.
func _posicao_livre(pos: Vector2, proprio: Dictionary) -> Vector2:
	var alvo_slot := int(proprio.get("slot", 0))
	var vizinhos := 0
	var raio_conta := RAIO_SEPARAR * 3.0
	for p in pool:
		if not bool(p["ativo"]) or p == proprio:
			continue
		if (pos - (p["pos"] as Vector2)).length() < raio_conta:
			vizinhos += 1
	if vizinhos == 0:
		# Sozinho: jitter, que dá vida sem risco de cobrir ninguém.
		return pos + Vector2(randf_range(-26.0, 26.0), randf_range(-6.0, 2.0))
	# Acompanhado: sai da origem por uma direção que depende do SLOT, que é
	# único entre os números vivos. Contar vizinhos não serve de índice: à
	# medida que eles se espalham para fora do raio de contagem, o número cai e
	# a mesma direção é escolhida de novo — foi assim que 45 pares acabaram no
	# mesmo pixel. O slot não repete enquanto os dois estiverem na tela.
	var indice := int(alvo_slot)
	var ang := float(indice) * ANGULO_AUREO
	var raio := RAIO_SEPARAR * (0.9 + 0.55 * float(indice % 5))
	pos += Vector2(cos(ang), sin(ang) * 0.62) * raio

	if _vaga_livre(pos, proprio):
		return pos
	for tentativa in TENTATIVAS_SEPARAR:
		var vizinho: Dictionary = {}
		var pior := RAIO_SEPARAR * RAIO_SEPARAR
		for p in pool:
			if not bool(p["ativo"]) or p == proprio:
				continue
			var d: float = (pos - (p["pos"] as Vector2)).length_squared()
			if d < pior:
				pior = d
				vizinho = p
		if vizinho.is_empty():
			return pos
		var fuga: Vector2 = pos - (vizinho["pos"] as Vector2)
		if fuga.length_squared() < 0.01:
			fuga = Vector2(cos(float(tentativa) * ANGULO_AUREO), sin(float(tentativa) * ANGULO_AUREO))
		pos = (vizinho["pos"] as Vector2) + fuga.normalized() * RAIO_SEPARAR

	# Empurrar do vizinho MAIS PRÓXIMO pode oscilar entre dois: foge de um,
	# encosta no outro, volta. Quando isso acontece, a última palavra é uma
	# busca em espiral por uma vaga que esteja livre de TODO MUNDO — 24
	# direções, raio crescendo. Determinística e limitada.
	for passo in 24:
		var ang2 := float(passo) * ANGULO_AUREO
		var r2 := RAIO_SEPARAR * (1.0 + 0.35 * float(passo))
		var cand: Vector2 = pos + Vector2(cos(ang2), sin(ang2) * 0.62) * r2
		if _vaga_livre(cand, proprio):
			return cand
	return pos

## Verdadeiro quando nenhum número ativo está perto o bastante para virar borrão.
func _vaga_livre(pos: Vector2, proprio: Dictionary) -> bool:
	for p in pool:
		if not bool(p["ativo"]) or p == proprio:
			continue
		if (pos - (p["pos"] as Vector2)).length() < RAIO_SEPARAR * 0.55:
			return false
	return true

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
