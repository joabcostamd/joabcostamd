extends Node
## Confere a tipografia: escala, tamanhos mínimos e comportamento dos números.
##
## Existe porque tipografia é o item que mais se decide "no olho" e mais se
## erra: os tamanhos deste projeto foram escolhidos um a um e resultaram em
## 13 e 14 px lado a lado (que ninguém distingue) e um salto de 18 para 50.

## A escala vive em `temas.gd`, junto das cores — este arquivo só CONFERE.
## Validador que carrega a própria cópia dos valores não valida nada: valida a
## cópia, e a tela pode divergir sem ninguém notar.
const ESCALA := {
    "rotulo": Temas.T_ROTULO, "corpo": Temas.T_CORPO, "numero": Temas.T_NUMERO,
    "titulo": Temas.T_TITULO, "heroi": Temas.T_HEROI,
}

## Mínimo de corpo para texto de jogo, pelas diretrizes de acessibilidade.
const MINIMO := 14

func _ready() -> void:
    var falhas := 0
    var f: FontFile = Temas.fonte()
    var fb: FontFile = Temas.fonte(true)

    print("── escala tipográfica ──")
    var nomes := ESCALA.keys()
    var anterior := 0
    for nome in nomes:
        var tam: int = ESCALA[nome]
        var razao := 0.0 if anterior == 0 else float(tam) / float(anterior)
        var marca := ""
        if anterior > 0 and razao < 1.12:
            marca = "  REPROVA: degrau indistinguível"
            falhas += 1
        if tam < MINIMO:
            marca = "  REPROVA: abaixo do mínimo de %d" % MINIMO
            falhas += 1
        print("  %-8s %3d px   %s%s" % [nome, tam,
              "" if razao == 0.0 else "×%.2f" % razao, marca])
        anterior = tam

    print()
    print("── algarismos: o número que sobe não pode dançar ──")
    for par in [["Regular", f], ["Bold", fb]]:
        var fonte: FontFile = par[1]
        var menor := 999.0
        var maior := 0.0
        for d in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]:
            var w: float = fonte.get_string_size(d, HORIZONTAL_ALIGNMENT_LEFT, -1, 50).x
            menor = minf(menor, w)
            maior = maxf(maior, w)
        var variacao := (maior / menor - 1.0) * 100.0
        var tabular := maior - menor < 0.5
        print("  %-8s largura %.1f a %.1f  (variação %.1f%%)  %s"
              % [par[0], menor, maior, variacao, "tabular" if tabular else "PROPORCIONAL"])
        if not tabular:
            print("           -> o 1 é mais estreito que o 8: a pontuação treme ao contar.")
            print("              Conserto: desenhar cada algarismo em célula de largura fixa.")

    print()
    if falhas > 0:
        print("TIPOGRAFIA: %d degraus reprovaram" % falhas)
        get_tree().quit(1)
    else:
        print("TIPOGRAFIA OK — %d degraus, todos distintos e acima de %d px"
              % [ESCALA.size(), MINIMO])
        get_tree().quit(0)
