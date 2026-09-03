# A sonda — protótipo headless do núcleo do CRUZADA

Implementação do núcleo em GDScript puro, rodada no **Godot 4.7.2** headless. Não é o jogo:
é o **instrumento de medição** que respondeu se valia a pena construir o jogo.

Guardado porque reconstruir isso custa horas, e porque toda medição da pesquisa saiu daqui.

| Arquivo | O que faz |
|---|---|
| `nucleo.gd` | avaliador de mãos de pôquer + RNG xorshift64* semeado |
| `mesa.gd` | grade 5×5, posicionamento, colheita, cruzada, Tear, colheita final |
| `sonda.gd` | as 12 métricas da auditoria e as políticas gulosa/aleatória/profunda/caçadora |
| `testes.gd` | 43 asserções, incluindo o replay do documento e a curva de metas |
| `experimento.gd` | bancada das correções (Pulso, Tique do Tear) |
| `mesa2-avesso.gd` | núcleo estendido com o coringa AVESSO |
| `bancada-coringa.gd` | varredura AVESSO × AGULHA, mapa de calor 5×5 |

Como rodar (com `godot` no PATH):

    godot --headless --path . testes.gd     # valida o núcleo
    godot --headless --path . sonda.gd      # roda as métricas
