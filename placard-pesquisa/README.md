# PLACARD — pesquisa de design medida

> **Sobre o nome.** Esta pesquisa foi feita quando o jogo se chamava CRUZ.
> Ele hoje se chama **PLACARD** — as referências ao *jogo* foram atualizadas, e as
> referências à **jogada** (colher fileira e coluna de uma vez) continuam sendo
> *cruz*, que é o nome dela e não mudou. Métricas como `0,146 cruz/mesa` são
> a jogada. O porquê da troca está em `placard/NOME.md`.

Documentos de pesquisa produzidos **antes** de escrever o jogo, para decidir se o
design do `PROMPT-JOGO-DE-CARTAS.md` merecia ser construído.

Nada aqui é opinião. Um protótipo headless do núcleo foi implementado em GDScript
e rodado no Godot 4.7.2; todas as afirmações têm um número medido atrás.

| Arquivo | O que é |
|---|---|
| **`DECISOES.md`** | **o livro-razão: tudo o que foi aprovado, tudo o que foi reprovado, e o número que decidiu cada um. Comece por aqui** |
| `01-AUDITORIA.md` | O jogo é simples de aprender, simples de jogar e viciante? 2.000 mesas por política |
| `02-NUCLEO-POLIDO.md` | Coringas, cascata e escalada: o que entrou, o que foi reprovado e por quê |
| `03-NOTAS-DA-SONDA.md` | Notas de quem implementou o núcleo: ambiguidades e contradições encontradas nas regras |
| `bancada-1.md` | Bancada do coringa (AVESSO × AGULHA) |
| `bancada-2.md` | Bancada da cascata / reação em cadeia |
| `bancada-3.md` | Bancada da escalada, tetos e variedade |
| `metricas-base.json` | Medições brutas do núcleo sem ajuste |
| `sonda/` | O protótipo headless do núcleo em GDScript, validado no Godot 4.7.2 — o instrumento que produziu todas as medições |

## As três conclusões que decidem o projeto

1. **O núcleo tem profundidade real.** A jogada óbvia coincide com a ótima em 58,8%
   dos turnos — nem se resolve sozinho, nem pune a intuição.
2. **O núcleo estava faminto de recompensa.** 86% dos turnos não pagavam nada.
   Com o Pulso e o Tique do Tear, 65,7% passam a pagar e a seca cai de 7 para 2 turnos.
3. **A cruz não acontece.** Zero em 30.944 turnos. Fechar uma linha em 4/5 é sempre
   a jogada que mais paga na hora, então duas linhas nunca ficam em 4/5 ao mesmo tempo.
   O gargalo é de *ordem*, não de carta nem de preço — nenhum coringa e nenhum
   multiplicador conserta. Falta resolver isso antes de construir.

## Regra da casa

Nenhuma decisão de design entra sem um número medido atrás. Antes de propor mudança,
leia `DECISOES.md`: metade das boas ideias deste projeto já foi testada e morreu com um
número específico, e a seção de erros de medição existe para não repetirmos os nossos.
