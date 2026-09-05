extends SceneTree
## Suíte das conquistas: as marcas que a run junta e a conta que as confere.
##
##     godot --headless --script res://testes/conquistas.gd

var _passou := 0
var _falhou := 0

func _init() -> void:
    _catalogo()
    _a_conta()
    _as_marcas()
    _numa_run()

    print("")
    if _falhou > 0:
        print("CONQUISTAS: %d de %d asserções FALHARAM" % [_falhou, _passou + _falhou])
        quit(1)
        return
    print("CONQUISTAS OK — %d asserções" % _passou)
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

func _catalogo() -> void:
    secao("o catálogo")
    ok(Conquistas.total() >= 20, "há conquistas suficientes (%d)" % Conquistas.total())
    var ids := {}
    var sem_como := 0
    var vazias := 0
    for c in Conquistas.LISTA:
        ids[str(c["id"])] = true
        if str(c["como"]).strip_edges().is_empty():
            sem_como += 1
        if int(c["alvo"]) <= 0:
            vazias += 1
    igual(ids.size(), Conquistas.total(), "nenhum id repetido")
    igual(sem_como, 0, "toda conquista diz COMO se consegue — nada escondido")
    igual(vazias, 0, "e todo alvo é alcançável")

    ## Nada de grind: contagem alta sem decisão nova é trabalho, não conquista.
    var grind := 0
    for c in Conquistas.LISTA:
        if str(c["chave"]) == "mesas_jogadas" and int(c["alvo"]) > 50:
            grind += 1
    igual(grind, 0, "nenhuma conquista pede centenas de mesas")

func _a_conta() -> void:
    secao("a conta")
    var vazio := Conquistas.conferir({}, {})
    igual(vazio.size(), 0, "sem marca nenhuma, nada cai")

    var uma := Conquistas.conferir({"colheitas": 1}, {})
    ok(uma.has("primeira_colheita"), "a primeira colheita cai")

    ## Um alvo maior arrasta os menores da mesma chave: quem colhe quatro linhas
    ## de uma vez fez, no mesmo instante, uma dupla e uma tripla.
    var quatro := Conquistas.conferir({"linhas_no_evento": 4}, {})
    ok(quatro.has("dupla") and quatro.has("tripla") and quatro.has("cruz_total"),
       "quatro linhas de uma vez dão dupla, tripla e cruz total juntas")

    ## Nada cai duas vezes.
    var ja := {"dupla": true}
    ok(not Conquistas.conferir({"linhas_no_evento": 4}, ja).has("dupla"),
       "o que já foi conquistado não cai de novo")

    igual(Conquistas.conferir({"linhas_no_evento": 1}, {}).size(), 0,
          "uma linha só não é cruzada")

func _as_marcas() -> void:
    secao("as marcas")
    ## Quem conta é a MESA, sem ninguém precisar avisar: uma partida jogada por
    ## teste, por simulação ou por replay conta igual à jogada com a tela aberta.
    var m := Mesa.new(Metas.CHEFE, 1, 5)
    for casa in 5:
        m.posicionar(0, casa)
    m.posicionar(0, 5)
    igual(int(m.contas["colheitas"]), 1, "a mesa contou a colheita sozinha")
    igual(int(m.marcas["linhas_no_evento"]), 1, "e quantas linhas tinha")
    ok(int(m.marcas["maior_evento"]) > 0, "e quanto ela pagou")
    ok(int(m.marcas["tear_maximo"]) >= 1, "e o Tear que alcançou")

    var run := Run.new(31337)
    run.mesa.contas["colheitas"] = 2
    run.mesa.marcas["maior_evento"] = 4200
    run.mesa.marcas["linhas_no_evento"] = 2
    run.mesa.marcas["cat_7"] = 1

    ## As marcas de estado entram no fim da mesa.
    run.poderes.colar_na_casa(12, "brasa")
    run.poderes.guardar_reliquia("novelo")
    run.poderes.subir_nivel(Maos.FULL)
    run.mesa.acabou = true
    run.mesa.venceu = true
    run.concluir_mesa()
    igual(int(run.marcas["colheitas"]), 2, "a run absorveu o contador da mesa")
    igual(int(run.marcas["maior_evento"]), 4200, "e a maior colheita")
    igual(int(run.marcas["cat_7"]), 1, "e a Quadra")
    igual(int(run.marcas["selos"]), 1, "o selo colado ficou marcado")
    igual(int(run.marcas["reliquias"]), 1, "a relíquia também")
    igual(int(run.marcas["nivel_maximo"]), 1, "e o nível de mão")

func _numa_run() -> void:
    secao("numa run de verdade")
    var perfil := Perfil.new()
    var caiu := {}
    for s in 4:
        var run := Run.new(31337 + s * 7919)
        var voltas := 0
        while not run.acabou and voltas < 90:
            voltas += 1
            Politica.jogar(run.mesa)
            var passo := run.concluir_mesa()
            if bool(passo.get("pode_continuar", false)):
                run.encerrar()
                break
            if run.loja != null:
                Politica.comprar(run.loja, run.poderes)
                run.fechar_loja()
            for id in perfil.conferir_conquistas(run):
                caiu[id] = true
        perfil.mesas_jogadas += run.mesas_jogadas
        if run.venceu:
            perfil.runs_vencidas += 1
        for id in perfil.conferir_conquistas(run):
            caiu[id] = true

    ok(caiu.size() >= 6, "o jogador simulado conquista várias sem tentar (%d)"
       % caiu.size())
    ok(caiu.has("primeira_colheita"), "a primeira colheita, obviamente")
    ok(caiu.has("dupla"), "e a cruzada, que é o verbo do jogo")
    igual(perfil.quantas_conquistas(), caiu.size(),
          "o perfil guarda exatamente as que caíram")

    ## Guardar e ler não perde conquista.
    var caminho := "user://teste-conquistas.save"
    perfil.gravar(caminho)
    var lido := Perfil.ler(caminho)
    igual(lido.quantas_conquistas(), perfil.quantas_conquistas(),
          "as conquistas sobrevivem ao save")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho))
