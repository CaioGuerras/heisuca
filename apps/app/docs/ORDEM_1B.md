# Ordem de serviço: Etapa 1B (redesenho) — 07/10/2026

Arquivo de referência para as rotinas da nuvem (o prompt aponta para cá). Ramo `cgflix/etapa-1b`, PR #3 (rascunho).

## Andamento
- Feito e enviado: versão própria `1.0.0+200` e "CGFLIX 1.0.0" no Sobre (`3b8ec83`).
- Uma tentativa anterior escreveu (e perdeu, sem push) navegação, dados da Início com cache, cartões/Top 10/esqueletos, prévia
  e destaque. Desenho que ela seguiu e que pode ser reaproveitado: `lib/cgflix/cgflix_style.dart` (cores, curvas, durações),
  `lib/cgflix/cgflix_you_screen.dart` (aba Você), `lib/cgflix/home/` com `cgflix_home_logic.dart` (regras testáveis: ordem das
  linhas, emalta.json, chips), `cgflix_home_repository.dart` (cache por servidor/usuário na pasta de suporte, rede depois),
  `cgflix_jellyfin_queries.dart` (`part of` do `jellyfin_client.dart`, gancho de 1 linha), `cgflix_actions.dart`,
  `cgflix_cards.dart`, `cgflix_preview_sheet.dart`, `cgflix_hero.dart`; ganchos em `navigation_tabs.dart` e `main_screen.dart`.


## Contexto
- Público: amigos e família do dono, no Brasil, celular Android (motorola edge 70 é a referência). O servidor é Jellyfin (principal) em https://netflix.docaio.com.br (o app NÃO vem com servidor pré-preenchido; isso continua assim) e Plex como opção.
- Filosofia omakase: pronto do jeito que o dono usaria; poucas escolhas na cara; o avançado fica escondido (já feito na 1A em Configurações). Código novo em `lib/cgflix/`, tudo listado no `CGFLIX.md`; diff mínimo no código do upstream.
- O dono já testou a 1A ("mais responsivo") e quer agora **tirar de vez a cara de Plezy/Jellyfin** e chegar à experiência de streaming de primeira linha: navegação enxuta e rápida da Netflix + tela "só o nosso acervo" do Infuse/Wholphin + identidade roxa do CGFLIX. Ele nota "cortes brutos": tudo precisa de transições suaves (~250–350 ms, curvas ease-out), sem piscar nem pular.
- Identidade: fundo preto OLED `#07060a`, roxo `#a855f7` (destaque) e `#9333ea` (pressionado), verde `#22c55e` só na dedicatória; emblema "C com play" e marca já estão em `cgflix-brand/`.

## O que fazer
### A. Navegação
- Barra inferior com 4 destinos: **Início · Buscar · Baixados · Você** (Você = trocar usuário/perfil, Configurações, Sobre). Nada além do avatar no topo da Início.
- Chips no topo da Início: **Filmes · Séries · Animes** (abrem as bibliotecas do servidor; Animes = biblioteca de séries com nome "Animes"; se não existir, o chip some).
- Android TV continua funcionando, mas SEM destaque nesta etapa (não gaste tempo com TV).

### B. Início ("só o nosso acervo"), nesta ordem
1. **Destaque** no topo: fundo (backdrop) + logo do título + "Assistir" e "Detalhes", trocando a cada ~8 s com transição cruzada suave; SEM vídeo automático.
2. **Continuar assistindo** (barra de progresso; segurar = remover da linha).
3. **Em alta no Brasil** em estilo Top 10 (número grande vazado ao lado do pôster). Fonte: `GET <endereço do servidor>/cgflix/emalta.json` → `{"titulo","itens":[{"id","nome","tipo"}]}` (ids do Jellyfin, já ordenados); se falhar, a coleção do Jellyfin chamada "Em alta no Brasil"; se nenhum, a linha some. Cache de 1 h.
4. **Lançamentos** (filmes por data de lançamento), **Novos episódios**, **Novidades em filmes**, **Novidades em séries e animes** (os mesmos nomes do site).
5. Linhas por gênero (os gêneros já vêm em português do servidor).
- Esqueletos (shimmer discreto) no lugar de círculos de carregamento; as linhas carregam independentes; voltar mantém a rolagem; puxar para atualizar.

### C. Cartões e página do título
- Ao tocar e segurar um cartão (ou ao tocar, num painel inferior), uma **prévia** como no site: fundo, logo, ano · classificação · duração/temporadas · ★ nota, gêneros, sinopse curta, botões **Assistir / Minha lista / Detalhes**. Filme/episódio: "Assistir" toca DIRETO; série: "Ver episódios" abre a página.
- Página do título: fundo + logo no topo com gradiente, botão principal grande roxo (**Assistir** / **Continuar S02E05**), secundários (Trailer, Minha lista, Baixar). Linha curta de metadados + selos **Dublado** (áudio `por`) e **Legendado** (legenda `por`/`pob`). Séries: temporadas em chips, episódios com miniatura, número, título, duração e sinopse de 2 linhas, o próximo já selecionado. "Mais como este" no fim. Gêneros/estúdio alinhados ao rótulo (não esticados).
- Transição de elemento compartilhado pôster → página do título.

### D. Abertura animada (logo)
- Abertura no estilo Netflix com o emblema CGFLIX: ~1,2–1,6 s (por exemplo: o "C" desenha/expande com um brilho roxo que varre e o play aparece), depois transição suave para a Início. Usar a Splash Screen API do Android (ícone animado) + uma tela de intro em Flutter.
- **Som opcional**: um "tum" curto e elegante (gerado/procedural ou um arquivo pequeno livre de direitos, licença compatível com GPL-3.0, < 50 KB), tocado só se o aparelho não estiver no silencioso/vibrar; chave "Som da abertura" em Configurações (padrão: ligado). Pular a animação em aberturas seguidas (< 30 s).

### E. Player
- Áudio e legenda num menu em sobreposição discreta, sem pausar (estilo Netflix); a barra some em 3 s; "próximo episódio" só nos créditos de verdade (sem cortar o final).
- Modo imersivo (barras do sistema escondidas), respeitar recortes de câmera.
- Não trocar o motor (mpv) nem os padrões de reprodução direta da 1A.

### F. Android de verdade (developer.android.com/design)
- Edge-to-edge: barras de status e navegação transparentes, `WindowInsets`, gradiente atrás de títulos; nunca barras opacas.
- Gesto de voltar preditivo; controles de mídia na notificação/tela de bloqueio (MediaSession) e imagem flutuante (PiP) no player.
- Layout adaptável (horizontal/tablet).

### G. Numeração própria e Play
- Versão do app: `1.0.0` com versionCode **200** (a Play já tem o 152 da 1A; o código precisa ser MAIOR). Em `pubspec.yaml`: `version: 1.0.0+200`. Mostrar "CGFLIX 1.0.0" no Sobre.
- O workflow `CGFLIX Android` já gera APK (por ABI) e AAB assinados com a chave do CGFLIX (secrets ANDROID_*). Manter.

## Qualidade
- `flutter analyze` sem erros novos; testes que já passavam continuam passando; adicione testes para a lógica nova (emalta.json, chips, ordem das linhas, versão).
- Desempenho: Início utilizável < 2 s com cache no aparelho de referência; imagens pedidas no tamanho de exibição (`maxWidth`/`fillHeight` + `quality` ~80); nenhuma chamada de rede bloqueando a renderização.
- PR com: o que mudou (organizado por tela), prints se conseguir gerar (ex.: golden tests ou capturas do emulador), riscos, como testar, e o que ficou de fora.
