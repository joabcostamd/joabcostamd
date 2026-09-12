# <NOME DO JOGO> — telas e fluxo

Data: <AAAA-MM-DD>

> Tela não é lista, é **grafo**. O que sempre escapa não é o nome da tela: é a saída dela.

---

## As telas

| Tela | Conteúdo | Entra de | Sai para | Esc / botão B faz | Estado ao voltar |
|---|---|---|---|---|---|
| <nome> | <o que mostra> | <de onde> | <para onde> | <o quê> | <o que sobra> |

## O fluxo

```
<Abertura> → <Menu> → <Jogo> → <Fim> → <Menu>
```

## Primeiro boot × jogador que volta

| | o que acontece |
|---|---|
| primeira vez | <do duplo clique até estar jogando> |
| volta depois de dias | <como ele lembra onde estava> |

## Estados de borda

| situação | o que acontece |
|---|---|
| fechar o jogo no meio de uma partida | <...> |
| primeiro boot sem save | <...> |
| save corrompido ou de versão antiga | <...> |
| controle desconectado no meio | <...> |
| janela redimensionada / alt-tab | <...> |
| pausa | <pausa som, física e timers?> |

---

## Está pronto quando

- [ ] **nenhuma tela sem saída** — toda linha tem "sai para" preenchido
- [ ] o fluxo inteiro é percorrível **só com controle**, do boot ao desligar
- [ ] toda ação destrutiva tem confirmação
- [ ] a transição entre telas é a mesma em todo lugar (identidade mínima)
- [ ] a versão do build aparece em algum canto
