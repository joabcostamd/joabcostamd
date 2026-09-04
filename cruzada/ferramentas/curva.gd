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
    print("CURVA — %d sementes por célula, jogador guloso, sem loja" % sementes)
    print("")
    print("  grau                       vitória por rodada 1→6      run inteira")
    for grau in graus:
        var d := Desafio.tabuleiro(grau)
        var r := medir(sementes, d)
        print("  %-12s  %s   %5.1f%%   completou %.1f de 18"
              % [d.nome(), r["texto"], float(r["mesas"]), float(r["ate_onde"])])

    var e := medir(sementes, Desafio.estufa())
    print("  %-12s  %s   %5.1f%%   completou %.1f de 18"
          % ["Estufa", e["texto"], float(e["mesas"]), float(e["ate_onde"])])
    print("")
    print("  vitória por mesa avulsa. 'completou' = quantas mesas a run vence")
    print("  antes de acabarem as três vidas.")
    quit()

func medir(sementes: int, d: Desafio) -> Dictionary:
    ## Duas medições diferentes, e as duas importam: a vitória de uma mesa
    ## avulsa em cada rodada (a curva) e quanto de uma run inteira o jogador
    ## atravessa antes de gastar as vidas (a experiência real).
    var vitorias := []
    var mesas := []
    for i in Metas.RODADAS:
        vitorias.append(0)
        mesas.append(0)
    var total := 0
    var vencidas := 0
    for s in sementes:
        for rodada in range(1, Metas.RODADAS + 1):
            for tipo in Metas.TIPOS:
                var m := Mesa.new(tipo, rodada, SEMENTE_BASE + s * PASSO, 1, d)
                Politica.jogar(m)
                mesas[rodada - 1] += 1
                total += 1
                if m.venceu:
                    vitorias[rodada - 1] += 1
                    vencidas += 1

    var ate_onde := 0.0
    for s in sementes:
        var run := Run.new(SEMENTE_BASE + s * PASSO, d)
        var voltas := 0
        while not run.acabou and voltas < 80:
            voltas += 1
            Politica.jogar(run.mesa)
            run.concluir_mesa()
        ate_onde += float(run.mesas_vencidas)
    ate_onde /= float(maxi(1, sementes))

    var texto := ""
    for i in Metas.RODADAS:
        texto += "%6.1f" % (100.0 * float(vitorias[i]) / float(maxi(1, mesas[i])))
    return {"texto": texto, "mesas": 100.0 * float(vencidas) / float(maxi(1, total)),
            "ate_onde": ate_onde}
