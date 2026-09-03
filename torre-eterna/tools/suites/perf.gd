extends RefCounted

## Corpo da ferramenta. Vive fora do script de entrada de propósito: em modo
## `-s` o Godot compila o script de entrada ANTES de registrar os autoloads, e
## qualquer classe que use `Bus`/`Cfg` falha a compilar de forma intermitente.
## Carregado por `res://tools/perf.gd` já dentro de `_initialize()`.

var arvore: SceneTree
var root: Node

## Teste de estresse: enche a arena e mede o custo real de um passo de simulação.
##   godot --headless --path . -s res://tools/perf.gd -- 400

const DT := 1.0 / 60.0
const ORCAMENTO_US := 4000.0   ## 4 ms de simulação por frame (de 16,6 ms)

## Orçamento em microssegundos só significa alguma coisa se as duas máquinas
## correrem na mesma velocidade, e não correm: o runner do CI é bem mais lento
## que a máquina de quem desenvolve. Sem normalizar, o portão vira loteria de
## hardware — o mesmo commit passa aqui e falha lá. A saída: medir a máquina
## com uma conta fixa antes de medir o jogo, e esticar o orçamento na mesma
## proporção. O orçamento nunca aperta em máquina rápida (piso 1.0), e para de
## esticar em máquina absurdamente lenta (teto 3.0), senão não sobraria portão.
const REF_US := 39000.0        ## a conta abaixo custa isso na máquina de referência
const FATOR_MIN := 1.0
const FATOR_MAX := 3.0

## Conta fixa e determinística: float, seno, raiz, dicionário e array — a mesma
## mistura que a simulação faz. Cinco medidas e fica com a MEDIANA, não com a
## melhor: a melhor encontra a brecha ociosa entre duas tarefas vizinhas e diz
## que a máquina está livre, enquanto o laço de 900 passos come a disputa
## inteira. Mediana descreve a condição que o jogo de fato encontra.
static func medir_maquina() -> float:
	var amostras: Array[float] = []
	for tentativa in 5:
		var v := PackedFloat32Array()
		v.resize(4096)
		var d := {"a": 1.0, "b": 2.0}
		var t := Time.get_ticks_usec()
		for rep in 40:
			for i in 4096:
				var x := float(i) * 0.001 + float(rep)
				var y: float = float(d["a"]) * x + float(d["b"])
				v[i] = sqrt(y * y + 1.0) * sin(x) + float(v[(i + 1) & 4095]) * 0.5
		amostras.append(float(Time.get_ticks_usec() - t))
	amostras.sort()
	return amostras[amostras.size() / 2]

func rodar(cena: SceneTree) -> void:
	arvore = cena
	root = cena.root
	# roda num save separado: a suite nao pode apagar o progresso de quem joga
	SaveSys.prefixo = "_ferramenta_"
	Dados.carregar(true)
	var args := OS.get_cmdline_user_args()
	var alvo := 400
	if args.size() > 0:
		alvo = maxi(20, int(str(args[0])))

	var save = root.get_node_or_null("SaveSys")
	var cfg = root.get_node_or_null("Cfg")
	cfg.v = cfg.PADRAO.duplicate(true)
	save.apagar()
	var j = root.get_node_or_null("Jogo")
	j.stats = StatEngine.new()
	j.iniciar()

	# torre poderosa e onda alta: pior caso realista
	j.s["onda"] = 200
	j.s["onda_maxima"] = 200
	j.s["onda_maxima_global"] = 200
	for i in 300:
		j.comprar_upgrade("dano", 5)
		j.ganhar_ouro(Big.mul_f(Bal.ouro_onda(200), 900.0), "perf", true)
	j.comprar_upgrade("multishot", "max")
	j.comprar_upgrade("perfuracao", "max")
	j.comprar_upgrade("ricochete", "max")
	j.comprar_upgrade("area", "max")
	j.comprar_upgrade("orbe", "max")
	j.comprar_upgrade("fogo", "max")
	j.comprar_upgrade("gelo", "max")
	j.comprar_upgrade("raio", "max")
	j.comprar_upgrade("veneno", "max")
	j.comprar_upgrade("vida", "max")
	j.marcar_sujo()
	j.recalcular()

	var pool := Dados.pool_da_onda(200)
	for i in alvo:
		var def: Dictionary = pool[i % pool.size()]
		EnemyAI.criar(def, 200, j, {"elite": i % 5 == 0})

	# Uma medida só, tirada antes, não vale: a disputa por CPU pode começar
	# depois. Mede de novo no fim e fica com a PIOR das duas — as duas cercam a
	# janela inteira em que o jogo foi medido.
	var ref_antes := medir_maquina()

	print("=== ESTRESSE: %d inimigos, onda %d ===" % [j.arena.inimigos.size(), int(j.s["onda"])])
	print("projeteis/s: %.1f | orbes: %d | elementos ativos: sim" % [j.stats.n("cadencia") * j.stats.n("projeteis"), int(j.stats.n("orbes"))])

	# aquecimento
	for i in 60:
		j.simular(DT)

	var pico_i := 0
	var pico_p := 0
	var passos := 900

	# --- perfil por subsistema (mede o custo real de cada etapa) ---
	var custo := {"grade": 0, "status": 0, "inimigos": 0, "torre": 0, "projeteis": 0,
		"coletaveis": 0, "habilidades": 0, "diretor": 0, "resto": 0}
	var t0 := Time.get_ticks_usec()
	for i in passos:
		var a := Time.get_ticks_usec()
		j.arena.reconstruir_grade()
		var b := Time.get_ticks_usec(); custo["grade"] += b - a
		Combate.atualizar_status(DT, j)
		var c := Time.get_ticks_usec(); custo["status"] += c - b
		EnemyAI.atualizar(DT, j)
		var d := Time.get_ticks_usec(); custo["inimigos"] += d - c
		j.torre.atualizar(DT)
		var e := Time.get_ticks_usec(); custo["torre"] += e - d
		j.torre.atualizar_projeteis(DT)
		var f := Time.get_ticks_usec(); custo["projeteis"] += f - e
		Economia.atualizar_coletaveis(DT, j)
		var g := Time.get_ticks_usec(); custo["coletaveis"] += g - f
		Habilidades.atualizar(DT, j)
		var h := Time.get_ticks_usec(); custo["habilidades"] += h - g
		j.diretor.atualizar(DT)
		custo["diretor"] += Time.get_ticks_usec() - h
		pico_i = maxi(pico_i, j.arena.inimigos.size())
		pico_p = maxi(pico_p, j.arena.projeteis.size())
	var total := Time.get_ticks_usec() - t0
	var por_passo := float(total) / float(passos)
	var ref := maxf(ref_antes, medir_maquina())
	var fator := clampf(ref / REF_US, FATOR_MIN, FATOR_MAX)
	var orcamento := ORCAMENTO_US * fator
	print("maquina: %.0f us na conta de referencia (%.0f esperado) -> fator %.2fx" % [ref, REF_US, fator])
	print("--- perfil por subsistema (us/passo) ---")
	for k in custo.keys():
		var v := float(custo[k]) / float(passos)
		if v >= 1.0:
			print("  %-12s %7.0f us  (%4.1f%%)" % [k, v, v / maxf(1.0, por_passo) * 100.0])

	print("pico: %d inimigos, %d projeteis, %d coletaveis" % [pico_i, pico_p, j.arena.coletaveis.size()])
	print("custo por passo: %.0f us  (orcamento %.0f us = %.0f x %.2f)" % [por_passo, orcamento, ORCAMENTO_US, fator])
	print("normalizado para a maquina de referencia: %.0f us" % (por_passo / fator))
	print("equivale a %.0f fps so de simulacao" % (1000000.0 / maxf(1.0, por_passo)))
	print("recalculos de atributos: %d" % j.stats.recalculos)
	var ok := por_passo <= orcamento
	print("===STATUS=== ", "PASS" if ok else "FAIL")
	arvore.quit(0 if ok else 1)
