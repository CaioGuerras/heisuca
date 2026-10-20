# CGFLIX: Etapa 1E (busca com pedidos embutidos + categorias certas + limpeza) — 07/10/2026

Referência para as rotinas. Resumo da ordem de serviço (a partir do 1.2.0 (400), PR #5):

- **A. Uma busca só, com pedidos embutidos (Seerr)**: sai o ícone "Pedir" da barra (fica emblema · Filmes · Séries ·
  Animes · Busca). A busca mostra primeiro o que já temos e, abaixo, "Disponível para pedir" (Seerr
  `GET /api/v1/search`, `mediaInfo.status` ausente/1 = pedir; 2/3 = selo "Pedido"/"Baixando"; 4/5 não repete). Pedir:
  filme direto, série com escolha de temporadas (padrão: todas). Entrada automática no Seerr por Quick Connect
  (initiate → Authorize no Jellyfin com o token da pessoa → authenticate → cookie `connect.sid` no armazenamento
  seguro, renovado em 401/403). Sem Seerr: aviso pequeno "Pedidos indisponíveis agora", nunca formulário de login.
  "Meus pedidos" no menu do usuário (tela nativa).
- **B. Categorias certas**: Filmes/Séries/Animes por biblioteca (`ParentId`), nunca pelo tipo do item. "Em alta no
  Brasil" por categoria via `porBiblioteca` do `emalta.json` (fallback: `itens` filtrados por `biblioteca`; sem nada,
  esconder nas categorias de série/anime). Esconder com menos de 3.
- **C. Início sem "Novos episódios"** (trocar por "Séries com episódio novo" com a capa da série, ou só remover).
- **D. Dedicatória só no Sobre**; sai o interruptor "Mostrar dedicatória" e a preferência.
- **E. Som de abertura em Configurações › Avançado**; `MediaPlayer.create` fora da thread de UI.
- **F. Serviços: só o Trakt**, com credenciais próprias (`--dart-define=TRAKT_CLIENT_ID/TRAKT_CLIENT_SECRET` dos
  secrets `CGFLIX_TRAKT_CLIENT_ID`/`CGFLIX_TRAKT_CLIENT_SECRET`); sem secrets, Trakt escondido. Sem "Plezy" visível.
- **G. Emulador**: barra nova, busca com "Disponível para pedir" (mock), as 3 categorias, menu › Meus pedidos.
- Versão 1.3.0 (500).
