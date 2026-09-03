class_name TorreSim
extends RefCounted

## A torre: mira, disparo, projéteis, orbes e defesa.

var j                                 # autoload Jogo
var cd_tiro := 0.0
var angulo_canhao := -PI * 0.5
var recuo := 0.0
var pulso := 0.0
var iframes := 0.0
## Reusado a cada quadro para achar o segundo alvo sem alocar Dicionário novo.
var _ids_alvo := {}
var tempo_sem_dano := 0.0
var orbes: Array = []                 # [{ang, raio, cd, pos}]
var orbes_extra := 0
## Contador da salva circular do Coro de Estilhaços.
var tiros_para_salva := 0

const MODOS_MIRA := ["proximo", "avancado", "forte", "fraco", "chefe", "longe"]

## Quantos DISPAROS a torre desenha por passo de fisica. O que a cadencia pedir
## alem disso vira dano por salva (ver `atualizar`): oito salvas em 1/60 s ja
## sao mais do que o olho separa, e cada uma custa `projeteis` entidades.
const TIROS_POR_PASSO := 8

## Chaves de atributo dos elementos, prontas. Eram montadas com `capitalize()`
## a cada projetil criado — cinco strings novas por tiro, dentro do passo de
## fisica.
const CHAVES_ELEMENTO := {
	"fogo": "danoFogo", "gelo": "danoGelo", "raio": "danoRaio",
	"veneno": "danoVeneno", "vazio": "danoVazio",
}

# Pesos dos elementos: mudam só quando os atributos são recalculados, e não a
# cada tiro. Guardamos junto o contador de recálculos para saber quando o cache
# venceu.
var _pesos_elem: Array = []
var _pesos_total := 0.0
var _pesos_versao := -1

func _init(jogo) -> void:
	j = jogo

## ------------------------------------------------------------- update

func atualizar(dt: float) -> void:
	var s: Dictionary = j.s
	var torre: Dictionary = s["torre"]
	if not bool(torre["viva"]):
		torre["tempo_morta"] = float(torre["tempo_morta"]) - dt
		if float(torre["tempo_morta"]) <= 0.0:
			j.reviver_torre()
		return

	if iframes > 0.0:
		iframes -= dt
	if recuo > 0.0:
		recuo = maxf(0.0, recuo - dt * 7.0)
	pulso += dt
	tempo_sem_dano += dt

	# regeneração (bloqueada por parasitas grudados)
	# Regeneração como parcela da vida máxima — ver Bal.REGEN_POR_PONTO.
	var regen: float = j.stats.b("regen")
	if not Big.is_zero(regen) and j.parasitas == 0 and Big.lt(torre["vida"], torre["vida_max"]):
		var cura := Big.mul_f(Big.mul(regen, torre["vida_max"]), Bal.REGEN_POR_PONTO * dt)
		torre["vida"] = Big.min_b(torre["vida_max"], Big.add(torre["vida"], cura))
	var esc_regen: float = j.stats.b("escudoRegen")
	if not Big.is_zero(esc_regen) and Big.lt(torre["escudo"], torre["escudo_max"]) and tempo_sem_dano > 2.0:
		var recarga := Big.mul_f(Big.mul(esc_regen, torre["escudo_max"]), Bal.ESCUDO_REGEN_POR_PONTO * dt)
		torre["escudo"] = Big.min_b(torre["escudo_max"], Big.add(torre["escudo"], recarga))

	# juros sobre o ouro guardado, com teto (ver Bal.juros_teto)
	var juros: float = j.stats.n("jurosOuro")
	if juros > 0.0:
		var bruto := Big.mul_f(s["moedas"]["ouro"], juros * dt)
		var teto := Bal.juros_teto(int(s["onda"]), dt)
		j.ganhar_ouro(Big.min_b(bruto, teto), "juros", true)

	# mira
	var alcance: float = j.stats.n("alcance")
	var centro_m: Vector2 = j.arena.centro
	var alvo: Inimigo = j.arena.alvo(centro_m, alcance, str(torre["mira"]))
	if alvo != null:
		var centro_a: Vector2 = j.arena.centro
		var ang := (alvo.pos - centro_a).angle()
		angulo_canhao = Ux.ang_lerp(angulo_canhao, ang, minf(1.0, dt * 16.0))

	# cadência
	var cadencia: float = maxf(0.05, j.stats.n("cadencia"))
	cd_tiro -= dt
	var tiros := 0
	# O segundo alvo é calculado UMA vez por quadro, aqui, e não por disparo.
	# `disparar` chamava `arena.alvo()` de novo a cada tiro — uma varredura da
	# lista inteira de inimigos — e com cadência alta são até doze varreduras
	# por quadro para receber quase sempre a MESMA resposta que a mira já tinha.
	# Com 160 vivos isso era o maior custo isolado do passo de simulação.
	var segundo: Inimigo = null
	if alvo != null and int(j.stats.n("projeteis")) > 1:
		_ids_alvo.clear()
		_ids_alvo[alvo.id] = true
		segundo = j.arena.alvo_ids(j.arena.centro, alcance, _ids_alvo)
	# CADENCIA ALEM DO TETO VIRA DANO, NAO PROJETIL.
	#
	# O laco disparava ate doze vezes por passo e JOGAVA FORA o resto: quem
	# comprava cadencia depois disso pagava por nada — a melhoria continuava
	# vendendo velocidade de tiro e nao entregava mais nenhum tiro. E, no
	# caminho contrario, cada tiro extra ate o teto custava quinze projeteis no
	# pool: medido, a onda 209 saturava os 800 projeteis do pool e o subsistema
	# sozinho custava 4.778 us por passo, mais do que o orcamento inteiro do
	# quadro.
	#
	# Agora a conta e fechada e exata: quantos tiros a cadencia pede neste
	# passo, quantos cabem (`TIROS_POR_PASSO`), e a razao entre os dois vira
	# multiplicador de dano da salva. O jogador recebe o dano que comprou, o
	# quadro nao paga por projetil que ninguem consegue ver, e a conta e O(1) —
	# nao ha laco que cresca com a cadencia.
	if alvo != null and cd_tiro <= 0.0:
		var pedidos := clampi(int(floor(-cd_tiro * cadencia)) + 1, 1, 100000)
		cd_tiro += float(pedidos) / cadencia
		tiros = mini(pedidos, TIROS_POR_PASSO)
		var forca := float(pedidos) / float(tiros)
		for i in tiros:
			disparar(alvo, segundo, forca)
	if cd_tiro < 0.0:
		cd_tiro = 0.0

	atualizar_orbes(dt)

## ------------------------------------------------------------ disparo

func disparar(alvo: Inimigo, segundo: Inimigo = null, forca: float = 1.0) -> void:
	var n: int = clampi(int(j.stats.n("projeteis")), 1, Bal.PROJETEIS_TETO)
	var espalhamento: float = minf(0.6, 0.06 * float(n)) if n > 1 else 0.0
	var centro_b: Vector2 = j.arena.centro
	var base := (alvo.pos - centro_b).angle()
	var alcance: float = j.stats.n("alcance")

	# O segundo alvo vem pronto de `atualizar`: uma varredura por quadro, nao uma
	# por tiro. Se nao houver um segundo inimigo, os extras acompanham o primeiro.
	var alvo_extra: Inimigo = segundo if segundo != null else alvo

	for i in n:
		var t := 0.0 if n == 1 else (float(i) / float(n - 1) - 0.5) * 2.0
		var ang := base + t * espalhamento
		_criar_projetil(ang, alvo if i == 0 else alvo_extra, forca)

	# passiva Eco Balístico: chance de repetir a salva
	if j.pas.has("eco"):
		var chance: float = float(j.pas.get("eco:valor", 0.12)) * float(j.pas["eco"])
		if j.rng.chance(minf(0.6, chance)):
			_criar_projetil(base, alvo, forca)

	recuo = 1.0
	j.s["stats"]["tiros"] = int(j.s["stats"]["tiros"]) + 1
	Bus.torre_atirou.emit(angulo_canhao, n)

	# Coro de Estilhaços: "a cada 5º disparo, a torre solta uma salva circular
	# de 12 projéteis; cada nível reduz o intervalo em 1 tiro". A relíquia
	# existia, o texto prometia e nada acontecia.
	if j.pas.has("salva_coral"):
		tiros_para_salva += 1
		var intervalo := maxi(2, 5 - (int(j.pas["salva_coral"]) - 1))
		if tiros_para_salva >= intervalo:
			tiros_para_salva = 0
			var quantos := int(j.pas.get("salva_coral:valor", 12.0))
			for i in quantos:
				_criar_projetil(TAU * float(i) / float(quantos), alvo, forca)
			Bus.particulas.emit("pulso", centro_b, {"raio": 110.0, "cor": "#fcd34d"})

func _criar_projetil(ang: float, alvo: Inimigo, forca: float = 1.0) -> void:
	var p: Projetil = j.arena.novo_projetil()
	# `danoTorre` é o dano QUE A TORRE CAUSA — "cada tiro causa 5× de dano",
	# "Dano ×20" — e estava sendo aplicado no dano que ela RECEBE. O desafio
	# Ferrugem, anunciado e pintado de verde como bônus, multiplicava por cinco
	# o dano que o jogador levava. Sinal invertido no lugar mais caro possível.
	var dano_base := Big.mul_f(Big.mul_f(Big.mul_f(j.stats.b("dano"), j.stats.n("multiplicador")),
		float(j.mods_dif.get("danoTorre", 1.0))), forca)
	var golpe := Combate.rolar_golpe(dano_base, j, alvo)

	p.ativo = true
	var centro_p: Vector2 = j.arena.centro
	p.pos = centro_p + Vector2(cos(ang), sin(ang)) * (Bal.RAIO_TORRE - 4.0)
	p.velocidade = j.stats.n("velProjetil")
	p.vel = Vector2(cos(ang), sin(ang)) * p.velocidade
	p.ang = ang
	p.dano = golpe[0]
	p.critico = golpe[1]
	p.alvo = alvo
	p.perfuracao = int(j.stats.n("perfuracao"))
	p.ricochete = int(j.stats.n("ricochete"))
	p.area = j.stats.n("area")
	p.raio = 6.0 if p.critico else 4.0
	# VIDA DO PROJETIL PROPORCIONAL A TRAVESSIA, nao um numero fixo.
	#
	# Eram 3,5 s para todo mundo. Com velocidade alta (a melhoria da +26 px/s
	# por nivel) o projetil cruza a arena inteira em menos de dois segundos e
	# passa o resto do tempo vivo sem poder acertar nada — mas continua sendo
	# testado contra a grade a cada quadro. Medido: o pool de 800 ficava
	# saturado com ~500 projeteis vivos e a colisao sozinha custava 2,9 ms por
	# passo. Um projetil que nao acertou em uma travessia e meia nao vai acertar.
	p.vida = Bal.vida_projetil(p.velocidade)
	p.origem = "torre"
	p.elemento = _sortear_elemento()
	if p.elemento != "":
		p.cor = Color.html(str(Bal.ELEMENTOS[p.elemento]["cor"]))
	else:
		p.cor = Color.html("#fde047") if p.critico else Color.html("#7dd3fc")
	p.tipo = "morteiro" if p.area > 0.0 else "bala"

func _sortear_elemento() -> String:
	var versao: int = j.stats.recalculos
	if versao != _pesos_versao:
		_pesos_versao = versao
		_pesos_elem = []
		_pesos_total = 0.0
		for chave in CHAVES_ELEMENTO.keys():
			var v: float = j.stats.n(str(CHAVES_ELEMENTO[chave]))
			if v > 0.0:
				_pesos_elem.append([chave, v])
				_pesos_total += v
	if _pesos_elem.is_empty():
		return ""
	if not j.rng.chance(minf(0.95, _pesos_total)):
		return ""
	var r: float = float(j.rng.f()) * _pesos_total
	for par in _pesos_elem:
		r -= float(par[1])
		if r <= 0.0:
			return str(par[0])
	return str(_pesos_elem[0][0])

## ---------------------------------------------------------- projéteis

## O laço mais quente do jogo: até 800 projéteis, 60 vezes por segundo.
##
## Em GDScript o que pesa aqui não é a conta, é a CHAMADA — cada `arena.x.y()`
## paga busca de propriedade mais despacho de método. A versão anterior fazia
## seis dessas por projétil por quadro (`j.arena` quatro vezes, `fora_da_arena`,
## `vivo()`, `ang_lerp`, `_colisao`) e um `distance_to` com raiz quadrada. A
## 800 projéteis isso é meio milhão de chamadas por segundo só de cerimônia.
##
## Tudo que dava foi içado para fora do laço ou escrito inline. As contas são
## as mesmas — a comparação de distância virou quadrado contra quadrado, que é
## a mesma desigualdade sem a raiz. O jogo não mudou; só parou de pagar pedágio.
func atualizar_projeteis(dt: float) -> void:
	_atualizar_opt_impacto()
	var arena = j.arena
	var lista: Array = arena.projeteis
	var centro: Vector2 = arena.centro
	var cx := centro.x
	var cy := centro.y
	var raio_torre2 := Bal.RAIO_TORRE * Bal.RAIO_TORRE
	# `fora_da_arena` inline: os limites não mudam durante o quadro.
	var margem := 140.0
	var lim_x0 := -margem
	var lim_y0 := -margem
	var lim_x1: float = arena.largura + margem
	var lim_y1: float = arena.altura + margem
	var t_lerp := minf(1.0, dt * 12.0)
	for i in range(lista.size() - 1, -1, -1):
		var p: Projetil = lista[i]
		if not p.ativo:
			arena.soltar_projetil(i)
			continue
		p.t += dt
		p.vida -= dt
		if p.vida <= 0.0:
			arena.soltar_projetil(i)
			continue

		if p.origem == "inimigo":
			p.pos += p.vel * dt
			var idx := p.pos.x - cx
			var idy := p.pos.y - cy
			if idx * idx + idy * idy < raio_torre2:
				j.dano_na_torre(p.dano_torre, null, {"projetil": true})
				arena.soltar_projetil(i)
			elif p.pos.x < lim_x0 or p.pos.y < lim_y0 or p.pos.x > lim_x1 or p.pos.y > lim_y1:
				arena.soltar_projetil(i)
			continue

		var alvo := p.alvo
		# `alvo.vivo()` inline: é `ativo and morrendo <= 0.0`.
		if alvo != null and alvo.ativo and alvo.morrendo <= 0.0 and alvo.intangivel <= 0.0:
			var ang := (alvo.pos - p.pos).angle()
			# `Ux.ang_lerp` inline: leva o ângulo pelo caminho curto.
			var d := fposmod(ang - p.ang + PI, TAU) - PI
			var na := p.ang + d * t_lerp
			p.ang = na
			p.vel = Vector2(cos(na), sin(na)) * p.velocidade
		p.pos += p.vel * dt

		if p.pos.x < lim_x0 or p.pos.y < lim_y0 or p.pos.x > lim_x1 or p.pos.y > lim_y1:
			arena.soltar_projetil(i)
			continue

		var atingido: Inimigo = arena.primeiro_colidindo(p.pos, p.raio, p.atingidos)
		if atingido != null:
			if _impacto(p, atingido):
				arena.soltar_projetil(i)

## Reusado a cada impacto. Tres dos cinco campos sao ATRIBUTOS DA TORRE: eles
## nao mudam dentro do quadro, e montar um Dicionario novo por impacto — com 53
## impactos por passo na perna cheia — e alocacao pura. Os dois campos que
## variam por projetil sao escritos antes de cada uso.
var _opt_impacto := {"crit": false, "penetracao": 0.0, "execucao": 0.0,
	"roubodeVida": 0.0, "elemento": ""}

func _atualizar_opt_impacto() -> void:
	_opt_impacto["penetracao"] = j.stats.n("penetracao")
	_opt_impacto["execucao"] = j.stats.n("execucao")
	_opt_impacto["roubodeVida"] = j.stats.n("roubodeVida")

func _impacto(p: Projetil, alvo: Inimigo) -> bool:
	var opt := _opt_impacto
	opt["crit"] = p.critico
	opt["elemento"] = p.elemento

	# O Guardiao do Espelho declara `"mecanica": "refletir"`, e so o refletor
	# comum declara `"hab"`. O codigo olhava so `hab`, entao o chefe cujo nome e
	# a mecanica nunca refletiu nada — e o codex explicava o reflexo dele.
	if (alvo.hab == "refletir" or str(alvo.def.get("mecanica", "")) == "refletir") and not p.critico:
		j.dano_na_torre(Bal.dano_refletido(p.dano, j.s["torre"]["vida_max"]), alvo, {"reflexo": true})
	if bool(alvo.def.get("invisivel", false)):
		alvo.revelado = true

	Combate.aplicar_dano(alvo, p.dano, j, opt)
	if p.elemento != "":
		Combate.aplicar_elemento(alvo, p.elemento, p.dano, j)

	# O MORTEIRO EXPLODE UMA VEZ, nao uma por corpo atravessado.
	#
	# `area` e `perfuracao` se multiplicavam: um projetil com estilhaco e doze
	# perfuracoes soltava DOZE explosoes, cada uma varrendo ~20 inimigos.
	# Medido na perna de 160 vivos segurados: 48 impactos por passo, 962
	# chamadas de `aplicar_dano` por passo, 10 ms so em `_impacto` — sozinho,
	# duas vezes e meia o orcamento do quadro inteiro. Fisicamente tambem nao
	# fazia sentido: uma carga explode, ela nao explode de novo no proximo osso.
	if p.area > 0.0 and not p.explodiu:
		p.explodiu = true
		Combate.dano_area(p.pos, p.area, Big.mul_f(p.dano, 0.6), j, {
			"crit": p.critico, "penetracao": opt["penetracao"], "queda": true, "ignorar": [alvo],
		})
		Bus.particulas.emit("explosao", p.pos, {"raio": p.area, "cor": p.cor})
	else:
		Bus.particulas.emit("impacto", p.pos, {"ang": p.ang, "cor": p.cor, "crit": p.critico})

	p.atingidos[alvo.id] = true

	if p.perfuracao > 0:
		p.perfuracao -= 1
		p.dano = Big.mul_f(p.dano, 0.82)
		p.alvo = j.arena.alvo_ids(p.pos, 400.0, p.atingidos)
		return false
	if p.ricochete > 0:
		var prox: Inimigo = j.arena.alvo_ids(p.pos, 240.0, p.atingidos)
		if prox != null:
			p.ricochete -= 1
			p.dano = Big.mul_f(p.dano, 0.75)
			p.alvo = prox
			p.ang = (prox.pos - p.pos).angle()
			p.vel = Vector2(cos(p.ang), sin(p.ang)) * p.velocidade
			p.vida = maxf(p.vida, 1.2)
			return false
	return true

## --------------------------------------------------------------- orbes

func atualizar_orbes(dt: float) -> void:
	var n: int = mini(int(j.stats.n("orbes")) + orbes_extra, Bal.ORBES_TETO)
	var centro_o: Vector2 = j.arena.centro
	if orbes.size() != n:
		orbes.clear()
		for i in n:
			orbes.append({
				"ang": (float(i) / maxf(1.0, float(n))) * TAU,
				"raio": 78.0 + float(i % 3) * 22.0,
				"cd": float(j.rng.entre(0.0, 0.6)),
				"pos": centro_o,
			})
	if n == 0:
		return
	var vel_orb := 1.6 * float(j.stats.n("velOrbe"))
	var dano_orb := Big.mul_f(j.stats.b("dano"), 0.45 * float(j.stats.n("danoOrbe")) * float(j.stats.n("multiplicador")))

	for o in orbes:
		o["ang"] = float(o["ang"]) + vel_orb * dt
		o["pos"] = centro_o + Vector2(cos(float(o["ang"])), sin(float(o["ang"]))) * float(o["raio"])
		o["cd"] = float(o["cd"]) - dt
		if float(o["cd"]) <= 0.0:
			var op: Vector2 = o["pos"]
			# Pela grade, não pela lista inteira: o orbe só alcança 150px.
			var alvo: Inimigo = j.arena.alvo_no_raio(op, 150.0)
			if alvo == null:
				# Sem ninguém ao alcance, espera um pouco antes de procurar de
				# novo. Antes o relógio não era reiniciado, então cada orbe
				# procurava a cada quadro, para sempre, sem achar nada.
				o["cd"] = 0.08
			else:
				o["cd"] = 0.75
				var golpe := Combate.rolar_golpe(dano_orb, j, alvo)
				Combate.aplicar_dano(alvo, golpe[0], j, {"crit": golpe[1], "penetracao": j.stats.n("penetracao")})
				Bus.particulas.emit("feixe", op, {"para": alvo.pos, "cor": "#a78bfa"})

## -------------------------------------------------------------- defesa

## `dano_log` está em log10, como todo valor grande do jogo.
func levar_dano(dano_log: float, fonte, opt: Dictionary = {}) -> float:
	var s: Dictionary = j.s
	var torre: Dictionary = s["torre"]
	if not bool(torre["viva"]):
		return Big.ZERO
	if iframes > 0.0 and not bool(opt.get("ignora_iframes", false)):
		return Big.ZERO

	var armadura: float = j.stats.n("armadura")
	var dano := Big.mul_f(dano_log, Bal.ARMADURA_K / (Bal.ARMADURA_K + armadura))

	if not Big.is_zero(torre["escudo"]):
		var esc: float = torre["escudo"]
		if Big.gte(esc, dano):
			torre["escudo"] = Big.sub(esc, dano)
			iframes = 0.0 if bool(opt.get("drenar", false)) else Bal.IFRAMES
			tempo_sem_dano = 0.0
			Bus.torre_atingida.emit(dano, torre["vida"], torre["vida_max"])
			return dano
		dano = Big.sub(dano, esc)
		torre["escudo"] = Big.ZERO
		if j.pas.has("escudo_explosivo"):
			var centro_x: Vector2 = j.arena.centro
			Combate.dano_area(centro_x, 200.0, Big.mul_f(j.stats.b("dano"), 20.0 * float(j.pas["escudo_explosivo"])), j, {"crit": true})
			Bus.particulas.emit("explosao", centro_x, {"raio": 200.0, "cor": "#60a5fa"})

	if not Big.is_zero(dano):
		torre["vida"] = Big.sub(torre["vida"], dano)
		iframes = 0.0 if bool(opt.get("drenar", false)) else Bal.IFRAMES
		tempo_sem_dano = 0.0

	Bus.torre_atingida.emit(dano, torre["vida"], torre["vida_max"])

	if Big.is_zero(torre["vida"]):
		if j.pas.has("fenix") and not j.fenix_usada:
			j.fenix_usada = true
			torre["vida"] = Big.mul_f(torre["vida_max"], 0.4)
			iframes = 2.0
			Bus.celebracao.emit("fenix", {})
			Bus.toast(Txt.t("sim_fenix"), "epico")
			return dano
		# Vela do Segundo Fôlego: "+1 renascimento extra por onda (revive com
		# 50% da vida)". O especial `revivesExtra` existia no JSON, aparecia no
		# painel de Relíquias e não tinha um único leitor na simulação.
		var extras := int(j.esp.get("revives", 0.0))
		if extras > 0 and j.revives_usados < extras:
			j.revives_usados += 1
			torre["vida"] = Big.mul_f(torre["vida_max"], 0.5)
			iframes = 2.0
			Bus.celebracao.emit("fenix", {})
			Bus.toast(Txt.f("sim_revive_extra", {"n": extras - j.revives_usados}), "epico")
			return dano
		torre["vida"] = Big.ZERO
		torre["viva"] = false
		torre["tempo_morta"] = Bal.RESPAWN
		s["stats"]["mortes"] = int(s["stats"]["mortes"]) + 1
		Bus.torre_caiu.emit()
		# A torre cair era o evento mais importante do jogo e não gerava uma
		# única palavra: tela treme, som toca, e o jogador fica sem saber que
		# perdeu uma onda nem quanto tempo vai ficar sem atirar.
		Bus.toast(Txt.f("sim_torre_caiu", {
			"n": Bal.PENALIDADE_MORTE,
			"s": int(ceil(Bal.RESPAWN)),
		}), "ruim", "coracao")
	return dano
