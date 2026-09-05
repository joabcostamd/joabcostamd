# Como trabalhar neste repositório

Leia isto antes de agir. Ele existe para o Joab não precisar repetir nada.

## O ambiente aqui (nuvem)

| Tem | Não tem |
|---|---|
| Godot **4.7.2** headless (instalado pelo hook) | Editor Godot com janela |
| Python 3.11, Node 22 | MCP `godot-ai` (só na máquina do Joab) |
| Git, rede, disco | Tela, GPU, áudio, Blender |

Sessão da nuvem é container novo toda vez. O hook `.claude/hooks/session-start.sh`
instala o Godot e põe no PATH. Se `godot` sumir, rode `scripts/preparar-nuvem.sh`.

## Os comandos

```bash
./scripts/testar-tudo.sh              # suíte de todos os jogos (~22 s)
./<jogo>/testar.sh                    # suíte de um jogo só
./scripts/api.py Area2D body_         # o que existe nessa classe
./scripts/api.py --tem Node2D look_at # essa API existe mesmo?
```

## Regras que não se negociam

**1. Nunca invente API do Godot.** É o erro nº 1 de IA nesta engine, e ele não
avisa — o script parece certo e quebra em runtime. Antes de escrever qualquer
método, propriedade ou sinal que você não leu nesta sessão, rode
`scripts/api.py --tem <Classe> <membro>`. Custa 1 segundo.

**2. Prova antes de afirmar.** Só diga que algo funciona depois que o teste
passou e você viu a saída. "Deve funcionar" não é resultado. Se não deu pra
provar, diga que não deu pra provar.

**3. Bug vira teste antes da correção.** Escreve o teste que pega o defeito,
vê ele falhar, aí conserta.

**4. Número de jogo vem de medição.** Dano, custo, dificuldade, duração de
partida: sai de simulação headless (como o solucionador do picross), nunca de
intuição. Se o número foi chutado, diga que foi chutado.

**5. Travou em loop? Pare e reporte.** Duas tentativas na mesma parede já é
sinal de que a hipótese está errada. Fale, não insista.

## O que dá e o que não dá provar aqui

| Consigo provar na nuvem | Preciso da máquina do Joab |
|---|---|
| Lógica, regra, estado, save | "Ficou bonito?" |
| Todas as fases são vencíveis | Enquadramento de câmera |
| Telas montam sem erro | Shader, material, iluminação |
| Balanceamento por simulação | Game feel, resposta ao toque |
| Determinismo (mesma semente = mesmo nível) | Áudio de verdade |

**Nunca afirme nada visual daqui.** Sem tela, sem opinião sobre visual.
Entregue com screenshot pendente e diga que falta olhar na máquina local.

## Os jogos

| Pasta | O que é | Estado |
|---|---|---|
| `picross/` | Revelar — picross, 400 fases, 21 idiomas | completo (111 testes) |
| `kit-puzzle/` | Sokoban com gerador e solucionador | núcleo pronto (16 testes) |
| `prototipo-godot/` | Plataforma 2D mínimo | protótipo (6 testes) |

Todo jogo tem `testar.sh` na raiz que roda sem tela. Jogo novo nasce com um.

## Estilo

- Código, nomes de arquivo, commits e testes **em português**
- Resposta curta. Construir > explicar
- Teste rápido e automatizado. Nada de espera longa
- Áudio e arte gerados por código quando der — repositório leve
