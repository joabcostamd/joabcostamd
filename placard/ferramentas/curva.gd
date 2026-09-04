extends SceneTree
## A curva de dificuldade, medida: vitória por rodada em cada grau do dial.
##
## É o instrumento que responde a pergunta que decide o jogo — "isto é difícil ou
## é impossível?" — e a diferença entre as duas é o motivo de este arquivo
## existir. Difícil é 30% de vitória; impossível é 0%, e 0% não é dificuldade, é
## uma porta fechada com o jogador do lado de fora.
##
##     godot --headless --script res://ferramentas/curva.gd -- 12 [graus]

const SEMENTE_BASE := 31337
const PASSO := 7919

func _init() -> void:
    var sementes := 12
    var graus := [0, 2, 4, 6, 8]
    var args := OS.get_cmdline_user_args()
    if args.size() > 0 and args[0].is_valid_int():
        sementes = args[0].to_int()
    if args.size() > 1 and args[1] == "todos":
        graus = [0, 1, 2, 3, 4, 5, 6, 7, 8]

    print("")
    var com_loja := args.size() > 2 or (args.size() > 1 and args[1] == "loja")
    print("CURVA — %d sementes por célula, jogador guloso%s"
          % [sementes, ", COM loja" if com_loja else ", sem loja"])
    print("")
    print("  grau            vitória da mesa por rodada 1→6    run    mesas   compras")
    for grau in graus:
        var d := Desafio.tabuleiro(grau)
        var r := medir(sementes, d, com_loja)
        print("  %-12s  %s   %5.1f%%  %4.1f/18  %.1f selos %.1f níveis"
              % [d.nome(), r["texto"], float(r["runs"]), float(r["ate_onde"]),
                 float(r["selos"]), float(r["niveis"])])

    var e := medir(sementes, Desafio.estufa(), com_loja)
    print("  %-12s  %s   %5.1f%%  %4.1f/18  %.1f selos %.1f níveis"
          % ["Estufa", e["texto"], float(e["runs"]), float(e["ate_onde"]),
             float(e["selos"]), float(e["niveis"])])
    print("")
    print("  vitória medida DENTRO da run, com a build que o jogador tinha ali.")
    print("  'run' = runs fechadas por inteiro; 'mesas' = quantas das 18 caem.")
    quit()

func medir(sementes: int, d: Desafio, com_loja := false) -> Dictionary:
    ## A medição que importa é DENTRO da run: uma mesa da rodada 6 jogada por
    ## quem chegou lá com uma build é outra mesa. Medir a rodada 6 isolada, com
    ## poderes zerados, mede um jogo que ninguém joga.
    var vitorias := []
    var tentadas := []
    for i in Metas.RODADAS:
        vitorias.append(0)
        tentadas.append(0)

    var runs_vencidas := 0
    var ate_onde := 0.0
    var selos := 0.0
    var dinheiro := 0.0
    var niveis := 0.0
    for s in sementes:
        var run := Run.new(SEMENTE_BASE + s * PASSO, d)
        var voltas := 0
        while not run.acabou and voltas < 90:
            voltas += 1
            var rodada := run.rodada
            Politica.jogar(run.mesa)
            tentadas[rodada - 1] += 1
            if run.mesa.venceu:
                vitorias[rodada - 1] += 1
            var passo := run.concluir_mesa()
            ## O simulado para na rodada 6, com a vitória na mão. A travessia é
            ## outra medição.
            if bool(passo.get("pode_continuar", false)):
                run.encerrar()
                break
            if com_loja and run.loja != null:
                Politica.comprar(run.loja, run.poderes)
            run.fechar_loja()
        if run.venceu:
            runs_vencidas += 1
        ate_onde += float(run.mesas_vencidas)
        selos += float(run.poderes.quantos_selos())
        dinheiro += float(run.poderes.dinheiro)
        var soma := 0
        for c in Maos.CATEGORIAS:
            soma += run.poderes.nivel(c)
        niveis += float(soma)

    var n := float(maxi(1, sementes))
    var texto := ""
    for i in Metas.RODADAS:
        if tentadas[i] == 0:
            texto += "     —"
        else:
            texto += "%6.1f" % (100.0 * float(vitorias[i]) / float(tentadas[i]))
    return {"texto": texto, "runs": 100.0 * float(runs_vencidas) / n,
            "ate_onde": ate_onde / n, "selos": selos / n,
            "dinheiro": dinheiro / n, "niveis": niveis / n}
