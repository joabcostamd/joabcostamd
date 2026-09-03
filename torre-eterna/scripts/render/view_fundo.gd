extends Node2D

## Camada de fundo: céu, chão e névoa da era atual. Parallax suave.

var arte := ArteFundo.new()
var jogo: Node
var parallax := Vector2.ZERO

func _ready() -> void:
	z_index = -100
	jogo = get_node_or_null("/root/Jogo")
	Bus.era_mudou.connect(_ao_mudar_era)

func _ao_mudar_era(_i: int, _e: Dictionary) -> void:
	arte.era_atual = -1

func preparar(tam: Vector2) -> void:
	# A ARENA SEGUE A JANELA, TODO QUADRO, E NAO SO QUANDO ELA MUDA DE TAMANHO.
	#
	# `Main._ao_redimensionar` lia o tamanho da janela no `_ready` e no sinal
	# `size_changed`. So que o autoload `Cfg` aplica a escala da interface no
	# `_ready` DELE, que roda ANTES do `Main._ready`: quando o Main perguntava o
	# tamanho, o viewport ainda nao tinha aceitado o `content_scale_factor`.
	# Resultado com escala 1,25 JA SALVA na configuracao: a arena nascia com
	# 1280x720 enquanto a janela logica era 1024x576, e a torre — o unico ponto
	# fixo da tela, em volta do qual todo o resto e lido — ficava em (640, 360)
	# num mundo cujo centro e (512, 288). Deslocada 128x72 px, ela encostava na
	# fileira de habilidades, o anel da Purga saia cortado pelos botoes, e parte
	# do disco de clique que dispara a Purga caia atras deles.
	#
	# E nao era um susto passageiro: quem mexesse UMA VEZ no controle de escala
	# abria assim em toda sessao seguinte, porque o defeito esta no caminho da
	# configuracao ja salva — abrir com a bandeira `--escala` nao reproduz, o
	# que fez a captura de 1,25 parecer certa.
	#
	# Aqui o tamanho ja e lido a cada quadro para o fundo. Comparar antes de
	# escrever custa duas leituras e fecha o buraco para qualquer ordem de
	# inicializacao futura.
	if jogo != null and (jogo.arena.largura != tam.x or jogo.arena.altura != tam.y):
		jogo.arena.redimensionar(tam.x, tam.y)
	var onda := int(jogo.s.get("onda", 1)) if jogo else 1
	arte.preparar(Dados.era_da_onda(onda), tam)

func _process(delta: float) -> void:
	preparar(get_viewport_rect().size)
	arte.atualizar(delta)
	queue_redraw()

func _draw() -> void:
	var tam := get_viewport_rect().size
	arte.desenhar(self, tam * 0.5 + parallax, _detalhe())

func _detalhe() -> float:
	return [0.3, 0.6, 1.0, 1.0][clampi(int(Cfg.get_v("qualidade", 2)), 0, 3)]
