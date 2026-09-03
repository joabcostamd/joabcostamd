extends Node

## SaveSys (autoload) — persistência em JSON com versionamento, backup,
## exportação em texto e migrações.

const VERSAO := 1
const CAMINHO := "user://torre_eterna.save"
const CAMINHO_BACKUP := "user://torre_eterna.bak"
const CAMINHO_CONFIG := "user://torre_eterna_config.json"
const ASSINATURA := "TORRE1|"

## Prefixo dos arquivos. As ferramentas de linha de comando (testes, soak,
## simulador) trocam isto para não mexer no save de quem joga: rodar a suíte
## apagava o progresso real e deixava as capturas de tela não determinísticas.
static var prefixo := ""

static func cam() -> String:
	return CAMINHO.replace("torre_eterna.", prefixo + "torre_eterna.")

static func cam_backup() -> String:
	return CAMINHO_BACKUP.replace("torre_eterna.", prefixo + "torre_eterna.")

static func cam_config() -> String:
	return CAMINHO_CONFIG.replace("torre_eterna_", prefixo + "torre_eterna_")

var ultimo_erro := ""

## ---------------------------------------------------------------- disco

func salvar(dados: Dictionary) -> bool:
	var texto := JSON.stringify(dados)
	# backup do save anterior antes de sobrescrever
	if FileAccess.file_exists(cam()):
		var antigo := FileAccess.open(cam(), FileAccess.READ)
		if antigo:
			var conteudo := antigo.get_as_text()
			antigo.close()
			var bak := FileAccess.open(cam_backup(), FileAccess.WRITE)
			if bak:
				bak.store_string(conteudo)
				bak.close()
	var f := FileAccess.open(cam(), FileAccess.WRITE)
	if f == null:
		ultimo_erro = "Não consegui abrir o arquivo de save (erro %d)." % FileAccess.get_open_error()
		push_error(ultimo_erro)
		return false
	f.store_string(texto)
	f.close()
	Bus.jogo_salvo.emit(texto.length())
	return true

func carregar() -> Dictionary:
	var d := _ler(cam())
	if d.is_empty():
		d = _ler(cam_backup())
		if not d.is_empty():
			push_warning("[save] save principal corrompido; backup restaurado.")
	if d.is_empty():
		return {}
	return migrar(d)

func _ler(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		return {}
	var texto := f.get_as_text()
	f.close()
	var r = JSON.parse_string(texto)
	if r is Dictionary:
		return r
	return {}

func existe_save() -> bool:
	return FileAccess.file_exists(cam())

func apagar() -> void:
	for c in [cam(), cam_backup()]:
		if FileAccess.file_exists(c):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(c))

func tamanho_kb() -> float:
	if not FileAccess.file_exists(cam()):
		return 0.0
	var f := FileAccess.open(cam(), FileAccess.READ)
	if f == null:
		return 0.0
	var t := f.get_length()
	f.close()
	return round(float(t) / 1024.0 * 10.0) / 10.0

## ------------------------------------------------------------ migrações

## Cada função leva o save da versão N para N+1. Nunca remova migrações.
func migrar(save: Dictionary) -> Dictionary:
	var v := int(save.get("versao", 0))
	while v < VERSAO:
		match v:
			0:
				save["versao"] = 1
			_:
				pass
		v += 1
		save["versao"] = v
	return save

## --------------------------------------------------------- exportar/importar

func exportar(dados: Dictionary) -> String:
	var json := JSON.stringify(dados)
	var b64 := Marshalls.utf8_to_base64(json)
	return ASSINATURA + _checksum(b64) + "|" + b64

func importar(texto: String) -> Dictionary:
	ultimo_erro = ""
	var t := texto.strip_edges().replace("\n", "").replace(" ", "")
	if not t.begins_with(ASSINATURA):
		ultimo_erro = "Código de save inválido (assinatura não reconhecida)."
		return {}
	var resto := t.substr(ASSINATURA.length())
	var sep := resto.find("|")
	if sep < 0:
		ultimo_erro = "Código de save incompleto."
		return {}
	var soma := resto.substr(0, sep)
	var b64 := resto.substr(sep + 1)
	if _checksum(b64) != soma:
		ultimo_erro = "Código de save corrompido (checksum não confere)."
		return {}
	var json := Marshalls.base64_to_utf8(b64)
	var r = JSON.parse_string(json)
	if not (r is Dictionary):
		ultimo_erro = "Conteúdo do save não pôde ser lido."
		return {}
	return migrar(r)

func _checksum(s: String) -> String:
	var h := 5381
	for i in s.length():
		h = ((h << 5) + h + s.unicode_at(i)) & 0x7FFFFFFF
	return String.num_int64(h, 36)

## ------------------------------------------------------------- configurações

func salvar_config(cfg: Dictionary) -> void:
	var f := FileAccess.open(cam_config(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(cfg))
		f.close()

func carregar_config() -> Dictionary:
	return _ler(cam_config())
