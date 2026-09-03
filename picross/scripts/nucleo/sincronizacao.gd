extends RefCounted
class_name Sincronizacao
## Mescla de salvamentos, para o progresso sobreviver a dois aparelhos.
##
## Não existe SDK de loja aqui. O que existe é a parte que realmente importa
## e que costuma ser feita errado: **resolver conflito sem perder progresso**.
## O Steam Cloud (e equivalentes) sincroniza arquivos de `user://` sozinho;
## o problema aparece quando os dois lados mudaram. A regra abaixo é a única
## segura para um jogo assim: nunca escolher um lado inteiro, e sim ficar com
## o melhor resultado de cada fase.

const VERSAO := 2

## Junta dois salvamentos. Para cada fase fica o melhor: mais estrelas e,
## em empate de estrelas, o menor tempo.
static func mesclar(a: Dictionary, b: Dictionary) -> Dictionary:
    var fases_a: Dictionary = a.get("fases", {})
    var fases_b: Dictionary = b.get("fases", {})
    var saida := {}

    for chave in fases_a.keys() + fases_b.keys():
        if saida.has(chave):
            continue
        var x: Dictionary = fases_a.get(chave, {})
        var y: Dictionary = fases_b.get(chave, {})
        if x.is_empty():
            saida[chave] = y.duplicate()
            continue
        if y.is_empty():
            saida[chave] = x.duplicate()
            continue
        var estrelas := maxi(int(x.get("estrelas", 0)), int(y.get("estrelas", 0)))
        var tempo_x := float(x.get("tempo", 0.0))
        var tempo_y := float(y.get("tempo", 0.0))
        var tempo := tempo_x
        if tempo_x <= 0.0:
            tempo = tempo_y
        elif tempo_y > 0.0:
            tempo = minf(tempo_x, tempo_y)
        saida[chave] = {"estrelas": estrelas, "tempo": tempo}

    # As opções não têm "melhor": fica a do salvamento gravado por último.
    var mais_novo: Dictionary = a if int(a.get("quando", 0)) >= int(b.get("quando", 0)) else b
    return {
        "versao": VERSAO,
        "quando": maxi(int(a.get("quando", 0)), int(b.get("quando", 0))),
        "fases": saida,
        "opcoes": mais_novo.get("opcoes", {}),
    }

## Código que o jogador copia para levar o progresso a outro aparelho.
static func exportar(save: Dictionary) -> String:
    var texto := JSON.stringify(save)
    return Marshalls.raw_to_base64(texto.to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP))

## Lê um código exportado. Devolve vazio quando o código não presta — o
## chamador decide o que dizer ao jogador.
static func importar(codigo: String) -> Dictionary:
    var cru := Marshalls.base64_to_raw(codigo.strip_edges())
    # Confere a assinatura do gzip antes de descomprimir: sem isso, um código
    # digitado errado faz o motor imprimir erro no console do jogador.
    if cru.size() < 3 or cru[0] != 0x1f or cru[1] != 0x8b:
        return {}
    # o tamanho descomprimido é desconhecido: 1 MB cobre qualquer save deste jogo
    var bytes := cru.decompress_dynamic(1 << 20, FileAccess.COMPRESSION_GZIP)
    if bytes.is_empty():
        return {}
    var dados = JSON.parse_string(bytes.get_string_from_utf8())
    if typeof(dados) != TYPE_DICTIONARY or not dados.has("fases"):
        return {}
    return dados
