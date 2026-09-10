class_name Balanceamento
extends RefCounted
## Os números do jogo num lugar só. Mexer aqui e rodar ./simular.sh é o ciclo
## de balanceamento — número sai da simulação, nunca de intuição.

const JOGADAS_POR_PARTIDA := 20
const PONTOS_BASE := 100

## Quanto o jogador precisa somar para as 3 estrelas na fase.
## O passo de 55 saiu de ./simular.sh: com 450 o alvo subia mais rápido que a
## habilidade e nem o jogador bom fechava a fase 10.
static func alvo_da_fase(fase: int) -> int:
	var f := maxi(fase, 1)
	return 1500 + (f - 1) * 55

## Quanto o acerto fica mais difícil conforme a fase sobe (0.0 a 1.0).
static func penalidade_da_fase(fase: int) -> float:
	return clampf(0.02 * float(maxi(fase, 1) - 1), 0.0, 0.35)
