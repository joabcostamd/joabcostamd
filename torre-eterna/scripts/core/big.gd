class_name Big
extends RefCounted

## Números gigantes para incremental profundo — SEM alocação.
##
## Todo valor "grande" do jogo é guardado como o seu LOGARITMO NA BASE 10,
## num float de 64 bits. Ou seja: se a variável vale `a`, o número real é 10^a.
##
## Por quê: multiplicar/dividir vira somar/subtrair (exato e instantâneo),
## o alcance vai muito além de 1e308, e nada é alocado no heap — essencial
## para rodar centenas de inimigos a 60 fps.
##
## Convenções:
##   ZERO  -> -1e30 (sentinela; sobrevive ao JSON, ao contrário de -INF)
##   ONE   -> 0.0
##   Números negativos NÃO são representáveis: quem precisa de sinal
##   (raro neste jogo) compara antes com `gt()` e subtrai na ordem certa.

const ZERO := -1.0e30
const ONE := 0.0
const LIMIAR_ZERO := -1.0e29
const CORTE_SOMA := 17.0          ## além disto a parcela menor some no float
const MAX_LOG := 1.0e29

## ------------------------------------------------------------- construção

static func from(n: float) -> float:
	if n <= 0.0:
		return ZERO
	return log(n) / 2.302585092994046

static func from_int(n: int) -> float:
	return from(float(n))

static func to_f(a: float) -> float:
	if a <= LIMIAR_ZERO:
		return 0.0
	if a > 308.0:
		return INF
	return pow(10.0, a)

## Converte para inteiro (satura em 2^62 para não estourar).
static func to_i(a: float) -> int:
	var f := to_f(a)
	if f >= 4.6e18:
		return 4611686018427387904
	return int(f)

static func is_zero(a: float) -> bool:
	return a <= LIMIAR_ZERO

## ------------------------------------------------------------- aritmética

static func mul(a: float, b: float) -> float:
	if a <= LIMIAR_ZERO or b <= LIMIAR_ZERO:
		return ZERO
	return clampf(a + b, ZERO, MAX_LOG)

## Multiplica por um número comum (>0).
static func mul_f(a: float, k: float) -> float:
	if a <= LIMIAR_ZERO or k <= 0.0:
		return ZERO
	return clampf(a + log(k) / 2.302585092994046, ZERO, MAX_LOG)

static func div(a: float, b: float) -> float:
	if a <= LIMIAR_ZERO:
		return ZERO
	if b <= LIMIAR_ZERO:
		return MAX_LOG
	return clampf(a - b, ZERO, MAX_LOG)

static func div_f(a: float, k: float) -> float:
	if k == 0.0:
		return MAX_LOG
	return mul_f(a, 1.0 / k)

## Soma exata via log-sum-exp: log10(10^a + 10^b).
static func add(a: float, b: float) -> float:
	if a <= LIMIAR_ZERO:
		return b
	if b <= LIMIAR_ZERO:
		return a
	var hi := a
	var lo := b
	if b > a:
		hi = b
		lo = a
	var d := hi - lo
	if d > CORTE_SOMA:
		return hi
	return hi + log(1.0 + pow(10.0, -d)) / 2.302585092994046

## Subtração: devolve ZERO se b >= a.
static func sub(a: float, b: float) -> float:
	if b <= LIMIAR_ZERO:
		return a
	if a <= LIMIAR_ZERO or b >= a:
		return ZERO
	var d := b - a
	if d < -CORTE_SOMA:
		return a
	var interno := 1.0 - pow(10.0, d)
	if interno <= 0.0:
		return ZERO
	return a + log(interno) / 2.302585092994046

static func pow_n(a: float, n: float) -> float:
	if a <= LIMIAR_ZERO:
		return ZERO if n > 0.0 else ONE
	return clampf(a * n, ZERO, MAX_LOG)

static func sqrt_b(a: float) -> float:
	return pow_n(a, 0.5)

## 10^x direto (x já é o logaritmo).
static func from_log(x: float) -> float:
	return clampf(x, ZERO, MAX_LOG)

static func log10_of(a: float) -> float:
	return a

## ------------------------------------------------------------ comparação

static func gt(a: float, b: float) -> bool: return a > b
static func gte(a: float, b: float) -> bool: return a >= b
static func lt(a: float, b: float) -> bool: return a < b
static func lte(a: float, b: float) -> bool: return a <= b
static func max_b(a: float, b: float) -> float: return maxf(a, b)
static func min_b(a: float, b: float) -> float: return minf(a, b)

## Fração a/b como float comum, limitada a [0,1] — para barras de vida.
static func frac(a: float, b: float) -> float:
	if b <= LIMIAR_ZERO:
		return 0.0
	var d := a - b
	if d >= 0.0:
		return 1.0
	if d < -12.0:
		return 0.0
	return clampf(pow(10.0, d), 0.0, 1.0)

## ------------------------------------------------------- custos geométricos

## Custo do item `n` (0-indexado) numa curva base * growth^n.
static func custo(base: float, growth: float, n: int) -> float:
	return mul_f(from(base), pow(growth, float(n)))

## Custo total de `count` compras a partir de `owned`.
static func geo_sum(base: float, growth: float, owned: int, count: int) -> float:
	if count <= 0:
		return ZERO
	var primeiro := custo(base, growth, owned)
	if absf(growth - 1.0) < 1e-9:
		return mul_f(primeiro, float(count))
	# primeiro * (growth^count - 1) / (growth - 1)
	var g_pow := pow_n(from(growth), float(count))
	var numerador := sub(g_pow, ONE)
	return div(mul(primeiro, numerador), from(growth - 1.0))

## Quantas compras cabem no orçamento (log) — resolve a soma geométrica.
static func max_afford(budget: float, base: float, growth: float, owned: int, teto: int = 1000000) -> int:
	if budget <= LIMIAR_ZERO:
		return 0
	var primeiro := custo(base, growth, owned)
	if primeiro > budget:
		return 0
	if absf(growth - 1.0) < 1e-9:
		return mini(teto, to_i(div(budget, primeiro)))
	# k = log_g(1 + orcamento*(g-1)/primeiro)
	var interno := add(ONE, div(mul_f(budget, growth - 1.0), primeiro))
	var k := int(floor(interno / (log(growth) / 2.302585092994046) + 1e-9))
	return clampi(k, 0, teto)

## ---------------------------------------------------------- serialização

## Guardado como float puro no JSON (finito, seguro).
static func to_save(a: float) -> float:
	if a <= LIMIAR_ZERO:
		return ZERO
	return a

static func from_save(v) -> float:
	if v is float or v is int:
		var f := float(v)
		if is_nan(f) or is_inf(f):
			return ZERO
		return clampf(f, ZERO, MAX_LOG)
	return ZERO
