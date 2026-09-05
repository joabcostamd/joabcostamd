extends Mini


func rodar() -> void:
	var novo := Save.vazio()
	igual(novo["schema_version"], Save.VERSAO_ATUAL, "save novo ja nasce versionado")
	igual(novo["fase_atual"], 1, "comeca na fase 1")

	var antigo := {"fase_atual": 5}
	var migrado := Save.migrar(antigo)
	igual(migrado["schema_version"], Save.VERSAO_ATUAL, "migracao carimba a versao")
	igual(migrado["fase_atual"], 5, "migracao preserva o progresso")
	certo(migrado.has("opcoes"), "migracao preenche o que faltava")

	var a := Save.vazio()
	a["fase_atual"] = 3
	a["melhores"] = {"1": 500, "2": 100}
	var b := Save.vazio()
	b["fase_atual"] = 2
	b["melhores"] = {"1": 200, "3": 900}
	var m := Save.mesclar(a, b)
	igual(m["fase_atual"], 3, "mescla mantem a fase mais avancada")
	igual(m["melhores"]["1"], 500, "mescla mantem o melhor placar")
	igual(m["melhores"]["3"], 900, "mescla nao perde fase so do outro lado")
