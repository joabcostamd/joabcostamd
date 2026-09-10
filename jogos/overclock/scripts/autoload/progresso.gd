extends Node
## Progresso do jogador: carrega, salva e avisa quem escuta.

signal mudou

const CAMINHO := "user://save.json"

var dados: Dictionary = Save.vazio()


func _ready() -> void:
	carregar()


func carregar() -> void:
	if not FileAccess.file_exists(CAMINHO):
		dados = Save.vazio()
		return
	var f := FileAccess.open(CAMINHO, FileAccess.READ)
	if f == null:
		dados = Save.vazio()
		return
	var lido = JSON.parse_string(f.get_as_text())
	f.close()
	dados = Save.migrar(lido) if lido is Dictionary else Save.vazio()


func salvar() -> void:
	var f := FileAccess.open(CAMINHO, FileAccess.WRITE)
	if f == null:
		push_warning("nao consegui gravar o save em %s" % CAMINHO)
		return
	f.store_string(JSON.stringify(dados, "  "))
	f.close()


func registrar_resultado(fase: int, pontos: int) -> void:
	var chave := str(fase)
	var melhores: Dictionary = dados.get("melhores", {})
	melhores[chave] = maxi(int(melhores.get(chave, 0)), pontos)
	dados["melhores"] = melhores
	dados["fase_atual"] = maxi(int(dados.get("fase_atual", 1)), fase + 1)
	salvar()
	mudou.emit()
