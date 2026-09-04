class_name Formas
extends RefCounted

## O REGISTRO DE FORMAS VISTAS, EXATO E PEQUENO.
##
## Com as Cepas o jogo passa a ter 58.282 formas nomeadas de inimigo. Guardar as
## que a pessoa ja viu como lista de textos ("grunhido|arisco+blindado") custaria
## perto de 1,5 MB num arquivo que e reescrito a cada 30 s — o save viraria o
## sistema mais caro do jogo por causa de um contador.
##
## Uma forma e sempre a mesma coisa: uma base, mais no maximo uma cepa de cada
## eixo. Isso e um endereco de quatro digitos num espaco fechado, e o espaco
## inteiro cabe num BITSET de 23 x 15 x 13 x 13 = 58.305 bits, ou 7,3 KB — 9,7 KB
## depois do base64. Exato, sem lista, sem teto, sem estimativa.
##
## POR QUE OS IDS FICAM GRAVADOS JUNTO. O endereco depende da posicao do id na
## lista ordenada. Se um dia entrar um inimigo novo ou uma cepa nova, todas as
## posicoes seguintes andam e o registro antigo passaria a apontar para as formas
## erradas — a pessoa veria o contador mudar sozinho e formas que nunca viu
## marcadas como vistas. Gravando as listas de ids que geraram aquele bitset,
## a leitura REMAPEIA endereco por endereco e o registro sobrevive intacto a
## qualquer mudanca no lexico. Custa ~600 bytes e compra corretude permanente.

const EIXOS := ["corpo", "andar", "marca"]

## Listas de ids ordenadas — a ordem alfabetica e o que da endereco estavel
## mesmo que alguem reordene o JSON.
static func _ids_bases() -> PackedStringArray:
	var v := PackedStringArray()
	for d in Dados.inimigos:
		if d is Dictionary:
			v.append(str(d.get("id", "")))
	v.sort()
	return v

static func _ids_eixo(eixo: String) -> PackedStringArray:
	var v := PackedStringArray()
	for c in Dados.cepas_por_eixo.get(eixo, []):
		if c is Dictionary:
			v.append(str(c.get("id", "")))
	v.sort()
	return v

## O endereco de uma forma. Zero, em cada eixo, quer dizer "nenhuma cepa deste
## eixo" — e por isso cada eixo tem tamanho N+1.
## POSICAO POR DICIONARIO, NAO POR VARREDURA.
##
## A primeira versao usava `PackedStringArray.find()`, que e busca linear: com
## 23 bases e 38 cepas, achar o endereco de UMA forma custava ate ~60
## comparacoes de texto. E `endereco` roda a cada morte de inimigo com cepa,
## que numa onda cheia sao dezenas por segundo. O indice e montado uma vez em
## `mapa_atual()` e a busca vira uma consulta.
static func endereco(tipo: String, lista: Array, mapa: Dictionary) -> int:
	var idx_bases: Dictionary = mapa["i_bases"]
	if not idx_bases.has(tipo):
		return -1
	var idx: int = idx_bases[tipo]
	for eixo in EIXOS:
		var ids: PackedStringArray = mapa[eixo]
		var indice: Dictionary = mapa["i_" + eixo]
		var pos := 0
		for c in lista:
			if c is Dictionary and str(c.get("eixo", "")) == eixo:
				pos = int(indice.get(str(c.get("id", "")), -1)) + 1
				break
		idx = idx * (ids.size() + 1) + pos
	return idx

static func mapa_atual() -> Dictionary:
	var m := {"bases": _ids_bases()}
	for eixo in EIXOS:
		m[eixo] = _ids_eixo(eixo)
	for k in m.keys():
		m["i_" + str(k)] = _indice(m[k])
	return m

static func _indice(ids: PackedStringArray) -> Dictionary:
	var d := {}
	for i in ids.size():
		d[ids[i]] = i
	return d

static func total_enderecos(mapa: Dictionary) -> int:
	var bases: PackedStringArray = mapa["bases"]
	var n := bases.size()
	for eixo in EIXOS:
		var ids: PackedStringArray = mapa[eixo]
		n *= ids.size() + 1
	return n

# ---------------------------------------------------------------- bitset

static func novo(mapa: Dictionary) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize((total_enderecos(mapa) + 7) / 8)
	b.fill(0)
	return b

## Marca a forma. Devolve `true` so na PRIMEIRA vez — e esse `true` que vale a
## comemoracao, entao quem chama nao precisa consultar antes de marcar.
static func marcar(bits: PackedByteArray, i: int) -> bool:
	if i < 0:
		return false
	var byte := i >> 3
	if byte < 0 or byte >= bits.size():
		return false
	var m := 1 << (i & 7)
	if (bits[byte] & m) != 0:
		return false
	bits[byte] = bits[byte] | m
	return true

## Quantas formas ja foram vistas. Contagem por tabela de nibble: 16 entradas
## resolvem um byte com dois indices, e a chamada e rara (so quando o painel
## abre ou uma forma nova aparece).
const _NIBBLE := [0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4]

static func contar(bits: PackedByteArray) -> int:
	var n := 0
	for b in bits:
		n += int(_NIBBLE[b & 15]) + int(_NIBBLE[(b >> 4) & 15])
	return n

# ---------------------------------------------------------------- save

static func guardar(bits: PackedByteArray, mapa: Dictionary) -> Dictionary:
	var d := {"bits": Marshalls.raw_to_base64(bits)}
	d["bases"] = Array(mapa["bases"])
	for eixo in EIXOS:
		d[eixo] = Array(mapa[eixo])
	return d

## Le o registro gravado e o traz para o lexico de hoje.
##
## Quando as listas batem, e uma copia. Quando nao batem — porque o jogo ganhou
## um inimigo ou uma cepa desde aquele save — cada endereco antigo e reconstruido
## em nomes e reendereçado no espaco novo. E O(n) sobre os bits acesos, roda uma
## vez ao carregar, e e a diferenca entre um registro que dura para sempre e um
## que mente na primeira atualizacao do jogo.
static func carregar(d, mapa: Dictionary) -> PackedByteArray:
	var novos := novo(mapa)
	if not (d is Dictionary):
		return novos
	var dd: Dictionary = d
	var b64 = dd.get("bits", "")
	if not (b64 is String) or (b64 as String).is_empty():
		return novos
	var velhos := Marshalls.base64_to_raw(b64)
	if velhos.is_empty():
		return novos

	var antigo := {"bases": PackedStringArray(dd.get("bases", []))}
	for eixo in EIXOS:
		antigo[eixo] = PackedStringArray(dd.get(eixo, []))
	for k in antigo.keys():
		antigo["i_" + str(k)] = _indice(antigo[k])

	var igual := true
	for k in ["bases", "corpo", "andar", "marca"]:
		if Array(antigo[k]) != Array(mapa[k]):
			igual = false
			break
	if igual:
		if velhos.size() == novos.size():
			return velhos
		return novos

	# Remapeamento: le cada endereco aceso no espaco antigo, reconstroi os nomes
	# e grava no endereco correspondente do espaco novo.
	var total_antigo := total_enderecos(antigo)
	for i in total_antigo:
		var byte := i >> 3
		if byte >= velhos.size():
			break
		if (velhos[byte] & (1 << (i & 7))) == 0:
			continue
		marcar(novos, _traduzir(i, antigo, mapa))
	return novos

static func _traduzir(i: int, antigo: Dictionary, mapa: Dictionary) -> int:
	var resto := i
	var partes := {}
	for k in range(EIXOS.size() - 1, -1, -1):
		var eixo := str(EIXOS[k])
		var ids: PackedStringArray = antigo[eixo]
		var n := ids.size() + 1
		var pos := resto % n
		resto = resto / n
		partes[eixo] = "" if pos == 0 else ids[pos - 1]
	var bases: PackedStringArray = antigo["bases"]
	if resto < 0 or resto >= bases.size():
		return -1
	var lista: Array = []
	for eixo in EIXOS:
		var id := str(partes.get(eixo, ""))
		if id != "":
			lista.append({"id": id, "eixo": eixo})
	return endereco(bases[resto], lista, mapa)
