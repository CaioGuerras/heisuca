# A2 — reprodução e correção da borda da arte

A evidência do Caio tem 1220×180 px (é um recorte do telefone, não a tela inteira).
Na linha 88 há 704 cores; linhas 86, 87, 89 e 90 são uniformes em RGB (39, 31, 63).
O zoom existente repete a fileira quatro vezes, sem criar uma faixa maior no original.

## Reprodução antes de corrigir

Flutter 3.47.1, `flutter_tester` Linux. Fixture de imagem sintética com cores fortes,
sem servidor nem mídia real. Mesma ordem de camadas da arte da Início e da ficha:
`ShaderMask → HeisucaParallax(ClipRect → Transform) → imagem`.

- DPR 2,97 e 2,96875; dimensões físicas 1220×2712; alturas reais dos dois quadros.
- 23 posições de rolagem, incluindo frações de pixel; filtro bicúbico.
- Leitura RGBA de todas as colunas em sete/oito fileiras ao redor da borda inferior.
  Ali o gradiente já é transparente, portanto cada pixel deve ser igual ao fundo.
- Teste padrão: 4 casos passaram. Com `--enable-impeller`: os 4 casos falharam.
  Exemplo: Início, DPR 2,97, rolagem 32,125 dp, borda física 1653,82875;
  **1220 pixels divergentes**, concentrados numa única linha, como no recorte do Caio.
- Controle com parallax desligado: passou no Impeller.
- Um ClipRect externo sem ampliar a máscara reduziu os casos, mas **não corrigiu**.

`a2_impeller_antes_inicio_32_125.png` é a captura sintética produzida pela estrutura
original. Não é print de telefone nem de conteúdo do acervo.

## Correção na composição

`HeisucaArtworkMask` mantém imagem, quadro e coordenadas do gradiente com as medidas
anteriores. Somente a área de composição de `ShaderMask` ganha **um pixel físico**
na parte inferior: cobre por inteiro a célula que pode ser rasterizada parcialmente
além da borda lógica. O recorte final conserva o tamanho original do quadro.

Não há detecção de modelo de aparelho, arredondamento do scroll, faixa pintada por
cima do sintoma, mudança de altura do destaque ou deslocamento dos stops do gradiente.
Os dois chamadores reais usam o mesmo componente.

`a2_impeller_depois_inicio_32_125.png`: mesma fixture, posição e DPR, após a correção.
A fileira colorida desaparece. Comparação de antes/depois, excetuada a borda:
nenhuma diferença maior que 1/255 por canal. Em repouso também não há diferença maior
que 1/255. O golden anterior em `test/heisuca/goldens/a2_home_before_fix.png` verifica
esse limite para não alterar o recorte/composição em repouso.

## Regressão permanente

`test/heisuca/heisuca_art_edge_test.dart`: oito casos (duas alturas × dois DPRs ×
parallax ligado/desligado), 184 quadros por renderizador. A comparação das fileiras
é exata; somente o golden de composição admite 1/255 para arredondamento da GPU.

```
export PATH="$HOME/sdk/flutter/bin:$PATH"
cd apps/app
flutter test test/heisuca/heisuca_art_edge_test.dart
flutter test --enable-impeller test/heisuca/heisuca_art_edge_test.dart
```

O segundo comando foi incluído no portão `scripts/heisuca-checar.sh`, porque rodar
só o primeiro não detecta esta regressão. A variável opcional `HEISUCA_A2_CAPTURE`
aponta para um diretório existente e permite gravar as capturas da fixture.

Limite: reprodução equivalente no Impeller do Flutter tester, sem validação física
no Edge 60 Pro. A correção ainda precisa ser conferida por Caio no aparelho.
