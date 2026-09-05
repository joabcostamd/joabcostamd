extends SceneTree

var falhas := 0

func c(naipe: int, v: String) -> int:
	var ordem := ["A","2","3","4","5","6","7","8","9","10","J","Q","K"]
	return naipe * 13 + ordem.find(v)

func ok(nome: String, got, esp) -> void:
	if got != esp:
		falhas += 1
		print("FALHA ", nome, " got=", got, " esperado=", esp)
	else:
		print("ok   ", nome, " = ", got)

func _initialize() -> void:
	Nucleo.init_estatico()
	const H := 0
	const O := 1
	const P := 2
	const E := 3
	# --- fichas
	ok("fichas As", Nucleo.fichas_carta(c(H,"A")), 11)
	ok("fichas 9", Nucleo.fichas_carta(c(H,"9")), 9)
	ok("fichas K", Nucleo.fichas_carta(c(H,"K")), 10)
	ok("fichas 10", Nucleo.fichas_carta(c(H,"10")), 10)
	# --- categorias
	ok("A2345 = SEQUENCIA", Nucleo.avaliar5(c(H,"A"),c(O,"2"),c(P,"3"),c(E,"4"),c(H,"5"))[0], Nucleo.SEQUENCIA)
	ok("A2345 fichas = 11+2+3+4+5", Nucleo.avaliar5(c(H,"A"),c(O,"2"),c(P,"3"),c(E,"4"),c(H,"5"))[1], 25)
	ok("10JQKA misto = SEQUENCIA", Nucleo.avaliar5(c(H,"10"),c(O,"J"),c(P,"Q"),c(E,"K"),c(H,"A"))[0], Nucleo.SEQUENCIA)
	ok("10JQKA mesmo naipe = REAL", Nucleo.avaliar5(c(H,"10"),c(H,"J"),c(H,"Q"),c(H,"K"),c(H,"A"))[0], Nucleo.REAL)
	ok("QKA23 NAO e sequencia", Nucleo.avaliar5(c(H,"Q"),c(O,"K"),c(P,"A"),c(E,"2"),c(H,"3"))[0], Nucleo.ALTA)
	ok("67890 mesmo naipe = SEQ_COR", Nucleo.avaliar5(c(H,"6"),c(H,"7"),c(H,"8"),c(H,"9"),c(H,"10"))[0], Nucleo.SEQ_COR)
	ok("QQQ99 = FULL", Nucleo.avaliar5(c(H,"Q"),c(O,"Q"),c(P,"Q"),c(E,"9"),c(H,"9"))[0], Nucleo.FULL)
	ok("QQQ99 fichas", Nucleo.avaliar5(c(H,"Q"),c(O,"Q"),c(P,"Q"),c(E,"9"),c(H,"9"))[1], 48)
	ok("QQ99K = 2PAR", Nucleo.avaliar5(c(H,"Q"),c(O,"Q"),c(P,"9"),c(E,"9"),c(H,"K"))[0], Nucleo.DOIS_PARES)
	ok("7777K = QUADRA", Nucleo.avaliar5(c(H,"7"),c(O,"7"),c(P,"7"),c(E,"7"),c(H,"K"))[0], Nucleo.QUADRA)
	ok("flush ignora valor", Nucleo.avaliar5(c(P,"2"),c(P,"5"),c(P,"9"),c(P,"J"),c(P,"K"))[0], Nucleo.FLUSH)
	ok("lixo = ALTA", Nucleo.avaliar5(c(H,"2"),c(O,"5"),c(P,"9"),c(E,"J"),c(H,"K"))[0], Nucleo.ALTA)
	# --- parcial (R14b)
	ok("parcial QQ9 = PAR", Nucleo.avaliar_parcial([c(H,"Q"),c(O,"Q"),c(P,"9")])[0], Nucleo.PAR)
	ok("parcial 3 copas NAO e flush", Nucleo.avaliar_parcial([c(H,"2"),c(H,"7"),c(H,"K")])[0], Nucleo.ALTA)
	ok("parcial QQQ = TRINCA", Nucleo.avaliar_parcial([c(H,"Q"),c(O,"Q"),c(P,"Q")])[0], Nucleo.TRINCA)

	# --- §4.4: matematica do turno 16 (sem o Ima; monto as cartas ja convertidas)
	# LINHA 3 = Q,Q,9,Q,9 -> FULL, fichas base 40, fichas cartas 48, mult 4
	var l3 := Nucleo.avaliar5(c(H,"Q"),c(E,"Q"),c(O,"9"),c(O,"Q"),c(E,"9"))
	ok("§4.4 linha3 cat", l3[0], Nucleo.FULL)
	ok("§4.4 linha3 fichas cartas", l3[1], 48)
	# COLUNA C = 10h,7h,9h,6h,8h -> SEQ_COR fichas base 100, cartas 40, mult 8
	var cc := Nucleo.avaliar5(c(H,"10"),c(H,"7"),c(H,"9"),c(H,"6"),c(H,"8"))
	ok("§4.4 colunaC cat", cc[0], Nucleo.SEQ_COR)
	ok("§4.4 colunaC fichas cartas", cc[1], 40)
	var fichas := (40 + 48) + (100 + 40)
	var teto := 24 + 4 * 4
	var mult: int = min(teto, 4 + 8 + 1)
	ok("§4.4 fichas da cruzada", fichas, 228)
	ok("§4.4 mult da cruzada", mult, 13)
	ok("§4.4 pontos da cruzada", fichas * mult, 2964)
	ok("§4.4 total", 1180 + fichas * mult, 4144)

	# --- §6.2 prova do teto da rodada 6
	var fichas_full := (40 + 3 * 14) + 48
	var fichas_sc := (100 + 2 * 35) + 40
	ok("§6.2 fichas full nivel 3", fichas_full, 130)
	ok("§6.2 fichas seqcor nivel 2", fichas_sc, 210)
	ok("§6.2 cruzada tear 4", (fichas_full + fichas_sc) * min(48, 7 + 10 + 4), 7140)

	# --- geometria R03b
	ok("C3 pertence a 4 linhas", Nucleo.CELL_LINHAS[12].size(), 4)
	ok("A1 pertence a 3 linhas", Nucleo.CELL_LINHAS[0].size(), 3)
	ok("B1 pertence a 2 linhas", Nucleo.CELL_LINHAS[1].size(), 2)
	var n3 := 0
	var n2 := 0
	var n4 := 0
	for i in range(25):
		match Nucleo.CELL_LINHAS[i].size():
			2: n2 += 1
			3: n3 += 1
			4: n4 += 1
	ok("16 casas com 2 linhas", n2, 16)
	ok("8 casas com 3 linhas", n3, 8)
	ok("1 casa com 4 linhas", n4, 1)

	# --- metas R21
	var erro := 0
	var esperado := [[450,639,907,1288,1830,2598],[675,959,1361,1932,2745,3897],[1035,1470,2086,2962,4209,5975]]
	for n in range(1, 7):
		var peq := int(round(450.0 * pow(1.42, n - 1)))
		var gra := int(round(peq * 1.50))
		var che := int(round(peq * 2.30))
		if peq != esperado[0][n-1]: erro += 1; print("  divergencia pequena r", n, " formula=", peq, " tabela=", esperado[0][n-1])
		if gra != esperado[1][n-1]: erro += 1; print("  divergencia grande r", n, " formula=", gra, " tabela=", esperado[1][n-1])
		if che != esperado[2][n-1]: erro += 1; print("  divergencia chefe r", n, " formula=", che, " tabela=", esperado[2][n-1])
	ok("R21 formula bate com a tabela §6.2", erro, 0)

	# --- determinismo
	var a := Mesa.new(3, 1, 12345, [])
	var b := Mesa.new(3, 1, 12345, [])
	ok("determinismo grade", str(a.grade), str(b.grade))
	ok("determinismo mao", str(a.mao), str(b.mao))
	var d := Mesa.new(3, 1, 12346, [])
	ok("seeds diferentes dao maos diferentes", str(a.mao) != str(d.mao), true)
	# --- R42
	var p := Mesa.new(1, 0, 777, [])
	var n := 0
	for i in range(25):
		if p.grade[i] >= 0: n += 1
	ok("R42 pequena nasce com 3 semeadas", n, 3)
	var gr := Mesa.new(1, 1, 777, [])
	var n2b := 0
	for i in range(25):
		if gr.grade[i] >= 0: n2b += 1
	ok("grande nasce vazia", n2b, 0)
	# --- conservacao das pilhas
	ok("conservacao inicial pequena", p.mao.size() + n + p.colhida.size() + p.baralho.size() + p.descarte.size(), 52)

	print("")
	print("FALHAS: ", falhas)
	quit(0 if falhas == 0 else 1)
