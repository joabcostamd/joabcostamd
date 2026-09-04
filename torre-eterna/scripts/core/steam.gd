class_name SteamPonte
extends RefCounted

## A PONTE PARA A STEAM — e o que acontece quando ela não existe.
##
## A integração com a Steam depende de um binário nativo (GodotSteam, hoje na
## 4.22 para o Godot 4.7.2) que **não está no repositório**: é um `.so`/`.dll`
## por plataforma, baixado na hora de exportar, do mesmo jeito que as fontes.
##
## Isso deixa o código diante de uma escolha, e a escolha errada é fácil: chamar
## `Steam.setAchievement(...)` direto. Aí o jogo roda na máquina de quem exportou
## e **quebra em toda máquina que não tem o plugin** — o editor de quem clona o
## repositório, o CI, a build de itch.io, a versão de demonstração. Pior: quebra
## com erro de identificador desconhecido, que não diz nada sobre o que faltou.
##
## Então nada aqui fala com a Steam diretamente. Tudo passa por `_s`, que é o
## singleton **se ele existir** e `null` se não existir, e toda função checa antes
## de agir. Sem o plugin, o jogo abre, joga, salva e termina igual — só não
## conversa com a loja. É o mesmo princípio das fontes: um jogo que não roda
## porque falta uma dependência opcional é pior do que um jogo sem a dependência.
##
## Ver `docs/STEAM.md` para a configuração do lado da Steamworks.

## O singleton do GodotSteam, ou `null`. Resolvido uma vez.
static var _s = null
static var _tentou := false
static var _ligado := false
static var _erro := ""

## Números que o jogo publica no placar de líderes. O nome é o do quadro na
## Steamworks e precisa bater exatamente com o que está cadastrado lá.
const PLACARES := {
	"onda_maxima": "MAX_WAVE",
	"ascensoes": "TOTAL_ASCENSIONS",
	"transcendencias": "TOTAL_TRANSCENDENCES",
	"formas_vistas": "FORMS_SEEN",
}

# ------------------------------------------------------------------ ligar

static func disponivel() -> bool:
	_resolver()
	return _s != null

static func ligado() -> bool:
	return _ligado

static func erro() -> String:
	return _erro

static func _resolver() -> void:
	if _tentou:
		return
	_tentou = true
	# `Engine.has_singleton` é a pergunta certa: ela não estoura quando a
	# resposta é não, ao contrário de tocar no identificador direto.
	if Engine.has_singleton("Steam"):
		_s = Engine.get_singleton("Steam")

## Chamado uma vez na abertura. Devolve `false` sem drama quando não há Steam —
## o que é o caso normal durante todo o desenvolvimento.
##
## As mensagens de `_erro` ficam em inglês de propósito: elas NÃO vão para a tela
## de ninguém que joga. São diagnóstico de quem exporta, lidas no relatório do
## build, no mesmo idioma do resto das mensagens do motor. Traduzi-las seria
## fingir que são interface — e aí o portão de tradução passaria a cobrar as
## vinte versões de uma frase que só um desenvolvedor lê.
static func iniciar() -> bool:
	_resolver()
	if _s == null:
		_erro = "GodotSteam plugin not present"
		return false
	var app := Marca.app_id()
	if app <= 0:
		_erro = "steam.app_id not set in data/marca.json"
		return false
	# `steamInitEx` devolve um Dicionário com status e mensagem; a versão antiga
	# devolvia só um número. Aceita as duas para não amarrar numa versão do
	# plugin.
	var r = _s.steamInitEx(app, true) if _s.has_method("steamInitEx") else _s.steamInit(app)
	if r is Dictionary:
		_ligado = int((r as Dictionary).get("status", 1)) == 0
		_erro = str((r as Dictionary).get("verbal", ""))
	else:
		_ligado = int(r) == 1
		_erro = "" if _ligado else "steamInit failed (%s)" % str(r)
	return _ligado

## Precisa rodar todo quadro para o overlay, os retornos de placar e os avisos
## da própria Steam chegarem. Sem isto, o overlay abre e o jogo não sabe.
static func passo() -> void:
	if _ligado and _s != null and _s.has_method("run_callbacks"):
		_s.run_callbacks()

# ------------------------------------------------------------ conquistas

## O nome da conquista na Steamworks, derivado do id do jogo.
##
## Derivar em vez de cadastrar um `api_name` por conquista no JSON tem uma razão
## prática: são 85 conquistas, e um campo a mais em cada uma é 85 chances de
## erro de digitação que só aparece quando alguém desbloqueia aquela específica,
## na produção. A regra é fixa e o portão confere que ela não colide.
static func nome_api(id: String) -> String:
	return "ACH_" + id.to_upper()

static func destravar(id: String) -> void:
	if not _ligado or _s == null:
		return
	_s.setAchievement(nome_api(id))
	_s.storeStats()

## Placar: a Steam guarda o MAIOR valor por conta, então mandar um número menor
## não apaga o recorde. `k_ELeaderboardUploadScoreMethodKeepBest` = 1.
static func enviar_placar(chave: String, valor: int) -> void:
	if not _ligado or _s == null:
		return
	var quadro := str(PLACARES.get(chave, ""))
	if quadro == "":
		return
	_s.findLeaderboard(quadro)
	# O envio real acontece no retorno de `findLeaderboard`; quem liga os sinais
	# é `SteamCola`, para que esta classe continue sem estado de cena.

# --------------------------------------------------------- presença rica

## O QUE APARECE PARA OS AMIGOS. O texto NÃO é escrito aqui: `steam_display`
## aponta para uma chave de tradução cadastrada na Steamworks, e a Steam monta a
## frase no idioma de quem LÊ. Mandar texto pronto daqui deixaria um brasileiro
## vendo "Onda 412" na lista de amigos de um japonês.
static func presenca(onda: int, camada: String) -> void:
	if not _ligado or _s == null:
		return
	_s.setRichPresence("onda", str(onda))
	_s.setRichPresence("camada", camada)
	_s.setRichPresence("steam_display", "#Status_Jogando")

static func limpar_presenca() -> void:
	if _ligado and _s != null:
		_s.clearRichPresence()

# ------------------------------------------------------------------ nuvem

## A NUVEM É AUTOMÁTICA, E ISSO É DE PROPÓSITO.
##
## A Steam sincroniza o save por Auto-Cloud, configurado na Steamworks por
## padrão de caminho — sem uma linha de código. A alternativa (a API
## `ISteamRemoteStorage`) obrigaria a reescrever todo o `save_system.gd` para
## gravar por lá, e trocaria um sistema com backup, quarentena e migração
## testados por um caminho novo, só para ganhar controle que não é preciso.
##
## O que a API resolve e o Auto-Cloud não: saber se a nuvem está LIGADA para
## este jogador. Ele pode ter desligado nas propriedades do jogo, e aí o
## progresso dele não atravessa máquina nenhuma — sem aviso. Isso vale um aviso.
static func nuvem_ligada() -> bool:
	if not _ligado or _s == null:
		return false
	if not _s.has_method("isCloudEnabledForAccount"):
		return false
	return bool(_s.isCloudEnabledForAccount()) and bool(_s.isCloudEnabledForApp())

# ----------------------------------------------------------------- overlay

static func overlay_aberto() -> bool:
	if not _ligado or _s == null:
		return false
	return bool(_s.isOverlayEnabled()) if _s.has_method("isOverlayEnabled") else false

## Abre uma página da própria Steam por cima do jogo — a loja, o perfil, o guia.
static func abrir_overlay(pagina: String) -> void:
	if _ligado and _s != null:
		_s.activateGameOverlay(pagina)

static func nome_do_jogador() -> String:
	if not _ligado or _s == null:
		return ""
	return str(_s.getPersonaName())

## O idioma que a pessoa escolheu NA STEAM, traduzido para o código do jogo.
##
## É a melhor primeira impressão possível: quem comprou em russo abre o jogo em
## russo, sem mexer em nada. A Steam devolve o código dela (`schinese`,
## `koreana`, `brazilian`), que não é o ISO — por isso a volta passa pela tabela.
static func idioma_da_steam() -> String:
	if not _ligado or _s == null:
		return ""
	var bruto := str(_s.getCurrentGameLanguage())
	for d in Idiomas.LISTA:
		if str((d as Dictionary).get("steam", "")) == bruto:
			return str((d as Dictionary)["cod"])
	return ""
