extends RefCounted
class_name Temas
## Os oito temas do CRUZADA. Um tema é uma linha de dados, nunca um caminho de
## código: toda cor e todo parâmetro de brilho que a tela desenha sai daqui.
##
## Além das cores, cada tema carrega os seus parâmetros de juice. É esse segundo
## bloco que permite ter temas de fundo claro sem ramificar o desenho: partícula
## que brilha sobre quase-preto some sobre creme, e glow vira borrão — então o
## tema declara a força de cada efeito em vez de o código decidir por tema.

## `escala_de_cinza` transforma a paleta em cinza no momento em que ela é
## aplicada. Não é um filtro por cima: é a paleta que um jogador com
## acromatopsia enxerga. Se a grade continuar legível assim, a forma está
## fazendo o trabalho e não a cor.
static var escala_de_cinza := false

const TEMAS: Array[Dictionary] = [
{
    "id": "casino", "nome": "Casino noturno", "claro": false, "fundo_estilo": "brilho",
    "sensacao": "frio, sóbrio, elegante",
    "fundo": "#0d1322", "fundo_alto": "#16203a", "painel": "#1a2544", "borda": "#33436f",
    "casa": "#16203a", "casa_borda": "#46609e",
    "filete": "#f2c45c",
    "texto": "#eef2fb", "texto_suave": "#9aa8c8",
    "carta": "#f7f3e9", "carta_borda": "#d8d0bd", "carta_texto": "#171b26",
    "destaque": "#f2c45c", "acento": "#6ab0d6", "alerta": "#e0655f", "sucesso": "#6fc48c",
    "copas": "#d6335e", "ouros": "#b06216", "paus": "#2f9e78", "espadas": "#2a3350",
    "vermelho": "#d6335e", "preto": "#232a3d",
    "brilho": 1.0, "particula": 0.16, "glow": 1.0, "contorno": 0.0,
    "sombra": 0.45, "fonte_forte": false, "espaco": 0.0,
},
{
    "id": "feltro", "nome": "Feltro e ouro", "claro": false, "fundo_estilo": "tecido",
    "sensacao": "mesa de carteado à meia-luz",
    # Feltro escurecido: o verde de mesa original era claro demais e a carta
    # creme separava só 12,8 contra 16,9 dos outros escuros. A lógica do feltro
    # físico — "carta salta sobre verde" — vale para papel sob lâmpada, não
    # para pixel em tela.
    "fundo": "#0b2116", "fundo_alto": "#0f2b1d", "painel": "#102a1c", "borda": "#2c5138",
    "casa": "#0d2519", "casa_borda": "#437757",
    "filete": "#c9a24a",
    "texto": "#f1f6f0", "texto_suave": "#9cb7a5",
    "carta": "#f9f5ea", "carta_borda": "#ddd2b8", "carta_texto": "#171d18",
    "destaque": "#e8c06a", "acento": "#c9a24a", "alerta": "#e07a68", "sucesso": "#79c99a",
    # O vermelho volta a ser vermelho de baralho. O magenta anterior resolvia um
    # problema inexistente: o naipe é desenhado sobre a CARTA, que é creme, e
    # nunca sobre o verde — o contraste medido é contra a carta.
    "copas": "#c0202e", "ouros": "#a8620f", "paus": "#1c6b4a", "espadas": "#151f18",
    "vermelho": "#c0202e", "preto": "#151f18",
    "brilho": 0.0, "particula": 0.04, "glow": 1.0, "contorno": 0.0,
    "sombra": 0.55, "fonte_forte": false, "espaco": 0.0,
},
{
    "id": "neon", "nome": "Neon arcade", "claro": false, "fundo_estilo": "grade",
    "sensacao": "vívido, anos 80",
    # O brilho radial lavava a tela de verde-piscina: ciano interpolado com
    # amarelo dá verde. Neon não tem luz ambiente difusa — tem preto duro e
    # linha acesa. Por isso brilho quase zero e a identidade na grade de fundo.
    "fundo": "#050509", "fundo_alto": "#0b0b16", "painel": "#0e0e1f", "borda": "#22e0ff",
    "casa": "#0b0b1a", "casa_borda": "#1d6f88",
    "filete": "#22e0ff",
    "texto": "#f2f2ff", "texto_suave": "#8f8fc0",
    "carta": "#fbfbff", "carta_borda": "#c9c9e8", "carta_texto": "#0b0b14",
    "destaque": "#ffd400", "acento": "#22e0ff", "alerta": "#ff4d7d", "sucesso": "#4dffb0",
    # O neon vive no fundo e na moldura. Sobre a carta, que é superfície clara,
    # a tinta precisa ser escura ou o naipe some — o validador reprovou a versão
    # saturada em quatro pares de uma vez.
    "copas": "#d1005a", "ouros": "#c47000", "paus": "#0d7d9e", "espadas": "#5a2fb8",
    "vermelho": "#d1005a", "preto": "#3b3b7a",
    # Fonte forte e mais espaçamento contra halation: texto claro sobre
    # quase-preto "brilha" e borra. Achado da pesquisa.
    "brilho": 0.12, "particula": 0.10, "glow": 2.0, "contorno": 0.0,
    "sombra": 0.6, "fonte_forte": true, "espaco": 1.0,
},
{
    "id": "veludo", "nome": "Veludo e brasa", "claro": false, "fundo_estilo": "brilho",
    "sensacao": "quente, saturado, cassino clássico",
    "fundo": "#1e0d12", "fundo_alto": "#2c1219", "painel": "#33161f", "borda": "#5c2b33",
    "casa": "#2a1119", "casa_borda": "#8d4e5d",
    "filete": "#e8953c",
    "texto": "#fbeee9", "texto_suave": "#c9a49c",
    "carta": "#f9f0e4", "carta_borda": "#dbc9b2", "carta_texto": "#22131a",
    "destaque": "#e8953c", "acento": "#d97b5a", "alerta": "#ff6b5e", "sucesso": "#8fc99a",
    "copas": "#c22a45", "ouros": "#a86a12", "paus": "#2a7255", "espadas": "#2b1a20",
    "vermelho": "#c22a45", "preto": "#2b1a20",
    "brilho": 1.1, "particula": 0.18, "glow": 1.1, "contorno": 0.0,
    "sombra": 0.5, "fonte_forte": false, "espaco": 0.0,
},
{
    "id": "meianoite", "nome": "Meia-noite", "claro": false, "fundo_estilo": "vinheta",
    "sensacao": "dessaturado, minimalista",
    "fundo": "#131417", "fundo_alto": "#1b1d21", "painel": "#1f2126", "borda": "#3a3d45",
    "casa": "#1c1e23", "casa_borda": "#5f6471",
    "filete": "#cfd6e0",
    "texto": "#eceef2", "texto_suave": "#9498a1",
    "carta": "#f4f5f7", "carta_borda": "#cfd2d8", "carta_texto": "#16171a",
    "destaque": "#cfd6e0", "acento": "#8fb3d9", "alerta": "#c96a62", "sucesso": "#7fae92",
    "copas": "#b03a54", "ouros": "#8a6220", "paus": "#35705f", "espadas": "#23252a",
    "vermelho": "#b03a54", "preto": "#23252a",
    "brilho": 0.0, "particula": 0.07, "glow": 0.6, "contorno": 0.0,
    "sombra": 0.4, "fonte_forte": false, "espaco": 0.0,
},
{
    # Substituiu o "Mata funda", que era um segundo verde escuro com acento
    # quente e ficava indistinguível do Feltro na folha de contato. Roxo é a
    # única família de matiz que faltava no conjunto.
    "id": "ameixa", "nome": "Ameixa e ouro", "claro": false, "fundo_estilo": "brilho",
    "sensacao": "quente, encorpado, noturno",
    "fundo": "#1a0f22", "fundo_alto": "#241533", "painel": "#2a1a3b", "borda": "#4d2f66",
    "casa": "#241533", "casa_borda": "#794ea6",
    "filete": "#d9a441",
    "texto": "#f3ecf8", "texto_suave": "#b49dc6",
    "carta": "#f8f4ec", "carta_borda": "#d9cfc0", "carta_texto": "#1c1420",
    "destaque": "#d9a441", "acento": "#c9a0e0", "alerta": "#d9615f", "sucesso": "#79c99a",
    "copas": "#c2305c", "ouros": "#a06a12", "paus": "#2f7a62", "espadas": "#241a2c",
    "vermelho": "#c2305c", "preto": "#241a2c",
    "brilho": 0.9, "particula": 0.14, "glow": 1.0, "contorno": 0.0,
    "sombra": 0.5, "fonte_forte": false, "espaco": 0.0,
},
# ── fundo claro: o juice inverte, então os parâmetros mudam de verdade ──
{
    "id": "papel", "nome": "Papel e tinta", "claro": true, "fundo_estilo": "papel",
    "sensacao": "editorial, tipográfico",
    "fundo": "#efe9dc", "fundo_alto": "#e6dfd0", "painel": "#faf6ec", "borda": "#b0a68f",
    "casa": "#c6bba3", "casa_borda": "#8a7f66",
    "filete": "#9a6b10",
    "texto": "#1a1814", "texto_suave": "#5f5849",
    "carta": "#ffffff", "carta_borda": "#1a1814", "carta_texto": "#1a1814",
    "destaque": "#9a6b10", "acento": "#2f6f8f", "alerta": "#a82a24", "sucesso": "#1f6b4a",
    "copas": "#a82a24", "ouros": "#8f5410", "paus": "#1a5c46", "espadas": "#1a1814",
    "vermelho": "#a82a24", "preto": "#1a1814",
    # Sem glow: sobre creme ele vira borrão. O destaque vem de contorno e de
    # sombra projetada, não de luz.
    "brilho": 0.0, "particula": 0.09, "glow": 0.0, "contorno": 1.0,
    "sombra": 0.18, "fonte_forte": true, "espaco": 0.0,
},
{
    "id": "porcelana", "nome": "Porcelana", "claro": true, "fundo_estilo": "papel",
    "sensacao": "limpo, board-game premium",
    "fundo": "#f4f6f9", "fundo_alto": "#e9edf3", "painel": "#ffffff", "borda": "#a9b6c9",
    "casa": "#c2cad8", "casa_borda": "#7b8899",
    "filete": "#a8730f",
    "texto": "#1c2330", "texto_suave": "#5c6779",
    "carta": "#ffffff", "carta_borda": "#c9d2e0", "carta_texto": "#1c2330",
    "destaque": "#a8730f", "acento": "#37699c", "alerta": "#b0392f", "sucesso": "#1f7a55",
    "copas": "#b03050", "ouros": "#a35f14", "paus": "#1f7a5f", "espadas": "#2a3446",
    "vermelho": "#b03050", "preto": "#2a3446",
    "brilho": 0.0, "particula": 0.06, "glow": 0.0, "contorno": 0.6,
    "sombra": 0.16, "fonte_forte": false, "espaco": 0.0,
},
]

static var atual := 0

static var FUNDO := Color("#0d1322")
static var FUNDO_ALTO := Color("#16203a")
static var PAINEL := Color("#1a2544")
static var BORDA := Color("#33436f")
static var TEXTO := Color("#eef2fb")
static var TEXTO_SUAVE := Color("#9aa8c8")
## A casa vazia da grade. Token próprio, nunca derivado de PAINEL com alfa:
## derivar cor de outra cor funciona no tema escuro e quebra no claro.
## O filete: linha de 1 px do acento, desenhada por dentro da borda dos
## painéis. É o detalhe mais barato que existe e o que mais separa interface
## cara de interface improvisada — borda grossa é indie, filete é premium.
static var FILETE := Color("#f2c45c")
static var CASA := Color("#16203a")
static var CASA_BORDA := Color("#354877")
static var CARTA := Color("#f7f3e9")
static var CARTA_BORDA := Color("#d8d0bd")
static var CARTA_TEXTO := Color("#171b26")
static var DESTAQUE := Color("#f2c45c")
static var ACENTO := Color("#6ab0d6")
static var ALERTA := Color("#e0655f")
static var SUCESSO := Color("#6fc48c")
static var COPAS := Color("#d6335e")
static var OUROS := Color("#e08a2e")
static var PAUS := Color("#2f9e78")
static var ESPADAS := Color("#2a3350")

## Parâmetros de juice do tema vigente.
static var BRILHO := 1.0     ## força do brilho central do fundo
static var PARTICULA := 0.16 ## opacidade da poeira flutuante
static var GLOW := 1.0       ## halo em volta de número e carta madura
static var CONTORNO := 0.0   ## traço em volta dos naipes (temas claros)
static var SOMBRA := 0.45    ## opacidade da sombra projetada da carta
static var FONTE_FORTE := false
static var ESPACO := 0.0     ## espaçamento extra entre letras
## Estilo do fundo: "brilho", "grade", "tecido", "papel" ou "vinheta". Todos os
## temas compartilhavam o mesmo brilho radial, e era por isso que vários
## pareciam o mesmo tema pintado de outra cor. Fundo é identidade, não matiz.
static var FUNDO_ESTILO := "brilho"

## Quatro cores de naipe em vez de duas. Padrão ligado: é redundância a mais
## para daltônicos, e a forma do naipe continua sendo a informação principal.
static var quatro_cores := true

static func total() -> int:
    return TEMAS.size()

static func dados(indice: int) -> Dictionary:
    return TEMAS[clampi(indice, 0, TEMAS.size() - 1)]

static func e_claro() -> bool:
    return bool(dados(atual)["claro"])

static func usar(indice: int, cinza := false) -> void:
    atual = clampi(indice, 0, TEMAS.size() - 1)
    escala_de_cinza = cinza
    var t := TEMAS[atual]
    FUNDO = _cor(t["fundo"])
    FUNDO_ALTO = _cor(t["fundo_alto"])
    PAINEL = _cor(t["painel"])
    BORDA = _cor(t["borda"])
    TEXTO = _cor(t["texto"])
    TEXTO_SUAVE = _cor(t["texto_suave"])
    FILETE = _cor(t["filete"])
    CASA = _cor(t["casa"])
    CASA_BORDA = _cor(t["casa_borda"])
    CARTA = _cor(t["carta"])
    CARTA_BORDA = _cor(t["carta_borda"])
    CARTA_TEXTO = _cor(t["carta_texto"])
    DESTAQUE = _cor(t["destaque"])
    ACENTO = _cor(t["acento"])
    ALERTA = _cor(t["alerta"])
    SUCESSO = _cor(t["sucesso"])
    if quatro_cores:
        COPAS = _cor(t["copas"])
        OUROS = _cor(t["ouros"])
        PAUS = _cor(t["paus"])
        ESPADAS = _cor(t["espadas"])
    else:
        COPAS = _cor(t["vermelho"])
        OUROS = _cor(t["vermelho"])
        PAUS = _cor(t["preto"])
        ESPADAS = _cor(t["preto"])
    BRILHO = float(t["brilho"])
    PARTICULA = float(t["particula"])
    GLOW = float(t["glow"])
    CONTORNO = float(t["contorno"])
    SOMBRA = float(t["sombra"])
    FONTE_FORTE = bool(t["fonte_forte"])
    ESPACO = float(t["espaco"])
    FUNDO_ESTILO = str(t["fundo_estilo"])

## Cor do naipe, por índice: 0 copas, 1 ouros, 2 paus, 3 espadas.
static func cor_do_naipe(naipe: int) -> Color:
    match naipe:
        0: return COPAS
        1: return OUROS
        2: return PAUS
        _: return ESPADAS

static func _cor(hex: String) -> Color:
    var c := Color(hex)
    if not escala_de_cinza:
        return c
    # Luminância perceptual (Rec. 709), a mesma conta do teste de contraste.
    var l := 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
    return Color(l, l, l, c.a)

# ── fontes ──

const FONTE_BASE := "res://recursos/fontes/Nunito-Regular.ttf"
const FONTE_FORTE_ARQ := "res://recursos/fontes/Nunito-Bold.ttf"

static var _fonte: FontFile = null
static var _fonte_forte: FontFile = null

static func fonte(forte := false) -> FontFile:
    if forte:
        if _fonte_forte == null:
            _fonte_forte = load(FONTE_FORTE_ARQ)
        return _fonte_forte
    if _fonte == null:
        _fonte = load(FONTE_BASE)
    return _fonte

## A fonte que o tema pede para o texto de interface: o Neon precisa de peso
## maior para o texto não borrar sobre o fundo quase preto.
static func fonte_do_tema(forte := false) -> FontFile:
    return fonte(forte or FONTE_FORTE)
