extends RefCounted
class_name Desafio
## A dificuldade, e ela é UMA COISA SÓ: três números.
##
## O jogo não tem "modo fácil" e "modo difícil" como caminhos separados de
## código. Tem três réguas — quanto tempo você tem, quanto o tabuleiro atrapalha,
## e quão alta é a meta — e tudo o mais escreve nelas. O dial Tabuleiro é um
## **preset** que escreve nos três; ele não soma com eles.
##
## Um caminho de código por dificuldade é como se ganha um jogo fácil que ninguém
## testou e um difícil que ninguém consegue.

## Quantos posicionamentos a mais (ou a menos) em toda mesa.
var orcamento := 0        ## −3 a +6
## Quanto o tabuleiro atrapalha. Cumulativo: o grau 4 tem também 1, 2 e 3.
var geometria := 0        ## 0 a 8
## Multiplicador da meta.
var metas := 1.0          ## 0,70 a 1,25
## Quantos descartes a mais.
var descartes := 0
## Sem derrota: a mesa perdida repete de graça, sem gastar vida.
var sem_derrota := false

const ORCAMENTO_MIN := -3
const ORCAMENTO_MAX := 6
const GEOMETRIA_MAX := 8
const METAS_MIN := 0.70
const METAS_MAX := 1.25

## O piso do baralho da run. A geometria 4 tira de circulação o que foi colhido,
## e uma mesa colhe umas nove cartas: sem piso, o baralho zera na rodada 4 e a
## run congela com a mão vazia — medido, e é o oposto de dificuldade.
##
## Com 32 cartas a regra continua mordendo (menos naipes, menos outs, o Baralho
## Aberto encolhendo à vista) sem nunca fechar a porta.
const BARALHO_MINIMO := 32

## Os graus da geometria, cumulativos. Cada um é uma linha desta tabela e não
## um `if` espalhado pelo motor.
const GEO_MENOS_UM_POSICIONAMENTO := 1
const GEO_CASAS_LACRADAS := 2
const GEO_COLUNA_PAGA_MENOS := 3
const GEO_COLHIDA_NAO_VOLTA := 4
const GEO_LOJA_PERDE_VAGA := 5
const GEO_CRUZADA_SO_DIFERENTES := 6
const GEO_LINHA_MORTA_POR_RODADA := 7
const GEO_METAS_MAIORES := 8

const GEO_NOMES: PackedStringArray = [
    "",
    "um posicionamento a menos em toda mesa",
    "duas casas nascem lacradas em cada mesa",
    "colunas pagam um multiplicador a menos",
    "a pilha colhida não volta para a mesa seguinte",
    "a loja perde uma vaga",
    "a cruzada só soma mults de categorias diferentes",
    "uma linha morre de vez a cada rodada",
    "as metas sobem 25%",
]

## Os nove presets do dial. Um degrau por vitória, reversível, nunca obrigatório.
##
## O grau 0 não é "modo fácil disfarçado": é a linha de base contra a qual todo
## número do DESIGN foi medido. Os graus negativos moram na ESTUFA.
const TABULEIROS: Array[Dictionary] = [
    {"nome": "Tabuleiro 0", "orcamento": 0, "geometria": 0, "metas": 1.00},
    {"nome": "Tabuleiro 1", "orcamento": 0, "geometria": 1, "metas": 1.00},
    {"nome": "Tabuleiro 2", "orcamento": 0, "geometria": 2, "metas": 1.00},
    {"nome": "Tabuleiro 3", "orcamento": 0, "geometria": 3, "metas": 1.00},
    {"nome": "Tabuleiro 4", "orcamento": 0, "geometria": 4, "metas": 1.00},
    {"nome": "Tabuleiro 5", "orcamento": 0, "geometria": 5, "metas": 1.00},
    {"nome": "Tabuleiro 6", "orcamento": 0, "geometria": 6, "metas": 1.00},
    {"nome": "Tabuleiro 7", "orcamento": 0, "geometria": 7, "metas": 1.00},
    {"nome": "Tabuleiro 8", "orcamento": 0, "geometria": 8, "metas": 1.25},
]

## O que cada grau produz, MEDIDO — não estimado.
##
## `ferramentas/curva.gd -- 16 loja` roda 16 runs inteiras por grau com o
## jogador simulado e imprime esta tabela. Os números vão para a tela de
## escolha: quem decide quanto quer apanhar tem direito de saber o que está
## escolhendo, e "difícil" e "muito difícil" não informam nada.
##
## Medido em 4 de setembro de 2026, com o comprador simulado. REMEDIR sempre que
## uma regra do motor, um item ou a curva de metas mudarem — tabela de dificuldade
## desatualizada é pior que tabela nenhuma, porque ela é acreditada.
const VITORIA_MEDIDA: Array[Dictionary] = [
    {"run": 56, "mesas": 16.3},
    {"run": 30, "mesas": 14.5},
    {"run": 13, "mesas": 12.7},
    {"run": 9, "mesas": 11.5},
    {"run": 6, "mesas": 10.4},
    {"run": 4, "mesas": 10.2},
    {"run": 2, "mesas": 10.1},
    {"run": 1, "mesas": 7.4},
    {"run": 0, "mesas": 4.7},
]

## Uma frase honesta sobre o que esperar deste grau. Sem adjetivo: o número.
func expectativa() -> String:
    if sem_derrota:
        return "a run sempre fecha — 18 de 18 mesas"
    var g := grau_do_dial()
    if g < 0:
        return "configuração própria — não medida"
    var m: Dictionary = VITORIA_MEDIDA[g]
    if int(m["run"]) <= 0:
        return "o simulado nunca fechou uma run — chega a %.1f das 18 mesas" % float(m["mesas"])
    return "%d%% das runs fecham — o simulado chega a %.1f das 18 mesas" \
        % [int(m["run"]), float(m["mesas"])]

## A ESTUFA. Não é versão de mentira: a coleção desbloqueia igual, e é onde o
## jogo se aprende. Quem nunca viu uma cruzada não decide nada sobre ela.
static func estufa() -> Desafio:
    var d := Desafio.new()
    d.orcamento = 4
    d.descartes = 2
    d.metas = 0.70
    d.sem_derrota = true
    return d

static func tabuleiro(grau: int) -> Desafio:
    var linha := TABULEIROS[clampi(grau, 0, TABULEIROS.size() - 1)]
    var d := Desafio.new()
    d.orcamento = int(linha["orcamento"])
    d.geometria = int(linha["geometria"])
    d.metas = float(linha["metas"])
    return d

## O grau do dial que corresponde a estes três números, ou −1 se o jogador mexeu
## nas réguas à mão. A tela mostra "Tabuleiro 3" ou "personalizado", e nunca
## finge que um ajuste manual é um degrau do dial.
func grau_do_dial() -> int:
    for i in TABULEIROS.size():
        var t := TABULEIROS[i]
        if int(t["orcamento"]) == orcamento and int(t["geometria"]) == geometria \
                and is_equal_approx(float(t["metas"]), metas) \
                and descartes == 0 and not sem_derrota:
            return i
    return -1

func nome() -> String:
    if sem_derrota:
        return "Estufa"
    var g := grau_do_dial()
    return str(TABULEIROS[g]["nome"]) if g >= 0 else "Personalizado"

func tem(grau_de_geometria: int) -> bool:
    return geometria >= grau_de_geometria

func copia() -> Desafio:
    var d := Desafio.new()
    d.orcamento = orcamento
    d.geometria = geometria
    d.metas = metas
    d.descartes = descartes
    d.sem_derrota = sem_derrota
    return d

func para_dicionario() -> Dictionary:
    return {"orcamento": orcamento, "geometria": geometria, "metas": metas,
            "descartes": descartes, "sem_derrota": sem_derrota}

static func de_dicionario(d: Dictionary) -> Desafio:
    var r := Desafio.new()
    r.orcamento = clampi(int(d.get("orcamento", 0)), ORCAMENTO_MIN, ORCAMENTO_MAX)
    r.geometria = clampi(int(d.get("geometria", 0)), 0, GEOMETRIA_MAX)
    r.metas = clampf(float(d.get("metas", 1.0)), METAS_MIN, METAS_MAX)
    r.descartes = clampi(int(d.get("descartes", 0)), 0, 6)
    r.sem_derrota = bool(d.get("sem_derrota", false))
    return r

# ─────────────────── o que cada régua faz, num lugar só ───────────────────

## Posicionamentos desta mesa. A `catraca` é a Segunda mão: repetir a mesma mesa
## dá uma carta a mais na manga, até três — ferramenta, nunca desconto na meta.
func posicionamentos(tipo: int, catraca := 0) -> int:
    var base := Metas.posicionamentos(tipo) + orcamento + catraca
    if tem(GEO_MENOS_UM_POSICIONAMENTO):
        base -= 1
    ## Piso duro: menos de 5 posicionamentos e nenhuma linha chega a 5 cartas,
    ## o que faz a mesa ser invencível por aritmética e não por dificuldade.
    return maxi(Geometria.LADO + 2, base)

func quantos_descartes(tipo: int) -> int:
    return maxi(0, Metas.descartes(tipo) + descartes)

func meta(tipo: int, rodada: int) -> int:
    var m := float(Metas.meta(tipo, rodada)) * metas
    if tem(GEO_METAS_MAIORES):
        ## O grau 8 já vem com o slider em 1,25; esta linha existe para o caso de
        ## alguém pôr geometria 8 à mão sem mexer nas metas, e não empilha com o
        ## preset — o slider é a régua, o grau só garante o piso.
        m = maxf(m, float(Metas.meta(tipo, rodada)) * 1.25)
    return int(round(m))

## Quantas casas nascem lacradas. Casa lacrada não recebe carta a mesa inteira.
func casas_lacradas() -> int:
    return 2 if tem(GEO_CASAS_LACRADAS) else 0
