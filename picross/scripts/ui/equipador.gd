extends Node
class_name EquipadorDeBotoes
## Equipa com juice todo botão que aparecer nesta tela, inclusive os criados
## depois — os de uma sobreposição de pausa, por exemplo.
##
## Isto é um nó, e não uma conexão solta, de propósito: quando a tela é
## liberada este nó vai junto e a conexão se desfaz sozinha. Uma lambda
## ligada ao sinal continuaria viva e apontando para uma tela destruída.

var raiz: Control

func _ready() -> void:
    if raiz == null:
        raiz = get_parent() as Control
    get_tree().node_added.connect(_ao_entrar)

func _ao_entrar(no: Node) -> void:
    if raiz != null and no is BaseButton and raiz.is_ancestor_of(no):
        Juice.equipar(no as BaseButton)
