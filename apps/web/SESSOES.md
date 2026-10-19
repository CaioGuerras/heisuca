# Heisuca Web v2 — manual das sessões (leia inteiro antes de começar)

Dono e decisor: **Caio Guerras**. A sessão principal do Claude (na Whatbox) desenha, revisa e junta tudo. Você é uma das
sessões na nuvem que constroem uma parte. Tudo em **português do Brasil** (interface, comentários, commits, relatório).

## 1. O que é e o que NÃO é
- O Heisuca é uma **suíte de players** com marca própria (japonesa, minimalista, de luxo). Este é o **site**: o cartão de
  visitas. O servidor CGSERVER é só um servidor Jellyfin entre outros; **nada de "CGFLIX" na interface** (o nome do servidor
  aparece só onde o próprio servidor o informa).
- **Leia `apps/web/plano/PLANO.md` inteiro.** Cada regra tem a origem (print em `plano/ref/` ou fala do Caio). A referência
  visual principal é o **VidHub** (`plano/ref/vidhub/`); busca e menu do usuário vêm do **CGFLIX completo** (`plano/ref/app_completo/`).
  O que foi reprovado está em `plano/ref/heisuca_reprovado/`: **não repita aquilo**.
- **Não invente.** Dado que o servidor não tem não aparece (nada de "HEVC / H.264" fixo, nada de "pular 85 s"). Função que
  ainda não existe fica "Em breve". Se o PLANO não decide algo, escolha o mais simples e anote como **[C] pergunta para o Caio**
  no seu relatório.

## 2. Preparar (5 min)
```bash
cd apps/web && npm ci
git fetch origin falso-dados && git archive origin/falso-dados | tar -x -C "$(git rev-parse --show-toplevel)"   # dados do servidor falso + prints de referência
python3 testes/falso/servidor.py 8097 &      # Jellyfin falso com dados reais gravados do CGSERVER (qualquer usuário; senha "errada" dá 401)
npm run dev -- --host 127.0.0.1 &           # site em http://127.0.0.1:5173
```
No site: endereço `http://127.0.0.1:8097`, usuário `caioguerras`, senha vazia. Para pular a abertura nos testes:
`sessionStorage.setItem('heisuca.abriu','1')`. Tema: `localStorage.setItem('heisuca.tema','verde'|'roxo'|'auto')`.
O vídeo de teste (90 s) tem capítulos Prólogo 0 s · Abertura 8 s · Episódio 38 s · Créditos 80 s, dois áudios e legendas VTT e ASS.

## 3. Conferir com os olhos (obrigatório)
```bash
pip install playwright pillow
python3 testes/prints_falso.py --site http://127.0.0.1:5173 --rotas "#/,#/fav" --saida testes/comparacoes/<sessao> \
  --chromium "$(ls -d /opt/pw-browsers/chromium-*/chrome-linux/chrome | head -1)"
python3 testes/lado_a_lado.py testes/comparacoes/<sessao>/cmp_x.png <seu_print.png> plano/ref/vidhub/<ref>.jpg --rotulos "Heisuca,VidHub"
```
**Abra a comparação e olhe.** Uma tela só está pronta quando (PLANO §15):
1. o lado a lado com a referência não tem diferença de estrutura (posição, proporção, ordem) e tem as mudanças do Caio;
2. não há erro no console; contraste AA (a paleta do pôster já garante o texto; confira o que você criar); teclado funciona no computador;
3. só dado real; 4. Roxo (escuro) e Verde (claro) bonitos; celular (412 px) e computador (1440 px) bonitos.
Os testes antigos do Gemini davam "100% OK" contando elementos e a tela estava feia: **contar elemento não é aprovação.**

## 4. O que já existe (fundação; não quebre as interfaces)
- `src/api/jellyfin.ts` (cliente da API; use as funções de lá), `api/servidor.ts` (entrada, Quick Connect), `api/seerr.ts` (pedidos; `temSeerr`).
- `src/cor/paleta.ts`: **a cor de cada tela sai do pôster** → chame `usePaleta(hashDe(item,'Backdrop'))` na sua tela. `fundoDesfocado(hash)` dá o fundo borrado.
- `src/tema.ts` (Roxo/Verde/Automático). Variáveis da página: `--hs-pagina`, `--hs-superficie`, `--hs-texto`, `--hs-texto-2`, `--hs-linha`,
  `--hs-vidro`, `--hs-realce` (a cor do tema). Medidas: `--hs-margem`, `--hs-vao`, `--hs-cartao-poster`, `--hs-cartao-paisagem` (`src/estilo/base.css`).
- Componentes: `comp/Cartoes.tsx` (Poster 2:3, Paisagem 16:9, Biblioteca, Top10, EmBreve), `comp/Fileira.tsx`, `comp/Folha.tsx`
  (janela contida: "folha" de baixo no celular / caixa no computador; "balao" que nasce de um elemento), `comp/MenuContexto.tsx`
  (botão direito / segurar), `comp/Navegacao.tsx` (Topo flutuante e Ilha), `comp/Imagem.tsx`, `comp/Icone.tsx` (Material Symbols
  Rounded 300; ícone novo = acrescentar no glob), `comp/Aviso.tsx` (`avisar('texto')`), `estado/usuario.ts` (visto/favorito em todas as telas).
- `src/app.tsx`: a casca e as rotas (`src/rota.ts`). Telas ainda não feitas aparecem como `EmConstrucao`: troque a linha da sua.
- Pode **acrescentar** CSS/props aos componentes comuns se precisar, sem mudar o que já existe; diga no relatório o que mexeu.

## 5. Divisão (cada sessão mexe só nos seus arquivos)
| Sessão | Ramo | Telas e arquivos |
|---|---|---|
| A | `site-v2-a-entrada` | Abertura → voo da logo → entrada única → 2ª animação (3–5 s) → home. `telas/Abertura.tsx`, `Entrada.tsx`, `Transicao.tsx` (+ css), `comp/Logo.*`, `anim/*`. **Entregar vídeos MP4** das animações (Playwright `record_video_dir`) para o Caio aprovar |
| B | `site-v2-b-inicio` | Início e Favoritos (PLANO §4 e §7). `telas/Inicio.tsx`, `inicio.css`, `telas/Favoritos.tsx` (+ css), `dados/inicio.ts` |
| C | `site-v2-c-titulo` | Título e Biblioteca (PLANO §5 e §6). `telas/Titulo.tsx`, `telas/Biblioteca.tsx` (+ css) |
| D | `site-v2-d-paginas` | Busca, menu do usuário, Minha conta, Como usar, Baixar os apps, Sobre, Meus pedidos, Apoiar (PLANO §8–§12). `telas/Busca.tsx`, `telas/Paginas.tsx` (+ css), `comp/MenuUsuario.*` |
| E | `site-v2-e-player` | Interface do player (PLANO §13): controles, painel de áudio/legendas com ✕, **Buscar legendas** (`buscarLegendas`/`baixarLegenda`, `pob` antes de `por`), **Pular abertura/créditos pelos capítulos**, carregamento com a nossa animação, atalhos de teclado. `telas/Player.tsx`, `player.css`, `player/*`. O motor (perfil do aparelho, HLS, JASSUB, guarda "sem quadro") **fica como está**: a sessão principal cuida dele com o servidor de verdade |

## 6. Entrega
- Trabalhe no seu ramo (a partir de `site-v2`), commits pequenos em PT-BR, `git push -u origin <seu-ramo>`. **Não junte no `site-v2`**
  e **não publique** (a publicação de teste é na VPS, pela sessão principal).
- `npx tsc -b` e `npm run build` sem erro. Bundle principal ≤ 70 KB gzip (veja a saída do build); coisa pesada carrega sob demanda.
- Ao terminar, crie `relatorios/<sessao>.md` (no seu ramo) com: o que fez; as comparações (`testes/comparacoes/<sessao>/*.png`,
  em JPEG ~1600 px de largura, ≤ 600 KB cada); o que difere da referência e por quê; dúvidas **[C]** para o Caio; o que mexeu fora dos seus arquivos.
- Seja honesto no relatório: o que não ficou bom, diga. A sessão principal vai conferir cada print.
