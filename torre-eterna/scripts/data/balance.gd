class_name Bal
extends RefCounted

## Bal — TODA a matemática de balanceamento num lugar só.
## Quem quiser rebalancear mexe aqui e roda `tools/sim_balance.gd`.

# ============================================================== ONDAS =====
const HP_BASE := 10.0
const HP_CRESC := 1.152
const HP_POLI_DIV := 55.0
const HP_POLI_EXP := 2.35

const OURO_BASE := 3.2
const OURO_CRESC := 1.128
const XP_BASE := 1.6
const XP_CRESC := 1.09

## HP (log10) de um inimigo comum na onda w.
static func hp_onda(w: int) -> float:
	var poli := 1.0 + pow(maxf(0.0, float(w)) / HP_POLI_DIV, HP_POLI_EXP)
	return Big.mul_f(Big.mul_f(Big.from(HP_BASE), pow(HP_CRESC, float(w - 1))), poli)

static func ouro_onda(w: int) -> float:
	return Big.mul_f(Big.from(OURO_BASE), pow(OURO_CRESC, float(w - 1)))

static func xp_onda(w: int) -> float:
	return Big.mul_f(Big.from(XP_BASE), pow(XP_CRESC, float(w - 1)))

static func contagem_onda(w: int, infinito: bool = false) -> int:
	if infinito:
		# Teto muito mais alto (128 em vez de 30), não teto nenhum: sem limite,
		# a onda 10.000 pediria 3.341 inimigos e levaria doze minutos só para
		# nascer. A dificuldade do Modo Infinito vem de `escala_infinito`, que
		# não para nunca; a contagem só precisa encher a tela.
		return 8 + mini(120, w / 3)
	return 8 + mini(22, w / 3)

## No Modo Infinito o inimigo também não para de crescer: o expoente da vida
## ganha um empurrão suave por onda, para que "infinito" seja um desafio de
## verdade e não uma esteira. Fora do modo, devolve 1,0 e nada muda.
static func escala_infinito(w: int, infinito: bool) -> float:
	if not infinito:
		return 1.0
	return 1.0 + float(w) * 0.004

static func eh_chefe(w: int) -> bool:
	return w % 10 == 0

static func eh_super_chefe(w: int) -> bool:
	return w % 50 == 0

## Velocidade calibrada pelo TEMPO MORTO: com 26 px/s o jogador olhava para
## uma tela vazia por 11 s antes do primeiro tiro. Agora o combate começa em
## ~5 s e cada inimigo passa ~6 s dentro do alcance.
static func velocidade_inimigo(w: int) -> float:
	return 44.0 + minf(30.0, float(w) * 0.16)

static func intervalo_spawn(w: int) -> float:
	return maxf(0.22, 1.15 - log(float(w) + 1.0) / 2.302585 * 0.28)

static func chance_elite(w: int) -> float:
	return 0.0 if w < 8 else minf(0.28, 0.02 + float(w) * 0.0022)

static func chance_dourado(w: int) -> float:
	return 0.0 if w < 5 else minf(0.035, 0.004 + float(w) * 0.00018)

# multiplicadores por arquétipo  [hp, ouro, xp, escala, velocidade]
const CHEFE := {"hp": 16.0, "ouro": 22.0, "xp": 18.0, "escala": 2.1, "vel": 0.62}
const SUPER_CHEFE := {"hp": 70.0, "ouro": 90.0, "xp": 70.0, "escala": 2.9, "vel": 0.5}
const ELITE := {"hp": 3.4, "ouro": 4.2, "xp": 3.5, "escala": 1.35, "vel": 1.0}
const DOURADO := {"hp": 0.9, "ouro": 35.0, "xp": 6.0, "escala": 1.15, "vel": 1.9}

# ========================================================== PROGRESSÃO ====
const NIVEL_MAX := 500

static func custo_nivel(n: int) -> float:
	return Big.mul_f(Big.mul_f(Big.from(12.0), pow(1.28, float(n - 1))), 1.0 + pow(float(n) / 30.0, 1.6))

static func pontos_por_nivel(n: int) -> int:
	var p := 1
	if n % 5 == 0:
		p += 1
	if n % 25 == 0:
		p += 3
	return p

# ============================================================= COMBATE ====
## Estes dois duplicam `data/stats.json`. Ficam aqui porque os testes precisam
## de um valor de referência em código, e `validar_dados.gd` compara os dois:
## se o JSON mudar e a constante não, o portão de dados reprova. Os outros seis
## que moravam neste bloco (cadência, crítico, velocidade, vida, regeneração)
## eram cópias sem nenhum leitor — dois deles nomeando stats que nem existem no
## JSON. Foram removidos em vez de mantidos por educação.
const DANO_BASE := 4.0
const ALCANCE_BASE := 260.0

const ARMADURA_K := 60.0
const COMBO_JANELA := 2.6
const COMBO_BONUS_POR := 0.006
const COMBO_TETO := 250
const OVERKILL_TETO := 0.5

# ========================================================== CEPAS ====
## O "maldito" paga 10x de ouro e cobra este tanto da vida MAXIMA da torre ao
## morrer. Fracao da maxima, e nao valor fixo, para que a barganha continue
## significando a mesma coisa na onda 2000.
const MALDITO_DANO := 0.04
## Vida do eco que o "ecoante" deixa, como fracao da do original.
const ECO_HP := 0.30
## Dano de contato: fração da vida MÁXIMA DO INIMIGO (que escala com a onda),
## com um piso linear para o começo do jogo ainda ter tensão.
## Antes isso era uma fração da vida da torre — o que tornava comprar vida inútil.
const DANO_CONTATO_FRAC := 0.013
const DANO_CONTATO_CHEFE := 0.040
const DANO_CONTATO_PISO_BASE := 2.0
const DANO_CONTATO_PISO_ONDA := 0.45
## O escudo e a regeneração são PARCELAS da vida máxima, não números soltos.
##
## Enquanto foram absolutos (+45 de escudo por nível, teto 2025; +0,65 de regen
## por nível), e a vida ganhou multiplicadores em seis lugares diferentes (Forja
## ×1,4 por nível, talento Fortaleza, relíquia Costela, nó af_vida, cartas), o
## escudo e a regeneração viravam pó no meio do jogo — e a categoria Defesa
## inteira deixava de valer a compra. Como parcela, herdam TODOS os
## multiplicadores de vida, inclusive o ×0 da carta Espelho do Enxame.
##
## Nos números de hoje, investimento máximo dá ~60% de vida extra em escudo e
## ~1,8% de vida por segundo de regeneração.
const ESCUDO_POR_PONTO := 0.0003
const REGEN_POR_PONTO := 0.0004
const ESCUDO_REGEN_POR_PONTO := 0.002

const IFRAMES := 0.35
const RESPAWN := 3.0
const PENALIDADE_MORTE := 1
## Quanto do ouro NAO GASTO fica no chao quando a torre cai.
##
## Um quarto: doi o bastante para deixar a torre cair nunca ser a jogada certa,
## pouco o bastante para nao apagar uma sessao. Nao toca no que ja virou
## melhoria — so no que estava parado no cofre.
const PERDA_OURO_MORTE := 0.25
const RAIO_TORRE := 34.0

## Dano (log10) que um inimigo causa ao alcançar a torre.
## Teto do dano de contato, como fração da vida MÁXIMA da torre.
##
## `dano_contato` era função pura do inimigo: 1,3% da vida DELE. Como a vida do
## inimigo cresce 0,061 década por onda e a da torre cresce menos, o contato
## ganhava da vida ~1,12× por onda. Medido numa corrida de 3 h: na onda 230 a
## torre aguentava 28.190 vazamentos; na onda 422 morria em UM toque, com
## 354.000× de sobra. Ou seja, a categoria Defesa inteira — vida, armadura,
## escudo, regeneração, forja de vida — virava desperdício a partir da onda
## ~300, e o relatório fechava com 181 mortes em 3 h, uma por minuto.
##
## Com o teto, vazar volta a ser CUSTO em vez de morte instantânea, e comprar
## vida volta a comprar sobrevivência. Chefe machuca mais, como sempre.
const CONTATO_TETO_VIDA := 0.22
const CONTATO_TETO_VIDA_CHEFE := 0.45

static func dano_contato(hp_inimigo_log: float, onda: int, chefe: bool, escala: float, vida_max_log: float = Big.ZERO) -> float:
	var frac := DANO_CONTATO_CHEFE if chefe else DANO_CONTATO_FRAC
	var por_hp := Big.mul_f(hp_inimigo_log, frac)
	# o piso também respeita o arquétipo: chefe machuca mais mesmo no começo
	var piso := Big.mul_f(
		Big.from(DANO_CONTATO_PISO_BASE + float(onda) * DANO_CONTATO_PISO_ONDA),
		frac / DANO_CONTATO_FRAC)
	var base := Big.max_b(por_hp, piso)
	if escala > 1.0:
		base = Big.mul_f(base, sqrt(escala))
	if vida_max_log > Big.LIMIAR_ZERO:
		var teto := Big.mul_f(vida_max_log, CONTATO_TETO_VIDA_CHEFE if chefe else CONTATO_TETO_VIDA)
		base = Big.min_b(base, teto)
	return base

## Atalho: dano de contato de um inimigo específico, multiplicado.
static func mul_contato(e, onda: int, mult: float, vida_max_log: float = Big.ZERO) -> float:
	return Big.mul_f(dano_contato(e.hp_max, onda, e.chefe, e.escala, vida_max_log), mult)

## O teto de uma melhoria cresce com o recorde global.
##
## Somando o custo de maxar TODAS as 33 melhorias com teto, o catálogo inteiro
## custava 6,3e10 de ouro. Medido numa corrida automática: na onda 65, aos 22
## minutos, o jogador já tinha 2,6e11 no banco — 4,2× o preço de comprar o jogo
## inteiro. Dali em diante sobravam SEIS botões para as ~370 ondas restantes, e
## as categorias Elemental, Orbes, Utilidade e Defesa viravam enfeite antes de
## um terço da sessão. A tela de melhorias ficava sem decisão nenhuma.
##
## O teto agora acompanha o recorde. Como o custo cresce geométrico, os níveis
## além do teto original custam muito mais — o sink continua aberto sem que
## nada fique barato. Abaixo da onda 50 nada muda: o começo do jogo é o mesmo.
##
## Este numero ja foi 0,006, 0,01 e 0,02, e a medicao antiga dizia que subir nao
## entregava nada e custava 2,3x de CPU (p90 de 3.633 us em 0,01 contra 8.532 us
## em 0,02, o bastante para reprovar o portao de desempenho). A conclusao estava
## certa sobre o SINTOMA e errada sobre a CAUSA, e as duas coisas ja foram
## consertadas:
##
##  - A CPU nao explodia por causa do teto em si. Explodia porque quatro
##    melhorias transformam NIVEL em ENTIDADE: multishot da +1 projetil, orbe
##    da +1 orbe, perfuracao e ricochete dao +1 corpo por tiro. Com o teto
##    crescendo, a onda 200 pedia 1.190 projeteis por disparo num pool de 800.
##    Essas quatro agora tem `tetoFixo` no JSON e nao crescem; as outras 29,
##    que so mexem em numero, crescem sem custo de quadro.
##  - O catalogo tambem nao esvaziava por causa do teto. Esvaziava porque o
##    jogador PARAVA na onda ~85 e o teto e funcao do recorde: sem recorde, sem
##    teto novo. E ele parava porque reflexo e espinho devolviam uma fracao do
##    dano DELE sem teto nenhum (ver REFLEXO_TETO_VIDA). Corrigido isso, o
##    recorde volta a subir e o teto sobe junto.
const TETO_ONDA_LIVRE := 50
const TETO_CRESCE_POR_ONDA := 0.03

## O teto cresce GEOMETRICO com o recorde, nao linear.
##
## Era linear: `base * 0,01 * (recorde - 50)`. O ouro cresce exponencial, entao
## nenhum crescimento linear acompanha a capacidade de compra: medido, o
## catalogo esvaziava na onda 64 e dali em diante 33 dos 39 botoes ficavam
## mortos. Agora e `base * 1,03^(recorde-50)`: onda 100 da 4,4x o teto original,
## onda 200 da 84x, e o limite volta a ser o CUSTO, que tambem e geometrico.
## Nada fica barato; o que muda e a tela nao ficar sem decisao.
## `tetoFixo` no JSON: melhorias cujo NIVEL vira ENTIDADE nao crescem.
##
## multishot da +1 projetil por nivel, orbe da +1 orbe, perfuracao e ricochete
## dao +1 corpo atravessado por tiro. Com o teto geometrico, na onda 200 o teto
## de multishot seria 14 x 1,03^150 = 1.190 niveis, ou seja 1.191 PROJETEIS por
## disparo, ate 12 disparos por quadro, num pool de 800. Nao e balanceamento, e
## um travamento — e o mesmo vale para 850 orbes. Estas quatro ficam no teto de
## projeto; as outras 29 crescem.
static func teto_upgrade(teto_base: int, recorde: int, fixo: bool = false) -> int:
	if teto_base < 0:
		return -1
	if fixo:
		return teto_base
	var ondas := float(maxi(0, recorde - TETO_ONDA_LIVRE))
	return maxi(teto_base, int(floor(float(teto_base) * pow(1.0 + TETO_CRESCE_POR_ONDA, ondas))))

## Redes de seguranca: por mais que os dados mudem, um quadro nao pode pedir mil
## projeteis nem duzentos orbes. Nao apertam nenhum build real (o teto de
## projeto e 15 projeteis e 11 orbes); existem para que um numero errado no JSON
## vire "menos do que pedi" em vez de "o jogo parou".
const PROJETEIS_TETO := 48
const ORBES_TETO := 24

## Quanto tempo um projetil vive, em funcao da velocidade dele.
##
## Era 3,5 s para todo mundo. Com a melhoria de velocidade (+26 px/s por nivel)
## ele cruza a arena inteira em menos de dois segundos e passa o resto do tempo
## vivo sem poder acertar nada — mas continua sendo testado contra a grade a
## cada quadro. Medido: o pool de 800 ficava saturado com ~500 projeteis vivos e
## a colisao sozinha custava 2,9 ms por passo.
##
## Vive aqui, e nao inline na torre, porque assim o portao pode perguntar pela
## CURVA em vez de procurar a formula no texto do arquivo.
const VIDA_PROJETIL_MAX := 3.5
const VIDA_PROJETIL_MIN := 0.7
static func vida_projetil(velocidade: float) -> float:
	return clampf(2200.0 / maxf(160.0, velocidade), VIDA_PROJETIL_MIN, VIDA_PROJETIL_MAX)

static func fator_armadura(armadura: float, penetracao: float) -> float:
	var a := maxf(0.0, armadura * (1.0 - minf(0.95, penetracao)))
	return ARMADURA_K / (ARMADURA_K + a)

# ---------------------------------------------------------- elementos ----
const ELEMENTOS := {
	"fogo":   {"cor": "#ff6b35", "dot": 0.35, "duracao": 3.0,  "pilhas": 5},
	"gelo":   {"cor": "#6bd6ff", "lentidao": 0.30, "duracao": 2.5, "pilhas": 3},
	"raio":   {"cor": "#ffe45e", "corrente": 3, "fator": 0.45},
	"veneno": {"cor": "#8cff6b", "dot": 0.22, "duracao": 6.0, "pilhas": 12},
	"vazio":  {"cor": "#b06bff", "ampliacao": 0.18, "duracao": 4.0, "pilhas": 4},
}

# =========================================================== PRESTÍGIO ====
const ASC_ONDA_MIN := 25
const ASC_EXP := 0.055
const SING_ONDA_MIN := 150
const SING_ASC_MIN := 8
const SING_EXP := 0.021
const TRANS_ONDA_MIN := 500
const TRANS_SING_MIN := 5
const TRANS_EXP := 0.008

static func fragmentos(w: int, bonus: float = 1.0) -> float:
	if w < ASC_ONDA_MIN:
		return Big.ZERO
	return Big.mul_f(Big.from_log(float(w - ASC_ONDA_MIN + 1) * ASC_EXP), bonus)

static func nucleos(w_global: int, ascensoes: int, bonus: float = 1.0) -> float:
	if w_global < SING_ONDA_MIN:
		return Big.ZERO
	var base := Big.from_log(float(w_global - SING_ONDA_MIN + 1) * SING_EXP)
	return Big.mul_f(base, (1.0 + log(1.0 + float(ascensoes)) / 2.302585 * 0.6) * bonus)

static func eter(w_global: int, singularidades: int, bonus: float = 1.0) -> float:
	if w_global < TRANS_ONDA_MIN:
		return Big.ZERO
	var base := Big.from_log(float(w_global - TRANS_ONDA_MIN + 1) * TRANS_EXP)
	return Big.mul_f(base, (1.0 + float(singularidades) * 0.15) * bonus)

# ============================================================= OFFLINE ====
const OFFLINE_EFICIENCIA := 0.45
const OFFLINE_HORAS_BASE := 4.0
const OFFLINE_HORAS_TETO := 48.0
const OFFLINE_MIN_SEG := 30.0

# ================================================================ LOOT ====
const CHANCE_CARTA := 0.0009
const CHANCE_CARTA_TETO := 0.010
const CHANCE_CARTA_ELITE_TETO := 0.06
const CHANCE_CARTA_CHEFE := 1.0
const CHANCE_CARTA_ELITE := 0.018
const GEMAS_CHEFE := 3
const GEMAS_SUPER := 25
const POEIRA := {"comum": 5, "incomum": 14, "raro": 45, "epico": 160, "lendario": 600, "mitico": 2400}

# ========================================================== AUTOMAÇÃO ====
## Teto do rendimento dos juros, em "quantas ondas de ouro por segundo".
##
## Juros compostos sobre o estoque nao tem ponto fixo: com 10% ao segundo o
## ouro cresce e^360 em uma hora e a economia inteira deixa de existir — matar
## inimigo, vender carta, evento de ouro, nada mais importa perto do relogio.
## O teto amarra o rendimento ao PROGRESSO (o que uma onda paga) em vez do
## tempo parado, e mantem a fantasia: guardar ouro rende, mas nao substitui
## jogar.
const JUROS_TETO_ONDAS := 2.5

static func juros_teto(onda: int, dt: float) -> float:
	return Big.mul_f(ouro_onda(onda), JUROS_TETO_ONDAS * dt)

## Recarga entre dois golpes de contato do MESMO inimigo. So o chefe sobrevive
## ao proprio impacto e fica encostado; sem esta recarga ele batia a cada passo
## de fisica, ou seja, 60 golpes por segundo em vez de um.
const CD_CONTATO := 0.9

## O inimigo "refletir" devolve uma fracao do golpe na torre. Fica aqui, e nao
## solto no codigo da torre, porque ja passou uma vez em unidade errada: o valor
## LINEAR foi entregue onde se esperava log10 e a torre morria num tiro.
const REFLEXO_FRAC := 0.02
const ESPINHO_FRAC := 0.06

## ...e agora tem TETO, pela mesma razao que o dano de contato tem.
##
## Reflexo e espinho eram fracao do DANO DO JOGADOR, que cresce exponencial, sem
## nenhum limite ligado a torre. Medido numa corrida automatica: na onda 85 o
## tiro valia 1,1e10 e a torre tinha 1,3e7 de vida, entao 2% do proprio golpe
## dava 17x a vida MAXIMA da torre — um tiro no Guardiao do Espelho, ou num
## elite espinhoso, e a torre caia inteira. O relatorio mostrava 23 quedas entre
## as ondas 58 e 85 com ZERO inimigos chegando na torre: ela se matava sozinha,
## e o recorde parava ali. Nao era teto de melhoria nem curva de custo; era o
## jogador sendo punido por ficar mais forte.
##
## Com teto, a punicao volta a ser CUSTO: cada golpe devolvido tira no maximo
## uma parcela da vida maxima, os iframes de 0,35 s limitam a ~3 golpes por
## segundo, e a regeneracao no investimento maximo (~1,8%/s) segura uma
## exposicao curta mas nao uma longa. Quem insiste em atirar no refletor ainda
## morre; quem mata e segue, nao.
const REFLEXO_TETO_VIDA := 0.08
const ESPINHO_TETO_VIDA := 0.04

static func dano_refletido(dano_log: float, vida_max_log: float = Big.ZERO) -> float:
	return _devolvido(dano_log, vida_max_log, REFLEXO_FRAC, REFLEXO_TETO_VIDA)

static func dano_espinho(dano_log: float, vida_max_log: float = Big.ZERO) -> float:
	return _devolvido(dano_log, vida_max_log, ESPINHO_FRAC, ESPINHO_TETO_VIDA)

static func _devolvido(dano_log: float, vida_max_log: float, frac: float, teto: float) -> float:
	var base := Big.mul_f(dano_log, frac)
	if vida_max_log > Big.LIMIAR_ZERO:
		base = Big.min_b(base, Big.mul_f(vida_max_log, teto))
	return base

const INTERVALO_AUTOCOMPRA := 0.35

## Quanto do cofre a compra automatica pode gastar de uma vez. Um terco: alto o
## bastante para acompanhar a inflacao do idle (o ouro cresce em ordens de
## grandeza), baixo o bastante para nao despejar tudo numa melhoria so e deixar
## as outras paradas.
const FATIA_AUTOCOMPRA := 0.34

static func velocidade_max(nucleos_log: float) -> float:
	return minf(6.0, 1.0 + floor(maxf(0.0, nucleos_log) * 2.0))
