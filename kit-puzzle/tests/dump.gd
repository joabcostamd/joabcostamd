extends SceneTree
## Imprime um nível em texto — útil para conferir o gerador sem abrir nada.
## Uso: godot --headless --script res://tests/dump.gd

func _initialize() -> void:
    for semente in [76049, 1, 2]:
        var g := Gerador.new()
        var t := g.gerar(semente)
        if t == null:
            print("semente ", semente, ": não gerou\n")
            continue
        var s := ""
        for y in t.altura:
            for x in t.largura:
                var p := Vector2i(x, y)
                if t.paredes.has(p): s += "#"
                elif t.caixas.has(p): s += "*" if t.alvos.has(p) else "$"
                elif t.alvos.has(p): s += "."
                elif t.jogador == p: s += "@"
                else: s += "."if false else " "
            s += "\n"
        print("semente %d — ideal %d passos, %d tentativas" % [semente, g.ultimo_tamanho_solucao, g.tentativas_gastas])
        print(s)
    quit()
