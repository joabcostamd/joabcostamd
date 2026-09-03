extends Node

## SaveSys (autoload) — persistência em JSON com versionamento, backup,
## exportação em texto e migrações.

const VERSAO := 2
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

static func cam_corrompido() -> String:
	return cam() + ".corrompido"

func cam_backup() -> String:
	return CAMINHO_BACKUP.replace("torre_eterna.", prefixo + "torre_eterna.")

static func cam_config() -> String:
	return CAMINHO_CONFIG.replace("torre_eterna_", prefixo + "torre_eterna_")

var ultimo_erro := ""

## ---------------------------------------------------------------- disco

## Procura NaN ou INF em qualquer profundidade do estado.
##
## Isto era conferido por acidente. No Godot 4.4 `JSON.stringify` escrevia
## `inf`/`nan` no texto, que não é JSON válido, e a recusa vinha do round-trip
## falhar — nunca de alguém ter perguntado "tem número quebrado aqui?".
##
## No Godot 4.7 o motor passou a trocar esses valores por `null`. O JSON fica
## válido, o round-trip passa, e o save gravaria `null` no lugar do ouro do
## jogador; na leitura o `null` vira o padrão e a partida some sem aviso — pior
## que a recusa, porque a recusa ao menos preserva o save anterior. A troca de
## motor não criou o defeito, só tirou a rede que o escondia.
##
## Agora a pergunta é feita de propósito, e a resposta não depende de qual
## versão do motor está rodando.
static func _tem_nao_finito(v) -> bool:
	match typeof(v):
		TYPE_FLOAT:
			return not is_finite(v)
		TYPE_DICTIONARY:
			for k in v:
				if _tem_nao_finito(v[k]):
					return true
		TYPE_ARRAY:
			for item in v:
				if _tem_nao_finito(item):
					return true
	return false

func salvar(dados: Dictionary) -> bool:
	var texto := JSON.stringify(dados)
	# Um único NaN ou INF no estado corrompe o arquivo: ele grava, o jogo
	# continua, e no próximo autosave esse arquivo quebrado vira o backup. Dois
	# autosaves depois o jogador perdeu save E backup sem nunca ter visto um
	# aviso. Por isso o save só acontece com número finito e texto que volta a
	# virar Dicionário.
	if _tem_nao_finito(dados) or JSON.parse_string(texto) == null:
		ultimo_erro = Txt.t("sv_json_invalido")
		push_error(ultimo_erro)
		Bus.toast(Txt.t("save_falhou"), "ruim", "cadeado")
		return false
	# Rotação do backup — só promove conteúdo VÁLIDO.
	#
	# Antes, o backup era "o arquivo anterior", corrompido ou não. Isso monta uma
	# armadilha: se o principal corrompe, o boot seguinte recupera do backup e
	# segue jogando; vinte segundos depois o autosave copia o principal AINDA
	# corrompido por cima do backup, destruindo a única cópia boa. O jogador
	# perdia tudo sem nunca ver um aviso. Agora, conteúdo ilegível no principal
	# vai para a quarentena `.corrompido` e o backup fica onde está.
	if FileAccess.file_exists(cam()):
		var antigo := FileAccess.open(cam(), FileAccess.READ)
		if antigo:
			var conteudo := antigo.get_as_text()
			antigo.close()
			if JSON.parse_string(conteudo) is Dictionary:
				var bak := FileAccess.open(cam_backup(), FileAccess.WRITE)
				if bak:
					bak.store_string(conteudo)
					bak.close()
			else:
				push_warning("[save] principal ilegível: não vai virar backup; guardado em %s" % cam_corrompido())
				DirAccess.rename_absolute(cam(), cam_corrompido())

	# Escrita atômica — grava no temporário, confere que volta a ser Dicionário,
	# e só então troca pelo definitivo. Antes, `store_string` num disco cheio (ou
	# um kill no meio) deixava o save truncado no lugar do bom, e `salvar()`
	# devolvia `true` do mesmo jeito: o `jogo_salvo` era mentira.
	var tmp := cam() + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		# Disco cheio, pasta sem permissao, arquivo travado por outro processo.
		# Isto ia so para o console: quem joga via o jogo seguir normalmente e
		# so descobria no proximo boot que as ultimas horas nao existiam.
		ultimo_erro = Txt.f("sv_abrir_falhou", {"e": int(FileAccess.get_open_error())})
		push_error(ultimo_erro)
		Bus.toast(Txt.t("save_falhou"), "ruim", "cadeado")
		return false
	f.store_string(texto)
	f.close()
	var conferido := FileAccess.open(tmp, FileAccess.READ)
	var de_volta := conferido.get_as_text() if conferido != null else ""
	if conferido != null:
		conferido.close()
	if not (JSON.parse_string(de_volta) is Dictionary):
		ultimo_erro = Txt.t("sv_grava_incompleta")
		push_error(ultimo_erro)
		Bus.toast(Txt.t("save_falhou"), "ruim", "cadeado")
		DirAccess.remove_absolute(tmp)
		return false
	if DirAccess.rename_absolute(tmp, cam()) != OK:
		ultimo_erro = Txt.t("sv_substituir_falhou")
		push_error(ultimo_erro)
		Bus.toast(Txt.t("save_falhou"), "ruim", "cadeado")
		DirAccess.remove_absolute(tmp)
		return false
	Bus.jogo_salvo.emit(texto.length())
	return true

## Verdadeiro quando a última `carregar()` encontrou arquivo de save e não
## conseguiu ler NENHUM deles. É diferente de "não existe save": no primeiro
## caso o jogo mostrava o tutorial como se fosse jogador novo e sobrescrevia os
## dois arquivos no autosave seguinte, apagando o progresso de quem talvez só
## precisasse fechar o jogo e pedir ajuda.
var falhou_ao_ler := false

func carregar() -> Dictionary:
	falhou_ao_ler = false
	var tinha := FileAccess.file_exists(cam()) or FileAccess.file_exists(cam_backup())
	var d := _ler(cam())
	if d.is_empty():
		d = _ler(cam_backup())
		if not d.is_empty():
			push_warning("[save] save principal corrompido; backup restaurado.")
			# Volta a ter duas cópias boas AGORA. Rodar com uma cópia só é o
			# estado em que a próxima falha custa a partida inteira.
			salvar(d)
	if d.is_empty():
		if tinha:
			falhou_ao_ler = true
			ultimo_erro = Txt.t("sv_ilegivel")
			push_error(ultimo_erro)
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

## Apagar o save apaga TODOS os arquivos do save, quarentena inclusa.
##
## O `.corrompido` guarda um principal ilegivel para quem quiser tentar
## recuperar depois. Mas ele ficava no disco para sempre: quem pedia "apagar
## meu progresso" recomecava do zero com um arquivo antigo encostado ali, sem
## nenhum jeito de tirar de dentro do jogo.
func apagar() -> void:
	for c in [cam(), cam_backup(), cam_corrompido()]:
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

## Lê o carimbo de versão de um arquivo que pode ter sido adulterado.
##
## `versao` vem de um arquivo em disco que qualquer pessoa abre num editor de
## texto. Com `"versao": -999999999999` a escada rodava um trilhão de degraus
## antes de chegar na versão de hoje: o jogo abria e congelava para sempre —
## sem erro, sem tela, sem volta. É o pior tipo de falha, porque parece um jogo
## travado e não um save ruim, e a pessoa não tem como saber que basta apagar
## o arquivo.
##
## Carimbo quebrado (texto, nulo, não finito, negativo) não é save de outra
## versão, é lixo: vale 0, e o `mesclar`/`sanear` completa o resto. Carimbo
## acima do que este build conhece é save de um jogo mais novo: não dá para
## descer, então nenhuma migração roda e os dados passam como estão.
static func _versao_do_arquivo(save: Dictionary) -> int:
	var bruto = save.get("versao", 0)
	if not (bruto is int or bruto is float):
		return 0
	var f := float(bruto)
	if not is_finite(f) or f < 0.0:
		return 0
	if f > float(VERSAO):
		return VERSAO
	return int(f)

## Cada função leva o save da versão N para N+1. Nunca remova migrações.
## Sobe um save antigo até a versão de hoje, um degrau por vez.
##
## Esta escada era de um degrau só e não subia nada: carimbava o número e
## pronto, o que fazia o critério de persistência ser cumprido por uma função
## que nunca migrou um campo. O degrau 1 -> 2 é uma migração de verdade, e
## existe porque o jogo precisou dela.
func migrar(save: Dictionary) -> Dictionary:
	var v := _versao_do_arquivo(save)
	# O laço não pode passar do número de degraus que existem. O `v` já vem
	# preso na faixa, então este contador nunca é o que para o laço — ele é a
	# garantia de que nenhum jeito futuro de ler o carimbo consiga travar o
	# jogo aqui, nem se alguém trocar o `_versao_do_arquivo` sem pensar nisso.
	var degraus := 0
	while v < VERSAO and degraus < VERSAO:
		degraus += 1
		match v:
			0:
				# Antes da versão 1 não havia carimbo. Nada a converter: o
				# `GameState.mesclar` completa os campos que faltarem.
				pass
			1:
				_migrar_1_para_2(save)
		v += 1
		save["versao"] = v
	return save

## 1 -> 2: a memória dos eventos `unico` saiu do histórico rolante.
##
## O histórico é cortado em 60 entradas, e era ele que servia de memória do "já
## vi". Os eventos de lore da torre voltavam ao sorteio assim que saíam dessa
## janela. Agora há uma lista própria — e o save de quem já jogou precisa ganhar
## essa lista a partir do que ainda restar no histórico, senão a correção
## "esquece" o que a pessoa já viu.
func _migrar_1_para_2(save: Dictionary) -> void:
	var ev = save.get("eventos", null)
	if not (ev is Dictionary):
		return
	var evd: Dictionary = ev
	if evd.has("unicos_vistos"):
		return
	var vistos: Array = []
	var hist = evd.get("historico", [])
	if hist is Array:
		for item in hist:
			if not (item is Dictionary):
				continue
			var id := str((item as Dictionary).get("id", ""))
			if id == "" or vistos.has(id):
				continue
			var def: Dictionary = Dados.evento_por_id.get(id, {})
			if bool(def.get("unico", false)):
				vistos.append(id)
	evd["unicos_vistos"] = vistos

## --------------------------------------------------------- exportar/importar

func exportar(dados: Dictionary) -> String:
	var json := JSON.stringify(dados)
	var b64 := Marshalls.utf8_to_base64(json)
	return ASSINATURA + _checksum(b64) + "|" + b64

func importar(texto: String) -> Dictionary:
	ultimo_erro = ""
	var t := texto.strip_edges().replace("\n", "").replace(" ", "")
	if not t.begins_with(ASSINATURA):
		ultimo_erro = Txt.t("sv_assinatura")
		return {}
	var resto := t.substr(ASSINATURA.length())
	var sep := resto.find("|")
	if sep < 0:
		ultimo_erro = Txt.t("sv_incompleto")
		return {}
	var soma := resto.substr(0, sep)
	var b64 := resto.substr(sep + 1)
	if _checksum(b64) != soma:
		ultimo_erro = Txt.t("sv_checksum")
		return {}
	var json := Marshalls.base64_to_utf8(b64)
	var r = JSON.parse_string(json)
	if not (r is Dictionary):
		ultimo_erro = Txt.t("sv_conteudo_ilegivel")
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
