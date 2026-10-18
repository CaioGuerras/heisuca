# Heisuca, site (primeiro app) — 18/10/2026

Escrito do zero. Vira também o app das TVs Samsung (Tizen) e LG (webOS): a mesma build embrulhada num pacote.

## Pilha (decidida pelo Claude em 18/10; o Caio pode vetar)
- **Preact + TypeScript + Vite.** API do React em 4 KB; build moderna (~18 KB gzip) e build *legacy* automática para
  Chromium 56+ (Tizen 3.0, TVs 2017+). Enact (o do Moonfin) é pesado e preso à LG; Lightning (WebGL) não serve para site.
- **Cliente Jellyfin próprio** (`src/api/jellyfin.ts`, só `fetch`), sem o SDK oficial (axios e peso desnecessários).
- **Navegação espacial própria** (`src/foco.ts`): setas do controle e do teclado sobre `[data-foco]`.
- **Marca** vem de `~/cgflix/pesquisa_apps/marca` por `scripts/marca.sh` (tokens CSS, temas, fontes, ícones, abertura).
- **Ícones de interface:** Material Symbols Rounded 300 (`@material-symbols/svg-300`, Apache-2.0), a recomendação da
  BASE_MARCA §5 — **[C] o Caio ainda não confirmou** (troca é só no `comp/Icone.tsx`).
- hls.js já instalado para o player (M2).

## Teste (regra R1: só o Caio até aprovar)
- `scripts/publicar-teste` → https://netflix.docaio.com.br/__heisuca/ (mesmo domínio do Jellyfin: sem CORS).
  Só entram `caioguerras` e a conta da bancada (`VITE_SO_USUARIO`). Bloco `# >>> HEISUCA teste` no nginx da VPS, fora do
  bloco gerado pelo `cgf-jellyfin-tema` (o publicar dele não apaga o nosso). Desfazer: `scripts/publicar-teste --remover`.
- Bancada: `testes/bancada.py` (copiar para `/root/cgflix-bench/heisuca_teste.py`; roda no contêiner `cgflix-bench-chrome`
  com `.jf_teste.env`): abertura, login, início em desktop, celular e TV (setas). Capturas em `shots/heisuca/`.

## Marcos
- **M1 (feito 18/10):** abertura carimbo (1× por sessão, tecla/toque pula), login, início (destaque com fundo +
  Continuar assistindo + Novidades por biblioteca), 5 temas (`?tema=`), celular e TV. 0 erros no console nas 3 telas.
- **M2 (feito 18/10):** rotas por `#` (`src/rota.ts`: `#/t/<id>`, `#/ver/<id>?t=<ticks>`; Esc/Voltar do controle).
  Página do título (`telas/Titulo.tsx`: filme e série, logo, temporadas, episódios, "Continuar T1E3", marcar assistido).
  Player próprio (`telas/Player.tsx` + `api/perfil.ts`): perfil do aparelho perguntado ao `<video>`; toca direto quando dá
  (MKV no Chrome/Edge/Tizen/webOS), senão HLS fMP4 com `hls.js/light` carregado só quando precisa; se tocar direto
  falhar, cai sozinho no servidor. Áudio: o navegador não troca faixa, então áudio fora do padrão do arquivo vai por HLS
  (remonta, não converte o vídeo). Legendas de texto como WebVTT por fora (troca na hora); de imagem (PGS) e **ASS**
  gravadas no vídeo (o Jellyfin não converte ASS→VTT: `SupportsSubtitleConversionTo`). Retoma do ponto salvo, relata
  início/progresso (10 s)/fim e encerra a conversão (`DELETE /Videos/ActiveEncodings`). Próximo episódio no fim.
  Erros do navegador vão ao log do nginx da VPS: `grep __heisuca/__erro /var/log/nginx/access.log` (token mascarado).
  Bancada: `testes/bancada_m2.py` (desktop/celular/TV) e `testes/bancada_m2_trocas.py <id>` (retomar, SRT, áudio, assistido).
- **M3:** TV de verdade: destaque fixo e fileiras rolando por dentro, tecla Voltar (Tizen/webOS), pacote Tizen com outro ID
  (teste), teste no Chrome 83 da bancada (`cgflix-c83`) e AVPlay.
- **M4:** busca, Quick Connect, perfis/kids (Ichigo/Sorairo com a abertura kids), Pedidos (Seerr), PWA.
- **M5:** paridade com o site atual (apps.html, Como usar, push) e o OK do Caio para trocar o endereço.

## Pendências
- **ASS no navegador (feito 18/10):** JASSUB 2.5 (código MIT; libass/freetype/fribidi embutidos, LGPL e outras, usados sem
  modificação), mesmo caminho do jellyfin-web. Perfil `{ass|ssa, External}` só onde há WebAssembly + worker de módulo
  (`assNoNavegador`); TV antiga segue com a legenda gravada pelo servidor. Fontes = anexos do MKV (`MediaAttachments`).
  wasm (~900 KB gzip) carrega só ao escolher ASS; nginx serve `application/wasm` (bloco `types` no `publicar-teste`).
  Bancada: `testes/bancada_ass.py <id> <segundos>` (escolher um trecho com fala).
- **Guarda "toca sem quadro" (18/10 noite):** o Chrome do Android abriu o MKV do One Piece, tocou e mostrou só a legenda
  (o JASSUB desenha por quadro; sem quadro, só no avanço), sem erro, então o "cai no servidor" não disparou. Agora:
  MKV direto só onde `canPlayType('video/x-matroska')` responde (Chrome 154 sim, Chromium 128 não) ou Tizen/webOS, como no
  jellyfin-web; e 3 s tocando direto com `videoWidth` 0 ou `totalVideoFrames` 0 → recarrega em HLS do mesmo ponto (só
  remonta: `TranscodeReasons=ContainerNotSupported`), avisa no log (`sem quadro no direto`) e marca o aparelho por 30 dias
  (`localStorage hs-sem-mkv`). Bancada: `testes/bancada_guarda.py <id> chrome 0|1` (1 finge zero quadros). O Chromium do
  Playwright não tem H.264: na bancada, só o canal `chrome` vale para tocar.
- **Regra (Caio, 18/10):** não reinventar. Antes de desenhar algo, ver como os players da pesquisa resolvem e reaproveitar
  biblioteca/solução que já roda bem; o código de cola é nosso.
- Limite de 2 telas (plugin StreamLimit) barra a 3ª reprodução em sequência rápida da mesma conta (o gate conta sessões
  recém-paradas): na bancada, rodar uma tela por vez (`SO=tv`).
- Inter (OFL, `@fontsource-variable/inter`, só latin) entrou no M2. Repositório: `CaioGuerras/heisuca` (privado).
