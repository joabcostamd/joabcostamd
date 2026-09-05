extends Control
## Partida. A lógica de pontuação mora em scripts/regras/pontuacao.gd.

@onready var _placar: Label = %Placar
@onready var _acertar: Button = %Acertar
@onready var _errar: Button = %Errar
@onready var _voltar: Button = %Voltar

var _pontos := 0
var _combo := 0


func _ready() -> void:
	_acertar.pressed.connect(_jogada.bind(true))
	_errar.pressed.connect(_jogada.bind(false))
	_voltar.pressed.connect(_encerrar)
	_atualizar()
	_acertar.grab_focus()


func _jogada(acertou: bool) -> void:
	if acertou:
		_pontos += Pontuacao.pontos_da_jogada(100, _combo)
	_combo = Pontuacao.proximo_combo(_combo, acertou)
	_atualizar()


func _atualizar() -> void:
	_placar.text = "%s: %d   %s: x%d" % [tr("PLACAR"), _pontos, tr("COMBO"), _combo]


func _encerrar() -> void:
	Progresso.registrar_resultado(1, _pontos)
	Navegacao.voltar()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("acao_voltar"):
		_encerrar()
