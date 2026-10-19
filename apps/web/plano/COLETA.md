# Heisuca Web — coleta para o planejamento (19/10/2026)

> **Superado pelo `PLANO.md` (19/10, tarde).** Este arquivo fica como registro da coleta.

Fase de coleta: **nenhum código ainda**. Fonte: conversa com o geMinionsbot (18/10 19:05 → 19/10 06:27),
39 prints do Telegram + 4 prints de 19/10 07:44–07:52, conversa com o Claude em 19/10.
Prints organizados em `ref/` (vidhub, app_completo, site_atual, streamyfin, heisuca_reprovado).

## 1. Princípios (Caio)
- O produto é a **suíte de players Heisuca**; o CGSERVER é só um servidor (amigos e conhecidos).
  O site mora no docaio **temporariamente** (domínio próprio virá). Nada de CGSERVER pré-preenchido.
- O site é o **cartão de visitas**: bonito, responsivo, minimalista, requinte refinado. Não é o melhor
  player; ajustes profundos ficam nos apps nativos.
- Algo **nosso**: telas próprias; inspiração e trechos de outros players são bem-vindos. Nem fork, nem
  "parecer mais um fork do Jellyfin". Moonfin web funciona, mas é pesado e feio.
- Referência principal: **VidHub**. Outras ideias valem se melhorarem.
- **Temas são detalhe delicado, não cara imutável**: a cor da tela sai do pôster; o tema (roxo/verde/auto)
  entra como toque. Roxo e Verde no site/Android; Vermelho/Azul só Modo Kids; Dourado só iOS.

## 2. Servidores
- **Só Jellyfin.** "Trocar servidor" discreto (pílula do servidor no topo da home, à esquerda).
- Fora do site: Plex, WebDAV, SMB (SMB impossível no navegador; WebDAV entrega MKV cru; Plex = 2º sistema).

## 3. Entrada (ref/streamyfin + falas do Caio)
1. **Servidor**: só a nossa logo, caixa "Digite o endereço do servidor", botão Conectar.
   Sem "custom headers", sem "procurar servidores locais".
2. **Login**: topo com ← voltar (esq.) e ícone Quick Connect (dir.). Título "Iniciar sessão em <ServerName>"
   (nome vindo do servidor). Sem o nome repetido no topo e sem a URL. Usuário + senha (senha pode ser vazia).
   Botão Iniciar sessão. Sem "Guardar esta conta" (sessão salva por padrão).
3. **Animação**: fluida, 3–5 s, enquanto a home carrega (destaque + primeiras fileiras); nunca abre pela metade.
   Hoje: `comp/Abertura.tsx` + `marca/abertura.css` — carimbo de 2,3 s, uma vez por sessão, ANTES do login,
   pula com qualquer toque.
   **Decidido (Caio, 19/10):** as duas existem e se ligam pela logo. Abertura curta ao entrar no site →
   a logo **viaja até o lugar dela na tela de entrada** → depois de Iniciar sessão a logo **cresce e ocupa
   a tela** e começa a 2ª animação (pode ser a inversa da 1ª ou outra), 3–5 s, até a home estar pronta.

## 4. Home (ref/vidhub: home_topo, home_rolada, foto67)
- **Cor da página tirada do pôster do destaque** (InuYasha = azul-acinzentado; Terra da Máfia = cinza),
  com toque do tema. A arte do hero vai até o topo e se dissolve no fundo, sem faixa separando.
- Topo flutuante, sem barra: esq. pílula [foto + nome do servidor] → trocar servidor; dir. busca (com Seerr).
  **Sem 3 pontinhos.** Nada de barra semi-transparente de ponta a ponta.
- Hero: logo do título centralizada; linha `★ 8,6 | 2000–2010 | gêneros | [BR-12]`; sinopse 2 linhas
  `「Título」 texto`; pontinhos do carrossel; troca automática.
- **Ao rolar, a logo sobe e encaixa no topo** entre a pílula e a busca (home_rolada).
- Fileiras: **Continuar** (16:9, ▶ no centro, `26:44 / 40:39`, barra de progresso, título + `S1:E1 - nome`),
  **Próximo**, **Mídia** (bibliotecas como cartões 16:9 com o nome por cima — é aqui que as bibliotecas
  ficam, não em chips abaixo do hero), uma fileira por biblioteca com "Ver tudo ›"
  (pôster 2:3, nota no canto inferior direito, título + anos).
- Ilha inferior flutuante de vidro (no VidHub é clara): **Início · Biblioteca · Favoritos · Usuário (foto)**.
- Botão direito no cartão (toque longo no celular): Marcar visto · Favoritar.

## 5. Tela do título (ref/vidhub foto42–44)
- Arte até o topo, dissolvendo na cor tirada do pôster. ← voltar no topo. **Sem ⋯ no topo** (o menu
  Download/Marcar visto sai): ações viram **♡ e ⚑ abaixo do Reproduzir**.
- Logo centralizada; linha `★ 7,1 | 20/03/2004 | HBO | gêneros | [BR-18]`; sub-linha pequena
  `3 temps. · 1h2min · 1080p H264 SDR`.
- **Reproduzir** largo em pílula translúcida. Ao rolar, ele **gruda no topo** com a sub-linha (foto43).
- Sinopse pequena do episódio da vez: `「Deadwood·Temp. 1·EP 1」 …`.
- `Temporada 1 ⌄` (à esq.) + `Ver tudo ›` (à dir.); fileira de episódios 16:9, atual com borda, `1. Título`
  embaixo; páginas `1-10` `11-12` em pílulas.
  O seletor de temporada abre **contido** (folha/popover), nunca empurra nem cobre a página (erro foto72).
- **Elenco**: fotos em **quadrado arredondado** (não círculo), nome + personagem. Sem letra por cima (erro foto71).
- Gêneros em pílulas.
- Info mídia: VidHub mostra 2 cartões (Vídeo/Áudio) com tabela completa + cartão com o caminho do arquivo.
  **Decidido:** tabela refinada (como o VidHub, com acabamento nosso), **sem o caminho do arquivo**.
  **Nunca inventar dado**: o Gemini escrevia "HEVC / H.264" e "AAC / EAC3" quando faltava (`Titulo.tsx:339,364`).
- Sinopse veio em inglês no HSOTD (foto70): conferir idioma dos metadados.

## 6. Biblioteca (ref/vidhub foto50–51)
- Topo: ← | nome da biblioteca centralizado | ícone à direita → **menu lateral direito com as bibliotecas**.
- **Somem** as abas Séries / Episódios / Gêneros / Pastas.
- Grade 3 colunas (celular), pôster 2:3, nota no canto inferior direito, ✓ visto no canto superior direito,
  título + anos.
- Botão direito: Marcar visto · Favoritar (o "Excluir" do VidHub não entra). **Sem ordenar e sem filtrar** (decidido).

## 7. Player (ref/vidhub foto44–49; ref/app_completo foto24–25)
- Carregamento: a nossa animação (no lugar dos pontinhos "Carregando").
- **Removidos**: girar, trava, ícones de capítulos e episódios, menu avançado (⋮), transmitir, captura,
  velocidade, gestos de brilho/volume.
- **Ficam**: ← + título `Deadwood S1E1`; anterior / −10 / play / +10 / próximo; barra fina; legendas;
  tela cheia; **Pular abertura e créditos**. **Sem PiP** (decidido).
- Áudio e legendas: painel organizado com ✕ (o do app completo, foto25, foi elogiado); nunca fica preso
  sobre o vídeo. Legendas com **"Buscar legendas…"** (pedido do Caio: o plugin Open Subtitles,
  já instalado, tem de funcionar fácil). **Sem "Carregar local"** (decidido).
- Ao sair do player, o vídeo para de verdade (bug do áudio tocando na home, foto18).
- Sem selo "pelo servidor"; tela cheia sem tela preta (foto19/20).

### Pular abertura — dado medido em 19/10 (API do Jellyfin 10.11.11, só leitura)
Sem plugin Intro Skipper: **MediaSegments vazios** em todos. Mas **os capítulos dos arquivos já trazem a abertura**:
| Episódio | Capítulos |
|---|---|
| Deadwood T1E1 | Studio Logo 0 · Studio Logo 6 · **Opening Credits 12** · próximo 104 |
| Aoashi T1E2 | Prologue 0 · **Opening 22** · Episode 113 (T1E1 não tem capítulo de abertura) |
| HSOTD T1E1 | Prologue 0 · **OP 123** · Part A 213 · Part B 616 · **ED 1188** · Epilogue 1279 · Preview 1406 |
| One Piece T1E1 | Part 01 0 · **Intro 46** · Part 02 124 · **Credits 1375** |
| InuYasha T1E1/E2 | sem capítulos |
- O "Pular início" do VidHub no Deadwood (00:35, foto48) bate com o capítulo "Opening Credits" 12→104.
- Regra: casar nomes (Opening, Opening Credits, OP, Intro, Abertura → abertura; ED, Ending, Credits,
  Créditos → créditos; Preview → prévia) e pular para o início do capítulo seguinte. Sem capítulo, sem botão.
- Cobertura do acervo inteiro: medir depois (leitura de API, sem tocar no Drive). Intro Skipper só com
  medição de custo e OK do Caio (lê o áudio do acervo no Drive).

## 8. Usuário / ajustes (falas 22:24; ref/vidhub foto52)
Menu curto que abre **a partir do avatar** (não de baixo para cima): Como usar (checkboxes; some do topo
quando tudo marcado) · Perfil (foto e senha) · Temas (Roxo, Verde, Automático) · Sobre · Baixar os apps ·
Apoiar o Heisuca · Sair.

## 9. Processo (lições de 18–19/10)
- Toda tela é comparada **lado a lado com o print de referência**, no mesmo tamanho, antes de ir ao Caio.
- Testes que só contam elementos (o "100% OK" do Gemini) não valem como aprovação visual.
- Dados reais ou nada. Valores fixos ("85 s") são proibidos.

## 10. Pendências de coleta
- [ ] Prints restantes que o Caio vai mandar.
- [ ] A home do VidHub de 18/10 22:17 (vídeo > 20 MB) — substituída pelos prints de 07:44.
- [x] Decidido 19/10: abertura dupla ligada pela logo; tabela técnica sem caminho; sem ordenar/filtrar; sem PiP; sem legenda local.
- [ ] Medir a cobertura de capítulos de abertura no acervo.
