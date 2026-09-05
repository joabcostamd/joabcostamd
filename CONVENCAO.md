# Convenções

## Nomes de pasta e repositório
- Jogo: `game-<slug>` (repo próprio) ou `jogos/<slug>` (aqui dentro)
- Aplicativo: `app-<slug>`
- Ferramenta/servidor: `mcp-<slug>`
- Slug: minúsculas, números e hífen. Sem acento, sem `_`, sem maiúscula.

## Dentro do código
Tudo em **português**: nome de arquivo, de classe, de função, de variável, de sinal,
de nó e de chave de tradução (a chave em MAIÚSCULA: `JOGAR`, `PLACAR`).

| Coisa | Estilo | Exemplo |
|---|---|---|
| arquivo `.gd` | minúscula com `_` | `grade_jogo.gd` |
| `class_name` | PascalCase | `Pontuacao` |
| função | minúscula com `_` | `pontos_da_jogada()` |
| variável privada | `_` na frente | `_combo` |
| constante | MAIÚSCULA | `VERSAO_ATUAL` |
| sinal | verbo no passado | `fase_concluida` |
| nó na cena | PascalCase | `GradeJogo` |
| grupo | minúscula | `inimigos` |

Exceção: nada de acento em identificador de código. Acento só em texto para o jogador,
comentário e documentação.

## Commits
Imperativo, em português, dizendo o efeito:

```
Picross: 400 fases, salvamento mesclável e conquistas com aviso
Modelo: portão frio pega caminho res:// quebrado dentro do código
```

Não: `fix bug`, `update files`, `wip`.

## Documentos de um jogo
| Arquivo | Para quê |
|---|---|
| `CONCEITO.md` | o que o jogo é e **o que não tem**. Vem antes do código. |
| `README.md` | como rodar e testar |
| `DESIGN.md` | GDD, quando o jogo cresce |
| `AUDITORIA.md` | o que foi medido e quando |
