class_name Pontuacao
extends RefCounted
## Regras puras de pontuacao. Sem nó, sem sinal, sem estado global.
## Tudo aqui é `static func` e é o que a suíte de testes mede.

## Pontos de uma jogada: base multiplicada pelo combo, com teto.
static func pontos_da_jogada(base: int, combo: int, teto: int = 9999) -> int:
	if base <= 0:
		return 0
	var multiplicador := 1 + maxi(combo, 0)
	return mini(base * multiplicador, teto)

## Combo sobe a cada acerto e zera no erro.
static func proximo_combo(combo: int, acertou: bool) -> int:
	return maxi(combo, 0) + 1 if acertou else 0

## Estrelas (0 a 3) a partir da razao entre pontos e alvo.
static func estrelas(pontos: int, alvo: int) -> int:
	if alvo <= 0:
		return 0
	var razao := float(pontos) / float(alvo)
	if razao >= 1.0:
		return 3
	if razao >= 0.7:
		return 2
	if razao >= 0.4:
		return 1
	return 0
