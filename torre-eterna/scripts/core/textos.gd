class_name Txt
extends RefCounted

## Textos da interface em PT-BR e EN.
##
## O conteúdo (nomes de melhorias, inimigos, lore...) já é bilíngue nos JSONs —
## use `Ux.txt(dicionario, "nome", Cfg.ingles())` para aquilo.
## Este arquivo cuida do "cromo": rótulos, botões, títulos e avisos.
##
## Regra: NENHUMA string visível ao jogador escrita direto no painel.
##        Sempre `Txt.t("chave")`. Chave desconhecida devolve a própria chave,
##        o que aparece feio de propósito — para ser notado e corrigido.

const PT := {
	# --- geral ---
	"fechar": "Fechar", "voltar": "Voltar", "cancelar": "Cancelar", "confirmar": "Confirmar",
	"comprar": "Comprar", "maximo": "MÁXIMO", "bloqueado": "Bloqueado", "vazio": "Vazio",
	"nivel": "Nível", "novo": "NOVO", "total": "Total", "de": "de", "custo": "Custo",
	"proximo": "Próximo", "atual": "Atual", "sim": "Sim", "nao": "Não", "tudo": "Tudo",
	"nenhum": "Nenhum", "ativo": "Ativo", "completo": "Completo", "coletar": "Coletar",
	"coletado": "Coletado", "requer": "Requer", "recompensa": "Recompensa", "efeito": "Efeito",
	"em_breve": "Em breve", "sem_itens": "Nada por aqui ainda.",

	# --- HUD ---
	"onda": "ONDA", "pontos_talento": "pontos de talento", "dps": "DPS",
	"vida_torre": "Vida da torre", "combo": "Combo", "velocidade": "Velocidade do jogo",
	"mira": "Mira", "salvar_agora": "Salvar agora", "jogo_salvo": "Jogo salvo",
	"retomada": "RETOMADA", "alvo": "alvo",

	# --- painéis ---
	"p_upgrades": "Melhorias", "p_talentos": "Talentos", "p_cartas": "Cartas",
	"p_prestigio": "Prestígio", "p_conquistas": "Conquistas", "p_config": "Configurações",
	"p_codex": "Codex", "p_stats": "Estatísticas", "p_missoes": "Missões",
	"p_reliquias": "Relíquias", "p_desafios": "Desafios", "p_habilidades": "Habilidades",

	# --- moedas ---
	"m_ouro": "ouro", "m_gemas": "gemas", "m_fragmentos": "fragmentos",
	"m_nucleos": "núcleos", "m_eter": "éter", "m_poeira": "poeira",

	# --- prestígio ---
	"ganho_previsto": "Ganho previsto", "o_que_reseta": "O que se desfaz",
	"o_que_permanece": "O que permanece", "arvore_permanente": "Árvore permanente",
	"ascensoes": "ascensões", "melhor_onda": "melhor onda",

	# --- purga ---
	"purga": "PURGA", "purga_dica": "Solte na faixa dourada para o efeito máximo.",
	"purga_estourou": "O núcleo estourou sozinho — você perdeu a janela.",

	# --- config ---
	"c_jogo": "Jogo", "c_audio": "Áudio", "c_graficos": "Gráficos",
	"c_acessibilidade": "Acessibilidade", "c_save": "Save", "c_sobre": "Sobre",
	"c_idioma": "Idioma", "c_notacao": "Notação numérica", "c_casas": "Casas decimais",
	"c_volume_geral": "Volume geral", "c_volume_efeitos": "Efeitos", "c_volume_musica": "Música",
	"c_mudo": "Mudo", "c_qualidade": "Qualidade", "c_particulas": "Partículas",
	"c_tremor": "Tremor de tela", "c_flashes": "Flashes", "c_numeros_dano": "Números de dano",
	"c_movimento_reduzido": "Movimento reduzido", "c_daltonismo": "Modo daltônico",
	"c_alto_contraste": "Alto contraste", "c_fonte_grande": "Fonte grande",
	"c_mostrar_fps": "Mostrar FPS", "c_tela_cheia": "Tela cheia", "c_exportar": "Exportar",
	"c_importar": "Importar", "c_apagar": "Apagar tudo", "c_copiar": "Copiar",
	"c_restaurar": "Restaurar padrões", "c_atalhos": "Atalhos de teclado",

	# --- avisos ---
	"ouro_insuficiente": "Ouro insuficiente", "recurso_insuficiente": "Recurso insuficiente",
	"nada_para_comprar": "Nada para comprar aqui", "salvo": "Salvo",
	"save_importado": "Save importado", "save_invalido": "Código de save inválido",
}

const EN := {
	"fechar": "Close", "voltar": "Back", "cancelar": "Cancel", "confirmar": "Confirm",
	"comprar": "Buy", "maximo": "MAXED", "bloqueado": "Locked", "vazio": "Empty",
	"nivel": "Level", "novo": "NEW", "total": "Total", "de": "of", "custo": "Cost",
	"proximo": "Next", "atual": "Current", "sim": "Yes", "nao": "No", "tudo": "All",
	"nenhum": "None", "ativo": "Active", "completo": "Complete", "coletar": "Claim",
	"coletado": "Claimed", "requer": "Requires", "recompensa": "Reward", "efeito": "Effect",
	"em_breve": "Coming soon", "sem_itens": "Nothing here yet.",

	"onda": "WAVE", "pontos_talento": "talent points", "dps": "DPS",
	"vida_torre": "Tower HP", "combo": "Combo", "velocidade": "Game speed",
	"mira": "Targeting", "salvar_agora": "Save now", "jogo_salvo": "Game saved",
	"retomada": "RECLAIM", "alvo": "target",

	"p_upgrades": "Upgrades", "p_talentos": "Talents", "p_cartas": "Cards",
	"p_prestigio": "Prestige", "p_conquistas": "Achievements", "p_config": "Settings",
	"p_codex": "Codex", "p_stats": "Statistics", "p_missoes": "Missions",
	"p_reliquias": "Relics", "p_desafios": "Challenges", "p_habilidades": "Abilities",

	"m_ouro": "gold", "m_gemas": "gems", "m_fragmentos": "shards",
	"m_nucleos": "cores", "m_eter": "ether", "m_poeira": "dust",

	"ganho_previsto": "Projected gain", "o_que_reseta": "What is undone",
	"o_que_permanece": "What remains", "arvore_permanente": "Permanent tree",
	"ascensoes": "ascensions", "melhor_onda": "best wave",

	"purga": "PURGE", "purga_dica": "Release in the golden band for maximum effect.",
	"purga_estourou": "The core burst on its own — you missed the window.",

	"c_jogo": "Game", "c_audio": "Audio", "c_graficos": "Graphics",
	"c_acessibilidade": "Accessibility", "c_save": "Save", "c_sobre": "About",
	"c_idioma": "Language", "c_notacao": "Number notation", "c_casas": "Decimals",
	"c_volume_geral": "Master volume", "c_volume_efeitos": "Effects", "c_volume_musica": "Music",
	"c_mudo": "Mute", "c_qualidade": "Quality", "c_particulas": "Particles",
	"c_tremor": "Screen shake", "c_flashes": "Flashes", "c_numeros_dano": "Damage numbers",
	"c_movimento_reduzido": "Reduced motion", "c_daltonismo": "Color-blind mode",
	"c_alto_contraste": "High contrast", "c_fonte_grande": "Large font",
	"c_mostrar_fps": "Show FPS", "c_tela_cheia": "Fullscreen", "c_exportar": "Export",
	"c_importar": "Import", "c_apagar": "Erase everything", "c_copiar": "Copy",
	"c_restaurar": "Restore defaults", "c_atalhos": "Keyboard shortcuts",

	"ouro_insuficiente": "Not enough gold", "recurso_insuficiente": "Not enough resources",
	"nada_para_comprar": "Nothing to buy here", "salvo": "Saved",
	"save_importado": "Save imported", "save_invalido": "Invalid save code",
}

## Texto da interface na língua atual.
static func t(chave: String) -> String:
	if Cfg.ingles():
		var en = EN.get(chave, null)
		if en != null:
			return str(en)
	return str(PT.get(chave, chave))

## Texto com substituição: Txt.f("onda_n", {"n": 42})
static func f(chave: String, params: Dictionary) -> String:
	var s := t(chave)
	for k in params.keys():
		s = s.replace("{%s}" % str(k), str(params[k]))
	return s

## Todas as chaves — usado pelo validador para achar tradução faltando.
static func chaves_sem_en() -> Array:
	var faltando: Array = []
	for k in PT.keys():
		if not EN.has(k):
			faltando.append(k)
	return faltando
