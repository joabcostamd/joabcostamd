extends Mini
## O simulador só vale se for reprodutível e se ordenar as habilidades certo.


func rodar() -> void:
	var a := Simulador.rodar([1, 5], 200, 12345)
	var b := Simulador.rodar([1, 5], 200, 12345)
	igual(JSON.stringify(a["linhas"]), JSON.stringify(b["linhas"]), "mesma semente, mesmo resultado")

	var c := Simulador.rodar([1, 5], 200, 99999)
	certo(JSON.stringify(c["linhas"]) != JSON.stringify(a["linhas"]), "semente diferente, resultado diferente")

	var por_politica := {}
	for l in a["linhas"]:
		if l["fase"] == 1:
			por_politica[l["politica"]] = l["media"]
	certo(por_politica["bom"] > por_politica["medio"], "jogador bom pontua mais que o medio")
	certo(por_politica["medio"] > por_politica["ruim"], "jogador medio pontua mais que o ruim")

	# a fase 10 tem que ser mais dura que a fase 1 para a MESMA habilidade
	var f1 := 0
	var f10 := 0
	for l in Simulador.rodar([1, 10], 200, 777)["linhas"]:
		if l["politica"] == "medio" and l["fase"] == 1:
			f1 = int(l["pct_3estrelas"])
		if l["politica"] == "medio" and l["fase"] == 10:
			f10 = int(l["pct_3estrelas"])
	certo(f10 < f1, "fase 10 e mais dura que a fase 1")

	certo(a["ms"] < 15000, "a rodada de teste cabe no orcamento de relogio")
