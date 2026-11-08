# Lacunas visuais — Jocasta, 07/11/2026
Base: 4113f48, noite/visual. Linhas abaixo referem-se à base antes das alterações.

- Sistema visual: os tokens importados ainda são os de outubro (roxo vivo/papel), divergindo da PALETAS_HEISUCA de 31/10: `src/marca/temas/shikkoku.css:6`, `hisui.css:6`. Aplicar paletas oficiais no CSS do site sem editar os tokens gerados. O `body` já é pintado em `src/estilo/base.css:50`; não ampliar essa regra nem tocar na camada de vídeo.
- Home: `src/telas/Inicio.tsx:39` troca o destaque antes de decodificar a próxima arte/logo; a pausa não inclui foco/teclado nem movimento reduzido (`:44`, `:80`). CSS usa svh sem fallback e color-mix indisponível no Chrome 88 (`src/telas/inicio.css:3`, `:14`). Hero, logo, cor e fileiras já existem. Continuar mescla Próximo e não há Mídia; comentário da base registra decisão posterior do Caio (19/10 noite), por isso preservar essa composição.
- Título: fluxos já chegam do filme ou episódio (`src/telas/Titulo.tsx:138`), mas faltam selos Dublado/Legendado/4K/HDR. Gradiente depende de color-mix (`src/telas/titulo.css:14`), removendo a dissolução no Chrome 88. Foco em linhas de episódios é apagado (`:93`).
- Cartões: `src/comp/Imagem.tsx:8` mantém carga/erro da URL anterior; usa só cor média em vez do BlurHash desenhado (`:10`). Revelação não espera decode (`:16`). `src/comp/cartoes.css:10` reserva composição em todos os cartões; não oferece o mesmo tratamento de hover ao foco. `src/comp/fileira.css:7` pode cortar a elevação/contorno no topo. Fileira sempre pede scroll suave (`src/comp/Fileira.tsx:25`). Esqueletos já existem.
- Biblioteca: grade de 3 colunas, paginação e cor do primeiro item já estão presentes. `src/telas/Biblioteca.tsx:106` fica aria-busy até acabar o catálogo, mesmo sem requisição ativa; melhorar estado de carregamento e fundo desfocado local do primeiro item. Cabeçalho usa coluna 1fr que pode exceder 360 px (`src/telas/biblioteca.css:3`).
- Favoritos: seções por biblioteca, vazio, cor e fundo BlurHash já atendem ao plano (`src/telas/Favoritos.tsx:36`); herda melhorias dos cartões.
- Busca: lista com dados e sinopse, 300 ms e skeleton já atendem. Foco visível é removido em `src/telas/busca.css:27`; nomes/origem longos precisam quebra segura e ações a 360 px. Falta orientação inicial sem Seerr (`src/telas/Busca.tsx:105`).

Priorização: paleta e hero; cabeçalho/selos de Título; imagens/cartões/fileiras; Biblioteca e Busca. Sem chamadas adicionais ao servidor. Bancada visual e validação por Claude ficam com Jarvis.

## Conferência local da entrega
- Build: `cd apps/web && npm run build`.
- Contratos e selos: `node --test testes/*.test.ts` (47 casos).
- Bancada opcional: inicie `npx --no-install vite preview --host 127.0.0.1 --port 18107 --strictPort`.
  Em outro terminal, use `PLAYWRIGHT_MODULE=/caminho/playwright-core/index.mjs CHROMIUM_PATH=/caminho/chromium node testes/visual-browser.mjs`.
  É possível ajustar `VISUAL_URL` e `VISUAL_OUT`. O Playwright é fornecido pela bancada, sem dependência nova no projeto.
- A bancada usa somente fixtures, bloqueia rede externa e grava capturas + resultado.json em /tmp/jocasta-visual.
- Dados reais, Chrome 88, Safari e TV física ficam para a bancada/revisão do Jarvis. Não houve publicação.
- Commits locais impedidos por .git somente para leitura; patches numerados e instruções no handoff JOCASTA_VISUAL_FEITO.md.
