extends SceneTree

## Quanto tempo dura o jogo? Mede, nao estima.
##
## O portao de balanceamento (`sim_balance`) NUNCA ascende — o juiz de uma
## auditoria independente pegou isso, e procede: ele mede um jogador que nunca
## toca o sistema central do genero. Esta ferramenta faz o contrario: liga a
## ascensao automatica e roda ate onde mandarem, anotando QUANDO cada camada de
## prestigio e cada marco de conteudo acontece pela primeira vez.
##
##   godot --headless --path . -s res://tools/duracao.gd -- <horas>

const DT := 1.0 / 60.0
const SEMENTE := 20260903

func _initialize() -> void:
	var corpo = load("res://tools/suites/duracao_corpo.gd").new()
	corpo.arvore = self
	corpo.root = root
	corpo.executar()
	quit()
