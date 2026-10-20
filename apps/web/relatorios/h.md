# Sessão H — desempenho (nada visual muda)

## O que mudou
1. **Imagens em WebP** (`src/api/jellyfin.ts`): `imagem()` (capa, fundo, logo, miniatura, foto de pessoa), `fotoUsuario` e a capa
   do "Em breve" (Sonarr/Radarr → Jellyfin) agora pedem `format=Webp`. Sem teste de suporte: o site já exige Safari 15+ e
   navegadores atuais, todos leem WebP. Logos vão em WebP também (WebP tem transparência). Qualidades mantidas (capa/logo 90,
   fundo 80, resto 85): na comparação a nitidez ficou igual, então não precisei subir.
2. **Partida rápida do HLS** (`src/telas/Player.tsx`, só a configuração do hls.js; perfil do aparelho e escolha direto/HLS intocados):
   `testBandwidth: false` (não baixa pedaço só para medir), `abrEwmaDefaultEstimate: 20_000_000` (servidor caseiro com banda
   folgada), `startLevel: -1` (automático pela estimativa; o Jellyfin costuma mandar um nível só), `startFragPrefetch: true`
   (pede o 1º pedaço enquanto o MediaSource prepara). Limites de buffer mantidos (30 / 60 s / 60 MB / 30 s atrás). Cada opção
   tem comentário curto.

## Medição
O servidor falso ignora `format`, então medi com uma cópia dele (fora do repositório, no rascunho da sessão) que imita o Jellyfin:
redimensiona por `fillWidth/fillHeight` e codifica em JPEG/PNG ou, com `format=Webp`, em WebP na mesma `quality` (Pillow).
Mesmas telas (Início e Título, celular e computador, Roxo):

| | antes | depois | ganho |
|---|---|---|---|
| total (90 imagens) | 2 200 KB | 1 773 KB | **−19 %** |
| capas (Primary, 79) | 1 479 KB | 1 312 KB | −11 % |
| fundos (Backdrop, 4) | 483 KB | 333 KB | −31 % |
| logos (PNG → WebP, 4) | 178 KB | 83 KB | −53 % |
| miniaturas (Thumb, 3) | 60 KB | 46 KB | −23 % |

PSNR entre os prints inteiros antes/depois: 39–43 dB (diferença invisível). Ganho esperado no servidor de verdade: igual ou
maior, porque as imagens gravadas no falso já são JPEGs pequenos recomprimidos (o Jellyfin parte dos originais). O codificador
real é o SkiaSharp do Jellyfin, não o Pillow: os números são estimativa.

HLS: o servidor falso entrega o vídeo direto (MP4), então o caminho HLS **não foi exercitado aqui**; só `tsc` confere as opções.
Ganho esperado: a 1ª imagem sai sem a ida extra de medição de banda e com o 1º pedaço já em voo (tipicamente algumas centenas
de ms no início). Precisa de conferência com o CGSERVER pela sessão principal.

## Comparações (`testes/comparacoes/h/`)
- `capa_zoom.jpg` (capa no celular, 2× ampliada), `fundo_zoom.jpg` (fundo no computador), `logo_zoom.jpg` (logo, 3×): nitidez igual.
- `titulo_desk_antes_depois.jpg`, `inicio_cel_antes_depois.jpg`: telas inteiras lado a lado.

## Verificações
`npx tsc -b` ok; `npm run build` ok (bundle principal 27,96 KB gzip); `node --test testes/capitulos.test.ts` 8/8; sem erro no console nos prints.

## Não mexido / [C] perguntas para o Caio
- Pôster do Seerr (`api/seerr.ts`): vem do TMDB pelo `imageproxy` do Seerr, que não converte formato; ficou JPEG.
- Capa do "Em breve" que vem do plugin (`/HomeScreen/CachedImage/...`): endpoint do plugin, não aceita `format`; ficou como está.
- [C] Se algum aparelho antigo (Safari < 14) precisar ser atendido, aí sim valeria testar suporte antes; hoje o mínimo é Safari 15.
