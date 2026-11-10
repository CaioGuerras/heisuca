# P3 — barras pretas: prova pelo arquivo (27/10/2026)

Método: ffprobe (dimensões/SAR/DAR) + ffmpeg cropdetect=24:2:0 em 3 s de 3 pontos (20, 60 e 100 min) de cada arquivo.
| Arquivo | Codificado | Área com imagem (cropdetect) | Conclusão |
|---|---|---|---|
| Jurassic World (2015) alfaHD | 1920×960, SAR 1:1, DAR 2:1 | 1920×956 (+0+2) nos 3 pontos | sem barra gravada; na tela, as faixas vêm da proporção 2:1 × tela (16:9 TV ou 20:9 celular) |
| Jurassic World Dominion (2022) | 1920×1080, DAR 16:9 | 1920×960 (+0+60) em 20 e 60 min; 1886×960 em 100 min (cena escura) | **letterbox GRAVADO**: 60 px pretos em cima e embaixo dentro do arquivo |

Decisão: o app não altera recorte nem zoom por causa disso; fica só registrado. No celular 20:9, o Dominion aparece com faixas
laterais (16:9 × 20:9) mais as faixas gravadas em cima e embaixo; a iluminação dinâmica mede essas faixas pretas como parte do quadro.

Ideia futura (fora desta etapa): opção "aproximar para preencher" que respeite a área útil detectada.
