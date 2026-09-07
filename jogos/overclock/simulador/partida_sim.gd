class_name PartidaSim
extends RefCounted
## Uma partida simulada. Chama EXATAMENTE as mesmas funções que a tela chama —
## se houvesse uma segunda implementação aqui, o número não valeria nada.

static func jogar(politica: Politica, fase: int, rng: RandomNumberGenerator) -> Dictionary:
	var pontos := 0
	var combo := 0
	var acertos := 0
	var chance := politica.chance(fase)

	for _i in Balanceamento.JOGADAS_POR_PARTIDA:
		var acertou := rng.randf() < chance
		if acertou:
			pontos += Pontuacao.pontos_da_jogada(Balanceamento.PONTOS_BASE, combo)
			acertos += 1
		combo = Pontuacao.proximo_combo(combo, acertou)

	var alvo := Balanceamento.alvo_da_fase(fase)
	return {
		"pontos": pontos,
		"acertos": acertos,
		"estrelas": Pontuacao.estrelas(pontos, alvo),
		"alvo": alvo,
	}
