class_name Simulador
extends RefCounted
## Monte Carlo determinístico: mesma semente, mesmo resultado, sempre.
## Orçamento de relógio: a rodada padrão tem que fechar em menos de 15 s.

const PARTIDAS_PADRAO := 2000
const SEMENTE_PADRAO := 20260905


static func rodar(fases: Array, partidas: int = PARTIDAS_PADRAO, semente: int = SEMENTE_PADRAO) -> Dictionary:
	var inicio := Time.get_ticks_msec()
	var linhas: Array = []

	for politica in Politica.todas():
		for fase in fases:
			var rng := RandomNumberGenerator.new()
			# semente derivada: cada combinação é reprodutível sozinha
			rng.seed = hash("%d|%s|%d" % [semente, politica.nome, fase])

			var soma := 0
			var estrelas := [0, 0, 0, 0]
			var melhor := 0
			var pior := 1 << 30

			for _p in partidas:
				var r := PartidaSim.jogar(politica, fase, rng)
				soma += r["pontos"]
				estrelas[r["estrelas"]] += 1
				melhor = maxi(melhor, r["pontos"])
				pior = mini(pior, r["pontos"])

			linhas.append({
				"politica": politica.nome,
				"fase": fase,
				"alvo": Balanceamento.alvo_da_fase(fase),
				"media": int(round(float(soma) / float(partidas))),
				"pior": pior,
				"melhor": melhor,
				"pct_3estrelas": snappedf(100.0 * float(estrelas[3]) / float(partidas), 0.1),
				"pct_0estrelas": snappedf(100.0 * float(estrelas[0]) / float(partidas), 0.1),
			})

	return {
		"partidas_por_linha": partidas,
		"semente": semente,
		"ms": Time.get_ticks_msec() - inicio,
		"linhas": linhas,
		"alertas": _alertas(linhas),
	}


## O que a simulação tem a dizer sem ninguém precisar ler a tabela.
static func _alertas(linhas: Array) -> Array:
	var msgs: Array = []
	for l in linhas:
		if l["politica"] == "bom" and l["pct_3estrelas"] < 30.0:
			msgs.append("fase %d dura demais: nem o jogador bom tira 3 estrelas (%.1f%%)" % [l["fase"], l["pct_3estrelas"]])
		if l["politica"] == "ruim" and l["pct_3estrelas"] > 70.0:
			msgs.append("fase %d fácil demais: o jogador ruim gabarita (%.1f%%)" % [l["fase"], l["pct_3estrelas"]])
		if l["politica"] == "medio" and l["pct_0estrelas"] > 50.0:
			msgs.append("fase %d frustra o jogador médio: %.1f%% sai com zero estrela" % [l["fase"], l["pct_0estrelas"]])
	return msgs


static func relatar(res: Dictionary) -> void:
	print("\n%-8s %5s %8s %8s %8s %8s %8s" % ["politica", "fase", "alvo", "media", "pior", "melhor", "3estr%"])
	for l in res["linhas"]:
		print("%-8s %5d %8d %8d %8d %8d %7.1f%%" % [l["politica"], l["fase"], l["alvo"], l["media"], l["pior"], l["melhor"], l["pct_3estrelas"]])
	if not res["alertas"].is_empty():
		print("\nalertas:")
		for a in res["alertas"]:
			print("  ! %s" % a)
	print("\n===SIMULACAO===")
	print(JSON.stringify(res, "  "))
	print("===FIM-SIMULACAO===")
