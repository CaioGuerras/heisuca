# Heisuca Web — Especificação de Arquitetura e UI/UX (Novo Site)

> **Data:** 18/10/2026  
> **Status:** Aprovado para implementação  
> **Referências visuais:** VidHub (estética clean/Infuse, tela de título e cards de mídia) + CGFLIX completo / Plezy (hero rotativo, Continuar Assistindo 16:9, Top 10 alinhado).

---

## 1. Filosofia e Papel do Site
- **O Cartão de Visitas do Heisuca:** Minimalismo japonês de luxo (*"Nada entre você e o filme"*). O site deve ser deslumbrante, acolhedor, rápido e limpo.
- **Configurações enxutas:** Não tentar transformar o navegador numa bancada de 50 ajustes técnicos. Opções pesadas de motor de vídeo, decodificação avançada e buffers pertencem exclusivamente aos apps nativos (Android, iOS, Desktop, TVs), que têm acesso direto ao hardware.

---

## 2. Onboarding e Fluxo de Entrada
1. **Tela 1 — Servidor:**
   - Apresentação da marca Heisuca (logo em kanji 炳素華 + tipografia elegante).
   - O nosso servidor (**CGSERVER / Jellyfin**) já vem pré-configurado de fábrica: o usuário só clica em "Conectar".
   - Botão discreto `+ Adicionar outro servidor` abrindo caixa de opções:
     - 1. Jellyfin
     - 2. Plex
     - 3. WebDAV
     - 4. SMB
2. **Tela 2 — Usuário e Perfil:**
   - Grade de perfis do servidor com foto real e nome.
   - Suporte a login em 1 toque sem senha (para perfis livres) ou campo de senha elegante.

---

## 3. Estrutura Global e Navegação
- **Topo Global:**
   - Apenas a marca **HEISUCA** (em tipografia refinada) no canto esquerdo.
   - Sem botão de 3 pontinhos nem avatar misturado no topo.
- **Barra de Navegação Inferior (4 abas fixas):**
   1. **Início:** Ícone Home. Retorna à tela inicial.
   2. **Biblioteca:** Ícone Biblioteca. Abre o acervo com menu lateral à direita para troca direta de biblioteca (Animes, Séries, Filmes, Coleções) e o botão `+` para alternar servidor.
   3. **Favoritos:** Ícone Coração. Títulos favoritos sincronizados com o usuário.
   4. **Usuário:** Foto real do perfil. Abre a gaveta elegante com as configurações essenciais.

---

## 4. Tela Inicial (Home)
- **Hero Cinematográfico:**
  - Carrossel rotativo suave com indicador de slides (dots).
  - Imagem de fundo em alta definição com gradiente inferior escuro.
  - Logo do título em PNG transparente.
  - Linha de metadados fina (ano, classificação indicativa, gêneros).
  - Sinopse limitada a 3 linhas.
  - Dois botões pill: `▶ Assistir` (destaque com cor primária do tema) e `ⓘ Detalhes`.
- **Continuar Assistindo (Horizontal 16:9):**
  - Miniaturas estritamente em **16:9 (horizontal)** com o thumbnail real do episódio/filme (nunca pôster vertical esticado).
  - Botão circular de play centralizado.
  - Barra de progresso fina na cor do tema (roxo ou verde).
  - Título do show e subtítulo claro (`T1:E1 · Nome do Episódio`).
- **Em Alta no Brasil (Top 10):**
  - Pôsteres verticais 2:3.
  - Números 1 a 10 estilizados em outline, posicionados perfeitamente à esquerda de cada pôster e alinhados pela base (padrão CGFLIX completo / foto 21).
- **Fileiras de Conteúdo (Novidades / Bibliotecas):**
  - Pôsteres verticais 2:3 com altura estritamente padronizada.
  - Subtítulos e títulos travados em 1 linha com `white-space: nowrap; overflow: hidden; text-overflow: ellipsis;` para nunca quebrar o alinhamento da grade.
  - Selos discretos nos cartões: `Dublado`, `Legendado`, `4K`.
- **Ações Rápidas no Card:**
  - Botão direito do mouse no desktop (ou toque longo no mobile) abrindo mini-menu flutuante com: `Marcar visto` e `Favoritar`.

---

## 5. Tela de Detalhes do Conteúdo (Filme / Série)
*Inspirada diretamente no VidHub (fotos 42 e 43):*
- **Apresentação Cinematográfica:**
  - Backdrop expandido com gradiente escuro.
  - Botão Voltar `<` no topo esquerdo.
  - Logo grande do título centralizado.
  - Linha de metadados: `★ Nota | Data de lançamento | Classificação (BR-14) | Gêneros`.
  - Sub-linha: `X temps. · Duração · Resolução Codec`.
  - Botão pill de destaque: `▶ Reproduzir` (ou `▶ Assistir T1:E1`).
  - Botões de ação rápida abaixo do play: `♡ Favoritar` e `⚑ Visto/Não visto` (eliminando o menu de 3 pontinhos do topo).
  - Sinopse do show e do episódio atual.
- **Seletor de Temporadas:**
  - **Dropdown único (`Temporada 1 ∨`)**, idêntico à Netflix, Apple TV e VidHub, evitando poluição de dezenas de abas laterais.
  - Ao clicar, abre modal elegante para escolher a temporada.
- **Lista de Episódios:**
  - Fileira horizontal de miniaturas 16:9 arredondadas com borda ativa no episódio selecionado.
  - Número e título embaixo (`1. Primeiro Toque`).
  - Paginação suave para animes longos (`1-10`, `11-20`).
- **Elenco:**
  - Carrossel horizontal de fotos circulares dos atores, com nome real e nome do personagem abaixo.
- **Info Mídia (Cards Técnicos):**
  - Dois cards arredondados lado a lado:
    - **Card de Vídeo:** Título/resolução, codec, perfil, proporção, FPS, bitrate, pixel format.
    - **Card de Áudio:** Faixa de áudio, codec, canais (stereo / 5.1), taxa de amostragem, bitrate.

---

## 6. Player de Vídeo (Minimalista e Estável)
- **Carregamento:** Animação de loading do Heisuca (carimbo kanji 炳素華).
- **Motor Web Estável:**
  - Remux fMP4/HLS padrão no servidor (elimina o bug de tela preta no Chrome Android em tela cheia e dispensa transcode de vídeo).
  - Renderização de legendas ASS via JASSUB no navegador (WebAssembly/Worker).
- **Controles (Apenas o Essencial):**
  - **Topo:** Botão Voltar `<` e Título + Episódio.
  - **Centro:** Play/Pause com animação suave.
  - **Base:** Barra de tempo limpa com indicador decorrido / restante, botão de Áudio/Legendas, Tela Cheia e o botão **Pular abertura / créditos**.
  - **Removidos do VidHub:** Sem botões de trava, rotação, captura de tela, velocidade, capítulos, transmissão/cast ou gestos de volume/brilho nas bordas.
  - **Removido:** Selo confuso "pelo servidor".
- **Menu de Áudio e Legendas:**
  - Modal limpo e centralizado com duas colunas/abas bem divididas (Áudio à esquerda, Legendas à direita).
  - Botão de fechar `[X]` no canto superior e fechamento ao clicar fora ou ao selecionar a faixa (nunca fica travado sobre o vídeo).
- **Ciclo de Vida do Vídeo:**
  - Ao sair da rota do player, o elemento `<video>` é imediatamente pausado (`pause()`), o `src` é removido e descarregado (`load()`), e o MediaSession do Chrome é desativado para o áudio nunca continuar tocando na Home.

---

## 7. Configurações e Menu do Usuário (6 Itens)
*Gaveta lateral suave abrindo a partir da foto do perfil:*
1. **Perfil / Minha Conta:** Visualização do avatar, troca de foto e senha.
2. **Como Usar:** Guia com sistema de checklist/checkboxes para novos usuários (após marcar todos, migra automaticamente para dentro das configurações).
3. **Temas:** Apenas **Roxo** (Shikkoku, padrão), **Verde** (Hisui) e **Automático** (segue o sistema). Vermelho e Azul ficam reservados ao Modo Kids; Dourado fica no iOS.
4. **Download dos Apps:** Links e QR codes para os apps nativos (Android, TVs, Desktop).
5. **Sobre o Heisuca:** Versão, manifesto *"Nada entre você e o filme"* e licença GPL-3.0.
6. **Apoiar o Heisuca:** Canal para doações e apoio à infraestrutura.
- Botão **Sair** no rodapé.
