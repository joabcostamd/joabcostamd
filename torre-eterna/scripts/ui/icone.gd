class_name Icone
extends RefCounted

## Ícones vetoriais desenhados por código (a fonte padrão não tem emoji).
## Todos cabem num quadrado de lado `t` centrado em `c`.

static func desenhar(ci: CanvasItem, nome: String, c: Vector2, t: float, cor: Color, cor2: Color = Color.TRANSPARENT) -> void:
	var r := t * 0.5
	if cor2.a <= 0.0:
		cor2 = cor.darkened(0.45)
	match nome:
		# ---------------- moedas ----------------
		"ouro":
			ci.draw_circle(c, r * 0.92, cor)
			ci.draw_circle(c, r * 0.66, cor.lightened(0.35))
			ci.draw_circle(c - Vector2(r * 0.3, r * 0.32), r * 0.2, Color(1, 1, 1, 0.65))
		"gema":
			_poly(ci, [c + Vector2(0, -r), c + Vector2(r * 0.85, -r * 0.15), c + Vector2(0, r), c + Vector2(-r * 0.85, -r * 0.15)], cor)
			ci.draw_line(c + Vector2(0, -r), c + Vector2(0, r), Color(1, 1, 1, 0.4), 1.5)
		"fragmento":
			_poly(ci, [c + Vector2(0, -r), c + Vector2(r * 0.7, 0), c + Vector2(0, r), c + Vector2(-r * 0.7, 0)], cor)
			_poly(ci, [c + Vector2(0, -r * 0.5), c + Vector2(r * 0.35, 0), c + Vector2(0, r * 0.5), c + Vector2(-r * 0.35, 0)], Color(1, 1, 1, 0.45))
		"nucleo":
			ci.draw_circle(c, r * 0.5, cor)
			ci.draw_arc(c, r * 0.92, 0.4, 0.4 + PI * 1.6, 24, cor, 2.0, true)
			ci.draw_arc(c, r * 0.7, 3.4, 3.4 + PI * 1.4, 20, cor.lightened(0.4), 1.6, true)
		"eter":
			for i in 4:
				var a := float(i) / 4.0 * PI
				ci.draw_line(c - Vector2(cos(a), sin(a)) * r, c + Vector2(cos(a), sin(a)) * r, cor, 2.0, true)
			ci.draw_circle(c, r * 0.25, Color(1, 1, 1, 0.9))
		"poeira":
			for i in 5:
				var a2 := float(i) * 1.2566
				ci.draw_circle(c + Vector2(cos(a2), sin(a2)) * r * 0.6, r * 0.18, cor)
		# ---------------- painéis ----------------
		"espada":
			ci.draw_line(c + Vector2(-r * 0.55, r * 0.7), c + Vector2(r * 0.6, -r * 0.75), cor, 3.0, true)
			ci.draw_line(c + Vector2(-r * 0.7, r * 0.25), c + Vector2(-r * 0.15, r * 0.8), cor2, 3.0, true)
			ci.draw_circle(c + Vector2(r * 0.62, -r * 0.78), r * 0.14, cor.lightened(0.4))
		"arvore":
			ci.draw_line(c + Vector2(0, r * 0.9), c + Vector2(0, -r * 0.1), cor2, 3.0)
			ci.draw_line(c + Vector2(0, r * 0.3), c + Vector2(-r * 0.6, -r * 0.2), cor2, 2.0)
			ci.draw_line(c + Vector2(0, r * 0.1), c + Vector2(r * 0.6, -r * 0.4), cor2, 2.0)
			ci.draw_circle(c + Vector2(0, -r * 0.25), r * 0.26, cor)
			ci.draw_circle(c + Vector2(-r * 0.6, -r * 0.25), r * 0.2, cor)
			ci.draw_circle(c + Vector2(r * 0.6, -r * 0.45), r * 0.2, cor)
		"carta":
			ci.draw_rect(Rect2(c - Vector2(r * 0.55, r * 0.8), Vector2(r * 1.1, r * 1.6)), cor2)
			ci.draw_rect(Rect2(c - Vector2(r * 0.4, r * 0.65), Vector2(r * 0.8, r * 1.3)), cor)
			ci.draw_circle(c, r * 0.22, Color(1, 1, 1, 0.75))
		"prestigio":
			for i in 3:
				ci.draw_arc(c, r * (0.4 + float(i) * 0.3), float(i) * 1.6, float(i) * 1.6 + PI * 1.3, 20, cor, 2.0, true)
			ci.draw_circle(c, r * 0.24, Color(1, 1, 1, 0.9))
		"trofeu":
			ci.draw_rect(Rect2(c + Vector2(-r * 0.35, r * 0.55), Vector2(r * 0.7, r * 0.3)), cor2)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.12, r * 0.1), Vector2(r * 0.24, r * 0.5)), cor2)
			_poly(ci, [c + Vector2(-r * 0.55, -r * 0.75), c + Vector2(r * 0.55, -r * 0.75), c + Vector2(r * 0.3, r * 0.15), c + Vector2(-r * 0.3, r * 0.15)], cor)
			ci.draw_arc(c + Vector2(-r * 0.6, -r * 0.45), r * 0.3, PI * 0.5, PI * 1.5, 12, cor, 2.0)
			ci.draw_arc(c + Vector2(r * 0.6, -r * 0.45), r * 0.3, -PI * 0.5, PI * 0.5, 12, cor, 2.0)
		"engrenagem":
			var n := 8
			for i in n:
				var a3 := float(i) / float(n) * TAU
				ci.draw_line(c + Vector2(cos(a3), sin(a3)) * r * 0.55, c + Vector2(cos(a3), sin(a3)) * r, cor, 3.5)
			ci.draw_arc(c, r * 0.55, 0, TAU, 20, cor, 3.0, true)
			ci.draw_circle(c, r * 0.22, cor2)
		"livro":
			ci.draw_rect(Rect2(c - Vector2(r * 0.7, r * 0.6), Vector2(r * 1.4, r * 1.2)), cor2)
			ci.draw_rect(Rect2(c - Vector2(r * 0.6, r * 0.5), Vector2(r * 0.55, r * 1.0)), cor)
			ci.draw_rect(Rect2(c + Vector2(r * 0.05, -r * 0.5), Vector2(r * 0.55, r * 1.0)), cor)
		"missao":
			ci.draw_rect(Rect2(c - Vector2(r * 0.6, r * 0.75), Vector2(r * 1.2, r * 1.5)), cor2)
			for i in 3:
				var y := c.y - r * 0.35 + float(i) * r * 0.4
				ci.draw_line(Vector2(c.x - r * 0.35, y), Vector2(c.x + r * 0.4, y), cor, 2.0)
		"desafio":
			_poly(ci, [c + Vector2(0, -r), c + Vector2(r * 0.9, r * 0.6), c + Vector2(-r * 0.9, r * 0.6)], cor)
			ci.draw_line(c + Vector2(0, -r * 0.4), c + Vector2(0, r * 0.15), cor2, 3.0)
			ci.draw_circle(c + Vector2(0, r * 0.38), r * 0.11, cor2)
		"reliquia":
			ci.draw_arc(c, r * 0.75, 0, TAU, 18, cor, 3.0, true)
			_poly(ci, [c + Vector2(0, -r * 0.45), c + Vector2(r * 0.4, r * 0.3), c + Vector2(-r * 0.4, r * 0.3)], cor2)
		"stats":
			for i in 3:
				var h := r * (0.5 + float(i) * 0.45)
				ci.draw_rect(Rect2(c + Vector2(-r * 0.75 + float(i) * r * 0.55, r * 0.8 - h), Vector2(r * 0.4, h)), cor if i == 2 else cor2)
		# ---------------- jogo ----------------
		"coracao":
			ci.draw_circle(c + Vector2(-r * 0.32, -r * 0.18), r * 0.38, cor)
			ci.draw_circle(c + Vector2(r * 0.32, -r * 0.18), r * 0.38, cor)
			_poly(ci, [c + Vector2(-r * 0.68, -r * 0.05), c + Vector2(r * 0.68, -r * 0.05), c + Vector2(0, r * 0.85)], cor)
		"escudo":
			_poly(ci, [c + Vector2(-r * 0.7, -r * 0.7), c + Vector2(r * 0.7, -r * 0.7), c + Vector2(r * 0.55, r * 0.35), c + Vector2(0, r * 0.85), c + Vector2(-r * 0.55, r * 0.35)], cor)
		"alvo":
			ci.draw_arc(c, r * 0.9, 0, TAU, 24, cor, 2.0, true)
			ci.draw_arc(c, r * 0.5, 0, TAU, 18, cor, 2.0, true)
			ci.draw_circle(c, r * 0.16, cor)
		"velocidade":
			for i in 2:
				var off := float(i) * r * 0.55 - r * 0.28
				_poly(ci, [c + Vector2(off - r * 0.25, -r * 0.6), c + Vector2(off + r * 0.4, 0), c + Vector2(off - r * 0.25, r * 0.6)], cor)
		"salvar":
			ci.draw_rect(Rect2(c - Vector2(r * 0.72, r * 0.72), Vector2(r * 1.44, r * 1.44)), cor2)
			ci.draw_rect(Rect2(c - Vector2(r * 0.4, r * 0.72), Vector2(r * 0.8, r * 0.6)), cor)
			ci.draw_rect(Rect2(c - Vector2(r * 0.5, r * 0.05), Vector2(r * 1.0, r * 0.7)), cor)
		"pausa":
			ci.draw_rect(Rect2(c - Vector2(r * 0.5, r * 0.65), Vector2(r * 0.3, r * 1.3)), cor)
			ci.draw_rect(Rect2(c + Vector2(r * 0.2, -r * 0.65), Vector2(r * 0.3, r * 1.3)), cor)
		"fechar":
			ci.draw_line(c + Vector2(-r * 0.6, -r * 0.6), c + Vector2(r * 0.6, r * 0.6), cor, 3.0, true)
			ci.draw_line(c + Vector2(r * 0.6, -r * 0.6), c + Vector2(-r * 0.6, r * 0.6), cor, 3.0, true)
		"mais":
			ci.draw_line(c + Vector2(-r * 0.6, 0), c + Vector2(r * 0.6, 0), cor, 3.0, true)
			ci.draw_line(c + Vector2(0, -r * 0.6), c + Vector2(0, r * 0.6), cor, 3.0, true)
		"cadeado":
			ci.draw_rect(Rect2(c - Vector2(r * 0.55, -r * 0.05), Vector2(r * 1.1, r * 0.8)), cor)
			ci.draw_arc(c - Vector2(0, r * 0.1), r * 0.38, PI, TAU, 14, cor, 3.0)
		"raio":
			_poly(ci, [c + Vector2(r * 0.15, -r), c + Vector2(-r * 0.45, r * 0.1), c + Vector2(0, r * 0.1), c + Vector2(-r * 0.15, r), c + Vector2(r * 0.5, -r * 0.15), c + Vector2(0.0, -r * 0.15)], cor)
		"fogo":
			_poly(ci, [c + Vector2(0, -r), c + Vector2(r * 0.6, r * 0.2), c + Vector2(r * 0.3, r * 0.8), c + Vector2(-r * 0.3, r * 0.8), c + Vector2(-r * 0.6, r * 0.2)], cor)
			_poly(ci, [c + Vector2(0, -r * 0.2), c + Vector2(r * 0.3, r * 0.45), c + Vector2(-r * 0.3, r * 0.45)], Color(1, 1, 1, 0.6))
		"gelo":
			for i in 3:
				var a4 := float(i) / 3.0 * PI
				ci.draw_line(c - Vector2(cos(a4), sin(a4)) * r * 0.9, c + Vector2(cos(a4), sin(a4)) * r * 0.9, cor, 2.5, true)
		"veneno":
			ci.draw_circle(c + Vector2(0, r * 0.2), r * 0.6, cor)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.2, -r * 0.85), Vector2(r * 0.4, r * 0.6)), cor2)
		"vazio":
			ci.draw_circle(c, r * 0.85, Color(0.02, 0.0, 0.05, 0.95))
			ci.draw_arc(c, r * 0.85, 0, TAU, 24, cor, 2.5, true)
		"orbe":
			ci.draw_circle(c, r * 0.55, cor)
			ci.draw_arc(c, r * 0.9, 0.6, 0.6 + PI * 1.5, 20, cor2, 2.0, true)
		"nova":
			for i in 8:
				var a5 := float(i) / 8.0 * TAU
				ci.draw_line(c + Vector2(cos(a5), sin(a5)) * r * 0.4, c + Vector2(cos(a5), sin(a5)) * r, cor, 2.5)
			ci.draw_circle(c, r * 0.3, Color(1, 1, 1, 0.9))
		"ampulheta":
			_poly(ci, [c + Vector2(-r * 0.55, -r * 0.75), c + Vector2(r * 0.55, -r * 0.75), c + Vector2(0, 0)], cor)
			_poly(ci, [c + Vector2(-r * 0.55, r * 0.75), c + Vector2(r * 0.55, r * 0.75), c + Vector2(0, 0)], cor)
		"estrela":
			var v := PackedVector2Array()
			for i in 10:
				var rr := r if i % 2 == 0 else r * 0.45
				var a6 := -PI * 0.5 + float(i) / 10.0 * TAU
				v.append(c + Vector2(cos(a6), sin(a6)) * rr)
			ci.draw_colored_polygon(v, cor)
		"cura":
			ci.draw_rect(Rect2(c - Vector2(r * 0.22, r * 0.75), Vector2(r * 0.44, r * 1.5)), cor)
			ci.draw_rect(Rect2(c - Vector2(r * 0.75, r * 0.22), Vector2(r * 1.5, r * 0.44)), cor)
		"balanca":
			ci.draw_line(c + Vector2(0, -r * 0.8), c + Vector2(0, r * 0.8), cor, 2.5)
			ci.draw_line(c + Vector2(-r * 0.8, -r * 0.5), c + Vector2(r * 0.8, -r * 0.5), cor, 2.5)
			ci.draw_arc(c + Vector2(-r * 0.8, -r * 0.2), r * 0.32, 0, PI, 12, cor, 2.0)
			ci.draw_arc(c + Vector2(r * 0.8, -r * 0.2), r * 0.32, 0, PI, 12, cor, 2.0)
		"foguete":
			_poly(ci, [c + Vector2(0, -r), c + Vector2(r * 0.4, r * 0.2), c + Vector2(-r * 0.4, r * 0.2)], cor)
			_poly(ci, [c + Vector2(-r * 0.4, r * 0.2), c + Vector2(r * 0.4, r * 0.2), c + Vector2(0, r)], cor2)
		"torre":
			ci.draw_rect(Rect2(c - Vector2(r * 0.45, r * 0.2), Vector2(r * 0.9, r * 1.0)), cor2)
			_poly(ci, [c + Vector2(-r * 0.6, -r * 0.2), c + Vector2(r * 0.6, -r * 0.2), c + Vector2(0, -r)], cor)
		_:
			ci.draw_arc(c, r * 0.8, 0, TAU, 16, cor, 2.0, true)

static func _poly(ci: CanvasItem, pontos: Array, cor: Color) -> void:
	var v := PackedVector2Array()
	for p in pontos:
		v.append(p)
	ci.draw_colored_polygon(v, cor)

## Ícone de moeda por chave.
static func da_moeda(chave: String) -> String:
	match chave:
		"ouro": return "ouro"
		"gemas": return "gema"
		"fragmentos": return "fragmento"
		"nucleos": return "nucleo"
		"eter": return "eter"
		"poeira": return "poeira"
	return "ouro"

## Ícone de habilidade por id.
static func da_habilidade(id: String) -> String:
	match id:
		"nova": return "nova"
		"sobrecarga": return "raio"
		"tempo": return "ampulheta"
		"chuva_ouro": return "estrela"
		"escudo_absoluto": return "escudo"
		"sentinelas": return "orbe"
		"misseis": return "foguete"
		"buraco_negro": return "vazio"
		"reparo": return "cura"
		"julgamento": return "balanca"
	return "estrela"
