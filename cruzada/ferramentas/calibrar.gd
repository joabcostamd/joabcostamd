extends SceneTree
## Varre a constante da curva de metas e mostra o que cada valor produz.
##
## O K não é um gosto de designer: ele é o número que faz a razão pontos/meta do
## jogador guloso cair em 0,79 e a vitória ficar na banda. Este arquivo existe
## para reencontrar esse ponto quando uma regra muda — e para provar, com a
## tabela na mão, que o valor escolhido não foi chutado.
##
##     godot --headless --script res://ferramentas/calibrar.gd -- 30

const SEMENTE_BASE := 31337
const PASSO := 7919

func _init() -> void:
    var sementes := 30
    var fatores := PackedFloat32Array([1.00, 1.08, 1.16, 1.24])
    var args := OS.get_cmdline_user_args()
    for a in args:
        if a.is_valid_int():
            sementes = a.to_int()

    print("")
    print("CALIBRAGEM — %d sementes × 6 rodadas × 3 tipos = %d mesas por fator"
          % [sementes, sementes * 18])
    print("")
    print("  fator      K   razão   vitória    vitória por rodada 1→6")
    for f in fatores:
        var r := rodar(sementes, f)
        var por_rodada := ""
        for i in Metas.RODADAS:
            por_rodada += "%5.1f" % float(r["rodada"][i])
        print("  %5.2f  %5.2f   %5.3f   %5.1f%%   %s"
              % [f, Metas.BASE * f / 450.0, float(r["razao"]),
                 float(r["vitoria"]), por_rodada])
    print("")
    print("  alvo: razão 0,790 · vitória 20–40%% · rodada 6 quase intransponível")
    ## Sem isto o processo termina a conta e fica rodando o laço da SceneTree
    ## para sempre — e a saída, presa no buffer, nunca aparece.
    quit()

func rodar(sementes: int, fator: float) -> Dictionary:
    var razoes := []
    var vitorias := 0
    var mesas := 0
    var por_rodada := []
    var mesas_rodada := []
    for i in Metas.RODADAS:
        por_rodada.append(0)
        mesas_rodada.append(0)
    for s in sementes:
        for rodada in range(1, Metas.RODADAS + 1):
            for tipo in Metas.TIPOS:
                var m := Mesa.new(tipo, rodada, SEMENTE_BASE + s * PASSO)
                m.meta = int(round(float(m.meta) * fator))
                Politica.jogar(m)
                mesas += 1
                mesas_rodada[rodada - 1] += 1
                razoes.append(float(m.pontos) / float(m.meta))
                if m.venceu:
                    vitorias += 1
                    por_rodada[rodada - 1] += 1
    for i in Metas.RODADAS:
        por_rodada[i] = 100.0 * float(por_rodada[i]) / float(maxi(1, mesas_rodada[i]))
    razoes.sort()
    return {"razao": razoes[razoes.size() / 2],
            "vitoria": 100.0 * float(vitorias) / float(maxi(1, mesas)),
            "rodada": por_rodada}
