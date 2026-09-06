extends Mini


func rodar() -> void:
	igual(Pontuacao.pontos_da_jogada(100, 0), 100, "sem combo vale a base")
	igual(Pontuacao.pontos_da_jogada(100, 2), 300, "combo 2 triplica")
	igual(Pontuacao.pontos_da_jogada(0, 5), 0, "base zero nao pontua")
	igual(Pontuacao.pontos_da_jogada(-10, 5), 0, "base negativa nao pontua")
	igual(Pontuacao.pontos_da_jogada(5000, 9), 9999, "teto respeitado")
	igual(Pontuacao.pontos_da_jogada(100, -3), 100, "combo negativo trata como zero")

	igual(Pontuacao.proximo_combo(0, true), 1, "acerto sobe o combo")
	igual(Pontuacao.proximo_combo(7, false), 0, "erro zera o combo")

	igual(Pontuacao.estrelas(100, 100), 3, "alvo batido = 3 estrelas")
	igual(Pontuacao.estrelas(70, 100), 2, "70% = 2 estrelas")
	igual(Pontuacao.estrelas(40, 100), 1, "40% = 1 estrela")
	igual(Pontuacao.estrelas(10, 100), 0, "10% = nenhuma")
	igual(Pontuacao.estrelas(10, 0), 0, "alvo zero nao divide por zero")
