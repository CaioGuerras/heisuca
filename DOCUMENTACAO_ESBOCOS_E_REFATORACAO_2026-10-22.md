# Dossiê de Esboços, Design e Refatoração Heisuca Mobile (炳素華)
**Data:** 22 de Outubro de 2026 · **Dono e Decisor:** Caio Guerras
**Dispositivo Referência:** Motorola Edge 60 Pro (Android 14+, Snapdragon, 12 GB RAM, 144Hz pOLED)
**Objetivo:** Transformar o cliente mobile em um app flagship no nível do **VidHub** e **Infuse**, com estética minimalista sino-japonesa (*Shikkoku* Escuro e *Hisui* Claro).

---

## 1. Identidade Visual e Filosofia de Design (Esboço 01)
- **Nome & Selo:** `HEISUCA` acompanhado do selo Hanzi tradicional `炳素華`.
  - No canto superior esquerdo da Home, o nome fica colado ao selo (sem espaçamento exagerado).
- **Temas Oficiais:**
  1. **Shikkoku (漆黒 - Modo Escuro):** Fundo ébano profundo (`#0E0B16`), cartões de vidro translúcido (`rgba(255, 255, 255, 0.045)`), bordas suaves (`rgba(255, 255, 255, 0.08)`), texto `#F4F1FA`, acento ametista/púrpura imperial (`#7A40F2`).
  2. **Hisui (翡翠 - Modo Claro):** Fundo pergaminho/marfim suave (`#F7F3EC`), texto verde jade profundo (`#134E4A`), acento esmeralda (`#047857`), bordas sutis (`#E2E8F0`).
  - **Atenção:** No tema Hisui (Claro) é estritamente proibido o vazamento de cores roxas/lilases em fundos de cartões, seletores de episódio ou menus de contexto.

---

## 2. Tela de Login Flagship (Esboço 02 / 02C)
- **Layout:**
  - Topo centralizado com o selo `炳素華` e o nome `HEISUCA`.
  - Caixa de vidro com cantos arredondados contendo os campos: `SERVIDOR`, `USUÁRIO`, `SENHA`.
  - Botão principal: `Iniciar sessão`.
  - Botão secundário de acesso rápido: **Quick Connect via QR Code** (`Symbols.qr_code_2_rounded`).
  - Link de rodapé: `+ Outros servidores e pastas locais` (abrindo folha para Plex, Emby, SMB e WebDAV).
- **Arquivos:** `lib/heisuca/heisuca_login_screen.dart`, `lib/heisuca/heisuca_select_service_screen.dart`.

---

## 3. Home Cinematográfica & Atmosfera Dinâmica (Esboço 03 / 03B)
- **Topo (Topbar):** Logo oficial à esquerda e botão de busca à direita (`lib/heisuca/heisuca_home_screen.dart`).
- **Hero Edge-to-Edge:**
  - Zero botões de cápsula (como play) por cima da imagem. O toque abre a Ficha Técnica.
  - Scrim Easing Cúbico Hermite Smoothstep de 9 paradas (sem faixas pretas duras).
  - **Iluminação Dominante:** O topo da Home (70% da tela) e o halo na base do Hero adotam a cor predominante da obra em foco via `resolveHeroAmbientColor` (espaço OKLCH calibrado), interpolando em 650ms.
- **Fileiras de Conteúdo:**
  - `Continuar assistindo`: Cartões largos 16:9 widescreen (`CgflixWideCard`) com barra de progresso.
  - `Em alta no Brasil`: Prateleira Top 10 com tipografia estilizada.
  - Prateleiras do acervo: Lançamentos, Filmes, Séries, Animes e Gêneros sob demanda.
- **Ilha Flutuante (`HeisucaFloatingIsland`):** Fixa na base, 64dp de altura, com 4 ícones: Início, Biblioteca, Buscar e Você.

---

## 4. Ficha Técnica / Detalhes & Menu de Toque Longo (Esboço 04 / 04B)
- **Ficha Técnica em Tela Cheia (`lib/heisuca/heisuca_title_sheet.dart`):**
  - Rota de tela cheia com botão flutuante de voltar `←` no canto superior esquerdo com cápsula de vidro e blur (`BackdropFilter`).
  - Metadados autênticos: Ano, Dublado/Legendado, resolução real extraída do stream (`4K UHD`, `1080p`, etc.), áudio real (`5.1`, `7.1`, `Stereo`), nota real (apenas se existir).
  - **Sem dados falsos:** Proibido `'4K HDR'` fixo, nota `'9.1'` fictícia, sinopse de Duna fictícia ou episódios de 54 min fixos.
  - Ações rápidas: `Assistir Agora` / `Continuar Temporada`, `Favoritar` (reativo) e `Download Offline`.
  - **Sem a opção "Pedir no Seerr"**.
- **Menu de Toque Longo 500ms (`lib/heisuca/heisuca_context_menu.dart`):**
  - Caixa flutuante arredondada, rótulo à esquerda e ícone à direita.
  - Disparado com feedback tátil (`HapticFeedback.mediumImpact()`).
  - Estado reativo com `HeisucaStateStore`: alternância imediata do coração (cheio/vazio) e avisos de *"Adicionado aos favoritos"* / *"Removido dos favoritos"*.
  - Ações: `Ir para a série/filme`, `Marcar como visto/não visto`, `Favoritar/Tirar dos favoritos`, `Baixar episódio/filme`.

---

## 5. Hub Você & Configurações Nativas (Esboço 05)
- **Perfil do Usuário (`lib/heisuca/heisuca_profile_screen.dart`):**
  - Abre na 4ª aba da Ilha Flutuante.
  - Header: Avatar do usuário, nome e chip de status em tempo real (`CGSERVER · Conectado`).
  - Seções:
    - Mídia: `Baixados & Offline`, `Favoritos`, `Todas as Bibliotecas`.
    - Preferências: `Configurações Heisuca`, `Sobre o Heisuca`.
    - Conta: `Trocar Usuário / Servidor`, `Sair da Conta`.
  - Limpo de qualquer elemento legado como "Apoie o CGFLIX".
- **Configurações Heisuca (`lib/heisuca/heisuca_settings_screen.dart`):**
  - Aba Básica: Qualidade, pular introdução, idiomas.
  - Aba Avançada: Detecção de hardware Motorola Edge 60 Pro, Zero-Copy Vulkan/libmpv, Buffer de 256MB RAM, 144Hz pOLED, Calibração HDR/Dolby Vision.

---

## 6. Estado Atual do Código e Artefatos
- **Branch Ativo:** `gemini/heisuca-plex-home`
- **Último Commit:** `e8be7d2`
- **Validação de Código:** `bash apps/app/scripts/heisuca-checar.sh` → `APROVADO: 0 erros no analyze.`
- **Testes Unitários/Widgets:** `flutter test test/heisuca/heisuca_flagship_test.dart` → `12/12 aprovados.`
- **APK Publicado:** `https://heisuca.docaio.com.br/pacotes/heisuca-arm64-v8a.apk` (HTTP 200, 93.76 MB).
