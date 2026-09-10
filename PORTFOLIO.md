# Portfólio

Estado de cada projeto deste repositório. Atualize junto com o commit que muda o estado.

| Projeto | O que é | Estado | Verificação |
|---|---|---|---|
| [overclock](jogos/overclock/) | Bullet heaven 3D neon cyberpunk — o Clock: acelerar mata mais rápido e te mata mais rápido | **ATIVO** | portão OK · 27/27 |
| [picross](picross/) | Picross "Revelar" — 400 fases, 21 idiomas, conquistas, galeria | **Completo** | portão OK · 29/29 |
| [kit-puzzle](kit-puzzle/) | Sokoban com gerador e solucionador por semente | **Completo** | portão OK · 16/16 |
| [prototipo-godot](prototipo-godot/) | Protótipo de plataforma 2D | **Protótipo** | portão OK · 6/6 |
| [modelo-jogo](modelo-jogo/) | Esqueleto que todo jogo novo copia | **Infraestrutura** | portão OK · 27/27 · export OK |

**ATIVO: `overclock`** — bullet heaven 3D com ambientação neon cyberpunk, alvo Steam.
Leia `jogos/overclock/CONCEITO.md` (o que é e o que recusa), `DESIGN.md` (o como) e
`ARTE.md` (a direção visual). O marco atual é o **M1**: provar que o Clock é uma
decisão interessante, em caixa cinza, antes de qualquer arte.

Um jogo novo começa com:

```bash
.claude/scripts/novo-jogo.sh <slug> "Nome do Jogo"
```

## Estados
- **ATIVO** — em desenvolvimento agora
- **Protótipo** — prova uma ideia, não é para lançar
- **Completo** — jogável de ponta a ponta
- **Publicado** — está no ar (link)
- **Parado** — pausado (diga por quê)
