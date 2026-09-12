# planejamento-jogo-novo

A régua do **começo** de um jogo. A `AUDITORIA.md` da raiz é a régua do **fim**.

| A auditoria pergunta | Aqui a pergunta é |
|---|---|
| "você fez isso bem?" | "você já **decidiu** isso?" |

## O que tem aqui

| Arquivo | Para quê |
|---|---|
| `BLOCOS.md` | os 13 blocos de decisão, o grafo de dependência e as 5 fases |
| `PERGUNTAS.md` | o banco de perguntas das fases 0 e 1 — 44, cada uma com recomendação |
| `portao-plano.py` | diz se o jogo já pode virar código |
| `testes-portao.py` | 24 testes do portão, rodam em menos de 1 s, sem Godot |

## Usar

```bash
python3 planejamento-jogo-novo/portao-plano.py jogos/<slug>
python3 planejamento-jogo-novo/testes-portao.py
```

O portão imprime um bloco delimitado. **O bloco é a única fonte de verdade** — exit code não
conta, igual ao portão frio:

```
===PLANO-VERIFY===
{ "status": "FALTA", "fase_alcancada": 1, "bloqueia_codigo": [...] }
===FIM-PLANO-VERIFY===
```

## A regra que impede alucinação

Toda decisão guarda **de onde veio**: 👤 o Joab decidiu · 📏 saiu de medição · 🤖 recomendação
aceita · 🟡 palpite do agente que ninguém confirmou.

**🟡 em bloco que trava = código bloqueado.** O agente não constrói em cima do próprio palpite.

## Ainda falta construir

- `PERGUNTAS.md` da **fase 2 em diante** (B4 a B12) — a fase 0 e 1 já estão prontas
- `generos/` — perfil por gênero, para marcar N/A automático
- `modelos/` — os 11 documentos em branco
- `tarefas.py` · `cartao.py` · `handoff.py` — os arquivos gerados a partir do plano
- a skill `novo-jogo` deste repositório, que embrulha tudo

O portão **ainda não entra no `testar-tudo.sh`**: nenhum jogo usa este formato, e ligá-lo agora
deixaria o repositório inteiro vermelho sem motivo. Entra quando o primeiro jogo migrar.
