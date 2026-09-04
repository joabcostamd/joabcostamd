extends Node

## A COLA ENTRE O JOGO E A STEAM.
##
## `SteamPonte` é estática e não sabe nada de cena; esta é a parte que vive na
## árvore, ouve os sinais que o jogo já emite e traduz para a Steam. Ela existe
## separada por um motivo: o jogo NÃO PODE saber que a Steam existe. Nenhum
## sistema de simulação chama nada daqui — tudo entra por `Bus`, que é o mesmo
## caminho que o áudio e a interface já usam.
##
## Consequência prática: tirar a Steam do jogo é apagar este arquivo do autoload.
## Nada mais muda.
##
## SEM O PLUGIN, ISTO É UM NÓ QUE NÃO FAZ NADA. Ele liga os sinais, descobre que
## não há Steam e volta a dormir — sem erro, sem aviso, sem custo por quadro.

## De quanto em quanto tempo a presença rica é atualizada. A Steam limita a
## frequência de `setRichPresence`, e a onda muda a cada dezenas de segundos:
## mandar a cada quadro seria desperdício e levaria bloqueio.
const PRESENCA_SEG := 20.0

var _t := 0.0
var _ultima_onda := -1
var jogo: Node

func _ready() -> void:
	name = "SteamCola"
	jogo = get_node_or_null("/root/Jogo")
	if not SteamPonte.iniciar():
		# Caso normal em desenvolvimento. Não é erro e não vira aviso na tela:
		# quem exporta para a Steam vê no relatório do build.
		set_process(false)
		return
	Bus.conquista_desbloqueada.connect(_ao_conquistar)
	Bus.prestigio_feito.connect(_ao_prestigio)
	Bus.forma_nova.connect(_ao_forma_nova)
	_talvez_idioma_da_steam()

func _process(dt: float) -> void:
	SteamPonte.passo()
	_t += dt
	if _t < PRESENCA_SEG:
		return
	_t = 0.0
	_atualizar_presenca()
	_enviar_placares()

## A PRIMEIRA IMPRESSÃO É DE GRAÇA. Quem comprou o jogo em russo abre em russo,
## sem mexer em nada. Só vale na PRIMEIRA abertura: depois disso quem manda é a
## escolha da pessoa, mesmo que ela tenha escolhido o mesmo idioma da Steam.
func _talvez_idioma_da_steam() -> void:
	if SaveSys.carregar_config().has("idioma"):
		return
	var cod := SteamPonte.idioma_da_steam()
	if cod != "" and Idiomas.existe(cod):
		Cfg.set_v("idioma", cod)

func _ao_conquistar(id: String) -> void:
	SteamPonte.destravar(str(id))

func _ao_prestigio(_camada: String, _ganho: float) -> void:
	_enviar_placares()

func _ao_forma_nova(_e) -> void:
	# Descoberta de forma nova é rara e vale placar, mas não vale uma chamada de
	# rede por bicho morto: o número vai junto no envio periódico.
	pass

func _atualizar_presenca() -> void:
	if jogo == null or not jogo.iniciado:
		return
	var onda := int(jogo.s.get("onda", 0))
	if onda == _ultima_onda:
		return
	_ultima_onda = onda
	var camada := "transcendencia"
	var p: Dictionary = jogo.s.get("prestigio", {})
	if int(p.get("transcendencias", 0)) == 0:
		camada = "singularidade" if int(p.get("singularidades", 0)) > 0 else "ascensao"
	SteamPonte.presenca(onda, camada)

## O PLACAR MEDE A ONDA MÁXIMA GLOBAL, e não a da partida atual.
##
## A partida atual zera a cada Ascensão — um placar sobre ela mediria quem
## ascendeu por último, e não quem foi mais longe. `onda_maxima_global` é a
## única marca que atravessa os três prestígios.
func _enviar_placares() -> void:
	if jogo == null or not jogo.iniciado:
		return
	var s: Dictionary = jogo.s
	var p: Dictionary = s.get("prestigio", {})
	SteamPonte.enviar_placar("onda_maxima", int(s.get("onda_maxima_global", 0)))
	SteamPonte.enviar_placar("ascensoes", int(p.get("ascensoes", 0)))
	SteamPonte.enviar_placar("transcendencias", int(p.get("transcendencias", 0)))
	if jogo.has_method("formas_vistas"):
		SteamPonte.enviar_placar("formas_vistas", int(jogo.formas_vistas()))
