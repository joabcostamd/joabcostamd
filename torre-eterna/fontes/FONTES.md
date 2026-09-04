# Fontes do jogo

Esta pasta é a **única exceção** à regra "nada de mídia no repositório". O motivo
é simples: vinte idiomas incluem chinês, japonês, coreano e tailandês, e não
existe jeito de desenhar um ideograma por código. Ou o jogo embarca uma fonte que
os tem, ou esses quatro idiomas mostram quadradinhos.

Os arquivos `.ttf` **não são versionados** (ver `.gitignore`): eles são baixados
por `tools/baixar_fontes.sh` antes de exportar. O que o repositório guarda é a
procedência — qual fonte, de onde, sob qual licença, cobrindo quais idiomas.
Fonte solta sem procedência é problema jurídico na loja.

Se a pasta estiver vazia, o jogo **roda mesmo assim**, usando a fonte embutida
do Godot. Ver `scripts/core/tipografia.gd`.

## O que baixar

| Arquivo | Família | Licença | Papel | Cobre |
|---|---|---|---|---|
| `Orbitron.ttf` | Orbitron (variável) | SIL OFL 1.1 | Logo, títulos grandes, números de destaque | Latim |
| `Exo2.ttf` | Exo 2 (variável) | SIL OFL 1.1 | Interface, corpo, HUD | Latim, latim estendido (vietnamita), cirílico, grego |
| `NotoSansThai.ttf` | Noto Sans Thai | SIL OFL 1.1 | Reserva para tailandês | Tailandês |
| `NotoSansSC.otf` | Noto Sans SC | SIL OFL 1.1 | Reserva para chinês simplificado | Han simplificado |
| `NotoSansTC.otf` | Noto Sans TC | SIL OFL 1.1 | Reserva para chinês tradicional | Han tradicional |
| `NotoSansJP.otf` | Noto Sans JP | SIL OFL 1.1 | Reserva para japonês | Kana e kanji |
| `NotoSansKR.otf` | Noto Sans KR | SIL OFL 1.1 | Reserva para coreano | Hangul |

## Por que estas

**Orbitron** é o padrão de fato para logo de jogo futurista: letras largas,
geométricas, com muito ar entre os traços — exatamente o que faz um contorno de
neon respirar. Não tem cirílico nem CJK, e por isso **só** aparece na logo e nos
títulos em alfabeto latino; em russo, chinês, japonês e coreano o título usa a
fonte de interface num peso mais forte.

**Exo 2** carrega a interface porque é a única techy livre que cobre latim
estendido (o vietnamita tem diacríticos que quebram a maioria das fontes),
cirílico e grego na mesma família — russo e ucraniano são o terceiro maior
público da Steam e não podem cair numa fonte diferente do resto da tela.

**Noto** entra só como reserva, e por eliminação: é a única família livre com
cobertura completa de CJK e tailandês. Ela não combina com o resto por acaso —
combina porque é neutra o bastante para não brigar.

## Números

O jogo mostra número o tempo todo, em coluna. As duas fontes principais têm
algarismos de largura fixa (`tnum`), que é o que impede a coluna de dançar quando
um `1` vira `8`. Ver `Tipografia.aplicar()`.

## Como baixar

```bash
bash tools/baixar_fontes.sh
```

O script confere o SHA-256 de cada arquivo contra `fontes/SHA256SUMS`: fonte
trocada por outra versão muda a métrica e quebra o layout que a varredura
aprovou.
