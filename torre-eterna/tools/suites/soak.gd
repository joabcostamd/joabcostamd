extends RefCounted

## Corpo da ferramenta. Vive fora do script de entrada de propósito: em modo
## `-s` o Godot compila o script de entrada ANTES de registrar os autoloads, e
## qualquer classe que use `Bus`/`Cfg` falha a compilar de forma intermitente.
## Carregado por `res://tools/soak.gd` já dentro de `_initialize()`.

var arvore: SceneTree

## O soak ascende sozinho, e o limiar sobe a cada ascensão: sem isso a
## ferramenta fica presa num laço de quarenta ondas para sempre.
const ASCENDER_INICIAL := 40
const ASCENDER_PASSO := 1.6
var root: Node

## Teste de resistência: horas de jogo com invariantes checadas o tempo todo.
## Pega o que um teste unitário não pega — estado que apodrece devagar.
##   godot --headless --path . -s res://tools/soak.gd -- 6

const DT := 1.0 / 60.0
const JANELA_TRAVA := 420.0     ## sem avançar de onda por 7 min = travou

var falhas: Array = []
var jogo
var maior_inimigos := 0
var maior_projeteis := 0
var maior_coletaveis := 0
var maior_buffs := 0
var maior_inventario := 0

func rodar(cena: SceneTree) -> void:
	arvore = cena
	root = cena.root
	# roda num save separado: a suite nao pode apagar o progresso de quem joga
	SaveSys.prefixo = "_ferramenta_"
	Dados.carregar(true)
	var args := OS.get_cmdline_user_args()
	var horas := 2.0
	if args.size() > 0:
		horas = maxf(0.1, float(str(args[0])))

	var save = root.get_node_or_null("SaveSys")
	var cfg = root.get_node_or_null("Cfg")
	cfg.v = cfg.PADRAO.duplicate(true)
	save.apagar()
	jogo = root.get_node_or_null("Jogo")
	jogo.stats = StatEngine.new()
	jogo.iniciar()
	jogo.s["auto"]["comprar"] = true
	jogo.s["desbloqueios"]["autoCompra"] = true
	jogo.s["auto"]["habilidades"] = true
	jogo.s["desbloqueios"]["autoHabilidade"] = true
	# O soak rodava uma hora inteira sem ascender NENHUMA vez — e o prestígio é
	# justamente onde moram os piores bugs de estado (a Transcendência já apagou
	# o Álbum e o Panteão, e o congelamento de tempo já sobreviveu à ascensão).
	# Ascende sozinho assim que compensa, para o teste passar por esse caminho.
	jogo.s["desbloqueios"]["autoAscensao"] = true
	jogo.s["prestigio"]["auto_ascender"] = true
	# O limiar SOBE a cada ascensão, em vez de ficar preso em 40.
	#
	# Com 40 fixo, o soak repetia o mesmo laço de quarenta ondas por quantas
	# horas se pedisse: uma corrida de 1 h e uma de 3 h fechavam as duas com
	# `onda maxima 40`. Ou seja, a cláusula "sem travar em 3 h" estava protegida
	# por uma ferramenta cujo espaço de estados alcançável ia só até a onda 40 —
	# tudo que quebra depois dela era invisível para o único portão longo com
	# veredito. Agora cada ascensão empurra o limiar, e o soak sobe de verdade.
	jogo.s["prestigio"]["auto_ascender_onda"] = ASCENDER_INICIAL
	Bus.prestigio_feito.connect(func(_camada, _ganho):
		var atual := int(jogo.s["prestigio"]["auto_ascender_onda"])
		jogo.s["prestigio"]["auto_ascender_onda"] = int(round(float(atual) * ASCENDER_PASSO)))
	jogo.marcar_sujo()
	jogo.recalcular()

	var passos := int(horas * 3600.0 / DT)
	var ultima_onda := 1
	var tempo_ultima_onda := 0.0
	var checagens := 0

	print("=== SOAK: %.1f h de jogo, invariantes a cada 10s ===" % horas)

	for i in passos:
		jogo.simular(DT)
		var t: float = jogo.s["stats"]["tempo_total"]

		if int(jogo.s["onda"]) != ultima_onda:
			ultima_onda = int(jogo.s["onda"])
			tempo_ultima_onda = t
		elif t - tempo_ultima_onda > JANELA_TRAVA:
			_falha("onda %d travada por %.0fs (estado do diretor: %s)" % [ultima_onda, t - tempo_ultima_onda, jogo.diretor.estado])
			tempo_ultima_onda = t

		if i % 600 == 0:
			checagens += 1
			_checar_invariantes(t)

		# Prestígio periódico: exercita reset, Retomada e persistência. Antes o
		# intervalo era de uma hora simulada, então um soak de `-- 1` nunca
		# chegava a ascender e o caminho mais perigoso do jogo ficava sem teste.
		if i % 54000 == 0 and i > 0 and Prestigio.pode_ascender(jogo.s):
			jogo.ascender()
			_checar_invariantes(t)

		# salvar/carregar no meio da partida
		if i % 108000 == 0 and i > 0:
			_checar_roundtrip()

	print("\n=== PICOS ===")
	print("inimigos %d · projeteis %d · coletaveis %d · buffs %d · inventario %d" % [
		maior_inimigos, maior_projeteis, maior_coletaveis, maior_buffs, maior_inventario])
	# Conta do ESTADO, não de uma variável local: a ascensão automática também
	# vale, e ela não passa pelo laço daqui.
	print("onda maxima %d · ascensoes %d · checagens %d" % [
		int(jogo.s["onda_maxima_global"]), int(jogo.s["prestigio"]["ascensoes"]), checagens])
	print("\n=== SOAK === falhas=%d" % falhas.size())
	for f in falhas:
		print("  FALHA: ", f)
	print("===STATUS=== ", "PASS" if falhas.is_empty() else "FAIL")
	arvore.quit(0 if falhas.is_empty() else 1)

func _falha(msg: String) -> void:
	if falhas.size() < 40:
		falhas.append(msg)

func _num_ok(v: float, nome: String) -> void:
	if is_nan(v) or is_inf(v):
		_falha("%s virou %s" % [nome, str(v)])

func _checar_invariantes(t: float) -> void:
	var s: Dictionary = jogo.s
	for k in s["moedas"].keys():
		_num_ok(float(s["moedas"][k]), "moeda " + str(k))
	_num_ok(float(s["torre"]["vida"]), "vida da torre")
	_num_ok(float(s["torre"]["vida_max"]), "vida maxima")
	_num_ok(float(s["xp"]), "xp")
	_num_ok(jogo.stats.b("dano"), "dano")
	_num_ok(jogo.stats.n("cadencia"), "cadencia")

	if Big.gt(s["torre"]["vida"], Big.mul_f(s["torre"]["vida_max"], 1.01)):
		_falha("vida acima do maximo")
	if int(s["onda"]) < 1:
		_falha("onda invalida: %d" % int(s["onda"]))
	if int(s["nivel"]) < 1 or int(s["nivel"]) > Bal.NIVEL_MAX:
		_falha("nivel fora da faixa: %d" % int(s["nivel"]))
	if int(s["pontos_talento"]) < 0:
		_falha("pontos de talento negativos")

	maior_inimigos = maxi(maior_inimigos, jogo.arena.inimigos.size())
	maior_projeteis = maxi(maior_projeteis, jogo.arena.projeteis.size())
	maior_coletaveis = maxi(maior_coletaveis, jogo.arena.coletaveis.size())
	maior_buffs = maxi(maior_buffs, s["buffs"].size())
	maior_inventario = maxi(maior_inventario, s["cartas"]["inventario"].size())

	if jogo.arena.inimigos.size() > jogo.arena.max_inimigos:
		_falha("estouro do pool de inimigos: %d" % jogo.arena.inimigos.size())
	if jogo.arena.projeteis.size() > jogo.arena.max_projeteis:
		_falha("estouro do pool de projeteis: %d" % jogo.arena.projeteis.size())
	if s["buffs"].size() > 40:
		_falha("buffs acumulando: %d" % s["buffs"].size())
	if s["cartas"]["equipadas"].size() > 8:
		_falha("slots de carta demais: %d" % s["cartas"]["equipadas"].size())

func _checar_roundtrip() -> void:
	var save = root.get_node_or_null("SaveSys")
	var codigo: String = jogo.exportar()
	var lido: Dictionary = save.importar(codigo)
	if lido.is_empty():
		_falha("save exportado no meio da partida nao importa de volta")
		return
	if int(lido.get("onda", -1)) != int(jogo.s["onda"]):
		_falha("roundtrip perdeu a onda")
	if absf(float(lido["moedas"]["ouro"]) - float(jogo.s["moedas"]["ouro"])) > 1e-6:
		_falha("roundtrip perdeu precisao do ouro")
	if lido["upgrades"].size() != jogo.s["upgrades"].size():
		_falha("roundtrip perdeu upgrades")
