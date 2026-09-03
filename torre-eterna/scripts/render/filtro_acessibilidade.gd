extends CanvasLayer

## Filtro de acessibilidade em tela cheia: daltonização e alto contraste.
##
## Não é simulação de daltonismo (isso ajuda quem enxerga, não quem não
## enxerga): é DALTONIZAÇÃO — o erro de cor que o olho não capta é
## redistribuído para os canais que a pessoa distingue. Vermelho e verde
## deixam de virar a mesma coisa.
##
## Vive acima de tudo (layer 100) e é criado pelo Cfg, então vale para o jogo
## E para os painéis — inclusive para o painel que liga a opção.

const CODIGO := """
shader_type canvas_item;

uniform sampler2D tela : hint_screen_texture, filter_linear;
uniform int modo = 0;          // 0 nenhum · 1 protanopia · 2 deuteranopia · 3 tritanopia
uniform float contraste = 0.0; // 0..1

void fragment() {
	vec3 c = texture(tela, SCREEN_UV).rgb;

	if (modo > 0) {
		mat3 sim;
		if (modo == 1) {
			sim = mat3(vec3(0.567, 0.558, 0.0), vec3(0.433, 0.442, 0.242), vec3(0.0, 0.0, 0.758));
		} else if (modo == 2) {
			sim = mat3(vec3(0.625, 0.7, 0.0), vec3(0.375, 0.3, 0.3), vec3(0.0, 0.0, 0.7));
		} else {
			sim = mat3(vec3(0.95, 0.0, 0.0), vec3(0.05, 0.433, 0.475), vec3(0.0, 0.567, 0.525));
		}
		vec3 s = sim * c;
		vec3 erro = c - s;
		// O erro volta para os canais que a pessoa ENXERGA. Em protanopia e
		// deuteranopia o par confundido e vermelho-verde, entao o erro vai
		// para G e B; em tritanopia o canal morto e o AZUL, e mandar o erro
		// de volta para B seria devolve-lo justamente a quem nao o ve.
		vec3 corr;
		if (modo == 3) {
			corr = vec3(erro.b * 0.7 + erro.r, erro.b * 0.7 + erro.g, 0.0);
		} else {
			corr = vec3(0.0, erro.r * 0.7 + erro.g, erro.r * 0.7 + erro.b);
		}
		// A correcao soma na cor ORIGINAL, nunca na simulada. Somando em `s`,
		// o que ia para a tela era a SIMULACAO de daltonismo com um empurrao —
		// exatamente o contrario do que esta escrito no topo deste arquivo, e
		// media metade da separacao vermelho-verde que a opcao promete
		// aumentar. Ligar a acessibilidade piorava o problema que ela resolve.
		vec3 daltonizada = c + corr;
		// Redistribuir canal só move informação de lugar; não cria nenhuma. Num
		// jogo com paleta pequena e escolhida a dedo, isso sozinho dá quase
		// empate com o filtro desligado. O que um dicromata lê SEM erro é
		// luminância — então o par confundido também é separado por claro e
		// escuro, no sentido do erro que o olho perdeu.
		//
		// Medido sobre a paleta real da UI (11 cores, todos os pares, distância
		// vista pelo olho do dicromata): 0,3 melhora a média E o pior par nos
		// três modos — protanopia 101,5/15,3 -> 113,5/20,2; deuteranopia
		// 106,9/14,3 -> 119,6/19,3; tritanopia 121,0/10,8 -> 136,9/18,9.
		// Acima disso a média sobe e o PIOR par desaba (0,6 leva o mínimo a
		// ~1), que é o oposto do que acessibilidade quer.
		float perdido = (modo == 3) ? (erro.b - (erro.r + erro.g) * 0.5) : (erro.r - erro.g);
		c = clamp(daltonizada + vec3(perdido * 0.3), vec3(0.0), vec3(1.0));
	}

	if (contraste > 0.001) {
		c = clamp((c - vec3(0.5)) * (1.0 + contraste * 0.9) + vec3(0.5), vec3(0.0), vec3(1.0));
		// escurece o fundo e realça o traço: ajuda leitura em tela pequena
		float luz = dot(c, vec3(0.299, 0.587, 0.114));
		c = mix(c, vec3(step(0.42, luz)), contraste * 0.18);
	}

	COLOR = vec4(c, 1.0);
}
"""

var _rect: ColorRect
var _mat: ShaderMaterial

func _ready() -> void:
	layer = 100
	follow_viewport_enabled = false
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.color = Color(1, 1, 1, 1)
	var sh := Shader.new()
	sh.code = CODIGO
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	_rect.material = _mat
	add_child(_rect)
	visible = false

## modo: 0 nenhum · 1 protanopia · 2 deuteranopia · 3 tritanopia
func configurar(modo: int, contraste: float) -> void:
	if _mat == null:
		return
	_mat.set_shader_parameter("modo", clampi(modo, 0, 3))
	_mat.set_shader_parameter("contraste", clampf(contraste, 0.0, 1.0))
	visible = modo > 0 or contraste > 0.001
