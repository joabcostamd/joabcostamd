class_name Editos
extends RefCounted

## OS ÉDITOS — a física do jogo muda com você.
##
## As Cepas resolvem "o que vem contra mim". Isto resolve a outra metade: "com
## que regras eu jogo". Uma Ascensão deixava o jogo idêntico ao de antes, só mais
## rápido — a única coisa que mudava era a velocidade. Depois de dez ascensões a
## pessoa não estava aprendendo nada, estava repetindo.
##
## Um Édito é uma lei: uma DÁDIVA e um ÔNUS, sempre os dois. "A torre atira um
## terço das vezes, e cada tiro pesa três vezes mais." Nenhum é bônus puro, e é
## isso que impede o acúmulo de virar escada de poder: seis Éditos ativos são
## seis trocas, e a build que funcionava na ascensão passada pode não sobreviver
## à lei que você acabou de aceitar.
##
## O jogo escolhe três, você escolhe uma. Elas ficam até a próxima Singularidade.
##
## POR QUE NÃO USA O VOCABULÁRIO NOVO. Dádiva e ônus são arrays de
## `{stat, tipo, valor}` — exatamente o que melhorias, talentos, cartas e nós de
## prestígio já usam, lidos pelo mesmo `Mods.aplicar_efeitos`. E `mods` é o mesmo
## Dicionário que os desafios entregam a `mods_dif`. Nada aqui inventa formato:
## uma lei nova é uma linha de JSON, e o motor já sabe lê-la.

## Quantos Éditos cabem ao mesmo tempo. Cheio, o jogo para de oferecer até a
## Singularidade seguinte — o conjunto vira o seu, e não uma lista que só cresce.
const TETO := 6
## Quantas leis o jogo põe na mesa a cada Ascensão.
const OFERTA := 3
## A partir de qual Ascensão as leis começam a aparecer. Antes disso a pessoa
## ainda está aprendendo o jogo normal, e mudar a física seria ruído.
const ASCENSAO_MINIMA := 3

static func estado_padrao() -> Dictionary:
	return {"ativos": [], "oferta": [], "vistos": 0}

static func _estado(s: Dictionary) -> Dictionary:
	var e = s.get("editos", null)
	if not (e is Dictionary):
		e = estado_padrao()
		s["editos"] = e
	return e

static func ativos(s: Dictionary) -> Array:
	var lista: Array = []
	for id in _estado(s).get("ativos", []):
		var d: Dictionary = Dados.edito_por_id.get(str(id), {})
		if not d.is_empty():
			lista.append(d)
	return lista

static func oferta(s: Dictionary) -> Array:
	var lista: Array = []
	for id in _estado(s).get("oferta", []):
		var d: Dictionary = Dados.edito_por_id.get(str(id), {})
		if not d.is_empty():
			lista.append(d)
	return lista

static func tem_oferta(s: Dictionary) -> bool:
	return not _estado(s).get("oferta", []).is_empty()

static func cheio(s: Dictionary) -> bool:
	return _estado(s).get("ativos", []).size() >= TETO

## Põe três leis na mesa. Chamado quando a Ascensão acontece.
##
## Nunca oferece uma lei já ativa, nem duas do mesmo eixo na mesma mesa: três
## variações de cadência não são uma escolha, são a mesma escolha três vezes.
static func gerar_oferta(s: Dictionary, rng) -> bool:
	var e := _estado(s)
	if cheio(s) or int(s["prestigio"]["ascensoes"]) < ASCENSAO_MINIMA:
		return false
	if not e.get("oferta", []).is_empty():
		return false
	var ja: Dictionary = {}
	for id in e["ativos"]:
		ja[str(id)] = true
	var pool: Array = []
	for d in Dados.editos:
		if d is Dictionary and not ja.has(str(d.get("id", ""))):
			pool.append(d)
	if pool.is_empty():
		return false
	var eixos: Dictionary = {}
	var escolhidos: Array = []
	var tentativas := 0
	while escolhidos.size() < OFERTA and tentativas < 200 and not pool.is_empty():
		tentativas += 1
		var i: int = rng.inteiro(0, pool.size() - 1)
		var d: Dictionary = pool[i]
		var eixo := str(d.get("eixo", ""))
		if eixos.has(eixo):
			continue
		eixos[eixo] = true
		escolhidos.append(str(d.get("id", "")))
		pool.remove_at(i)
	e["oferta"] = escolhidos
	return not escolhidos.is_empty()

## Aceita uma das leis da mesa. Devolve `false` para qualquer id que não esteja
## sendo oferecido AGORA — sem isso, quem editasse o save escolheria as seis
## dádivas e nenhum ônus.
static func aceitar(s: Dictionary, id: String) -> bool:
	var e := _estado(s)
	if not e.get("oferta", []).has(id):
		return false
	if cheio(s):
		e["oferta"] = []
		return false
	e["ativos"].append(id)
	e["oferta"] = []
	e["vistos"] = int(e.get("vistos", 0)) + 1
	return true

## Recusa a mesa inteira. A pessoa pode não querer nenhuma das três — jogar sem
## lei nova É uma jogada, e negar essa saída transformaria a escolha em imposto.
static func recusar(s: Dictionary) -> void:
	_estado(s)["oferta"] = []

## A Singularidade devolve o jogo às regras de fábrica.
static func limpar(s: Dictionary) -> void:
	var e := _estado(s)
	e["ativos"] = []
	e["oferta"] = []

## Os modificadores de mundo somados, para entrar em `mods_dif`.
static func mods(s: Dictionary) -> Dictionary:
	var fora := {}
	for d in ativos(s):
		var m = (d as Dictionary).get("mods", {})
		if not (m is Dictionary):
			continue
		for k in (m as Dictionary).keys():
			var chave := str(k)
			fora[chave] = float(fora.get(chave, 1.0)) * float((m as Dictionary)[k])
	return fora
