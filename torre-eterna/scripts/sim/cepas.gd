class_name Cepas
extends RefCounted

## A GRAMÁTICA DO ENXAME.
##
## O jogo tinha 23 inimigos e 9 modificadores de elite, um por vez: 23 × 10 =
## 230 formas, e a medição de 7 h mostrou o catálogo esgotado bem antes do fim.
## Um jogo que se promete infinito não pode ter um número de formas que cabe
## numa tela.
##
## Em vez de escrever o inimigo 24, este arquivo escreve o COMPOSITOR. Uma cepa
## é um traço autoral — um jeito de ser duro, um jeito de andar, uma marca rara.
## Elas vivem em três eixos e um inimigo carrega no máximo uma de cada eixo, o
## que dá 14 × 12 × 12 combinações de três, mais as de duas e as de uma:
## 2.534 formas por base, 58.282 no total. Com 38 traços escritos à mão.
##
## As nove elites antigas continuam aqui, viraram cepas. Um inimigo com UMA cepa
## é exatamente o elite de antes, com os mesmos multiplicadores de `Bal.ELITE`:
## a economia medida pelo portão de balanceamento não se mexeu. O que é novo
## mora na profundidade — a segunda cepa só aparece depois da onda 60 e a
## terceira depois da 200, então o Enxame que ataca na hora 200 é feito de
## coisas que não podiam existir na hora 2.
##
## POR QUE MÁSCARA DE BITS. Os comportamentos de elite eram lidos com
## `e.elite_mod == "espinhoso"` em seis lugares quentes — comparação de string
## por impacto, por coleta, por quadro. Com três cepas por inimigo isso viraria
## três comparações. Cada cepa recebe um bit e a pergunta vira um E de inteiros:
## mais barato do que era ANTES da mudança, não apesar dela.

# ---------------------------------------------------------------- bits
# Só as cepas que algum ramo do jogo pergunta por nome precisam de bit.
const B_BLINDADO := 1 << 0
const B_ESPINHOSO := 1 << 1
const B_REGENERATIVO := 1 << 2
const B_MAGNETICO := 1 << 3
const B_FANTASMAL := 1 << 4
const B_VOLATIL := 1 << 5
const B_DENSO := 1 << 6
const B_FRIAVEL := 1 << 7
const B_CALCIFICADO := 1 << 8
const B_FEBRIL := 1 << 9
const B_SEIVA := 1 << 10
const B_ESPECTRO := 1 << 11
const B_BIPARTIDO := 1 << 12
const B_ARISCO := 1 << 13
const B_SALTADOR := 1 << 14
const B_ORBITAL := 1 << 15
const B_ACELERANTE := 1 << 16
const B_TEIMOSO := 1 << 17
const B_ERRANTE := 1 << 18
const B_RETARDATARIO := 1 << 19
const B_RECUADO := 1 << 20
const B_SANGUESSUGA := 1 << 21
const B_CINTILANTE := 1 << 22
const B_ECOANTE := 1 << 23
const B_FAMINTO := 1 << 24
const B_GLACIAL := 1 << 25
const B_MALDITO := 1 << 26
const B_TECELAO := 1 << 27
const B_ANCESTRAL := 1 << 28
const B_MIMETICO := 1 << 29
const B_SIMBIONTE := 1 << 30
const B_CASCUDO := 1 << 31

## O PORTÃO DE UM ÚNICO E.
##
## Quatro cepas pedem trabalho a cada quadro (regenerar, atravessar, acelerar,
## crescer). Sem esta máscara, todo inimigo pagaria quatro perguntas por quadro
## para que quatro em cada mil respondessem sim. Com ela, quem não tem nenhuma
## dessas paga UM E de inteiros e sai. A perna de 160 inimigos do portão de
## desempenho é onde isso se mede.
const MASCARA_TIQUE := B_REGENERATIVO | B_FANTASMAL | B_ACELERANTE | B_FAMINTO

## Cepas que o caminho do impacto pergunta. Mesmo portao de um E so.
const MASCARA_COMBATE := B_ESPINHOSO | B_BLINDADO | B_FRIAVEL

## Cepas que agem quando o corpo cai.
const MASCARA_MORTE := B_CINTILANTE | B_MALDITO | B_ECOANTE | B_BIPARTIDO

## Cepas que mudam o desenho do corpo. Mesmo motivo: o `_draw` pergunta uma vez.
const MASCARA_ARTE := B_BLINDADO | B_ESPINHOSO | B_CASCUDO | B_FAMINTO \
	| B_ANCESTRAL | B_TECELAO | B_MALDITO | B_ECOANTE | B_ESPECTRO

static var _bits := {
	"blindado": B_BLINDADO, "espinhoso": B_ESPINHOSO, "regenerativo": B_REGENERATIVO,
	"magnetico": B_MAGNETICO, "fantasmal": B_FANTASMAL, "volatil": B_VOLATIL,
	"denso": B_DENSO, "friavel": B_FRIAVEL, "calcificado": B_CALCIFICADO,
	"febril": B_FEBRIL, "seiva": B_SEIVA, "espectro": B_ESPECTRO,
	"bipartido": B_BIPARTIDO, "arisco": B_ARISCO, "saltador": B_SALTADOR,
	"orbital": B_ORBITAL, "acelerante": B_ACELERANTE, "teimoso": B_TEIMOSO,
	"errante": B_ERRANTE, "retardatario": B_RETARDATARIO, "recuado": B_RECUADO,
	"sanguessuga": B_SANGUESSUGA, "cintilante": B_CINTILANTE, "ecoante": B_ECOANTE,
	"faminto": B_FAMINTO, "glacial": B_GLACIAL, "maldito": B_MALDITO,
	"tecelao": B_TECELAO, "ancestral": B_ANCESTRAL, "mimetico": B_MIMETICO,
	"simbionte": B_SIMBIONTE, "cascudo": B_CASCUDO,
}

## O Array vazio compartilhado por todo inimigo sem cepa. Ver `EnemyAI.criar`.
## E somente leitura por contrato: quem tem cepas recebe a lista nova do sorteio.
static var VAZIO: Array = []

static func bit(id: String) -> int:
	return int(_bits.get(id, 0))

# ---------------------------------------------------------------- profundidade
## A partir de onde a segunda e a terceira cepa passam a ser possíveis.
const ONDA_SEGUNDA := 60
const ONDA_TERCEIRA := 200
## Chance de subir de um degrau para o próximo, uma vez que a onda permite.
const CHANCE_SEGUNDA := 0.30
const CHANCE_TERCEIRA := 0.22

## Quantas cepas este inimigo carrega.
##
## O primeiro degrau é a chance de elite de sempre — não mexi nela, para que o
## portão de balanceamento continue medindo o mesmo jogo. Os degraus 2 e 3 são
## a parte nova, e só existem fundo adentro.
## DOIS GERADORES, E O MOTIVO E O PORTAO.
##
## `rng` e o fluxo principal do jogo — o mesmo que decide qual inimigo nasce,
## quando cai um dourado, o que o bau larga. Ele tem semente fixa, e o portao de
## desempenho depende disso: rodar 20 minutos de jogo com a mesma semente tem
## que dar a mesma torre, senao a medida compara dois jogos diferentes. O
## comentario em `tools/suites/perf.gd` registra o estrago quando isso escorrega
## — 207 projeteis numa medicao e 536 na seguinte, do MESMO commit.
##
## As Cepas precisam de MAIS sorteios por inimigo do que o elite antigo (o grau,
## o eixo, a cepa de cada eixo). Se todos saissem do fluxo principal, cada
## nascimento empurraria a sequencia inteira para frente e o jogo de 20 minutos
## viraria outro. Entao o fluxo principal continua gastando exatamente o que
## gastava antes — uma chance de elite, mais UM sorteio para a primeira cepa,
## no lugar do `escolher` que sorteava o modificador — e todo o resto sai de
## `rng2`, um gerador so das Cepas. Mexer nas Cepas amanha nao move a onda.
static func quantas(onda: int, rng2, chance_base: float, rng) -> int:
	if not rng.chance(chance_base):
		return 0
	if onda < ONDA_SEGUNDA or not rng2.chance(CHANCE_SEGUNDA):
		return 1
	if onda < ONDA_TERCEIRA or not rng2.chance(CHANCE_TERCEIRA):
		return 2
	return 3

# ---------------------------------------------------------------- sorteio
const EIXOS := ["corpo", "andar", "marca"]

## Sorteia até `n` cepas, no máximo uma por eixo.
##
## Um eixo por vez, sorteado sem reposição: é isso que garante que o nome
## composto leia bem ("Grunhido Encouraçado Frenético" e nunca "Grunhido
## Encouraçado Colossal") e que dois traços do mesmo tipo não se anulem.
static func sortear(n: int, rng2, rng) -> Array:
	if n <= 0 or Dados.cepas.is_empty():
		return []
	# A PRIMEIRA CEPA SAI DO FLUXO PRINCIPAL, e sozinha — um sorteio, o mesmo
	# que o `escolher(Dados.elites)` de antes gastava. Ver `quantas`.
	var saida: Array = []
	var primeira = rng.por_peso(Dados.cepas, "peso")
	if not (primeira is Dictionary):
		return saida
	saida.append(primeira)
	if n <= 1:
		return saida
	# As outras vem dos eixos que sobraram, pelo gerador das Cepas.
	var restantes: Array = []
	for eixo in EIXOS:
		if str(eixo) != str((primeira as Dictionary).get("eixo", "")):
			restantes.append(eixo)
	# Embaralha para que a segunda cepa nao seja sempre do mesmo eixo.
	for i in range(restantes.size() - 1, 0, -1):
		var t: int = rng2.inteiro(0, i)
		var tmp = restantes[i]
		restantes[i] = restantes[t]
		restantes[t] = tmp
	for k in mini(n - 1, restantes.size()):
		var pool: Array = Dados.cepas_por_eixo.get(str(restantes[k]), [])
		if pool.is_empty():
			continue
		var c = rng2.por_peso(pool, "peso")
		if c is Dictionary:
			saida.append(c)
	return saida

# ---------------------------------------------------------------- nome
## O nome composto, nas duas línguas.
##
## Em português o adjetivo vem depois do substantivo e em inglês vem antes, e a
## ordem entre os adjetivos também muda de língua para língua. Compor por
## concatenação cega daria "Armored Frenzied Grunt" certo e "Encouraçado
## Frenético Grunhido" errado — por isso a ordem é decidida aqui, e não no lugar
## que desenha.
static func nome_composto(base: String, lista: Array, ingles: bool) -> String:
	if lista.is_empty():
		return base
	var adj: Array = []
	for c in lista:
		if c is Dictionary:
			var t := Ux.txt(c, "nome", ingles)
			if t != "":
				adj.append(t)
	if adj.is_empty():
		return base
	if ingles:
		return " ".join(adj) + " " + base
	return base + " " + " ".join(adj)

## A cor da cepa mais rara da lista, para tingir o corpo.
static func cor_marcante(lista: Array) -> String:
	var melhor := ""
	var menor := 1e9
	for c in lista:
		if not (c is Dictionary):
			continue
		var p := float(c.get("peso", 100.0))
		if p < menor:
			menor = p
			melhor = str(c.get("cor", ""))
	return melhor

## Assinatura estável de uma forma, para o contador de formas vistas.
##
## Ordenada por id: "grunhido|arisco+blindado" e "grunhido|blindado+arisco" são a
## MESMA forma, e sem ordenar o contador dobraria sozinho a cada permutação —
## um número inflado é pior do que nenhum número.
static func assinatura(tipo: String, lista: Array) -> String:
	if lista.is_empty():
		return tipo
	var ids: Array = []
	for c in lista:
		if c is Dictionary:
			ids.append(str(c.get("id", "")))
	ids.sort()
	return tipo + "|" + "+".join(ids)
