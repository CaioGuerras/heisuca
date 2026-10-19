# Sessão B — Início e Favoritos (ramo `site-v2-b-inicio`)

`npx tsc -b` e `npm run build` sem erro. Bundle principal: 183 KB / **56,3 KB gzip** (limite 70). Console sem erro nem aviso
nos 4 perfis (celular/computador × Roxo/Verde), no Início e nos Favoritos.

## O que fiz

### Início (`telas/Inicio.tsx`, `telas/inicio.css`)
- **Topo sem barra**: só a pílula [foto + servidor] e a busca redonda; sem os 3 pontinhos. Enquanto a página está no topo
  não há véu nenhum; o véu na cor da página (degradê, não barra) só aparece depois que a logo encaixa.
- **Destaque sem bordas**: a arte agora some por **máscara** (`mask-image`) na própria cor da página, em vez de um degradê
  pintado por cima. Isso tirou uma linha de 1 px que existia na base da fundação, no limite do destaque (dava para ver no
  Verde). Altura: 64,5% da tela no celular (o "Continuar" nasce onde nasce no VidHub), 72% no tablet, 80% no computador.
- **No centro**: logo (≤ 210×56 no celular, ≤ 460×130 no computador), a linha `★ 7,2 | 2026 | Terror, Comédia, Fantasia | [R]`
  numa linha só (os gêneros ganham reticências se faltar espaço; a classificação fica numa caixinha com o separador fora
  dela — na base o "|" caía dentro da caixa), a sinopse em 2 linhas `「Título」 texto` com o título em negrito, e os pontinhos.
- **Ao rolar, a logo sobe e encaixa no topo**: ela acompanha a página até o meio da pílula e fica ali, encolhendo nos
  últimos 140 px para caber entre a pílula e a busca (a conta usa as posições reais da pílula e da busca, então vale para
  qualquer nome de servidor e no computador). Movimento por `transform` num `requestAnimationFrame`, sem re-renderizar.
- **Carrossel**: troca a cada 8 s; para com o mouse em cima, com o dedo em cima e **enquanto a logo está encaixada** (a cor
  da página não muda debaixo de quem está lendo as fileiras). Arrastar para o lado troca; pontinhos têm área de toque maior.
- **Fileiras**: Continuar · Próximo · Em alta no Brasil (Top 10) · Mídia · uma por biblioteca com "Ver tudo ›" · **Em breve**
  (agora uma fileira só, no fim; na base eram "Séries em breve" + "Filmes em breve").
- **Top 10**: número em contorno na cor do tema, alinhado à base do pôster e encostado nele, sem ser coberto pelo pôster
  (o pôster do Top 10 é 12% maior que o das bibliotecas, como no `app_completo/…foto21`).

### Favoritos (`telas/Favoritos.tsx` novo, `telas/favoritos.css` novo; rota `fav` trocada em `app.tsx`)
- O mesmo topo da home; uma seção por biblioteca (nome + "Ver tudo ›"), pôster 2:3 com nota, ✓ visto, título + anos.
- Cor da página tirada do 1º favorito (`usePaleta`) e fundo desfocado do pôster dele (`fundoDesfocado`).
- **"Ver tudo ›"** abre a seção em grade (todos os favoritos daquela biblioteca, até 60) e vira "Mostrar menos".
- Desfavoritar pelo botão direito / segurar **some na hora** (sem recarregar). Sem favoritos: "Toque em ♡ num título para
  guardá-lo aqui." no meio da tela.

### Botão direito / segurar
Conferido com o Playwright: no computador, botão direito num pôster da home abre "Marcar como visto / Favoritar" e o aviso
"Guardado nos Favoritos." aparece; no celular, segurar 0,8 s num pôster dos Favoritos abre o menu e soltar **não** abre o
título. Desfavoritar todos pelo menu leva ao estado vazio. Teclado: Tab passa por pílula → busca → destaque → pontinhos.

### Paleta (`cor/paleta.ts`)
- **Verde**: a página era quase branca (L 0,86, croma baixo) e a cor do pôster não aparecia; o VidHub claro é um pastel de
  verdade (InuYasha ≈ L 0,68; Terra da Máfia ≈ L 0,52). Passei para **L 0,80** e croma ×0,85 (teto 0,075): o InuYasha / Returner
  dá um azul-acinzentado parecido com o do print. Fiquei mais claro que o VidHub de propósito, para não perder o "papel" do Verde.
- **Roxo**: mudança pequena (L 0,205 → 0,215, croma teto 0,045 → 0,06).
- Vidro no Verde: branco 60% → 74% (a ilha ficava "suja" com os cartões passando por trás; no VidHub ela é quase opaca).
- **Contraste medido em pixel** (texto escondido, fundo fotografado, pior pixel atrás da linha de dados + sinopse), nos 9
  destaques do servidor falso: Roxo ≥ 10,4:1, Verde ≥ 7,4:1, no celular e no computador.
- Favoritos: o fundo desfocado não é cor lisa, então o AA da paleta não valia ali (medi 2,7:1 no texto secundário do Verde
  na primeira versão). Corrigi com véu mais forte da cor da página e o texto secundário puxado para o principal; medido:
  Roxo 13,1 / 9,0 e Verde 12,1 / 8,5 (texto / secundário), com a conta feita para o pior caso (pôster todo preto no Verde,
  todo branco no Roxo).

## Comparações (`testes/comparacoes/b/`)
| Arquivo | O que mostra |
|---|---|
| `home_topo_cel_{roxo,verde}.jpg` | 412×915, topo × VidHub `home_topo` e `foto67` |
| `home_rolada_cel_{roxo,verde}.jpg` | rolada 450 px (logo acabando de encaixar) e 1500 px × VidHub `home_rolada` |
| `home_topo_desk_*`, `home_rolada_desk_*`, `home_rolada2_desk_*` | 1440×900, topo, 450 px e 1500 px |
| `favoritos_cel_*`, `favoritos_desk_*` | × VidHub `favoritos` |

## O que difere da referência e por quê
1. **Tamanho das letras.** No VidHub, medido proporcionalmente a 412 px, a sinopse e a linha de dados têm ~7–8 px, o nome do
   cartão ~9 px e o "S1:E1 - …" ~8 px. Isso é ilegível no navegador. Usei **11 px** (dados/sinopse), **12 px** (nome),
   **10,5 px** (episódio/anos), **16 px** nos títulos das fileiras (VidHub ~14). Posições, proporções e tamanhos de cartão
   batem: 16:9 com 180 px, pôster com 80 px, vão de 10 px, margem de 14 px, ilha com ~290 px. → ver [C1].
2. **Pílula e busca**: VidHub ~32 px de altura; usei 34 px (36 px na busca) para o toque.
3. **Ilha**: 50 px de altura (VidHub ~44 px), porque leva rótulo embaixo do ícone e a foto do usuário.
4. **Cor do Verde**: mais clara que o VidHub (L 0,80 contra 0,52–0,68), explicado acima. → [C2].
5. **Fundo desfocado dos Favoritos no Verde**: para garantir AA ele ficou bem mais apagado que no VidHub (lá o desfoque é
   bem visível e o texto é preto puro). No Roxo o desfoque aparece mais. → [C3].
6. **Ordem das seções dos Favoritos**: segue a ordem das bibliotecas no servidor (no falso: Filmes antes de Séries; no print
   do VidHub, Séries antes). O título da seção é o nome da biblioteca ("Filmes"), não "Favorito Filmes" (PLANO §7).
7. **Ao rolar**, o VidHub mostra a logo no topo e a linha de dados ainda visível embaixo dela; no nosso, quando a logo
   encaixa, o véu do topo cobre a linha de dados logo em seguida (a 450 px ainda se vê a sinopse). Achei melhor do que
   deixar texto passando por trás da pílula.

## O que não ficou bom (honesto)
- Logos **brancas** sobre o Verde (ex.: BUDDY) ficam com pouco contraste mesmo com a sombra; o VidHub tem o mesmo problema
  (Terra da Máfia vermelho sobre cinza). Não mexi na logo (é imagem do servidor).
- Logos em **duas linhas/quadradas** (ex.: "A Returner's Magic Should Be Special") ficam pequenas quando encaixam no topo,
  porque o limite é a altura da pílula ×1,6.
- O servidor falso **não devolve** um item favoritado na hora se ele estiver numa subpasta da biblioteca (o falso compara
  `ParentId` com a biblioteca; o Jellyfin de verdade busca recursivo). No teste, "Bleach" favoritado na home não apareceu nos
  Favoritos por isso — a tela pede `filters=IsFavorite&recursive=true`, que no servidor real funciona. Vale conferir na VPS.
- "Ver tudo ›" dos Favoritos abre uma grade na própria tela (não existe biblioteca filtrada por favoritos, e a Biblioteca
  não filtra, PLANO §6). → [C4].
- Não testei em celular de verdade (só Playwright com toque emulado).

## Dúvidas para o Caio
- **[C1]** Letras: copio o tamanho do VidHub (7–9 px, que no celular deles fica legível por causa da densidade) ou mantenho os
  11/12 px que usei?
- **[C2]** O Verde ficou num pastel L 0,80. Quer mais escuro, como o VidHub (0,65–0,70)? É uma linha em `paleta.ts`.
- **[C3]** Favoritos no Verde: aceita o desfoque mais apagado (AA garantido) ou prefere o desfoque visível como no VidHub,
  com o texto em preto puro (AA garantido também, mas o cinza do "2026"/"Ver tudo" some)?
- **[C4]** "Ver tudo ›" nos Favoritos: grade na própria tela (como fiz) ou outra coisa?
- **[C5]** Juntei "Séries em breve" e "Filmes em breve" numa fileira só, "Em breve". Prefere separadas?
- **[C6]** O carrossel para enquanto a logo está encaixada no topo (para a cor não mudar durante a leitura). Ok?

## O que mexi fora dos meus arquivos
- `src/estilo/base.css` (tokens do celular): pôster 84 → **80 px**, título de seção 18 → **16 px** (19 no tablet), ilha 56 → **50 px**
  (60 no computador), raio do cartão 12 → **9 px** (11 tablet, 12 computador). Afeta as telas das outras sessões
  (Biblioteca usa o mesmo pôster e raio, o que bate com `vidhub/…foto50`).
- `src/comp/cartoes.css`: nome 13 → 12 px, sub 11,5 → 10,5 px; **nota** virou o selinho escuro no canto (como no VidHub
  `foto50`); ✓ visto um pouco menor com sombra; selo "Novo episódio" não quebra mais em 2 linhas; Top 10 ajustado.
- `src/comp/fileira.css`: espaçamentos (20 px entre fileiras no celular, 30 no computador; "Ver tudo" 13 px).
- `src/comp/navegacao.css` e `Navegacao.tsx`: pílula 40 → 34 px (texto 12,5 px), busca 44 → 36 px no topo (42 no computador),
  foto 30 → 28, ilha 304 → 290 px de largura, ícones 22 px, foto da ilha 24 → 22.
- `src/cor/paleta.ts`: claridade/croma (acima) e vidro do Verde.
- `src/estado/usuario.ts`: **acrescentei** `useMudancas()` (re-render em qualquer troca de visto/favorito). Nada mudou no resto.
- `src/app.tsx`: só a linha da rota `fav` (+ import).
- `dados/inicio.ts` ficou como estava.
