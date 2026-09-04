extends SceneTree
## Afere o motor contra as bandas medidas pela bancada (DESIGN §9).
##
## Os números do DESIGN vieram de um protótipo descartável. Este arquivo existe
## para provar que o jogo de verdade reproduz aquele protótipo — se a colheita,
## a parcela ou o Tear tivessem sido portados torto, é aqui que apareceria.
##
##     godot --headless --script res://ferramentas/aferir.gd -- 60
##
## O jogador simulado é o GULOSO: ele sempre faz a jogada de maior ganho
## imediato. É de propósito o pior jogador competente que existe — se as bandas
## fecham com ele, fecham.

const SEMENTE_BASE := 31337
const PASSO := 7919

func _init() -> void:
    var sementes := 60
    for arg in OS.get_cmdline_user_args():
        if arg.is_valid_int():
            sementes = arg.to_int()

    var mesas := 0
    var vitorias := 0
    var turnos := 0
    var turnos_pagos := 0
    var cruzadas := 0
    var avessos := 0
    var colheitas := 0
    var conservacao_quebrou := 0
    var secas := []
    var tears := []
    var razoes := []
    var graus := {"colheita": 0, "DUPLA": 0, "TRIPLA": 0, "CRUZ TOTAL": 0}
    var maior_evento := 0

    for s in sementes:
        for rodada in range(1, Metas.RODADAS + 1):
            for tipo in Metas.TIPOS:
                var m := Mesa.new(tipo, rodada, SEMENTE_BASE + s * PASSO)
                mesas += 1
                var seca := 0
                var pior_seca := 0
                while not m.acabou:
                    if not m.conservacao():
                        conservacao_quebrou += 1
                        break
                    Politica.talvez_descartar(m)
                    var jogada := Politica.gulosa(m)
                    if int(jogada[0]) < 0:
                        break
                    if int(jogada[2]) != m.mao[int(jogada[0])]:
                        m.girar_na_mao(int(jogada[0]))
                    var r := m.posicionar(int(jogada[0]), int(jogada[1]))
                    if not bool(r["valido"]):
                        break
                    turnos += 1
                    if int(r["pontos_total"]) > 0:
                        turnos_pagos += 1
                        if seca > pior_seca:
                            pior_seca = seca
                        seca = 0
                    else:
                        seca += 1
                    if bool(r["cruzada"]):
                        cruzadas += 1
                    if r["grau"] != "":
                        graus[r["grau"]] = int(graus[r["grau"]]) + 1
                if seca > pior_seca:
                    pior_seca = seca
                if not m.conservacao():
                    conservacao_quebrou += 1
                if m.venceu:
                    vitorias += 1
                secas.append(pior_seca)
                tears.append(m.tear)
                razoes.append(float(m.pontos) / float(m.meta))
                avessos += m.avessos_forjados
                colheitas += m.colheitas
                if m.maior_evento > maior_evento:
                    maior_evento = m.maior_evento

    var pagos := 100.0 * float(turnos_pagos) / float(maxi(1, turnos))
    var vitoria := 100.0 * float(vitorias) / float(maxi(1, mesas))
    print("")
    print("AFERIÇÃO — %d mesas (%d sementes × 6 rodadas × 3 tipos), jogador guloso"
          % [mesas, sementes])
    print("")
    var falhas := 0
    falhas += banda("turnos com recompensa", pagos, 70.0, 100.0, "%", 75.9)
    falhas += banda("seca máxima mediana", mediana(secas), 0.0, 6.0, " turnos", 3.0)
    falhas += banda("cruzadas por mesa", float(cruzadas) / float(mesas), 0.5, 3.0, "", 0.839)
    falhas += banda("razão pontos/meta", mediana(razoes), 0.55, 1.00, "", 0.79)
    falhas += banda("vitória do guloso", vitoria, 15.0, 45.0, "%", 34.1)
    falhas += banda("Tear no fim da mesa", mediana(tears), 4.0, 8.0, "", 7.0)
    falhas += banda("Avessos por mesa", float(avessos) / float(mesas), 1.0, 2.5, "", 1.66)
    falhas += banda("conservação quebrada", float(conservacao_quebrou), 0.0, 0.0, "", 0.0)
    print("")
    print("  colheitas por mesa    %.2f" % (float(colheitas) / float(mesas)))
    print("  maior evento único    %d" % maior_evento)
    var eventos := 0
    for g in graus:
        eventos += int(graus[g])
    for g in ["colheita", "DUPLA", "TRIPLA", "CRUZ TOTAL"]:
        print("  %-14s        %5d  (%.1f%%)"
              % [g, int(graus[g]), 100.0 * float(graus[g]) / float(maxi(1, eventos))])

    print("")
    if falhas > 0:
        print("AFERIÇÃO: %d métricas fora da banda medida" % falhas)
        quit(1)
        return
    print("AFERIÇÃO OK — o motor reproduz a bancada")
    quit(0)

func banda(nome: String, valor: float, minimo: float, maximo: float,
           unidade: String, medido: float) -> int:
    var dentro := valor >= minimo and valor <= maximo
    print("  [%s] %-22s %8.3f%s   banda %.2f–%.2f · bancada %.3f"
          % ["ok" if dentro else "FORA", nome, valor, unidade, minimo, maximo, medido])
    return 0 if dentro else 1

func mediana(lista: Array) -> float:
    if lista.is_empty():
        return 0.0
    var copia := lista.duplicate()
    copia.sort()
    return float(copia[copia.size() / 2])
