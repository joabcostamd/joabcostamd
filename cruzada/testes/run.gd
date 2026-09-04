extends SceneTree
## Suíte da run e do perfil: o encadeamento das 18 mesas, as 3 vidas, a gravação
## e as condições de desbloqueio.
##
##     godot --headless --script res://testes/run.gd

var _passou := 0
var _falhou := 0

func _init() -> void:
    _encadeamento()
    _vidas()
    _contagens()
    _perfil()
    _desbloqueios()

    print("")
    if _falhou > 0:
        print("RUN: %d de %d asserções FALHARAM" % [_falhou, _passou + _falhou])
        quit(1)
        return
    print("RUN OK — %d asserções" % _passou)
    quit(0)

func secao(nome: String) -> void:
    print("── %s" % nome)

func ok(condicao: bool, descricao: String) -> void:
    if condicao:
        _passou += 1
    else:
        _falhou += 1
        print("   FALHA  %s" % descricao)

func igual(obtido: Variant, esperado: Variant, descricao: String) -> void:
    if obtido == esperado:
        _passou += 1
    else:
        _falhou += 1
        print("   FALHA  %s — obtive %s, esperava %s"
              % [descricao, str(obtido), str(esperado)])

## Termina a mesa da run com o resultado pedido, sem jogá-la.
func encerrar(r: Run, venceu: bool) -> Dictionary:
    r.mesa.acabou = true
    r.mesa.venceu = venceu
    return r.concluir_mesa()

# ─────────────────────── o encadeamento das mesas ───────────────────────

func _encadeamento() -> void:
    secao("as 18 mesas da run")
    var r := Run.new(31337)
    igual(r.rodada, 1, "a run começa na rodada 1")
    igual(r.indice_da_mesa, Metas.PEQUENA, "e na mesa Pequena")
    igual(r.vidas, 3, "com 3 vidas")
    igual(r.total_de_mesas(), 18, "são 18 mesas: 6 rodadas de 3")
    igual(r.mesa.meta, Metas.meta(Metas.PEQUENA, 1), "a mesa carrega a meta certa")

    encerrar(r, true)
    igual(r.indice_da_mesa, Metas.GRANDE, "vencer a Pequena leva à Grande")
    igual(r.rodada, 1, "sem trocar de rodada")
    encerrar(r, true)
    igual(r.indice_da_mesa, Metas.CHEFE, "e depois ao Chefe")
    var passagem := encerrar(r, true)
    igual(r.rodada, 2, "vencer o Chefe abre a rodada 2")
    igual(r.indice_da_mesa, Metas.PEQUENA, "de novo na Pequena")
    ok(not bool(passagem["fim_da_run"]), "e a run continua")
    igual(r.mesas_concluidas(), 3, "três mesas concluídas")
    igual(r.mesa.meta, Metas.meta(Metas.PEQUENA, 2), "a meta subiu com a rodada")

    ## Vencer as 15 restantes fecha a run.
    var voltas := 0
    while not r.acabou and voltas < 40:
        voltas += 1
        encerrar(r, true)
    ok(r.acabou and r.venceu, "vencer as 18 mesas vence a run")
    igual(r.mesas_vencidas, 18, "com 18 mesas vencidas")
    igual(r.vidas, 3, "e sem gastar vida nenhuma")

# ─────────────────────────── R20 — as vidas ───────────────────────────

func _vidas() -> void:
    secao("derrota, vidas e repetição (R20)")
    var r := Run.new(480011)
    var baralho_antes := r.mesa.baralho.duplicate()

    var derrota := encerrar(r, false)
    igual(r.vidas, 2, "perder gasta uma vida")
    igual(r.rodada, 1, "e não avança a rodada")
    igual(r.indice_da_mesa, Metas.PEQUENA, "nem o tipo de mesa")
    ok(bool(derrota.get("repetindo", false)), "a mesa é repetida")
    igual(r.tentativa, 2, "na segunda tentativa")
    ok(r.mesa.baralho != baralho_antes,
       "com outro embaralhamento — não é a mesma mesa de novo")
    igual(r.mesa.meta, Metas.meta(Metas.PEQUENA, 1),
          "mas com a mesma meta: a dificuldade não é ressorteada")

    encerrar(r, false)
    igual(r.vidas, 1, "segunda derrota, segunda vida")
    var fim := encerrar(r, false)
    igual(r.vidas, 0, "terceira derrota gasta a última")
    ok(r.acabou and not r.venceu, "e a run acaba, perdida")
    ok(bool(fim["fim_da_run"]), "o relato diz que a run acabou")

    ## Vencer depois de perder zera a contagem de tentativas.
    var v := Run.new(7)
    encerrar(v, false)
    igual(v.tentativa, 2, "a tentativa subiu")
    encerrar(v, true)
    igual(v.tentativa, 1, "e volta a 1 ao vencer")
    igual(v.vidas, 2, "a vida gasta não volta")

# ────────────────────── o que a run vai contando ──────────────────────

func _contagens() -> void:
    secao("as contas da run")
    var r := Run.new(3)
    r.anotar_colheita({"colheita": true, "linhas": [
        {"linha": 0, "categoria": Maos.FLUSH},
        {"linha": 5, "categoria": Maos.SEQ_COR},
    ]})
    igual(int(r.categorias_feitas.get(Maos.SEQ_COR, 0)), 1,
          "a Sequência de Cor foi anotada")
    igual(r.maior_cruzada, 2, "a maior cruzada tem duas linhas")
    r.anotar_colheita({"colheita": false, "linhas": []})
    igual(r.maior_cruzada, 2, "turno sem colheita não anota nada")

    ## A CRUZADA DO CENTRO: as quatro linhas que passam pela casa central.
    var centro := {"colheita": true, "linhas": [
        {"linha": 2}, {"linha": 7}, {"linha": 10}, {"linha": 11},
    ]}
    ok(Run.e_cruzada_do_centro(centro),
       "fileira 3, coluna C e as duas diagonais é a CRUZADA DO CENTRO")
    ok(not Run.e_cruzada_do_centro({"colheita": true, "linhas": [
        {"linha": 0}, {"linha": 1}, {"linha": 2}, {"linha": 3}]}),
       "quatro fileiras que não passam pelo centro, não é")
    ok(not Run.e_cruzada_do_centro({"colheita": true, "linhas": [
        {"linha": 2}, {"linha": 7}, {"linha": 10}]}),
       "três linhas pelo centro ainda não é")

# ──────────────────────────── o perfil ────────────────────────────

func _perfil() -> void:
    secao("perfil: gravar, ler e não travar")
    var caminho := "user://teste-perfil.save"
    var p := Perfil.new()
    p.tema = 3
    p.mesas_jogadas = 12
    p.runs_vencidas = 1
    p.destravar("veludo")
    ok(p.gravar(caminho), "grava")

    var lido := Perfil.ler(caminho)
    igual(lido.tema, 3, "o tema escolhido volta")
    igual(lido.mesas_jogadas, 12, "as mesas jogadas voltam")
    igual(lido.runs_vencidas, 1, "as runs vencidas voltam")
    ok(lido.destravados.has("veludo"), "o tema destravado volta")

    ## Os temas de saída entram sempre, mesmo se o save não os trouxer.
    ok(lido.destravados.has("feltro"), "o padrão está sempre destravado")
    ok(lido.destravados.has("papel") and lido.destravados.has("porcelana"),
       "os dois de fundo claro também — acessibilidade não se merece")

    ## Save corrompido vira perfil zerado, nunca trava.
    var f := FileAccess.open(caminho, FileAccess.WRITE)
    f.store_string("{isto não é json")
    f.close()
    var quebrado := Perfil.ler(caminho)
    igual(quebrado.tema, Temas.PADRAO, "save corrompido volta ao tema padrão")
    ok(quebrado.destravados.has("feltro"), "e ainda tem os temas de saída")

    var ausente := Perfil.ler("user://nao-existe-mesmo.save")
    igual(ausente.mesas_jogadas, 0, "save ausente vira perfil zerado")

    DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho))

# ────────────────────────── os desbloqueios ──────────────────────────

func _desbloqueios() -> void:
    secao("desbloqueio dos temas")
    var p := Perfil.new()
    igual(p.destravados.size(), 3, "três temas nascem destravados")

    var r := Run.new(1)
    igual(p.conferir(r).size(), 0, "run recém-começada não destrava nada")

    r.venceu = true
    var novos := p.conferir(r)
    ok(novos.has("casino"), "vencer a run destrava o Casino noturno")
    igual(p.conferir(r).size(), 0, "e não destrava duas vezes")

    p.mesas_jogadas = 25
    ok(p.conferir(r).has("meianoite"), "25 mesas destravam a Meia-noite")

    r.categorias_feitas[Maos.SEQ_COR] = 1
    ok(p.conferir(r).has("veludo"), "uma Sequência de Cor destrava o Veludo")

    r.rodada = Metas.RODADAS
    ok(p.conferir(r).has("ameixa"), "chegar à rodada 6 destrava a Ameixa")

    var centro := {"colheita": true, "linhas": [
        {"linha": 2}, {"linha": 7}, {"linha": 10}, {"linha": 11}]}
    ok(p.conferir(r, centro).has("neon"),
       "a CRUZADA DO CENTRO destrava o Neon — o último de propósito")
    igual(p.destravados.size(), Temas.total(), "os oito temas cabem no jogo")
