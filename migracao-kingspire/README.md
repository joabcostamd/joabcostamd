# Kingspire

**Tower defense 3D entre dimensões.** Um castelo no meio do mapa, várias frentes de
ataque ao mesmo tempo, e noites que só começam quando você decide que está pronto.

Feito em **Godot 4.7.2**.

## Onde o jogo está

Na fase de **plano**. Nenhuma linha de GDScript ainda — e isso é de propósito:
neste repositório o conceito vem antes do código, e um portão automático impede
que a ordem se inverta.

```bash
./testar.sh          # roda o portão do plano e diz em que fase estamos
```

## O que já está decidido

Dezessete decisões fechadas em [`docs/PLANO.md`](docs/PLANO.md), cada uma com o
motivo escrito e a marca de quem decidiu. As principais:

| | |
|---|---|
| **Modelo** | as mecânicas do Thronefall com as torres do Kingdom Rush |
| **Partida** | 10 a 15 minutos |
| **Torres** | 4 famílias × 3 caminhos de evolução |
| **Inimigos** | 15 tipos, 5 manias — manias só aparecem com mutadores |
| **Mapas** | 15 à mão para a campanha, gerados para o modo sem fim |
| **Castelo** | quatro lugares possíveis: meio, embaixo da tela, canto e escada |
| **Noite** | começa quando o jogador quiser; nas dificuldades altas esse tempo encolhe |

## O protótipo

`prototipo/` é código descartável que existe para **decidir com a imagem na mão**,
antes de existir engine:

```bash
python3 prototipo/gerador_mapa.py          # gera mapas e valida cada um
python3 prototipo/maquete3d.py arranjos    # desenha os 4 lugares do castelo
python3 prototipo/maquete3d.py dimensoes   # o mesmo mapa em 5 biomas
```

As imagens saem em `prototipo/saida/`.
