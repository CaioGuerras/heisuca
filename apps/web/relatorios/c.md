# Sessão C — Título e Biblioteca (ramo `site-v2-c-titulo`)

## O que fiz
**Título** (`src/telas/Titulo.tsx`, `titulo.css`), rota `#/t/<id>`, para série, filme e coleção:
- Arte (Backdrop) até o topo, dissolvendo na cor tirada do pôster (`usePaleta(hashDe(item,'Backdrop'))`). ← redondo fixo, **sem ⋯**.
- Logo centralizada (sem logo: o nome em Sora). Linha `★ 8,1 | 21/03/2004 | HBO | Faroeste, Crime, Drama [BR-18]`; embaixo, pequena,
  `3 temps. · 1h2min · 1080p H264 SDR`. Cada parte só aparece se o servidor tiver o dado.
- **Reproduzir** largo em pílula translúcida; vira `Continuar T1:E3` quando o episódio da vez tem posição salva ou a série tem
  algo visto (`PlayedPercentage`); no filme, `Continuar de 26:44`. **Gruda no topo ao rolar**, com a linha pequena por cima
  (como no `foto43`); no celular, grudado, ele abre espaço para o ←.
- ♡ e ⚑ abaixo dele (Favoritar e Visto/Não visto, por `estado/usuario.ts`, com aviso).
- Sinopse pequena do episódio da vez `「Deadwood·Temp. 1·EP 1」 …` (4 linhas; um toque abre tudo). Filme/coleção: `「Nome」 …`.
- `Temporada 1 ⌄` + `Ver tudo ›`. A temporada abre **contida** (`comp/Folha`: folha de baixo no celular, caixa no computador,
  rolagem própria, fecha ao escolher, no ✕, no Esc ou tocando fora). `Ver tudo ›` abre a lista da temporada (miniatura,
  `1. Título`, duração, sinopse) na mesma folha contida.
- Episódios 16:9 com o da vez em destaque (anel) e `1. Título` embaixo; ✓ quando visto, barra quando em andamento; botão direito/
  segurar = visto/favoritar. Páginas `1-10` / `11-12` em pílulas quando a temporada passa de 10; abre na página do episódio da vez.
- **Elenco** em quadrado arredondado com nome e personagem; sem foto = silhueta discreta (nunca letra por cima). Só atores
  (se não houver, os convidados).
- **Gêneros** em pílulas.
- **Info mídia**: cartões finos Vídeo (resolução, codec · perfil, faixa dinâmica, quadros/s, taxa de bits) e Áudio (idioma,
  codec, canais, padrão), um por faixa de áudio. **Sem caminho de arquivo; linha sem dado não aparece.** Na série, os fluxos
  vêm do episódio da vez.
- Episódio ou temporada aberto por link (`#/t/<id do episódio>`) vira a página da série (`location.replace`).
- Coleção (BoxSet): mesma cabeça (sem Reproduzir) e a grade dos títulos da coleção em ordem de lançamento.

**Biblioteca** (`src/telas/Biblioteca.tsx`, `biblioteca.css`), rota `#/b/<id>`:
- Topo `← | nome | ☰`; o ☰ abre o **menu lateral direito** com as bibliotecas de vídeo (ícone por tipo, ✓ na atual) e troca direto.
- O menu lateral termina com uma linha discreta do servidor atual (`dns` + nome que o servidor informa + "Trocar"), que abre o
  "Trocar servidor" da fundação (`abrirServidores()`), conforme o pedido do Caio de 18/10 repassado pela sessão principal.
- Sem abas e sem ordenar/filtrar: ordem alfabética (`daBiblioteca`). Grade 2:3 em 3 colunas no celular, `auto-fill` no
  computador (8 colunas a 1440 px); nota, ✓ visto, título + anos (o `CartaoPoster` da fundação, com botão direito).
- Carrega de 60 em 60 ao rolar (IntersectionObserver com folga de 900 px); para no total ou numa página vazia/curta.
- Lembra a última biblioteca (`lembrarBiblioteca`); `#/b` abre a última (se ainda existe) ou a primeira, e corrige o endereço
  para `#/b/<id>` sem empilhar. A ilha aparece. Cor da página tirada do pôster do 1º item.

## Conferência
- `npx tsc -b` e `npm run build` sem erro. Bundle principal **65,5 KB gzip** (limite 70), já com o `site-v2` atual (A e B juntas); só a C somava ~0,9 KB.
- Console sem erro nas 18 cenas × 4 contextos (celular 412×915 e computador 1440×900, Roxo e Verde).
- Prints: `python3 testes/prints_c.py --chromium …` (cenas: Deadwood topo/rolado/baixo/temporada/ver tudo, One Piece,
  HSOTD, InuYasha, Aoashi, Masterplan, coleção Alien, Biblioteca, menu lateral, rolada e `#/b`).
- Comparações em `testes/comparacoes/c/`:
  - `cel_titulo_topo.jpg` (× `vidhub/…foto42`), `cel_titulo_rolado.jpg` (× `…foto43`), `cel_titulo_temporada.jpg`
    (seletor aberto, Deadwood e One Piece × o reprovado `…foto72`), `cel_titulo_baixo.jpg` (elenco/Info mídia × `…foto71`),
    `cel_titulo_outros.jpg`, `cel_titulo_filme_colecao.jpg`, `cel_titulo_vertudo.jpg`;
  - `cel_biblioteca.jpg` (× `…foto50`), `cel_biblioteca_menu.jpg` (menu lateral × `…foto51`), `cel_biblioteca_trocar.jpg` (linha do servidor e o Trocar servidor aberto);
  - `desk_{roxo,verde}_*.jpg`: título topo, rolado, temporada aberta, baixo, filme, coleção, biblioteca e menu lateral.
- Teclado no computador: tudo é botão; as folhas prendem o foco e fecham no Esc; o foco volta para quem abriu.

## O que difere da referência e por quê
- **Nota e data são da série**, não do episódio. O VidHub mostra `★ 7,1 | 20/03/2004` (nota e data do episódio 1, com a
  data deslocada pelo fuso). Usei a da série (8,1; 21/03/2004, sem deslocar o fuso). Ver [C1].
- **Gêneros com ", "** em vez de "Faroeste,Crime,Drama" colados; no máximo 3 na linha (todos nas pílulas).
- **Info mídia mais enxuta** que a do VidHub (que tem ~16 linhas e o caminho do arquivo): só os campos do PLANO §5. O VidHub
  mostra um cartão de Áudio; eu mostro **um por faixa** (Áudio 1, Áudio 2), lado a lado e rolando de lado no celular, como lá. Ver [C2].
- **"1080p H264 SDR" montado do fluxo** (largura + codec + faixa). O `DisplayTitle` do HSOTD vinha como
  `[philosophy-raws] - 1080p - H264 - SDR` (nome do grupo do arquivo), por isso não uso o texto pronto do servidor.
- **← e ☰ em botão redondo de vidro**; no VidHub são ícones soltos. Sobre a arte, o ícone solto some em imagem clara.
- Ao grudar, o Reproduzir no celular encolhe para a direita do ← (no VidHub o botão passa por baixo da seta).
- Biblioteca: no VidHub o ☰ é "ordenar"; aqui é o menu lateral das bibliotecas (pedido do Caio). O print do VidHub com menu
  (`foto51`) é o menu do cartão; o nosso menu do cartão é o da fundação (Marcar visto · Favoritar, sem Excluir).

## O que não ficou bom (honesto)
- **Coleção no servidor falso fica vazia** ("Nenhum título desta coleção no servidor"): o falso não gravou os filhos dos BoxSets
  (`/Items?parentId=<coleção>` devolve vazio) e a arte do Alien não está gravada. O código usa a API normal; precisa conferir
  com o CGSERVER de verdade.
- **Biblioteca no falso para em 60 itens** (o falso só gravou a 1ª página; o total diz 146). A parada por página vazia/curta
  funciona; a carga da 2ª página em diante só dá para ver no servidor real.
- **One Piece**: o falso só tem os episódios da Temporada 1 (8), então as páginas `1-10/11-…` aparecem no Deadwood (12), não
  no One Piece. O seletor com 24 temporadas abre contido e rola, mas **não rola sozinho até a temporada atual** (com o
  One Piece na T1 não importa; numa T20 a pessoa rola a lista).
- **Logo escura sobre arte escura** (HSOTD no Roxo) tem pouco contraste: só há uma sombra leve atrás da logo.
- A sinopse do HSOTD veio em inglês (é o que o servidor tem; PLANO §5 manda mostrar assim).
- Só testei com o servidor falso e no Chromium; Safari/iOS (o `position: sticky` + `backdrop-filter`) não conferido.

## Dúvidas [C] para o Caio
- **[C1]** Na série, a linha `★ nota | data` deve ser da **série** (fiz assim) ou do **episódio da vez**, como no VidHub?
- **[C2]** Info mídia com várias faixas de áudio: um cartão por faixa (fiz assim) ou só a faixa padrão?
- **[C3]** Coleção: pôr um **Reproduzir** (o 1º título não visto)? Deixei sem, para não inventar regra.
- **[C4]** Tocar num episódio **toca direto** (fiz assim). Prefere que só selecione (mude sinopse/mídia) e toque pelo Reproduzir?
- **[C5]** "Continuar T1:E3" aparece também quando o próximo episódio ainda não foi começado mas a série já tem episódios vistos.
  Ou deve ser "Reproduzir T1:E3" nesse caso e "Continuar" só com posição salva?

## O que mexi fora dos meus arquivos
- `src/app.tsx`: troquei as duas linhas `EmConstrucao` de `titulo` e `biblioteca` (e os dois imports).
- `src/comp/Folha.tsx` + `folha.css`: **acrescentei** a variante `'lateral'` (menu que entra pela direita). Nada do que existia mudou.
- `src/comp/Icone.tsx`: acrescentei `videocam` e `music_note` no glob.
- `src/api/jellyfin.ts`: acrescentei `daColecao` (filhos de um BoxSet em ordem de lançamento).
- Rebase no `site-v2` atual (f17be63); o único conflito foi em `app.tsx` (a linha do Favoritos da sessão B), resolvido mantendo as duas.
- `testes/prints_c.py` (novo): prints com ações por cena (rolar, clicar), com espera da transição.
