# Sessão E — Interface do player (PLANO §13)

Ramo `site-v2-e-player`, a partir do `site-v2`. `npx tsc -b` e `npm run build` sem erro; bundle principal **58,1 KB gzip**
(o hls.js e o JASSUB continuam sob demanda). Teste da regra de capítulos: `node --test testes/capitulos.test.ts` → 7/7.

## O que fiz

| Arquivo | O quê |
|---|---|
| `src/telas/Player.tsx` | Só a **interface** foi refeita. O motor (perfil, direto/HLS, guarda "sem quadro", JASSUB, relatos, encerrar ao sair) ficou igual, linha por linha, com **uma** mudança mecânica: a função `corpo` do PlaybackInfo saiu de dentro de `carregar` para o corpo do componente (mesmo conteúdo), porque a busca de legendas usa o mesmo pedido. |
| `src/telas/player.css` | Reescrito (o provisório do M2 saiu). |
| `src/player/capitulos.ts` | Regra pura do Pular abertura/créditos. |
| `src/player/Carregando.tsx` | Carregamento com o selo 炳素華 (carimba como na abertura e depois "respira"). |
| `src/player/PainelFaixas.tsx` | Painel Áudio e legendas + Buscar legendas. |
| `src/player/faixas.ts` | Nome das faixas como no app completo (língua em PT em cima; título · formato · canais embaixo). |
| `testes/capitulos.test.ts` | Teste `node --test` (Node ≥ 22.18, roda o .ts direto). |
| `testes/prints_player.py` | Prints + checagens automáticas do player (carregando, 0:10, painel, busca, baixar, créditos, fim, teclado). |

**Controles.** Topo: ← + `Deadwood T1:E1 · Deadwood` (série em negrito, o resto mais claro; filme: só o nome). Centro:
⏮ −10 ⏯ +10 ⏭ (anterior/próximo só em episódio, apagados quando não existem; trocam de episódio com `location.replace`,
então o Voltar continua levando ao título). Base: `0:10 ─── 1:30` com a barra fina na cor do tema, **Áudio e legendas** e
**tela cheia** (ícone troca para "sair"). Removidos: tudo da lista do Caio, e o selo "Pelo servidor".
Os controles somem em 3,5 s tocando e o cursor some junto; toque no celular mostra/esconde; clique no computador pausa,
duplo clique = tela cheia.

**Carregamento.** No lugar do círculo girando: só o selo 炳素華 (38 px), sem o HEISUCA, na cor do selo do tema. Enquanto
carrega, os botões do centro saem para não brigar com o selo.

**Painel Áudio e legendas.** Duas colunas com ✕ (computador e celular deitado), uma coluna rolável subindo de baixo no
celular em pé. Fecha no ✕, tocando fora, no Esc e ao escolher. O painel não fica preso: é uma camada com fundo que fecha ao
toque (checado no script: `painel_fecha_tocando_fora: true` nos 6 perfis — celular deitado, computador e celular em pé,
cada um em Roxo e Verde).

**Buscar legendas…** no fim da coluna de legendas, só se `euMesmo(s).Policy.EnableSubtitleManagement`. Abre a vista de
busca no próprio painel (‹ volta): **Português (Brasil)** (`pob`) e, separado, **Português (Portugal)** (`por`, sem repetir
o que já veio em `pob`). Cada linha: nome do arquivo, `Open Subtitles · SRT · 5.000 downloads` (+ "feita para este arquivo"
quando `IsHashMatch`). Ao tocar: `baixarLegenda` → `infoReproducao` de novo → a faixa nova (índice que não existia) entra na
lista e é ligada; texto externo entra como `<track>` sem recarregar o vídeo, o resto passa pelo `carregar` normal. Aviso
"Legenda baixada e ligada". Se nada novo aparecer (a mesma legenda baixada de novo), avisa "Essa legenda já estava na lista" (caminho exercitado no
script nas rodadas "em pé", que repetem itens já baixados no servidor falso).

**Pular abertura / Pular créditos.** `puloEm(item.Chapters, posição, temPróximo)`: acha o capítulo atual pelo início;
nomes comparados sem maiúscula/acento, aceitando número no fim (`OP 1`, `ED2`, `Opening 01`, `OP #2`); só os nomes do PLANO
(sem "Opening Scene", "Chapter 1", "Edward"…). O botão aparece **só dentro do capítulo**, no canto inferior esquerdo acima da
barra, e leva ao início do capítulo seguinte; créditos no último capítulo de episódio com sucessor → próximo episódio. No
vídeo de teste: nada em 0–8 s, "Pular abertura" de 8 a 38 s (→ 38 s), nada no Episódio, "Pular créditos" de 80 s ao fim
(→ próximo episódio). O botão continua visível com os controles escondidos (desce para perto da borda).

**Teclado (computador).** Espaço/K tocar-pausar, ←/→ 10 s, F tela cheia, M mudo (com aviso), Esc fecha o painel → sai da
tela cheia → volta. Enter num botão focado faz o normal. As teclas do controle remoto que já existiam continuam.
Checado no script: espaço toca, K pausa, → +10,0 s, ← −10,0 s, M liga/desliga, Esc volta.

**Fim do episódio.** Cartão discreto no canto inferior direito: miniatura 16:9 do próximo, "Próximo episódio",
`T1:E2 · Águas Profundas` e **Assistir** (focado para o Enter). Sem contagem automática (ver [C]).

## Comparações (`testes/comparacoes/e/`)
- `cmp_cel_*` = celular deitado 915×412; `cmp_desk_*` = computador 1440×900; `cmp_empe_painel.jpg` = celular em pé.
- `carregando` × vidhub/foto45 · `controles_pular` (0:10, Pular abertura) × vidhub/foto48 · `painel` × app_completo/foto25 ·
  `busca` × vidhub/foto49 · `creditos` (1:24) × vidhub/foto48 · `fim` × vidhub/foto46.

**Atenção:** o Chromium do Playwright não toca H.264, então para os prints converti o vídeo de teste para VP9/Opus numa
cópia do servidor falso fora do repositório (mesmos capítulos e duração). O vídeo é a barra de cores do teste, por isso os
prints não têm a "cara" de filme dos prints do VidHub.

## O que difere das referências e por quê
1. **⏮ −10 ⏯ +10 ⏭ no centro da tela**, e não na linha de baixo como no VidHub (foto46–48). O PLANO separa topo / centro /
   base e põe a barra, Áudio e legendas e tela cheia na base; o centro fica como no app completo (foto24). A base virou
   uma linha só (tempo · barra · duração · 2 ícones), mais limpa que as duas linhas do VidHub.
2. **Painel em caixa centralizada** como o app completo (foto25), não o balão do VidHub (foto49), conforme o PLANO.
3. Na busca de legendas, o VidHub abre um menu do sistema; nós mostramos as duas listas (BR e PT) dentro do painel.
4. Carregamento sem a palavra "Carregando" (só o selo; o texto vai no `aria-label`).
5. No tema Verde (claro) o player continua preto; a primária verde-escura `#047857` não lê bem sobre preto, então dentro do
   player uso `#34d399` (verde claro do mesmo matiz) para a barra e o ✓. É a única cor nova.

## O que não ficou bom / limites (honesto)
- **Legenda de texto de outro endereço não aparece** — achado no teste, é do motor, não mexi: o `<video>` não tem
  `crossorigin`, e o navegador recusa o `<track>` vindo de outro domínio ("Unsafe attempt to load URL … Stream.vtt").
  No servidor falso (5173 × 8097) a faixa fica "ligada" mas sem texto na tela. Em produção só funciona se o site e o
  servidor estiverem na mesma origem. Correção provável: `crossOrigin="anonymous"` no `<video>` (o Jellyfin manda CORS),
  mas mexe no carregamento do vídeo direto — fica para a sessão principal testar com o servidor de verdade.
- **Descobrir a legenda baixada** pela diferença de índices (a que não existia antes). Se o Jellyfin renumerar as faixas ao
  acrescentar uma externa, pode ligar a errada. Conferir no CGSERVER.
- Os nomes das legendas do servidor falso não têm `Title`, então aparecem duas "Português" (VTT e ASS) distintas só pela
  segunda linha. Com dados reais (que têm `Title`, como em foto25) fica como no app completo.
- O print de "carregando" é estático; a animação (carimbo + respiração) só se vê rodando. Não gravei vídeo.
- Não testei em celular de verdade nem em Safari/iOS (tela cheia do iPhone cai no `webkitEnterFullscreen` do vídeo, que já
  existia; ali os nossos controles não aparecem).
- Volume: não há controle de volume na tela (só M). Não estava na lista; ver [C].

## [C] Dúvidas para o Caio
1. Os botões ⏮ −10 ⏯ +10 ⏭ ficam **no centro da tela** (como fiz) ou **na linha de baixo** como no VidHub?
2. Fim do episódio: quer **contagem regressiva** que passa sozinho para o próximo (ex.: 10 s), ou fica só o cartão?
3. **Filme** com "Créditos" no último capítulo: hoje não aparece botão (não há para onde ir). Quer "Pular créditos" que
   encerra e volta ao título?
4. Computador: quer uma **barra de volume** ao lado da tela cheia, ou só o M e o volume do aparelho?
5. O "Pular abertura" fica visível mesmo com os controles escondidos (como Netflix). Prefere que suma junto?

## O que mexi fora dos meus arquivos
- Nada em componentes comuns, API ou rotas. Só arquivos novos em `src/player/`, `testes/capitulos.test.ts`,
  `testes/prints_player.py` e este relatório.
