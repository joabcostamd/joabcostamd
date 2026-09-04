extends RefCounted

## Varredura de layout: abre todos os paineis, nos dois idiomas e em duas
## escalas, e MEDE. Roda com `godot --path . -- --auditar-ui`.

## ------------------------------------------------------ varredura de layout

## Abre TODOS os paineis, nos dois idiomas e em duas escalas, e MEDE.
##
## Eu estava achando defeito de layout com uma captura de tela por vez: tres
## minutos cada, uma tela cada, e a olho. Assim achei quatro paineis estourando
## a largura — e so achei porque tirei as capturas em portugues por acaso. As
## frases em portugues sao mais longas que as inglesas, entao metade dos
## defeitos desta classe SO existe num dos idiomas, e a maquina das capturas
## esta em ingles.
##
## Esta varredura cobre 12 paineis x 2 idiomas x 2 escalas — 48 combinacoes —
## num unico processo, em segundos. E ela nao olha: mede tres coisas que a
## imagem so deixava adivinhar.
##
##   1. CONTROLE FORA DA JANELA. Foi assim que o painel de Conquistas escondeu
##      o contador de pontos e a ultima aba.
##   2. ROLAGEM HORIZONTAL LIGADA. Um `ScrollContainer` com a barra de baixo
##      visivel esta escondendo conteudo atras de um gesto que ninguem faz numa
##      grade. Foi assim que Cartas, Codex e Reliquias se denunciaram.
##   3. CONTROLE ESPREMIDO ABAIXO DO PROPRIO MINIMO. E o "Comprar" que vira
##      "Com": o botao continua la, so que sem espaco para o texto dele.
##
## A tolerancia de 1 px existe porque o motor arredonda posicoes.
## As tres telas que a varredura precisa cobrir, e por que cada uma.
##
## 1280x720 e o alvo de desktop. 900x1600 e celular em retrato — o caso que
## MAIS aperta, porque `window/stretch/aspect="expand"` transforma tela estreita
## em viewport logico estreito, e foi la que a grade de cartas se denunciou.
## 1600x720 e celular deitado (20:9), onde sobra largura e falta altura.
##
## A varredura roda em UMA resolucao por processo (a janela e criada antes de
## este codigo existir), entao quem chama passa `--resolution`; a lista abaixo
## esta aqui para o portao do CI e a documentacao concordarem sobre quais sao.
const AUD_RESOLUCOES := ["1280x720", "900x1600", "1600x720"]

const AUD_IDIOMAS := ["pt", "en"]
const AUD_ESCALAS := [1.0, 1.25]
const AUD_FOLGA := 1.0
const AUD_FOLGA_MIN := 8.0

func rodar(main: Node, gerente, jogo) -> void:
	var falhas: Array = []
	var conferidos := 0
	print("=== VARREDURA DE LAYOUT ===")
	# UMA RESOLUCAO POR PROCESSO, E O RELATORIO DIZ QUAL.
	#
	# A janela nasce antes deste codigo, entao quem chama escolhe com
	# `--resolution`. Sem esta linha o relatorio dizia "48 conferidos" sem
	# dizer 48 conferidos EM QUE TELA — e uma varredura que so roda em 16:9
	# passa verde num jogo que quebra no celular. Declarar as tres aqui tambem
	# e o que deixa o portao do CI e a documentacao concordarem sobre a lista.
	# JANELA e VIEWPORT LOGICO sao numeros diferentes, e a diferenca importa.
	#
	# Com `stretch/mode="canvas_items"` e `aspect="expand"`, uma janela de
	# 900x1600 vira um viewport logico de 1142x2031: o motor escala para caber a
	# base de 1280x720 e devolve o resto como espaco logico extra. Quem escreve
	# layout trabalha no numero LOGICO; quem escolhe a tela no CI trabalha no
	# numero da JANELA. O relatorio imprime os dois, senao a lista declarada
	# parece nao bater com a realidade — foi o que aconteceu na primeira vez.
	var janela := DisplayServer.window_get_size()
	var tela_janela := "%dx%d" % [janela.x, janela.y]
	var logico: Vector2 = main.get_viewport_rect().size
	print("janela %s -> viewport logico %dx%d %s" % [
		tela_janela, int(logico.x), int(logico.y),
		"(declarada)" if AUD_RESOLUCOES.has(tela_janela) else "(fora da lista)"])
	print("as outras telas precisam de execucao propria: %s" % ", ".join(AUD_RESOLUCOES))
	for idioma in AUD_IDIOMAS:
		for escala in AUD_ESCALAS:
			Cfg.set_v("idioma", str(idioma))
			Cfg.set_v("escala_ui", float(escala))
			await main.get_tree().process_frame
			await main.get_tree().process_frame
			# A ARENA TEM QUE ACOMPANHAR A JANELA LOGICA.
			#
			# Trocar a escala e exatamente a condicao que deslocava a torre: com
			# 1,25 salvo na configuracao, o autoload aplicava a escala antes de
			# o Main perguntar o tamanho, e a arena nascia 1280x720 num mundo de
			# 1024x576 — a torre, unico ponto fixo da tela, ia parar 128x72 px
			# fora do centro, encostando na barra de habilidades. A varredura ja
			# troca de escala; conferir o centro aqui custa duas linhas e cobre
			# as quatro combinacoes.
			var tela_v: Vector2 = main.get_viewport_rect().size
			var centro_v: Vector2 = jogo.arena.centro
			if absf(centro_v.x - tela_v.x * 0.5) > 1.0 or absf(centro_v.y - tela_v.y * 0.5) > 1.0:
				falhas.append("arena/%s/%.2fx: a torre esta em (%.0f, %.0f) e o centro da janela e (%.0f, %.0f)" % [
					str(idioma), float(escala), centro_v.x, centro_v.y,
					tela_v.x * 0.5, tela_v.y * 0.5])
			for nome in gerente.PAINEIS.keys():
				var rotulo := "%s/%s/%.2fx" % [str(nome), str(idioma), float(escala)]
				gerente.abrir(str(nome))
				# Tres quadros: um para o painel nascer, um para o tema e a
				# escala assentarem, um para o container distribuir a largura.
				await main.get_tree().process_frame
				await main.get_tree().process_frame
				await main.get_tree().process_frame
				conferidos += 1
				# ABRIR NAO E O MESMO QUE FUNCIONAR.
				#
				# O gerente cria o Control e so entao poe o script nele. Se o
				# script nao compila, o no existe, `painel_atual` nao e nulo, e
				# a varredura media uma casca vazia e dizia PASS — foi o que
				# aconteceu: um painel com erro de sintaxe passou por aqui verde.
				# Painel que abriu de verdade tem filhos; casca nao tem.
				if gerente.painel_atual == null or not is_instance_valid(gerente.painel_atual):
					falhas.append("%s: o painel nao abriu" % rotulo)
				elif gerente.painel_atual.get_child_count() == 0:
					falhas.append("%s: o painel abriu VAZIO (o script dele compila?)" % rotulo)
				else:
					_medir_no(main, gerente.painel_atual, rotulo, falhas)
				gerente.fechar()
				await main.get_tree().process_frame

			# A MESA DAS LEIS TAMBEM E TELA.
			#
			# Ela nao esta em `PAINEIS` — e uma janela modal, criada a mao pelo
			# gerente — e por isso escaparia da varredura inteira. Justamente
			# ela: tres fichas com duas linhas de texto cada, numa janela
			# centrada, e o texto em portugues bem mais longo que o ingles. Se
			# alguma tela do jogo vai transbordar, comeca por aqui.
			jogo.s["prestigio"]["ascensoes"] = maxi(
				int(jogo.s["prestigio"]["ascensoes"]), Editos.ASCENSAO_MINIMA)
			Editos.recusar(jogo.s)
			if Editos.gerar_oferta(jogo.s, jogo.rng_editos):
				gerente.abrir_editos()
				await main.get_tree().process_frame
				await main.get_tree().process_frame
				await main.get_tree().process_frame
				conferidos += 1
				var rot_ed := "editos/%s/%.2fx" % [str(idioma), float(escala)]
				if gerente.dialogo == null or not is_instance_valid(gerente.dialogo):
					falhas.append("%s: a mesa das leis nao abriu" % rot_ed)
				elif gerente.dialogo.get_child_count() == 0:
					falhas.append("%s: a mesa abriu VAZIA (o script dela compila?)" % rot_ed)
				else:
					_medir_no(main, gerente.dialogo, rot_ed, falhas)
					gerente.dialogo.queue_free()
				await main.get_tree().process_frame
			Editos.recusar(jogo.s)
	Cfg.set_v("idioma", "pt")
	Cfg.set_v("escala_ui", 1.0)
	print("paineis conferidos: %d" % conferidos)
	print("problemas: %d" % falhas.size())
	for f in falhas:
		print("  FALHA: ", f)
	print("===VARREDURA=== conferidos=%d problemas=%d" % [conferidos, falhas.size()])
	print("===STATUS=== ", "PASS" if falhas.is_empty() else "FAIL")
	main.get_tree().quit(0 if falhas.is_empty() else 1)

## Percorre a arvore do painel e junta o que estiver fora do lugar.
##
## Duas decisoes que a primeira versao desta funcao errou, e as duas importam:
##
## DENTRO DE UM `ScrollContainer` NAO SE MEDE POSICAO. O passe de temporada e
## uma trilha de 40 niveis que rola na horizontal DE PROPOSITO — trinta e sete
## deles estao fora da janela a qualquer momento, e isso e o desenho, nao o
## defeito. Medir posicao la dentro rendeu 250 acusacoes falsas num painel so.
## O que vale perguntar sobre um `ScrollContainer` e se a barra HORIZONTAL dele
## esta ligada em algo que deveria caber — uma grade, uma lista de fichas.
##
## UM ANCESTRAL FORA DA JANELA ARRASTA TODA A DESCENDENCIA. Reportar cada filho
## dava 99 linhas para um painel com um problema. So o no MAIS DE FORA de cada
## ramo interessa: e nele que se conserta.
func _medir_no(main: Node, raiz_no: Node, rotulo: String, falhas: Array) -> void:
	var tela: Vector2 = main.get_viewport_rect().size
	# pilha de [no, dentro_de_rolagem, ja_acusado_acima, dentro_de_rolagem_pedida]
	var pilha: Array = [[raiz_no, false, false, false]]
	var vistos := 0
	while not pilha.is_empty() and vistos < 4000:
		var item: Array = pilha.pop_back()
		var no = item[0]
		var em_rolagem: bool = item[1]
		var acusado: bool = item[2]
		var em_rolagem_pedida: bool = item[3]
		vistos += 1
		var c: Control = no as Control
		var visivel := true
		if c != null:
			visivel = c.is_visible_in_tree()
		if c != null and visivel:
			var r := c.get_global_rect()
			# 1. saiu da janela — so fora de rolagem, e so o no mais de fora
			if not em_rolagem and not acusado and r.size.x > 0.0 and r.size.y > 0.0:
				if r.position.x < -AUD_FOLGA or r.end.x > tela.x + AUD_FOLGA:
					falhas.append("%s: %s sai da janela (x %.0f..%.0f, janela %.0f)" % [
						rotulo, _caminho_curto(c), r.position.x, r.end.x, tela.x])
					acusado = true
			# 2. rolagem horizontal ligada onde deveria caber
			if c is ScrollContainer:
				# Uma rolagem horizontal PEDIDA nao e defeito: a trilha do passe
				# de temporada tem 40 niveis e existe para ser arrastada. Quem
				# quiser essa rolagem marca o no e assume a escolha por escrito.
				if c.get_meta("rolagem_horizontal_proposital", false):
					em_rolagem_pedida = true
				else:
					var barra := (c as ScrollContainer).get_h_scroll_bar()
					if barra != null and barra.visible and barra.max_value > barra.page + AUD_FOLGA:
						# "Transborda" sem dizer QUEM manda procurar a olho — que
						# e o trabalho que esta varredura veio substituir. O
						# culpado e o no mais largo la dentro, e ele tem nome.
						falhas.append("%s: %s rola na horizontal (conteudo %.0f, cabe %.0f) — mais largo: %s" % [
							rotulo, _caminho_curto(c), barra.max_value, barra.page,
							_mais_largo(c)])
				em_rolagem = true
			# 3. espremido abaixo do proprio minimo — o "Comprar" que vira "Com"
			var minimo := c.get_combined_minimum_size()
			# Aqui a folga e maior: o motor arredonda, e um no de 4.792 px de
			# largura fecha a conta com 3 px de diferenca sem nada estar errado.
			# O que este teste procura e o "Comprar" que vira "Com", uma falta de
			# dezenas de pixels, nao de tres.
			# Dentro de uma rolagem PEDIDA nao se mede aperto: a trilha e mais
			# larga que a janela por desenho, e a diferenca de arredondamento
			# entre 4.792 e 4.776 px nao e um botao sem espaco para o texto.
			if not em_rolagem_pedida and r.size.x > 0.0 and minimo.x > r.size.x + AUD_FOLGA_MIN:
				falhas.append("%s: %s espremido (precisa %.0f, tem %.0f)" % [
					rotulo, _caminho_curto(c), minimo.x, r.size.x])
		if visivel:
			for filho in no.get_children():
				pilha.append([filho, em_rolagem, acusado, em_rolagem_pedida])

## O descendente que mais pede largura — o que esta empurrando a rolagem.
func _mais_largo(raiz_no: Node) -> String:
	var largos: Array = []
	var pilha: Array = [raiz_no]
	var vistos := 0
	while not pilha.is_empty() and vistos < 4000:
		var no = pilha.pop_back()
		vistos += 1
		var c: Control = no as Control
		if c == null or not c.is_visible_in_tree():
			for filho0 in no.get_children():
				pilha.append(filho0)
			continue
		# NAO ENTRA EM ROLAGEM ANINHADA. O conteudo dela e problema dela: a
		# trilha do passe tem 4.792 px de largura e apareceria como "culpado" de
		# qualquer transbordo do painel inteiro, que e o oposto de ajudar.
		if not (c is ScrollContainer and c != raiz_no):
			for filho in no.get_children():
				pilha.append(filho)
		# SO AS FOLHAS. Um container largo apenas repassa o tamanho de quem esta
		# dentro dele; apontar `MarginContainer > VBoxContainer > PanelContainer`
		# nao ajuda ninguem a consertar nada. Quem PEDE a largura e a folha — o
		# rotulo, a barra, o botao — e e o numero dela que precisa mudar.
		var tem_filho_control := false
		for f2 in c.get_children():
			if f2 is Control:
				tem_filho_control = true
				break
		# Folha, OU container com minimo escrito na mao. A segunda metade veio de
		# uma cacada que se arrastou: o relatorio so mostrava folhas, e o que
		# estourava o painel de Missoes era uma fileira de sete cartoes de 122 px
		# — um container. Quem escreveu `custom_minimum_size` escolheu aquele
		# numero, entao e ele que precisa aparecer no relatorio.
		var minimo_escrito := c.custom_minimum_size.x > 0.0
		if not tem_filho_control or minimo_escrito:
			var w: float = c.get_combined_minimum_size().x
			var marca := " [minimo escrito]" if minimo_escrito else ""
			largos.append({"n": "%s (%.0f)%s" % [_caminho_curto(c), w, marca], "w": w})
	largos.sort_custom(func(a, b) -> bool: return float(a["w"]) > float(b["w"]))
	var partes: Array = []
	for i in mini(3, largos.size()):
		partes.append(str((largos[i] as Dictionary)["n"]))
	return " > ".join(partes)

## Nome util para achar o no na hora de consertar: classe + texto, se houver.
func _caminho_curto(c: Control) -> String:
	var t := ""
	if c is Button:
		t = str((c as Button).text)
	elif c is Label:
		t = str((c as Label).text)
	if t.length() > 26:
		t = t.substr(0, 26) + "..."
	return "%s%s" % [c.get_class(), (" \"%s\"" % t) if t != "" else ""]
