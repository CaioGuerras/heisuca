# Handoff para o Codex — rodada de 25/10/2026

Ramo único `codex/heisuca-home-site`. Regras de trabalho em `AGENTS.md`; filosofia em `docs/PILARES_HEISUCA.md`
(**leia antes**); análise de cada ponto em `docs/RETORNO_CAIO_2026-10-25.md` (tabela 1–16); guia do Google em
`docs/GUIA_ANDROID_GOOGLE.md`. Itens antigos ainda abertos estão em `docs/HANDOFF_GPT_2026-10-24.md`.

**Sem remendos:** cada correção vai na causa. Se o jeito certo exigir mexer em código herdado do Plezy, mexa: o fork é
independente. Um item por APK, na ordem abaixo (versão seguinte: 2.0.18+19), Actions verde antes do próximo, registro em
`docs/HANDOFF_GPT_ENTREGA_2026-10-24.md`.

## A. Acabamento da marca e da ficha (retorno 1, 3, 12, 13, 16)
- **Marca em SVG:** a abertura (`heisuca_opening_splash.dart`) usa o mesmo SVG da Início (`assets/heisuca/marca_site_*.svg`,
  pelo `HeisucaLogo`), nunca "HEISUCA" digitado. Declarar a fonte **Sora** (`assets/fonts/Sora-VF.ttf`) no `pubspec.yaml`,
  com a licença OFL ao lado, porque `HeisucaTheme.fonteTitulo` a usa e hoje cai na fonte do aparelho.
- **Brilho da abertura** menor; slogan com contraste AA sobre o fundo.
- **Listra abaixo do pôster: sai da etapa A e vira a etapa A2** (abaixo). Não bloqueia os outros itens da A.
- **Favoritos da Biblioteca** sem ícone (os vizinhos não têm).
- **Encaixe do título na ficha:** o logo/título da ficha encaixa no topo entre a marca e a busca, igual à Início
  (`heisuca_home_chrome.dart`). Um componente só para as duas telas, não duas cópias.

## A2. Listra abaixo do pôster (retorno 13) — reproduzir antes de corrigir
- O diagnóstico antigo (degradê dentro do `Transform`) estava errado; o Codex mostrou isso em `6e0b055`. Obrigado.
- **Evidência:** `docs/evidencias/listra_ficha_rolada_2026-10-25.png` e `..._zoom4x.png` (print do Caio, Edge 60 Pro,
  1220×2712 px). A listra é **uma única fileira de pixels físicos** com as cores da própria arte, na borda inferior da
  área da imagem, só com a tela rolada; acima e abaixo o fundo é uniforme. Ocorre na ficha e na Início.
- **Hipótese a confirmar:** borda subpixel. Com a rolagem parada em fração de pixel, a última fileira da camada da arte
  (`ShaderMask → HeisucaParallax(ClipRect → Transform) → imagem`) é rasterizada fora da cobertura da máscara.
- **Fazer:** um teste de widget/golden com o DPR do aparelho (~2,97) que rola a ficha e a Início para posições
  fracionárias e confere, pixel a pixel, a fileira da borda inferior da área da arte. Com o teste falhando, achar a camada
  responsável e corrigir na causa (ex.: alinhar a borda ao pixel físico, recortar depois de mascarar, ou garantir que a
  máscara cubra a borda), mantendo o recorte aprovado da Início. O teste fica no repositório para não voltar.

## B. Item 5 do handoff antigo + independência, parte 1
- Fazer o item 5 como decidido (sem chamadas ao Plezy), **removendo o Discord RPC inteiro** (serviço, ajustes, ganchos no
  player e no `main.dart`): não usamos Discord; nosso canal é o Telegram.
- Remover recursos herdados sem uso (listar no registro o que saiu e por quê).

## C. Item 9 — Início igual nas duas fontes (decidido)
Ver item 9 em `docs/HANDOFF_GPT_2026-10-24.md`. **Contrato de dados definido em 25/10 (resposta a
`docs/BLOQUEIO_ETAPA_C_2026-10-25.md`; opção 1, com vínculo declarado pelo servidor):**
- Em alta e Em breve no Plex **dependem de uma conexão Jellyfin já salva no perfil** que publique os feeds
  (`/cgflix/emalta.json` e `/cgflix/embreve.json` no endereço desse Jellyfin; o calendário vem das seções HomeScreen dessa
  mesma sessão, como hoje). Nada de URL, token ou ID fixo no app.
- **Vínculo Plex ↔ Jellyfin declarado pelo servidor:** os dois feeds agora trazem `"plex": ["<machineIdentifier>"]` (hoje
  `056b61fd…dbbba`). O Plex ativo recebe as duas fileiras só se o `machineIdentifier` dele estiver nessa lista de algum
  Jellyfin conectado no perfil. Assim funciona para qualquer administrador, sem regra fixa do CGSERVER.
- **Casamento por ID:** `emalta.json` → cada item tem `tmdb` e, quando há, `tvdb` (além de `id` do Jellyfin);
  `embreve.json` → `s` (séries) com `tmdb` e `tvdb`, `m` (filmes) com `tmdb`. No Plex, usar `PlexClient.findByExternalIds`;
  item sem correspondência no Plex: Em alta pula; Em breve segue o fluxo atual (busca de pedidos).
- Jellyfin vinculado desconectado, fora do ar, ou feed sem `plex`/sem o ID: as duas fileiras não aparecem no Plex (sem
  erro, sem aviso). Início do Jellyfin inalterada.
- Formato conferido pela URL pública em 25/10 05:22 (emalta: 10/10 com tmdb; embreve: 12/12 séries com tvdb).

## D. Item 8 — logo pelo app quando o servidor não tem (decidido)
Ver item 8 em `docs/HANDOFF_GPT_2026-10-24.md`.

## E. Fontes: área de servidores e origem na busca (retorno 4, 14)
- Redesenhar no padrão Heisuca "Adicionar a …", "Escolha uma fonte" e a linha da fonte no menu Você: ícone próprio de
  fonte (não o genérico de servidor), nome do servidor, tipo discreto (Jellyfin/Plex) e **bolinha de status** no lugar
  da palavra: verde on-line, âmbar conectando, cinza fora do ar, vermelho erro (com rótulo para o TalkBack).
- **Busca:** cada resultado mostra de onde vem (nome curto da fonte; "2 fontes" quando existe em mais de uma). Mantém a
  busca unificada.

## F. Movimento e navegação do jeito do Android (retorno 15)
- Abas da pílula: **fade through** (sem direção), nunca corte seco.
- Telas empurradas: transição e **voltar preditivo** como o Google recomenda. **Regressão:** o voltar preditivo foi feito
  na 1.6.1 (`lib/cgflix/cgflix_theme.dart`, auditoria 1D) e o movimento do item 4 passou por cima; restaurar e unificar usando a transição **oficial** do Flutter (`PredictiveBackPageTransitionsBuilder`, padrão do Flutter 3.47) no lugar da versão feita à mão (`_CgflixPredictiveBack`), e fazer as telas Heisuca usarem o tema em vez de rotas próprias (Flutter: `PredictiveBackPageTransitionsBuilder`,
  `android:enableOnBackInvokedCallback="true"`), seguindo o gesto pela borda de onde o dedo veio. Sheets com o padrão
  Material 3. Conferir edge-to-edge e insets. Fonte: `docs/GUIA_ANDROID_GOOGLE.md`.

## G. Modo infantil (retorno 6, 7, 8)
- Campo "Nome da criança" com contraste e rótulo visíveis nos temas claros.
- Foto escolhida aparece em círculo na criação (e na edição).
- Foto da criança na animação de abertura do modo infantil (imagem local; sem custo de rede).
- O tema infantil escuro fica para depois (retorno 5).

## H. Medidor dentro do popup (retorno 9)
- O medidor de 3 faixas vai **dentro do popup "Funções e desempenho"** (Configurações › Aparelho reconhecido › Ver funções
  ativas), estilizado no padrão Heisuca, com texto simples (sem "orçamento", "pressão de memória"; detalhe técnico
  recolhido). Apagar a tela "Este aparelho" e o item no menu Você.

## I. Dicas reescritas (retorno 10)
- Caminhos atuais (pílula: Início, Biblioteca, Baixados, Você; Você › Conta › Minha conta), Plex (plex.tv/link) além do
  Quick Connect, **uma** dica de TV: apps nossos (Samsung, LG), Fire TV, Google TV/Android TV, Roku, Apple TV e espelhar a
  tela. Sem "TV box". Mantém os ícones Material Symbols (padrão do Android).

## J. Itens 7 e 10 do handoff antigo
- Item 7 (os 16 testes que já falhavam) e item 10 (ícone variante 1 aplicado).

## K. Bancada Android no CI
- Job no Actions com emulador Android rodando `integration_test` sobre o app: abertura, login, Início, ficha, busca, player
  (vídeo curto), troca de abas, voltar; salva **capturas e vídeo da tela** como artifact. Não bloqueia o APK quando o
  emulador falhar por infraestrutura (marca como instável, não como verde).
- **Login de teste com rodízio** (autorizado pelo Caio, segredos já criados em 25/10): `HEISUCA_TESTE_SERVIDOR` (URL do
  Jellyfin) e `HEISUCA_TESTE_CONTAS` (um **nome de usuário** por linha; **todas entram com senha vazia**). A primeira é a
  conta de teste `teste-sem-senha`; as demais são contas da família sem senha. O teste entra com a primeira conta que
  **não tem sessão tocando** no servidor (consulta as sessões com o próprio token), para não disputar o limite de 2 telas.
  Em conta da família, ao terminar, **apaga o progresso e o "assistido" que o próprio teste criou** (o "Continuar" da
  pessoa fica como estava). Nunca imprimir os nomes nos logs; nunca usar contas `-kids`.

## L. Independência, parte 2
- Renomear o pacote Android `com.edde746.plezy` e os canais `com.plezy/*` para `app.heisuca` (sem mudar o
  `applicationId`, para não perder a atualização por cima); tirar "Plezy" de nomes e textos; trocar o texto de crédito
  do Sobre por uma página padrão de licenças (GPL-3.0 e aviso do Plezy, obrigatório). Registrar no `CLAUDE.md`.

## M. Esboço 04C — mídia fora do app (depois do guia do Google)
Ver `docs/ESBOCOS_PENDENTES_2026-10-25.md`: MediaSession e notificação MediaStyle para o vídeo, controles na tela de
bloqueio (controles de mídia do sistema), notificação de progresso dos downloads, PiP com transição suave e legendas
estilizadas. **Sem "ilha"/Live Updates**: o Google não permite para mídia nem download (ver guia).
**Decidido (Caio, 25/10):** opção "Continuar ouvindo ao sair", desligada por padrão; padrão ao sair = PiP. Ligada: só o
som, com serviço em primeiro plano `mediaPlayback` (Android 17 exige app visível ou serviço em primeiro plano para tocar
áudio). Pode ser feita depois da L.

## Depois (não agora)
- Varredura do app inteiro contra `docs/GUIA_ANDROID_GOOGLE.md`, com lista de falhas e correções.
- Tema infantil escuro.
