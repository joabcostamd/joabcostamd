extends SceneTree
## Até onde vai a travessia: o jogo depois da rodada 6, medido.
##
## A curva de metas é `1,42^n` e não tem fim; o poder da build tem. Este arquivo
## responde onde as duas se cruzam — que é onde o jogo de verdade acaba, e é o
## número que diz se a travessia é conteúdo ou é enfeite.
##
##     godot --headless --script res://ferramentas/travessia.gd -- 12

func _init() -> void:
    var sementes := 12
    var args := OS.get_cmdline_user_args()
    if args.size() > 0 and args[0].is_valid_int():
        sementes = args[0].to_int()

    print("")
    print("TRAVESSIA — %d runs por grau, jogador guloso seguindo até cair" % sementes)
    print("")
    print("  grau            rodada mais funda      maior colheita     mesas")
    for grau in [0, 2, 4]:
        var d := Desafio.tabuleiro(grau)
        var fundas := []
        var maior := 0
        var mesas := 0.0
        for s in sementes:
            var run := Politica.jogar_run(Run.new(31337 + s * 7919, d), 400, true)
            fundas.append(run.rodada_mais_funda)
            maior = maxi(maior, run.maior_evento)
            mesas += float(run.mesas_vencidas)
        fundas.sort()
        print("  %-12s   mediana %2d · máxima %2d      %12s   %5.1f"
              % [d.nome(), int(fundas[fundas.size() / 2]), int(fundas[-1]),
                 Pintura.milhar(maior), mesas / float(sementes)])
    print("")
    print("  a meta da rodada 15 já passa de 600 mil; a da 20, de 3 milhões.")
    quit()
