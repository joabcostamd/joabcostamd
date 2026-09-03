extends Node

## Bus (autoload) — barramento de sinais do jogo.
## Regra: quem simula EMITE, quem apresenta (UI/áudio/FX) ESCUTA.

# --- combate ---
signal inimigo_surgiu(e)
## `dot` = dano por tempo (queimadura, veneno). Nasceu porque fogo e veneno
## disparavam este sinal a 60 Hz POR INIMIGO: com 100 inimigos afetados sao
## ~6.000 emissoes por segundo, o som de impacto ficava preso no limitador de
## taxa para sempre e o tiro de verdade deixava de ser audivel. Quem escuta
## precisa poder distinguir o tique do golpe.
signal inimigo_atingido(e, dano_log, critico, elemento, dot)
signal inimigo_morreu(e, ouro_log)
## Um banner cinematografico ocupou o meio da tela por N segundos.
signal banner_cinematico(segundos: float)
## Mais um dia seguido de sequencia diaria, com a etapa alcancada.
signal sequencia_diaria(dias: int, etapa: Dictionary)
## O boot achou arquivo de save e nao conseguiu ler nem ele nem o backup.
signal save_ilegivel(motivo: String)
signal inimigo_chegou(e, dano)
signal chefe_surgiu(e)
signal chefe_morreu(e)
signal chefe_fase(e, fase)
signal torre_atirou(angulo, quantidade)
signal torre_atingida(dano, vida, vida_max)
signal torre_caiu()
signal torre_renasceu()
signal combo_mudou(valor)
signal combo_quebrou()
signal overkill(e, fracao)

# --- economia ---
signal ouro_ganho(valor_log, fonte)
signal moeda_ganha(chave, valor_log, fonte)
signal upgrade_comprado(id, quantidade, nivel)
signal talento_comprado(id, nivel)
signal carta_caiu(instancia)
signal carta_equipada(uid, slot)

# --- progressão ---
signal onda_iniciou(onda, eh_chefe)
signal onda_limpa(onda, tempo)
## O jogador chamou a proxima onda antes da hora, e levou bonus por isso.
signal onda_antecipada(onda, bonus)
signal onda_falhou(onda)
signal nivel_subiu(nivel, pontos)
signal conquista_desbloqueada(id)
signal missao_concluida(id)
signal prestigio_feito(camada, ganho_log)
signal era_mudou(indice, era)
signal desafio_iniciado(id)
signal desafio_concluido(id)
signal evento_sorteado(evento)
signal desbloqueio(chave)

# --- habilidades ---
signal habilidade_usada(id, nivel)
signal habilidade_pronta(id)
## A Purga com a QUALIDADE que ela teve (0,18 a 1,0). `habilidade_usada` diz
## que a Purga saiu; este diz COMO. Sem ele, uma Purga perfeita e uma estourada
## faziam exatamente o mesmo som — a qualidade era calculada e jogada fora.
signal purga_usada(qualidade: float, perfeita: bool)

# --- juice / apresentação ---
signal tremor_pedido(amplitude, duracao)
signal hitstop_pedido(ms)
signal flash_pedido(cor, forca)
signal zoom_pedido(forca)
signal camera_lenta(escala, ms)
signal celebracao(tipo, dados)
signal numero_dano(pos, texto, cor, critico, escala)
signal particulas(tipo, pos, dados)

# --- sistema / UI ---
signal jogo_pronto()
signal ui_atualizar(completo)
signal aviso(texto, tipo, icone)
signal tela_mudou(nome)
signal painel_aberto(nome)
signal config_mudou(chave, valor)
signal jogo_salvo(bytes)
signal relatorio_offline(dados)
signal tutorial_passo(passo)

## Aviso rápido (toast). tipo: "info" | "bom" | "ruim" | "epico"
func toast(texto: String, tipo: String = "info", icone: String = "") -> void:
	aviso.emit(texto, tipo, icone)
