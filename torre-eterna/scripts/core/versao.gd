class_name Versao
extends RefCounted

## A VERSÃO DO JOGO, E O QUE MUDOU NELA.
##
## O jogo não tinha número de versão em lugar nenhum. Sem ele: um relatório de
## bug não diz qual build quebrou, o save não sabe de onde veio, a página da
## loja não tem o que anunciar e o jogador não tem como saber que a atualização
## que ele esperava chegou.
##
## O número vive em `project.godot` (`application/config/version`), que é onde o
## exportador do Godot vai buscá-lo para carimbar o executável — Windows lê dali
## as propriedades do arquivo, e a Steam compara build por ali. Duplicar o número
## numa constante do GDScript garantiria duas verdades e, um dia, duas
## diferentes. Aqui existe uma leitura só.

static func numero() -> String:
	var v = ProjectSettings.get_setting("application/config/version", "")
	return str(v) if v != null and str(v) != "" else "0.0.0"

## Compara duas versões "maior.menor.correcao". Devolve -1, 0 ou 1.
##
## Comparar como TEXTO daria "0.10.0" < "0.9.0", que é falso e faria a tela de
## novidades aparecer para trás. Comparar campo a campo, como número, é o único
## jeito que não erra na décima versão menor.
static func comparar(a: String, b: String) -> int:
	var pa := a.split(".")
	var pb := b.split(".")
	for i in 3:
		var na := int(pa[i]) if i < pa.size() else 0
		var nb := int(pb[i]) if i < pb.size() else 0
		if na != nb:
			return -1 if na < nb else 1
	return 0

## Esta sessão está rodando uma versão mais nova do que a última que o jogador
## viu? É o que decide se a tela de novidades sobe.
static func e_novidade(vista: String) -> bool:
	if vista == "":
		return false
	return comparar(vista, numero()) < 0

## As mudanças desta versão, na língua da pessoa. Vêm de `data/changelog.json`,
## que é o mesmo texto do `CHANGELOG.md` — mas em dado, para poder ser traduzido
## e desenhado. Um changelog que só existe em Markdown é para quem lê o
## repositório, e não para quem comprou o jogo.
static func mudancas(v: String, ingles: bool) -> Array:
	for item in Dados.changelog:
		if not (item is Dictionary):
			continue
		var d: Dictionary = item
		if str(d.get("versao", "")) != v:
			continue
		var lista = d.get("itens", [])
		if not (lista is Array):
			return []
		var fora: Array = []
		for it in lista:
			if it is Dictionary:
				fora.append({
					"tipo": str((it as Dictionary).get("tipo", "novo")),
					"texto": Ux.txt(it, "texto", ingles),
				})
		return fora
	return []

static func entrada_atual() -> Dictionary:
	var alvo := numero()
	for item in Dados.changelog:
		if item is Dictionary and str((item as Dictionary).get("versao", "")) == alvo:
			return item
	return {}
