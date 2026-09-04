class_name Combate
extends RefCounted

## Aplicação de dano, status elementais e recompensas de abate.
## `j` é sempre o autoload Jogo (tipado como Node para evitar ciclo de tipos).

## Aplica dano a um inimigo. Devolve { morreu, dano, overkill, absorvido }.
## Resposta reaproveitada de `aplicar_dano`. LEIA ANTES DA PRÓXIMA CHAMADA.
##
## Montar `{"morreu": ..., "dano": ..., "overkill": ..., "absorvido": ...}` era
## uma alocação de Dicionário por golpe. Na perna de 160 vivos são centenas de
## golpes por passo — corrente, área, dano contínuo, orbe, purga, cada projétil
## —, e dos onze lugares que chamam, só DOIS olham a resposta (o dano em área e
## a Purga, os dois contando mortos), e os dois olham na linha seguinte.
##
## Quem precisar guardar copia: `resultado.duplicate()`.
static var _res := {"morreu": false, "dano": Big.ZERO, "overkill": Big.ZERO, "absorvido": false}

static func _responder(morreu: bool, dano: float, overkill: float, absorvido: bool) -> Dictionary:
	_res["morreu"] = morreu
	_res["dano"] = dano
	_res["overkill"] = overkill
	_res["absorvido"] = absorvido
	return _res

static func aplicar_dano(e: Inimigo, dano: float, j, opt: Dictionary = {}) -> Dictionary:
	if not e.vivo():
		return _responder(false, Big.ZERO, Big.ZERO, false)

	# AS OPÇÕES SÃO LIDAS UMA VEZ CADA.
	#
	# Eram doze `opt.get()` espalhados pela função — `crit` sozinho aparecia
	# quatro vezes —, cada um com conversão de tipo em cima. Esta função é o
	# átomo do combate: projétil, área, corrente, orbe, dano contínuo, purga e
	# habilidade passam todos por aqui, dezenas de vezes por passo. Ler o
	# Dicionário uma vez por campo não muda nenhum resultado e tira o trabalho
	# repetido do lugar mais quente do jogo.
	var crit := bool(opt.get("crit", false))
	var elemento := str(opt.get("elemento", ""))
	var eh_dot := bool(opt.get("dot", false))

	var dmg := dano

	if e.fissura > 0.0:
		dmg = Big.mul_f(dmg, 1.0 + e.fissura_forca)
	if e.marcado > 0.0:
		dmg = Big.mul_f(dmg, 1.5)
	if e.armadura > 0.0 and not bool(opt.get("puro", false)):
		dmg = Big.mul_f(dmg, Bal.fator_armadura(e.armadura, float(opt.get("penetracao", 0.0))))
	# "Devolve dano em contato" — a promessa estava no JSON, nos dois idiomas,
	# impressa no codex, e nada no jogo a lia: o modificador só trocava a cor.
	# Devolve uma fração pequena e fixa; quem reflete o golpe inteiro é o
	# Guardião do Espelho, e os dois não podem ser a mesma coisa.
	#
	# UM E DE INTEIROS NO LUGAR DE DUAS COMPARACOES DE STRING. Este bloco roda a
	# cada impacto, e um inimigo pode carregar tres cepas — pelo caminho antigo
	# seriam tres comparacoes de texto por golpe. `MASCARA_COMBATE` responde por
	# todas de uma vez e a esmagadora maioria dos impactos sai aqui.
	if (e.cepa_bits & Cepas.MASCARA_COMBATE) != 0:
		if (e.cepa_bits & Cepas.B_ESPINHOSO) != 0 and not bool(opt.get("reflexo", false)):
			j.dano_na_torre(Bal.dano_espinho(dano, j.s["torre"]["vida_max"]), e, {"reflexo": true})
		if (e.cepa_bits & Cepas.B_BLINDADO) != 0:
			dmg = Big.mul_f(dmg, 0.55)
		# "Friavel": quebra facil e paga o dobro. E a cepa que o jogador QUER
		# encontrar, e a unica que torna o inimigo mais fraco de proposito.
		if (e.cepa_bits & Cepas.B_FRIAVEL) != 0:
			dmg = Big.mul_f(dmg, 1.7)

	var absorvido := false
	if e.escudo > Big.LIMIAR_ZERO:
		if Big.gte(e.escudo, dmg):
			e.escudo = Big.sub(e.escudo, dmg)
			e.flash = maxf(e.flash, 0.12)
			Bus.inimigo_atingido.emit(e, dmg, crit, elemento, eh_dot)
			return _responder(false, dmg, Big.ZERO, true)
		dmg = Big.sub(dmg, e.escudo)
		e.escudo = Big.ZERO
		absorvido = true

	# execução
	var limiar := float(opt.get("execucao", 0.0))
	if limiar > 0.0 and not e.chefe and e.frac_vida() <= limiar:
		dmg = e.hp

	var hp_antes := e.hp
	e.hp = Big.sub(e.hp, dmg)
	e.flash = maxf(e.flash, 0.2 if crit else 0.12)
	e.tremor = minf(1.0, e.tremor + 0.35)
	e.sem_dano_t = 0.0

	var st: Dictionary = j.s["stats"]
	st["dano_total"] = Big.add(st["dano_total"], dmg)
	if Big.gt(dmg, st["dano_maximo"]):
		st["dano_maximo"] = dmg
	if crit:
		st["criticos"] = int(st["criticos"]) + 1

	var rv := float(opt.get("roubodeVida", 0.0))
	if rv > 0.0 and j.s["torre"]["viva"]:
		var cura := Big.min_b(Big.mul_f(dmg, rv), Big.mul_f(j.s["torre"]["vida_max"], 0.05))
		if not Big.is_zero(cura):
			j.curar_torre(cura)

	Bus.inimigo_atingido.emit(e, dmg, crit, elemento, eh_dot)

	if Big.lte(e.hp, Big.ZERO) or Big.is_zero(e.hp):
		var overkill := Big.ZERO
		if Big.gt(dmg, hp_antes):
			overkill = Big.min_b(Big.sub(dmg, hp_antes), Big.mul_f(hp_antes, Bal.OVERKILL_TETO))
		matar(e, j, overkill, crit, float(opt.get("ouro_mult", 1.0)))
		return _responder(true, dmg, overkill, absorvido)
	return _responder(false, dmg, Big.ZERO, absorvido)

## Dano em área.
## Cópia própria dos alvos da explosão, reaproveitada entre chamadas.
##
## `em_area` devolve um buffer interno que ela mesma reusa, então quem vai
## MEXER no jogo enquanto percorre precisa de cópia: matar um inimigo dispara
## efeitos que podem chamar `em_area` de novo e reescrever o buffer no meio do
## laço. A cópia era `.duplicate()` — uma alocação de Array por explosão, e com
## a área no máximo são dezenas de explosões por passo. `resize` num Array que
## já tem espaço não realoca: a cópia continua sendo cópia, sem lixo novo.
static var _alvos_area: Array[Inimigo] = []

static func dano_area(centro: Vector2, raio: float, dano: float, j, opt: Dictionary = {}) -> int:
	var vindos: Array[Inimigo] = j.arena.em_area(centro, raio)
	var quantos := vindos.size()
	_alvos_area.resize(quantos)
	for i in quantos:
		_alvos_area[i] = vindos[i]
	var mortos := 0
	var ignorar: Array = opt.get("ignorar", [])
	var tem_ignorar := not ignorar.is_empty()
	var queda := bool(opt.get("queda", false))
	var cx_a := centro.x
	var cy_a := centro.y
	var raio_seguro := maxf(1.0, raio)
	for e in _alvos_area:
		if tem_ignorar and ignorar.has(e):
			continue
		var q := 1.0
		if queda:
			# Números crus em vez de `e.pos.distance_to(centro)`: a raiz é
			# necessária, o Vector2 temporário não.
			var adx := e.pos.x - cx_a
			var ady := e.pos.y - cy_a
			q = maxf(0.35, 1.0 - sqrt(adx * adx + ady * ady) / raio_seguro)
		var r := aplicar_dano(e, Big.mul_f(dano, q), j, opt)
		if r["morreu"]:
			mortos += 1
	return mortos

## Corrente de raio entre alvos próximos.
static func corrente(origem: Inimigo, dano: float, saltos: int, j, opt: Dictionary = {}) -> Array:
	var visitados: Array = [origem]
	var atual := origem
	var dmg := dano
	var pontos: Array = [origem.pos]
	var fator := float(Bal.ELEMENTOS["raio"].get("fator", 0.45))
	for i in saltos:
		# Pela grade: o salto do raio alcança 190px, e varrer a lista inteira a
		# cada salto era o mesmo desperdício dos orbes.
		var prox = j.arena.alvo_no_raio(atual.pos, 190.0, visitados)
		if prox == null:
			break
		visitados.append(prox)
		dmg = Big.mul_f(dmg, fator)
		var o := opt.duplicate()
		o["elemento"] = "raio"
		aplicar_dano(prox, dmg, j, o)
		pontos.append(prox.pos)
		atual = prox
	if pontos.size() > 1:
		Bus.particulas.emit("raio", origem.pos, {"pontos": pontos, "cor": Bal.ELEMENTOS["raio"]["cor"]})
	return pontos

## Aplica um status elemental.
static func aplicar_elemento(e: Inimigo, elemento: String, dano_base_bruto: float, j) -> void:
	if not Bal.ELEMENTOS.has(elemento) or not e.vivo():
		return
	# O Enxame se adapta: o elemento que você mais usa passa a doer menos.
	Mecanicas.registrar_elemento(j.s, elemento)
	var dano_base := Big.mul_f(dano_base_bruto, Mecanicas.fator_elemento(j.s, elemento))
	var d: Dictionary = Bal.ELEMENTOS[elemento]
	match elemento:
		"fogo":
			e.queimadura = mini(int(d["pilhas"]), e.queimadura + 1)
			e.queimadura_dano = Big.mul_f(dano_base, float(d["dot"]))
			e.queimadura_t = float(d["duracao"])
		"veneno":
			e.veneno = mini(int(d["pilhas"]), e.veneno + 1)
			e.veneno_dano = Big.mul_f(dano_base, float(d["dot"]))
			e.veneno_t = float(d["duracao"])
		"gelo":
			# A ADAPTACAO VALE AQUI TAMBEM. `dano_base` ja traz o fator, mas gelo
			# e vazio nao dependem de dano: eles entregam lentidao e ampliacao.
			# Como estes dois ramos ignoravam `dano_base`, o Enxame nunca se
			# adaptava a eles — e mesmo assim o HUD mostrava a resistencia
			# subindo ate -62% para os CINCO elementos. Dois dos cinco numeros
			# na tela eram falsos, e a build que o jogador montava para fugir da
			# adaptacao fugia de um problema que ele nao tinha.
			var f_gelo := Mecanicas.fator_elemento(j.s, elemento)
			e.gelo = float(d["duracao"])
			e.gelo_forca = minf(0.75, float(d["lentidao"]) * (1.0 + float(j.stats.n("danoGelo"))) * f_gelo)
		"vazio":
			var f_vazio := Mecanicas.fator_elemento(j.s, elemento)
			e.fissura = float(d["duracao"])
			e.fissura_forca = minf(1.2, float(d["ampliacao"]) * (1.0 + float(j.stats.n("danoVazio"))) * f_vazio)
		"raio":
			# A CORRENTE TEM ESPERA. Ela partia a cada acerto: com 53 impactos
			# por passo e tres saltos cada, sao ate 159 buscas na grade e 159
			# aplicacoes de dano por passo so em raio — medido, 1,9 ms, quase
			# metade do orcamento do quadro. Um arco tambem nao reacende no
			# mesmo corpo no quadro seguinte; ele precisa recarregar.
			if e.raio_cd <= 0.0:
				e.raio_cd = RAIO_ESPERA
				corrente(e, dano_base, int(d["corrente"]), j, {})

## Tique de status (dano contínuo, lentidão, marcações).
## O DANO CONTINUO COBRA A CADA 0,1 s, NAO A CADA QUADRO.
##
## Queimadura e veneno aplicavam dano em todo passo de fisica: com 212 inimigos
## em chamas isso da 424 chamadas de `aplicar_dano` por passo — medido, 3,1 ms
## de um orcamento de 4 ms, so para dividir o mesmo dano em sessenta pedacos
## por segundo em vez de dez. O total nao muda (o acumulador guarda o tempo
## real decorrido); o que muda e o numero de chamadas, seis vezes menor.
##
## O deslocamento por `id` espalha os tiques entre os quadros: sem ele, todos os
## inimigos cobrariam no MESMO passo e o pico voltaria inteiro num quadro so.
const DOT_INTERVALO := 0.1
## Espera da corrente de raio por inimigo (ver `aplicar_elemento`).
const RAIO_ESPERA := 0.18

static func atualizar_status(dt: float, j) -> void:
	var lista: Array = j.arena.inimigos
	for e in lista:
		if not e.vivo():
			continue
		var cobra := false
		var janela := 0.0
		if e.queimadura > 0 or e.veneno > 0:
			e.dot_acc += dt
			if e.dot_acc >= DOT_INTERVALO:
				cobra = true
				janela = e.dot_acc
				e.dot_acc = 0.0
		if e.queimadura > 0:
			e.queimadura_t -= dt
			if e.queimadura_t <= 0.0:
				e.queimadura = 0
			elif cobra:
				aplicar_dano(e, Big.mul_f(e.queimadura_dano, float(e.queimadura) * janela), j, {"puro": true, "elemento": "fogo", "dot": true})
		if e.veneno > 0 and e.vivo():
			e.veneno_t -= dt
			if e.veneno_t <= 0.0:
				e.veneno = 0
			elif cobra:
				aplicar_dano(e, Big.mul_f(e.veneno_dano, float(e.veneno) * janela), j, {"puro": true, "elemento": "veneno", "dot": true})
		if e.raio_cd > 0.0:
			e.raio_cd -= dt
		if e.gelo > 0.0:
			e.gelo -= dt
		if e.fissura > 0.0:
			e.fissura -= dt
		if e.atordoado > 0.0:
			e.atordoado -= dt
		if e.marcado > 0.0:
			e.marcado -= dt
		if e.flash > 0.0:
			e.flash -= dt * 4.0
		if e.tremor > 0.0:
			e.tremor -= dt * 2.5

## Mata o inimigo e distribui recompensas.
## `ouro_mult` multiplica o ouro deste abate. Existe para o Julgamento, que
## promete "converte cada abate em ouro dobrado" — promessa que estava só no
## texto da habilidade.
static func matar(e: Inimigo, j, overkill: float = Big.ZERO, critico: bool = false, ouro_mult: float = 1.0) -> void:
	if e.morrendo > 0.0:
		return
	e.morrendo = 0.28
	e.hp = Big.ZERO

	var s: Dictionary = j.s
	var st: Dictionary = s["stats"]
	st["mortos"] = int(st["mortos"]) + 1
	st["por_inimigo"][e.tipo] = int(st["por_inimigo"].get(e.tipo, 0)) + 1
	s["codex"]["inimigos"][e.tipo] = int(s["codex"]["inimigos"].get(e.tipo, 0)) + 1
	# A DESCOBERTA. `ver_forma` responde `true` uma unica vez por combinacao na
	# vida do save — e esse `true` que vira o aviso na tela. Note que nao existe
	# lista de "formas que faltam" em lugar nenhum do jogo: o numero so sobe, e
	# nunca aparece um denominador. Um "347/58282" transformaria descoberta em
	# tarefa, que e exatamente o que este sistema existe para nao ser.
	if not e.cepas.is_empty() and j.ver_forma(e):
		Bus.forma_nova.emit(e)
	if e.chefe:
		st["chefes_mortos"] = int(st["chefes_mortos"]) + 1
		s["codex"]["chefes"][e.tipo] = int(s["codex"]["chefes"].get(e.tipo, 0)) + 1
	if e.dourado:
		st["dourados"] = int(st["dourados"]) + 1
		# Coleira Dourada: "soltam 1 gema ao morrer" — a terceira promessa da
		# relíquia, também sem código por trás.
		if j.pas.has("coleira_dourada"):
			Economia.ganhar_moeda("gemas", Big.from(1.0), j, "dourado")

	# combo
	var teto := int(j.esp.get("comboTeto", Bal.COMBO_TETO))
	s["combo"]["atual"] = mini(teto, int(s["combo"]["atual"]) + 1)
	s["combo"]["timer"] = Bal.COMBO_JANELA + (1.0 if j.pas.has("combo_estendido") else 0.0)
	if int(s["combo"]["atual"]) > int(st["combo_maximo"]):
		st["combo_maximo"] = int(s["combo"]["atual"])
	Bus.combo_mudou.emit(int(s["combo"]["atual"]))

	# ouro com bônus de combo e overkill
	var bonus_combo := 1.0 + float(s["combo"]["atual"]) * float(j.esp.get("comboBonus", Bal.COMBO_BONUS_POR))
	# Aglomeração: o teto de entidades vira economia — tela cheia rende mais.
	var aglom := Mecanicas.fator_aglomeracao(j.arena.contagem_viva())
	var ouro := Big.mul_f(e.ouro, bonus_combo * aglom * maxf(1.0, ouro_mult))
	if not Big.is_zero(overkill):
		var frac := minf(Bal.OVERKILL_TETO, Big.to_f(Big.div(overkill, e.hp_max)))
		ouro = Big.mul_f(ouro, 1.0 + frac)
		if frac > 0.25:
			Bus.overkill.emit(e, frac)

	j.soltar_ouro(e, ouro)
	j.ganhar_xp(e.xp)

	s["mortos_na_onda"] = int(s["mortos_na_onda"]) + 1
	Bus.inimigo_morreu.emit(e, ouro)
	if e.chefe:
		Bus.chefe_morreu.emit(e)

	if (e.cepa_bits & Cepas.MASCARA_MORTE) != 0:
		_cepas_ao_morrer(e, j)

	j.ao_morrer_inimigo(e, critico)

## O que as cepas fazem quando o corpo cai.
##
## Fica atras de `MASCARA_MORTE` pelo mesmo motivo dos outros portoes: a morte
## de inimigo e um caminho quente (dezenas por segundo numa onda cheia) e a
## esmagadora maioria dos corpos nao carrega nenhuma destas quatro.
static func _cepas_ao_morrer(e: Inimigo, j) -> void:
	if (e.cepa_bits & Cepas.B_CINTILANTE) != 0:
		Economia.ganhar_moeda("gemas", Big.from(1.0), j, "cintilante")
	if (e.cepa_bits & Cepas.B_MALDITO) != 0:
		# 10x de ouro tem preco. O dano e uma fracao da vida MAXIMA da torre para
		# que a maldicao continue significando a mesma coisa na hora 200.
		j.dano_na_torre(Big.mul_f(j.s["torre"]["vida_max"], Bal.MALDITO_DANO), e, {"puro": true})
	if (e.cepa_bits & Cepas.B_ECOANTE) != 0 and not e.segmento:
		EnemyAI.criar(e.def, int(j.s["onda"]), j, {
			"pos": e.pos, "hp_mult": Bal.ECO_HP, "esc_mult": 0.7, "segmento": true,
		})
	if (e.cepa_bits & Cepas.B_BIPARTIDO) != 0 and not e.segmento:
		for i in 2:
			var off: Vector2 = j.rng.direcao() * 18.0
			EnemyAI.criar(e.def, int(j.s["onda"]), j, {
				"pos": e.pos + off, "hp_mult": 0.35, "esc_mult": 0.6, "segmento": true,
			})

## Rola crítico e devolve [dano_final, foi_critico].
static func rolar_golpe(dano_base: float, j, alvo: Inimigo) -> Array:
	# "Glacial: imune a critico" e negado AQUI, onde o critico nasce, e nao la
	# no `aplicar_dano` onde o dano ja chega multiplicado. Desfazer o bonus
	# depois exigiria dividir pelo `critDano`, e as habilidades chamam
	# `aplicar_dano` com `crit: true` SEM terem multiplicado por nada — a divisao
	# tiraria dano que ninguem tinha dado. Negar na origem nao tem esse buraco.
	var crit: bool = j.rng.chance(j.stats.n("critChance"))
	if crit and alvo != null and (alvo.cepa_bits & Cepas.B_GLACIAL) != 0:
		crit = false
	var dmg := dano_base
	if crit:
		dmg = Big.mul_f(dmg, float(j.stats.n("critDano")))
	if alvo != null and alvo.chefe:
		dmg = Big.mul_f(dmg, float(j.stats.n("danoChefe")))
	return [dmg, crit]
