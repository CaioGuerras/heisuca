# Heisuca: esboços do logo (18/10/2026)

Arquivos nesta pasta. Ver primeiro **`FOLHA_TESTES.png`** (os 3 esboços sobre os 5 temas: ícone em 144/72/48/24 px e banner
de TV 400×240) e **`TESTE_PIXELS_48_24.png`** (renderizado no tamanho real e ampliado sem suavizar).

Letras convertidas em contornos (o SVG não depende de fonte instalada): Sora (OFL) e Shippori Mincho Bold (OFL, kanji e
katakana). Gerador: `gerador/glifos.py` (fonttools, venv em `~/TMP/venv_fontes`) e `gerador/gerar.py` (só stdlib).

| Esboço | Ideia | Ícone 48 px | 24 px | Banner TV |
|---|---|---|---|---|
| **A, monograma "H de luz"** (`A_monograma.svg`, `A_banner_tv.svg`) | Dois pilares e, entre eles, só um traço de luz no roxo/acento do tema: o slogan "Nada entre você e o filme" e o 炳 (luz) desenhados | Lê bem; o traço de luz aparece | O traço vira 1 px borrado; segue lendo "H" | Bom: monograma + HEISUCA |
| **B, logotipo HEISUCA** (`B_logotipo.svg`, `B_banner_tv.svg`) | Sora fina, espaçamento largo (0,32 em), fio de cor e slogan embaixo. Ícone = H da Sora em peso 600 | O mais legível | Fio some | O mais "luxo" (estilo Apple/Muji) |
| **C, selo hanko 炳素華** (`C_selo.svg`, `C_banner_tv.svg`) | Selo vertical em vermelhão `#B3262E` com os 3 kanji vazados + HEISUCA e ヘイスカ. Ícone = 炳 sozinho em selo | Reconhecível como selo; o kanji não se lê | Vira mancha vermelha | O mais "japonês" |

**Recomendação [I]:** sistema combinado: **A como ícone** (app, TV, favicon; é o único que segura em 24 px sem perder
a ideia), **B como logotipo** (abertura, site, banner) e **C como selo de assinatura** (tela Sobre, abertura, material
impresso), nunca como ícone pequeno. O vermelhão do selo é a única cor fixa da marca; o resto segue o tema.

**Ajustes a fazer depois da escolha:** traço de luz do A mais grosso para 24 px (versão "pequena" do ícone); variante
monocromática para notificação do Android; conferir Sora × alternativa de título (BASE_MARCA §4); cores de Sorairo
(`#F1F7FD`/`#1F6FC5`) e Shinju (`#F6F3EE`/`#7A6A55`) são proposta nova, sem contraste medido ainda.

**[C] Caio:** escolher A, B, C ou o sistema combinado; vermelhão no selo ou selo na cor do tema.

## Decisão do Caio (18/10): esboço C, selo na cor do tema

Selo 炳素華 escolhido; a cor do selo segue o tema (`FOLHA_C_TEMAS.png`). Kanji em `#FFF8F0`; contraste WCAG medido [V]:

| Tema | Selo | Kanji × selo | Selo × fundo | Selo × superfície |
|---|---|---|---|---|
| Shikkoku | `#7444E0` (= botão primário) | 5,5 | 3,4 | 3,1 |
| Hisui | `#05805C` (jade ajustado; `#047857` dava 2,9 na superfície) | 4,7 | 3,2+ | 3,2 |
| Ichigo | `#D62D45` | 4,6 | 4,5 | 4,9 |
| Sorairo | `#1F6FC5` | 4,8 | 4,7 | 5,1 |
| Shinju | `#7A6A55` | 5,0 | 4,7 | 5,2 |

Kanji passa AA (≥ 4,5); o selo passa 3:1 contra o fundo e a superfície (WCAG 1.4.11, elemento gráfico).
**Pendente:** em 24 px (aba, notificação, favicon) o 炳 vira mancha: fazer variante pequena (selo com o 炳 mais grosso
ou só o quadrado com o traço central) e versão monocromática para notificação do Android. Os SVGs `C_*.svg` saem no tema
padrão (Shikkoku); os outros saem do gerador (`gerador/gerar.py`, coluna `sel` em `TEMAS`).

## Selo pequeno e notificação (18/10)

Teste em pixel real (`TESTE_SELO_PEQUENO.png`; colunas 16/24/32/48 px roxo, 16/24 morango, mono 24/48; linhas P1–P4).
Gerador: `gerador/pequeno.py`.

| Variante | 16 px | 24 px | Veredito |
|---|---|---|---|
| P1 mincho Bold com moldura (o oficial) | borrão | moldura come o kanji | só ≥ 48 px |
| P2 mincho ExtraBold sem moldura | traços finos somem | aceitável | descartado |
| P3 gótico (Noto Sans JP 700) sem moldura | razoável | nítido | reserva |
| **P4 gótico (Noto Sans JP 900) sem moldura** | **nítido** | **nítido** | **escolhido para ≤ 32 px** |

Regra de tamanho óptico (como as marcas japonesas fazem com mincho/gótico) [I]: **≥ 48 px → selo oficial** (mincho com
moldura, `C_selo.svg`/ícone do app); **≤ 32 px → `C_icone_pequeno.svg`** (aba do navegador, favicon, atalhos);
**notificação do Android → `C_notificacao_mono.svg`** (silhueta branca com o 炳 vazado por máscara). Noto Sans JP é OFL.
Para o Android, o mono precisa virar *vector drawable* sem máscara (recortar o caminho) quando o app for feito.
