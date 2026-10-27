# P — ajuste da medição de imagem da bancada (em andamento)

Pedido da revisão de P1/P2, aprovadas. Não reabre as etapas nem altera o player.
A correção trata a prova de imagem; o restante da rodada continua na P3.

## Causa e prova anterior

`analisar()` usava `max(rgb) > 0` na captura inteira. Um quadro preto com HUD
branco no topo/centro e barra branca do Android recebia `sim`; o host liberava
o ACK e o Voltar. Novo teste em `scripts/bancada/test_imagem.py` reproduziu isso
no código anterior: **RuntimeError not raised**. Os quatro outros casos,
incluindo um quadro real, passaram. Log:
`evidencias/p_imagem_hud_antes_2026-10-27.txt`.

## Correção local

O evento das capturas 06/21 passa a levar dimensões de exibição do motor,
retângulo físico da superfície `Video`, tamanho físico da janela, proporção,
zoom e áreas do sistema. A integração usa a API existente do controlador para
ocultar o HUD e aguarda a retirada efetiva dos controles antes da captura.
A leitura numérica usa subpropriedades `video-params/*`, conforme a ponte
nativa MPV_FORMAT_STRING; não pressupõe um mapa JSON da API nativa.

O recorte considera conter/cobrir/esticar e zoom, limitado pela superfície e
janela sem áreas de barras/gestos. A largura de exibição respeita DW/DH ou PAR
informado pelo motor, além da rotação. Sem dimensões mensuráveis, HUD conhecido
ou correspondência entre janela e PNG, a bancada falha sem ACK. Não volta a
aceitar a tela inteira como prova.

No host, o letterbox geométrico sai da região medida. Exclusões de HUD são
subtraídas como retângulos disjuntos (sobreposições contam uma vez). A aprovação
exige **luma Rec.709 > 16 em pelo menos 2% dos pixels da área útil**. O JSON
registra retângulos, quantidade de pixels, fração, limiares, geometria e método.
`maiorCanalRGB` agora se refere apenas à região medida.

## Provas locais e limites

- Python: **46 testes aprovados**, incluindo preto + interface sem ACK/Voltar,
  quadro real, 1 pixel claro, limiar 1,99%/2%, luma 16/17, barras/pillarbox,
  exclusões sobrepostas e geometria ausente/incompatível.
- Flutter: **6 testes aprovados** do contrato de captura: dimensões
  anamórficas, PAR obrigatório no fallback, rotação, leitura da ponte e recusa
  a HUD visível/dimensões inválidas.
- Preto + interface: **42.320 pixels medidos, fração 0, `não`**.
- Quadro real do run P2 **40482536078** (arquivo
  `evidencias/p2_21_final_2026-10-27.png`): **506.880 pixels medidos, fração
  0,9977864583, `sim`**. O log daquele run informa vídeo 1920×1080, a captura
  tem 1200×540. As barras da fixture desse teste são parâmetros explícitos do
  teste, não uma nova medição dos insets daquele aparelho.
- Resultados reproduzíveis: `evidencias/p_imagem_areas_2026-10-27.json`.

Portão final local verde: 1.755 Flutter, 3 skips de capturas opcionais, 8 Impeller
e 46 Python (`/tmp/p3-adjusted-final-gate.log`). Ainda faltam push e leitura dos
runs de APK/bancada. Não testado em aparelho. Barras já gravadas no arquivo não são
inferidas apenas da proporção; a conferência da origem das faixas continua
pendente no registro da P3. Não alterar proporção/recorte no app para ocultá-las.
