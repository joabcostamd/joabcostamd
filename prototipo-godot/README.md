# Protótipo Plataforma 2D — Godot 4.6

Protótipo criado inteiramente num ambiente de nuvem **sem tela**, para provar
que dá para desenvolver jogo Godot assim de ponta a ponta.

## Rodar

```bash
godot                 # abre o editor / joga (na sua máquina)
./testar.sh           # roda os testes sem tela nenhuma
```

Controles: **setas / A D** para andar, **espaço / W** para pular.

## Como isso fica testável sem tela

O jogador não lê o teclado direto na física: ele age sobre `intencao_x` e
`intencao_pulo`. O teclado escreve nessas variáveis — e os testes também.
Resultado: dá para simular partidas inteiras em modo headless.

```
./testar.sh
  [ok]    cai por gravidade quando está no ar
  [ok]    pousa no chão e para de cair
  [ok]    anda para a direita ao receber intenção
  [ok]    pula quando está no chão
  [ok]    não pula no ar (sem pulo duplo)
  [ok]    coleta a moeda ao encostar nela
TODOS OS TESTES PASSARAM (6/6)
```

## Conferir o visual sem monitor

```bash
CAPTURA_DESTINO=/caminho/captura.png xvfb-run -a godot --resolution 640x360 -- --captura
```

Roda numa tela virtual (Xvfb) e salva um PNG do frame renderizado.

## Estrutura

| Arquivo | Papel |
|---|---|
| `scripts/jogador.gd` | Movimento, gravidade, pulo com coyote time e buffer |
| `scripts/jogo.gd` | Monta as plataformas, coleta de moedas, desenho e placar |
| `scripts/nivel_dados.gd` | O nível como dado (retângulos e posições), fácil de editar |
| `scripts/config_input.gd` | InputMap montado por código, não em binário |
| `tests/roteiro_testes.gd` | Suíte headless |
| `tests/captura.gd` | Screenshot em tela virtual |
