extends Node

## Jogo (autoload) — o orquestrador. Dono do estado e da simulação.
## Todos os módulos de simulação recebem este nó como `j`.

var s: Dictionary = {}
var stats: StatEngine
var esp: Dictionary = {}
var pas: Dictionary = {}
var rng := RngX.new()
var arena := Arena.new()
var torre: TorreSim
var diretor: Diretor
var mods_dif := {"hpInimigo": 1.0, "velocidadeInimigo": 1.0, "ouro": 1.0, "danoTorre": 1.0, "xp": 1.0}

var iniciado := false
var pausado := false
var sujo := true
var velocidade := 1.0
var hitstop := 0.0
var tempo_congelado := 0.0
var invulneravel := 0.0
var silenciado := 0.0
var fila_misseis = null
var buraco_negro = null
var parasitas := 0
var coleta_instantanea := false
var fenix_usada := false
## Quantas recompras (relíquia Contrato de Recompra) já foram gastas nesta onda.
var recompras_usadas := 0
## Renascimentos extras (relíquia Vela do Segundo Fôlego) gastos nesta onda.
var revives_usados := 0
var tempo_autosave := 0.0
var tempo_autohab := 0.0
var tempo_autocompra := 0.0
var tempo_amostra := 0.0
var tempo_evento := 0.0
var media_seg_por_onda := 18.0
var pontos_conquista := 0
var relatorio_offline := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Dados.carregar()
	stats = StatEngine.new()
	s = GameState.novo()
	# Quem congela o tempo e a simulacao, entao o pedido tem que chegar aqui.
	# Ficava sem ouvinte: a Purga pedia hitstop e nada acontecia.
	Bus.hitstop_pedido.connect(hitstop_ms)
	# a UI chama iniciar() quando a cena principal estiver pronta
	set_physics_process(false)

## ============================================================== boot ====

## Ligado quando o boot encontrou save e não conseguiu ler. Enquanto estiver
## ligado, `salvar()` não escreve nada: o arquivo ilegível continua no disco,
## intacto, esperando alguém decidir o que fazer com ele.
var salvamento_travado := false

func iniciar() -> void:
	if iniciado:
		return
	var salvo := SaveSys.carregar()
	if salvo.is_empty():
		s = GameState.novo()
		s["criado_em"] = int(Time.get_unix_time_from_system())
		s["tick_em"] = s["criado_em"]
		# "Não existe save" e "existe e não consigo ler" davam no mesmo lugar:
		# tela de tutorial, e o autosave sobrescrevendo os dois arquivos vinte
		# segundos depois. Quem só precisava fechar o jogo e pedir ajuda perdia
		# tudo em silêncio. Agora o jogo avisa, e desliga o autosave até a
		# pessoa decidir — recomeçar apaga, e apagar tem que ser escolha dela.
		if SaveSys.falhou_ao_ler:
			salvamento_travado = true
			Bus.save_ilegivel.emit(SaveSys.ultimo_erro)
	else:
		s = GameState.mesclar(GameState.novo(), salvo)

	arena.redimensionar(1280.0, 720.0)
	torre = TorreSim.new(self)
	diretor = Diretor.new(self)

	marcar_sujo()
	recalcular()
	Habilidades.desbloquear_por_progresso(s)
	Progresso.gerar_missoes(self)
	sincronizar_torre(true)

	# Progresso offline, com âncora que só anda para a frente.
	#
	# `tick_em` é o relógio do sistema, e o relógio do sistema é do jogador:
	# adiantá-lo pagava o teto offline quantas vezes ele quisesse, e atrasá-lo
	# dava um `fora` negativo que empurrava a âncora para trás e apagava tempo
	# real em silêncio. O `maxi` mantém a âncora monotônica: relógio para trás
	# não paga nada e não estraga nada; relógio para a frente paga uma vez e a
	# âncora avança junto, então a segunda vez não paga de novo.
	var agora := int(Time.get_unix_time_from_system())
	var ancora := int(s.get("tick_em", agora))
	var fora := float(agora - ancora)
	if fora > Bal.OFFLINE_MIN_SEG and not salvo.is_empty():
		relatorio_offline = Offline.calcular(self, fora)
		if bool(relatorio_offline.get("aplicado", false)):
			Bus.relatorio_offline.emit(relatorio_offline)
	s["tick_em"] = maxi(ancora, agora)

	# A Retomada é uma explosão de 6× logo depois do prestígio, e o estado dela
	# ia para o save. Quem fechava o jogo no meio voltava DENTRO de uma Retomada
	# sem velocidade nenhuma (a velocidade mora no nó, não no estado) e com a
	# compra automática ligada à força. Encerrar na abertura devolve tudo ao
	# lugar; a explosão vale a sessão em que aconteceu.
	if Mecanicas.em_retomada(s):
		Mecanicas.encerrar_retomada(self)

	# "Nesta sessão" era persistido e nunca zerado: o painel de Estatísticas
	# mostrava o tempo de vida inteiro do save numa linha que promete a sessão.
	s["stats"]["tempo_sessao"] = 0.0

	# A velocidade escolhida era gravada e nunca reaplicada: o painel mostrava
	# ×3 e o jogo rodava a ×1.
	definir_velocidade(float(s["auto"].get("velocidade", 1.0)))

	diretor.iniciar_onda(int(s["onda"]))
	iniciado = true
	set_physics_process(true)
	Bus.jogo_pronto.emit()

## ========================================================== atributos ====

func marcar_sujo() -> void:
	sujo = true

func recalcular() -> void:
	if not sujo:
		return
	var r := Mods.recalcular(s, stats)
	esp = r["especiais"]
	pas = r["passivas"]
	pontos_conquista = int(r["pontos_conquista"])
	sujo = false
	sincronizar_torre(false)
	_aplicar_mods_desafio()

func _aplicar_mods_desafio() -> void:
	# `densidade` e `ondaAuto` estavam anunciados no painel de Desafios e nunca
	# eram lidos por ninguém: o desafio Enxame prometia 5× mais inimigos e a
	# Esteira prometia a onda avançando sozinha; os dois entregavam uma partida
	# normal com o texto mentindo na tela.
	mods_dif = {
		"hpInimigo": float(esp.get("hpInimigo", 1.0)), "velocidadeInimigo": 1.0,
		"ouro": 1.0, "danoTorre": 1.0, "xp": 1.0, "densidade": 1.0, "ondaAuto": 0.0,
	}
	var id := str(s["desafios"]["ativo"])
	if id == "":
		return
	var d: Dictionary = Dados.desafio_por_id.get(id, {})
	var m: Dictionary = d.get("mods", {})
	mods_dif["hpInimigo"] *= float(m.get("hpInimigo", 1.0))
	mods_dif["velocidadeInimigo"] *= float(m.get("velocidadeInimigo", 1.0))
	mods_dif["ouro"] *= float(m.get("ouro", 1.0))
	mods_dif["danoTorre"] *= float(m.get("danoTorre", 1.0))
	mods_dif["xp"] *= float(m.get("xp", 1.0))
	mods_dif["densidade"] *= float(m.get("densidade", 1.0))
	mods_dif["ondaAuto"] = float(m.get("ondaAuto", 0.0))

func sincronizar_torre(cheia: bool) -> void:
	var t: Dictionary = s["torre"]
	var novo_max := stats.b("vidaMax")
	if Big.is_zero(novo_max):
		return
	# escudo como parcela da vida máxima — ver Bal.ESCUDO_POR_PONTO
	var esc_max := Big.mul_f(Big.mul(stats.b("escudoMax"), novo_max), Bal.ESCUDO_POR_PONTO)
	var frac_antes := Big.frac(t["vida"], t["vida_max"])
	var did := str(s["desafios"]["ativo"])
	if did != "":
		var vf := float(Dados.desafio_por_id.get(did, {}).get("mods", {}).get("vidaFixa", 0.0))
		if vf > 0.0:
			novo_max = Big.from(vf)
	t["vida_max"] = novo_max
	t["escudo_max"] = esc_max
	if cheia:
		t["vida"] = novo_max
		t["escudo"] = esc_max
	else:
		t["vida"] = Big.min_b(novo_max, Big.max_b(t["vida"], Big.mul_f(novo_max, minf(1.0, frac_antes))))
		t["escudo"] = Big.min_b(t["escudo"], esc_max)

## =============================================================== loop ====

func _process(delta: float) -> void:
	if hitstop > 0.0:
		hitstop -= delta

func _physics_process(dt: float) -> void:
	if not iniciado or pausado or hitstop > 0.0:
		return
	simular(dt)

func simular(dt: float) -> void:
	recalcular()

	var st: Dictionary = s["stats"]
	st["tempo_total"] = float(st["tempo_total"]) + dt
	st["tempo_sessao"] = float(st["tempo_sessao"]) + dt

	# Combo esfria — a não ser com a Ampulheta Rachada, cuja passiva
	# `combo_imortal` promete "o combo nunca expira por tempo: só zera quando a
	# torre leva dano". A promessa estava no JSON e ninguém a lia.
	var combo: Dictionary = s["combo"]
	if int(combo["atual"]) > 0 and not pas.has("combo_imortal"):
		combo["timer"] = float(combo["timer"]) - dt
		if float(combo["timer"]) <= 0.0:
			combo["atual"] = 0
			Bus.combo_quebrou.emit()
			if pas.has("sede_de_sangue"):
				marcar_sujo()

	# buffs
	if not s["buffs"].is_empty():
		var mudou := false
		for i in range(s["buffs"].size() - 1, -1, -1):
			var b: Dictionary = s["buffs"][i]
			b["restante"] = float(b["restante"]) - dt
			if float(b["restante"]) <= 0.0:
				s["buffs"].remove_at(i)
				mudou = true
		if mudou:
			marcar_sujo()

	Mecanicas.atualizar_purga(dt, self)
	Mecanicas.atualizar_retomada(dt, self)
	Mecanicas.decair_adaptacao(dt, self.s)

	Combate.atualizar_status(dt, self)
	EnemyAI.atualizar(dt, self)
	# A grade se reconstrói DEPOIS do movimento. Antes vinha primeiro, então a
	# torre e o dano em área consultavam posições de um quadro atrás: quem
	# tivesse acabado de mudar de célula (e o teleporte muda sempre) ficava
	# invisível para o splash. De quebra, a contagem de vivos que o diretor usa
	# para fechar a onda passa a ser a deste quadro.
	arena.reconstruir_grade()
	torre.atualizar(dt)
	torre.atualizar_projeteis(dt)
	Economia.atualizar_coletaveis(dt, self)
	Habilidades.atualizar(dt, self)
	diretor.atualizar(dt)
	Eventos.atualizar(dt, self)

	parasitas = 0
	for e in arena.inimigos:
		if e.grudado:
			parasitas += 1

	# automação
	if bool(s["auto"]["comprar"]) and esp["desbloqueios"].has("autoCompra"):
		tempo_autocompra -= dt
		if tempo_autocompra <= 0.0:
			tempo_autocompra = Bal.INTERVALO_AUTOCOMPRA
			auto_comprar()
	# Quatro vezes por segundo basta: habilidades tem recarga de segundos, e a
	# checagem rodava a 60 Hz para quase sempre nao fazer nada.
	if bool(s["auto"]["habilidades"]) and esp["desbloqueios"].has("autoHabilidade"):
		tempo_autohab -= dt
		if tempo_autohab <= 0.0:
			tempo_autohab = 0.25
			Habilidades.auto_usar(self)
	if bool(s["prestigio"]["auto_ascender"]) and esp["desbloqueios"].has("autoAscensao"):
		if int(s["onda_maxima"]) >= int(s["prestigio"]["auto_ascender_onda"]) and Prestigio.pode_ascender(s):
			ascender(true)

	# conquistas e missões (a cada 0,5 s)
	tempo_amostra += dt
	if tempo_amostra >= 0.5:
		tempo_amostra = 0.0
		Progresso.checar_conquistas(self)
		Progresso.checar_missoes(self)

	# autosave
	tempo_autosave += dt
	if tempo_autosave >= float(Cfg.get_v("autosave_seg", 20.0)):
		tempo_autosave = 0.0
		salvar()

## ========================================================= callbacks ====

func soltar_ouro(e: Inimigo, valor: float) -> void:
	Economia.soltar_ouro(e, valor, self)

func ganhar_ouro(valor: float, fonte: String = "", silencioso: bool = false) -> void:
	Economia.ganhar_ouro(valor, self, fonte, silencioso)

func ganhar_xp(valor: float) -> void:
	Economia.ganhar_xp(valor, self)

## `v_log` em log10.
func curar_torre(v_log: float) -> void:
	var t: Dictionary = s["torre"]
	var antes := Big.frac(t["vida"], t["vida_max"])
	t["vida"] = Big.min_b(t["vida_max"], Big.add(t["vida"], v_log))
	# subir de novo acima de 30% também tem que desligar a Última Chama na hora
	if pas.has("ultima_chama") and (antes >= 0.3) != (Big.frac(t["vida"], t["vida_max"]) >= 0.3):
		marcar_sujo()

## `dano_log` em log10.
func dano_na_torre(dano_log: float, fonte, opt: Dictionary = {}) -> float:
	if invulneravel > 0.0:
		return Big.ZERO
	var antes := Big.frac(s["torre"]["vida"], s["torre"]["vida_max"])
	var r := torre.levar_dano(dano_log, fonte, opt)
	# Última Chama dobra o dano abaixo de 30% de vida, mas só era aplicada no
	# próximo recálculo de atributos — que acontece por outros motivos, em outra
	# hora. Cruzar o limiar (nos dois sentidos) agora força o recálculo na hora.
	if pas.has("ultima_chama"):
		var depois := Big.frac(s["torre"]["vida"], s["torre"]["vida_max"])
		if (antes >= 0.3) != (depois >= 0.3):
			marcar_sujo()
	return r

func reviver_torre() -> void:
	var t: Dictionary = s["torre"]
	t["viva"] = true
	t["vida"] = t["vida_max"]
	t["escudo"] = t["escudo_max"]
	invulneravel = 2.5
	fenix_usada = false
	arena.limpar_inimigos()
	# Contrato de Recompra: "ao cair, você mantém todo o ouro e não retrocede
	# ondas — 1 vez por onda, por nível". Também não era lido por ninguém.
	var recompras := int(pas.get("contrato_recompra", 0))
	if recompras > 0 and recompras_usadas < recompras:
		recompras_usadas += 1
		diretor.reiniciar_onda(0)
		Bus.toast(Txt.f("sim_recompra", {"n": recompras - recompras_usadas}), "bom", "escudo")
	else:
		diretor.reiniciar_onda(Bal.PENALIDADE_MORTE)
	Bus.torre_renasceu.emit()

func impacto_na_torre(e: Inimigo) -> void:
	var dano := Bal.dano_contato(e.hp_max, int(s["onda"]), e.chefe, e.escala)
	dano_na_torre(dano, e)
	Bus.inimigo_chegou.emit(e, dano)

	var espinhos := stats.n("espinhos")
	if espinhos > 0.0:
		Combate.aplicar_dano(e, Big.mul_f(stats.b("dano"), espinhos * 6.0), self, {"puro": true})
	if e.hab == "explodir":
		Bus.particulas.emit("explosao", e.pos, {"raio": float(e.def.get("raio", 110.0)), "cor": "#fb923c"})
	if not e.chefe:
		e.morrendo = 0.2
		e.hp = Big.ZERO
	s["combo"]["atual"] = 0
	Bus.combo_quebrou.emit()

func ao_morrer_inimigo(e: Inimigo, critico: bool) -> void:
	if e.peregrino:
		if not e.saiu:
			Mecanicas.peregrino_morto(self)
		return
	# A Purga promete no proprio comentario da constante que "cada abate adianta
	# a carga". A constante existia desde sempre e ninguem a lia: a carga so
	# andava pelo relogio, entao o acoplamento Combate -> Purga era ficcao. Com
	# isso, matar rapido passa a valer Purga mais cedo, que e o que o jogo diz.
	Mecanicas.creditar_abate_purga(self)
	Saque.tentar_drop(e, self)
	if e.def.has("divide") and not e.dividido:
		EnemyAI.dividir(e, self)
	if e.elite_mod == "volatil" or str(e.def.get("hab", "")) == "explodir":
		Combate.dano_area(e.pos, float(e.def.get("raio", 100.0)), Big.mul_f(e.hp_max, 0.35), self, {"queda": true})
		Bus.particulas.emit("explosao", e.pos, {"raio": float(e.def.get("raio", 100.0)), "cor": "#fb923c"})
	if pas.has("colapso"):
		Combate.dano_area(e.pos, 90.0, Big.mul_f(e.hp_max, 0.05 * float(pas["colapso"])), self, {})

func projetil_inimigo(e: Inimigo) -> void:
	var p: Projetil = arena.novo_projetil()
	var ang := (arena.centro - e.pos).angle()
	p.ativo = true
	p.pos = e.pos
	p.velocidade = 220.0
	p.ang = ang
	p.vel = Vector2(cos(ang), sin(ang)) * p.velocidade
	p.raio = 5.0
	p.vida = 6.0
	p.cor = Color.html("#fb7185")
	p.tipo = "acido"
	p.origem = "inimigo"
	p.dano_torre = Big.mul_f(Bal.dano_contato(Bal.hp_onda(int(s["onda"])), int(s["onda"]), false, 1.0), 0.6)

func atualizar_chefe(e: Inimigo, dt: float) -> void:
	var fases := maxi(1, int(e.def.get("fases", 1)))
	if fases > 1:
		var frac := e.frac_vida()
		var fase_alvo := mini(fases - 1, int(floor((1.0 - frac) * float(fases))))
		if fase_alvo > e.fase:
			e.fase = fase_alvo
			e.atordoado = maxf(e.atordoado, 0.6)
			Bus.chefe_fase.emit(e, e.fase)
			Bus.particulas.emit("pulso", e.pos, {"raio": 140.0, "cor": e.cor})
			tremor(14.0, 0.35)
	match str(e.def.get("mecanica", "")):
		"onda_choque":
			e.cd -= dt
			if e.cd <= 0.0:
				e.cd = maxf(2.0, 5.0 - float(e.fase))
				dano_na_torre(Bal.mul_contato(e, int(s["onda"]), 1.6), e)
				Bus.particulas.emit("pulso", e.pos, {"raio": 260.0, "cor": "#fb923c"})
				tremor(10.0, 0.3)
		"escudo_regen":
			if e.sem_dano_t > 1.5:
				var teto := Big.max_b(e.escudo_max, Big.mul_f(e.hp_max, 0.3))
				e.escudo = Big.min_b(teto, Big.add(e.escudo, Big.mul_f(e.hp_max, 0.06 * dt)))
		"silenciar":
			e.cd -= dt
			if e.cd <= 0.0:
				e.cd = 12.0
				silenciado = 5.0
				Bus.toast(Txt.t("sim_silencio"), "ruim", "cadeado")
		"teleporte_drenar":
			e.cd -= dt
			if e.cd <= 0.0:
				e.cd = 7.0
				e.pos = arena.centro + Vector2(cos(e.dir_ang), sin(e.dir_ang)) * (Bal.RAIO_TORRE + 60.0)
				dano_na_torre(Bal.mul_contato(e, int(s["onda"]), 2.0), e)
				e.hp = Big.min_b(Big.add(e.hp, Big.mul_f(e.hp_max, 0.05)), e.hp_max)
		"fissuras":
			e.cd -= dt
			if e.cd <= 0.0:
				e.cd = 6.0
				Bus.particulas.emit("fissura", e.pos, {"cor": "#a855f7"})
				invulneravel = maxf(0.0, invulneravel - 0.5)

func adicionar_buff(b: Dictionary) -> void:
	for existente in s["buffs"]:
		if str(existente["id"]) == str(b["id"]):
			existente["restante"] = maxf(float(existente["restante"]), float(b["restante"]))
			existente["valor"] = b["valor"]
			marcar_sujo()
			return
	s["buffs"].append(b)
	marcar_sujo()

func recompensa_de_onda(onda: int) -> void:
	Economia.recompensa_onda(onda, self)
	Mecanicas.talvez_peregrino(onda + 1, self)
	fenix_usada = false
	if pas.has("imortal_pos_onda"):
		invulneravel = maxf(invulneravel, 2.0)
	var t := float(s["tempo_na_onda"])
	if t > 0.5:
		media_seg_por_onda = lerpf(media_seg_por_onda, t, 0.15)
		s["seg_por_onda_media"] = media_seg_por_onda
	Bus.ui_atualizar.emit(false)

func tremor(amp: float, dur: float) -> void:
	Bus.tremor_pedido.emit(amp * Cfg.forca_tremor(), dur)

func hitstop_ms(ms: float) -> void:
	hitstop = maxf(hitstop, minf(0.2, ms / 1000.0))

func camera_lenta(escala: float, ms: float) -> void:
	Bus.camera_lenta.emit(escala, ms)

## ============================================================= ações ====

func custo_upgrade(def: Dictionary, nivel: int) -> float:
	return Big.custo(float(def.get("base", 1)), float(def.get("cresc", 1.1)), nivel)

func max_upgrade(def: Dictionary, nivel: int) -> int:
	var maxn := int(def.get("max", -1))
	var teto := 1000000 if maxn < 0 else maxn - nivel
	if teto <= 0:
		return 0
	return mini(teto, Big.max_afford(s["moedas"]["ouro"], float(def.get("base", 1)), float(def.get("cresc", 1.1)), nivel))

func upgrade_disponivel(def: Dictionary) -> bool:
	var r = def.get("requer", null)
	if not (r is Dictionary):
		return true
	if r.has("onda") and int(s["onda_maxima_global"]) < int(r["onda"]):
		return false
	if r.has("upgrade") and int(s["upgrades"].get(str(r["upgrade"]), 0)) <= 0:
		return false
	if r.has("nivel") and int(s["nivel"]) < int(r["nivel"]):
		return false
	return true

func comprar_upgrade(id: String, qtd = 1) -> int:
	var def: Dictionary = Dados.upgrade_por_id.get(id, {})
	if def.is_empty() or not upgrade_disponivel(def):
		return 0
	if str(s["desafios"]["ativo"]) != "" and bool(Dados.desafio_por_id.get(s["desafios"]["ativo"], {}).get("mods", {}).get("semUpgrades", false)):
		return 0
	var nivel := int(s["upgrades"].get(id, 0))
	var maxn := int(def.get("max", -1))
	if maxn >= 0 and nivel >= maxn:
		return 0
	var n := 0
	if typeof(qtd) == TYPE_STRING and str(qtd) == "max":
		n = max_upgrade(def, nivel)
	else:
		n = int(qtd)
		if maxn >= 0:
			n = mini(n, maxn - nivel)
	if n <= 0:
		return 0
	var custo := Big.geo_sum(float(def.get("base", 1)), float(def.get("cresc", 1.1)), nivel, n)
	if not Economia.gastar_ouro(custo, self):
		return 0
	s["upgrades"][id] = nivel + n
	marcar_sujo()
	recalcular()
	Bus.upgrade_comprado.emit(id, n, nivel + n)
	return n

func auto_comprar() -> void:
	var modo := str(s["auto"]["comprar_modo"])
	var melhor: Dictionary = {}
	var melhor_custo := INF
	for def in Dados.upgrades:
		if not upgrade_disponivel(def):
			continue
		var id := str(def.get("id", ""))
		var nivel := int(s["upgrades"].get(id, 0))
		var maxn := int(def.get("max", -1))
		if maxn >= 0 and nivel >= maxn:
			continue
		if modo == "prioridade" and not bool(def.get("destaque", false)) and not melhor.is_empty():
			continue
		var c := custo_upgrade(def, nivel)
		if Big.lte(c, s["moedas"]["ouro"]) and c < melhor_custo:
			melhor_custo = c
			melhor = def
	if melhor.is_empty():
		return
	# Comprar 1 nivel por vez parece prudente e e o contrario disso: no meio do
	# jogo o ouro chega a 1e70 e a compra automatica so consegue gastar tres
	# niveis por segundo, entao a economia inteira vira enfeite. Compramos o
	# maximo que cabe numa FATIA do ouro — sobra dinheiro para as proximas
	# melhorias e o progresso acompanha o que o jogador ganha.
	var orcamento := Big.mul_f(s["moedas"]["ouro"], Bal.FATIA_AUTOCOMPRA)
	var id_alvo := str(melhor["id"])
	var nivel_alvo := int(s["upgrades"].get(id_alvo, 0))
	var maxn_alvo := int(melhor.get("max", -1))
	var teto := 1000000 if maxn_alvo < 0 else maxn_alvo - nivel_alvo
	var quantos := mini(teto, Big.max_afford(
		orcamento, float(melhor.get("base", 1)), float(melhor.get("cresc", 1.1)), nivel_alvo))
	comprar_upgrade(id_alvo, maxi(1, quantos))

func custo_talento(def: Dictionary, nivel: int) -> int:
	return int(def.get("custo", 1)) + nivel / 5

func talento_liberado(def: Dictionary) -> bool:
	var req = def.get("requer", null)
	if not (req is Array):
		return true
	for id in req:
		if int(s["talentos"].get(str(id), 0)) <= 0:
			return false
	return true

func comprar_talento(id: String) -> bool:
	var def: Dictionary = Dados.talento_por_id.get(id, {})
	if def.is_empty() or not talento_liberado(def):
		return false
	var nivel := int(s["talentos"].get(id, 0))
	var maxn := int(def.get("max", 1))
	if nivel >= maxn:
		return false
	var custo := custo_talento(def, nivel)
	if int(s["pontos_talento"]) < custo:
		return false
	s["pontos_talento"] = int(s["pontos_talento"]) - custo
	s["pontos_talento_gastos"] = int(s["pontos_talento_gastos"]) + custo
	s["talentos"][id] = nivel + 1
	marcar_sujo()
	recalcular()
	Bus.talento_comprado.emit(id, nivel + 1)
	return true

func redistribuir_talentos(custo_gemas: float = 50.0) -> bool:
	if not Economia.gastar_moeda("gemas", Big.from(custo_gemas), self):
		return false
	s["pontos_talento"] = int(s["pontos_talento"]) + int(s["pontos_talento_gastos"])
	s["pontos_talento_gastos"] = 0
	s["talentos"] = {}
	marcar_sujo()
	recalcular()
	return true

func comprar_no(id: String, qtd = 1) -> int:
	var def: Dictionary = Dados.no_por_id.get(id, {})
	if def.is_empty():
		return 0
	var camada := str(Dados.camada_do_no.get(id, "fragmentos"))
	var chave_tabela := "arvore_" + camada
	var tabela: Dictionary = s["prestigio"][chave_tabela]
	var nivel := int(tabela.get(id, 0))
	var maxn := int(def.get("max", -1))
	if maxn >= 0 and nivel >= maxn:
		return 0
	var n := 0
	if typeof(qtd) == TYPE_STRING and str(qtd) == "max":
		n = Prestigio.max_compravel_no(def, nivel, s["moedas"][camada])
	else:
		n = int(qtd)
		if maxn >= 0:
			n = mini(n, maxn - nivel)
	if n <= 0:
		return 0
	var custo := Big.geo_sum(float(def.get("base", 1)), float(def.get("cresc", 1.5)), nivel, n)
	if not Economia.gastar_moeda(camada, custo, self):
		return 0
	tabela[id] = nivel + n
	marcar_sujo()
	recalcular()
	Bus.upgrade_comprado.emit(id, n, nivel + n)
	return n

func comprar_reliquia(id: String, qtd: int = 1) -> int:
	var def: Dictionary = Dados.reliquia_por_id.get(id, {})
	if def.is_empty():
		return 0
	var moeda := str(def.get("moeda", "fragmentos"))
	var nivel := int(s["relicas"].get(id, 0))
	var maxn := int(def.get("max", 1))
	if maxn >= 0 and nivel >= maxn:
		return 0
	var n := mini(qtd, maxn - nivel) if maxn >= 0 else qtd
	if n <= 0:
		return 0
	var custo := Big.geo_sum(float(def.get("base", 1)), float(def.get("cresc", 1.6)), nivel, n)
	if not Economia.gastar_moeda(moeda, custo, self):
		return 0
	s["relicas"][id] = nivel + n
	marcar_sujo()
	recalcular()
	return n

func usar_habilidade(id: String) -> bool:
	if id == "purga":
		return Mecanicas.disparar_purga(self, false)
	return Habilidades.usar(id, self)

## A Purga: a única ação que exige o jogador (e recompensa o timing).
func purgar() -> bool:
	return Mecanicas.disparar_purga(self, false)

func melhorar_habilidade(id: String) -> bool:
	var def: Dictionary = Dados.habilidade_por_id.get(id, {})
	if def.is_empty():
		return false
	var h := GameState.hab(s, id)
	if not bool(h["desbloqueada"]) or int(h["nivel"]) >= Dados.nivel_max_habilidade:
		return false
	var custo := Habilidades.custo_melhoria(def, int(h["nivel"]))
	if not Economia.gastar_moeda("gemas", Big.from(custo), self):
		return false
	h["nivel"] = int(h["nivel"]) + 1
	Bus.ui_atualizar.emit(false)
	return true

func definir_mira(modo: String) -> void:
	s["torre"]["mira"] = modo

func alternar_farm(onda: int = -1) -> bool:
	if not esp["desbloqueios"].has("modoFarm"):
		return false
	s["modo_farm"] = not bool(s["modo_farm"])
	if bool(s["modo_farm"]):
		s["onda_farm"] = int(s["onda"]) if onda < 0 else onda
	return bool(s["modo_farm"])

## Liga e desliga o Modo Infinito. Sai do modo Farm ao entrar: travar a onda e
## nunca parar de avancar sao a mesma decisao tomada em dois sentidos opostos.
func alternar_infinito() -> bool:
	if not esp["desbloqueios"].has("modoInfinito"):
		return false
	var ligado := not bool(s.get("modo_infinito", false))
	s["modo_infinito"] = ligado
	if ligado:
		s["modo_farm"] = false
	marcar_sujo()
	Bus.ui_atualizar.emit(false)
	Bus.toast(Txt.t("infinito_ligado" if ligado else "infinito_desligado"), "epico", "nova")
	return ligado

func definir_velocidade(v: float) -> void:
	var teto := maxf(1.0, float(esp.get("velocidadeMax", 1.0)))
	velocidade = clampf(v, 1.0, teto)
	s["auto"]["velocidade"] = velocidade
	Engine.time_scale = velocidade

## ========================================================= prestígio ====

func ascender(auto: bool = false) -> bool:
	if not Prestigio.pode_ascender(s):
		return false
	var ganho := Prestigio.previa_fragmentos(self)
	s["moedas"]["fragmentos"] = Big.add(s["moedas"]["fragmentos"], ganho)
	s["prestigio"]["ascensoes"] = int(s["prestigio"]["ascensoes"]) + 1
	s["prestigio"]["ultima_onda_asc"] = int(s["onda_maxima"])
	s["prestigio"]["melhor_ascensao"] = maxi(int(s["prestigio"]["melhor_ascensao"]), int(s["onda_maxima"]))
	_resetar_run()
	Bus.prestigio_feito.emit("ascensao", ganho)
	return true

func colapsar() -> bool:
	if not Prestigio.pode_colapsar(s):
		return false
	var ganho := Prestigio.previa_nucleos(self)
	s["moedas"]["nucleos"] = Big.add(s["moedas"]["nucleos"], ganho)
	s["prestigio"]["singularidades"] = int(s["prestigio"]["singularidades"]) + 1
	s["moedas"]["fragmentos"] = Big.ZERO
	s["prestigio"]["arvore_fragmentos"] = {}
	s["prestigio"]["ascensoes"] = 0
	s["talentos"] = {}
	s["pontos_talento_gastos"] = 0
	_resetar_run()
	Bus.prestigio_feito.emit("singularidade", ganho)
	return true

func transcender() -> bool:
	if not Prestigio.pode_transcender(s):
		return false
	var ganho := Prestigio.previa_eter(self)
	# A Transcendência monta um estado NOVO — então tudo que precisa sobreviver
	# tem que estar listado aqui. O Álbum e o Panteão prometem, na própria
	# documentação, ser "imunes a todos os prestígios"; ficavam de fora e eram
	# apagados. O tutorial e as conquistas vistas também: ninguém quer refazer
	# o tutorial nem rever comemoração antiga.
	var guardar := {
		"eter": Big.add(s["moedas"]["eter"], ganho),
		"arvore_eter": s["prestigio"]["arvore_eter"],
		"transcendencias": int(s["prestigio"]["transcendencias"]) + 1,
		"conquistas": s["conquistas"],
		"conquistas_vistas": s["conquistas_vistas"],
		"codex": s["codex"],
		"stats": s["stats"],
		"onda_global": int(s["onda_maxima_global"]),
		"criado_em": int(s["criado_em"]),
		"temporada": s["temporada"],
		"album": s.get("album", {}),
		"panteao": s.get("panteao", {}),
		# O placar do Peregrino decide o Fim Verdadeiro: "o jogo só conta, para
		# sempre". Sem estas três linhas a tela final lia 0 × 0 depois de
		# transcender. A Caixa da Vigília e o total de missões são igualmente
		# vitalícios.
		"peregrinos_mortos": int(s.get("peregrinos_mortos", 0)),
		"peregrinos_poupados": int(s.get("peregrinos_poupados", 0)),
		"missoes_completas": int(s.get("missoes_completas", 0)),
		"caixa": s.get("caixa", {"seladas": 0, "abertas": 0}),
		# bônus permanentes vêm de missões e conquistas, que também sobrevivem
		"bonus_permanentes": s.get("bonus_permanentes", []),
		"desbloqueios": s["desbloqueios"],
		"tutorial": s["tutorial"],
		"novidades": s["novidades"],
	}
	s = GameState.novo()
	s["moedas"]["eter"] = guardar["eter"]
	s["prestigio"]["arvore_eter"] = guardar["arvore_eter"]
	s["prestigio"]["transcendencias"] = guardar["transcendencias"]
	s["conquistas"] = guardar["conquistas"]
	s["conquistas_vistas"] = guardar["conquistas_vistas"]
	s["codex"] = guardar["codex"]
	s["stats"] = guardar["stats"]
	s["onda_maxima_global"] = guardar["onda_global"]
	s["criado_em"] = guardar["criado_em"]
	s["temporada"] = guardar["temporada"]
	s["album"] = guardar["album"]
	s["panteao"] = guardar["panteao"]
	s["peregrinos_mortos"] = guardar["peregrinos_mortos"]
	s["peregrinos_poupados"] = guardar["peregrinos_poupados"]
	s["missoes_completas"] = guardar["missoes_completas"]
	s["caixa"] = guardar["caixa"]
	s["bonus_permanentes"] = guardar["bonus_permanentes"]
	s["desbloqueios"] = guardar["desbloqueios"]
	s["tutorial"] = guardar["tutorial"]
	s["novidades"] = guardar["novidades"]
	_resetar_run()
	Bus.prestigio_feito.emit("transcendencia", ganho)
	return true

func _resetar_run() -> void:
	var onda_anterior := int(s["onda_maxima"])
	Mecanicas.encerrar_retomada(self)
	# Testamento Dourado: "ao Ascender, você herda 8% do seu ouro por nível".
	# A relíquia existia, o texto prometia, e o ouro era zerado assim mesmo.
	var frac_herdada := minf(0.8, float(pas.get("heranca_dourada:valor", 0.0)) * float(pas.get("heranca_dourada", 0)))
	s["moedas"]["ouro"] = Big.mul_f(s["moedas"]["ouro"], frac_herdada) if frac_herdada > 0.0 else Big.ZERO
	s["upgrades"] = {}
	s["nivel"] = 1
	s["xp"] = Big.ZERO
	s["buffs"] = []
	s["combo"] = {"atual": 0, "melhor": 0, "timer": 0.0}
	s["modo_farm"] = false
	s["desafios"]["ativo"] = ""
	# Estado volátil da run anterior. Ascender com o tempo congelado, silenciado
	# ou com um buraco negro na tela deixava tudo isso ligado na run nova.
	tempo_congelado = 0.0
	silenciado = 0.0
	hitstop = 0.0
	fila_misseis = null
	buraco_negro = null
	parasitas = 0
	coleta_instantanea = false
	arena.limpar_tudo()
	torre = TorreSim.new(self)
	diretor = Diretor.new(self)
	marcar_sujo()
	recalcular()

	var inicio := maxi(1, 1 + int(esp.get("ondaInicial", 0)))
	s["onda"] = inicio
	s["onda_maxima"] = inicio
	if inicio > int(s["onda_maxima_global"]):
		s["onda_maxima_global"] = inicio
	# Os pontos seguem a arvore. Aqui devolvia TODOS os pontos ja gastos sem
	# limpar `talentos` nem `pontos_talento_gastos`: quem ascendia ficava com a
	# arvore comprada E com os pontos de volta na mao. Entrar e sair de um
	# desafio faz o mesmo caminho, entao dava para dobrar os pontos em segundos
	# e maxar a arvore inteira de graca — o que tambem apagava o sentido do
	# respec pago de 50 gemas em `redistribuir_talentos`. A Ascensao mantem os
	# talentos (nao estao no `resetaTexto`), entao ela nao devolve nada; quem
	# limpa a arvore — `colapsar` — ja zera os gastos antes de chegar aqui.
	s["pontos_talento"] = int(esp.get("pontosTalento", 0))
	sincronizar_torre(true)
	Habilidades.desbloquear_por_progresso(s)
	diretor.iniciar_onda(inicio)
	fenix_usada = false
	invulneravel = 3.0
	Mecanicas.iniciar_retomada(self, onda_anterior)
	Bus.ui_atualizar.emit(true)

## ============================================================ desafios ====

func iniciar_desafio(id: String) -> bool:
	if not esp["desbloqueios"].has("desafios"):
		return false
	var d: Dictionary = Dados.desafio_por_id.get(id, {})
	if d.is_empty():
		return false
	s["desafios"]["ativo"] = id
	s["desafios"]["tentativas"][id] = int(s["desafios"]["tentativas"].get(id, 0)) + 1
	_resetar_run()
	Bus.desafio_iniciado.emit(id)
	return true

func encerrar_desafio(vitoria: bool) -> void:
	var id := str(s["desafios"]["ativo"])
	if id == "":
		return
	if vitoria:
		s["desafios"]["completos"][id] = int(Time.get_unix_time_from_system())
		Bus.desafio_concluido.emit(id)
	s["desafios"]["ativo"] = ""
	_resetar_run()

## ================================================================ save ====

func salvar() -> bool:
	# Trancado quando o boot achou save ilegível: gravar por cima seria apagar
	# o que talvez ainda dê para recuperar. Destrancar é decisão de quem joga.
	if salvamento_travado:
		return false
	var agora := int(Time.get_unix_time_from_system())
	s["salvo_em"] = agora
	# a âncora do offline nunca anda para trás (ver `iniciar`)
	s["tick_em"] = maxi(int(s.get("tick_em", agora)), agora)
	return SaveSys.salvar(s)

func exportar() -> String:
	s["salvo_em"] = int(Time.get_unix_time_from_system())
	return SaveSys.exportar(s)

func importar(texto: String) -> bool:
	var novo := SaveSys.importar(texto)
	if novo.is_empty():
		return false
	s = GameState.mesclar(GameState.novo(), novo)
	arena.limpar_tudo()
	torre = TorreSim.new(self)
	diretor = Diretor.new(self)
	marcar_sujo()
	recalcular()
	sincronizar_torre(true)
	diretor.iniciar_onda(int(s["onda"]))
	Bus.ui_atualizar.emit(true)
	return true

func apagar_tudo() -> void:
	SaveSys.apagar()
	s = GameState.novo()
	s["criado_em"] = int(Time.get_unix_time_from_system())
	arena.limpar_tudo()
	torre = TorreSim.new(self)
	diretor = Diretor.new(self)
	marcar_sujo()
	recalcular()
	sincronizar_torre(true)
	Progresso.gerar_missoes(self, true)
	diretor.iniciar_onda(1)
	Bus.ui_atualizar.emit(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if iniciado:
			salvar()
