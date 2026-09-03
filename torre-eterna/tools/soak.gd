extends SceneTree

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
var prestigios := 0

func _initialize() -> void:
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
	jogo.marcar_sujo()

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

		# prestígio periódico: exercita reset, Retomada e persistência
		if i % 216000 == 0 and i > 0 and Prestigio.pode_ascender(jogo.s):
			jogo.ascender()
			prestigios += 1
			_checar_invariantes(t)

		# salvar/carregar no meio da partida
		if i % 108000 == 0 and i > 0:
			_checar_roundtrip()

	print("\n=== PICOS ===")
	print("inimigos %d · projeteis %d · coletaveis %d · buffs %d · inventario %d" % [
		maior_inimigos, maior_projeteis, maior_coletaveis, maior_buffs, maior_inventario])
	print("onda maxima %d · prestigios %d · checagens %d" % [int(jogo.s["onda_maxima_global"]), prestigios, checagens])
	print("\n=== SOAK === falhas=%d" % falhas.size())
	for f in falhas:
		print("  FALHA: ", f)
	print("===STATUS=== ", "PASS" if falhas.is_empty() else "FAIL")
	quit(0 if falhas.is_empty() else 1)

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
