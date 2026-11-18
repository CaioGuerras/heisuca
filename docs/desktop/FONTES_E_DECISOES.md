# Pesquisa auditada — Windows primeiro

As oito pesquisas brutas do CGMIND cobrem playback, UX, arquitetura, integrações, falhas reais, acessibilidade, distribuição e movimento. A busca localizou material; não se assume que o Gemini abriu cada página. Links de grounding são pistas e não referências finais. Esta lista contém fontes primárias abertas pela Jocasta em 18/11/2026. Não é um ranking de popularidade ou benchmark de performance.

| Fonte primária | O que sustenta | Decisão de produto/engenharia (inferência nossa) |
|---|---|---|
| https://docs.flutter.dev/platform-integration/windows/building | FFI/Win32 e empacotamento desktop | Preservar Flutter com host Windows próprio, verificar bundle |
| https://mpv.io/manual/stable/ | Controle de reprodução, faixas, opções de saída e aceleração | Motor nativo, legenda fora do navegador, controles observáveis |
| https://github.com/edde746/plezy | Base multiplataforma e código do motor/cliente | Reusar protocolos e GPL; identidade e shell próprios |
| https://github.com/edde746/flutter-plezy | Fork de engine utilizado pela base | Fixar engine e SHA; Flutter oficial sozinho não certifica composição |
| https://github.com/edde746/plezy/blob/main/.github/workflows/build.yml | Instalação de engine e validação de DLLs no upstream | Adaptar somente Windows, sem tarefas Android/Sentry/Store |
| https://learn.microsoft.com/en-us/windows/apps/design/accessibility/accessibility-overview | Teclado, leitores de tela e personalização | Foco visível, labels, escala e redução de movimento como critérios |
| https://github.com/edde746/plezy/issues/1753 | Relato de HDR condicionado a fullscreen | Não declarar HDR validado com teste SDR em runner |
| https://github.com/iina/iina/issues/4843 | Solicitação de acesso explícito a áudio externo | Menus de faixas acessíveis; áudio externo fica no roadmap |
| https://github.com/jellyfin/jellyfin/issues/18513 | Relato de demora de extração de legendas | Loading limitado, erro útil, testar legendas reais e mudanças de faixa |
| https://github.com/iina/iina | Player macOS com integração ao sistema e libmpv | Separar shell adaptado ao desktop de backend compartilhável |
| https://firecore.com/infuse | Produto combina arquivos, rede e servidores, com biblioteca integrada | Entrada sem login obrigatório e fontes identificadas; não prometer todos os protocolos no primeiro marco |
| https://github.com/jellyfin/jellyfin-desktop | Cliente nativo Jellyfin de referência | Testar reprodução além do êxito da interface/rede |
| https://github.com/edde746/plezy/releases | Correções públicas de encerramento, seleção de faixas e HDR | Regressões viram testes, não simples comparação por número de funções |

## Contraprovas e limites

Um link presumido para `mpvnet-player/mpvnet` devolveu 404: removido da evidência até localizar a origem correta. A página Plex `using-the-library-view` não abriu nesta ferramenta. Menções a VidHub/PotPlayer/media-kit/WinUI/Qt/Tauri nos relatórios não são aceitas automaticamente como fatos atuais. Não copiar arte ou interface dos concorrentes. Nenhum benchmark comparativo ou pesquisa estatística de usuários foi executado.

## Resultado adotado

M1: arquivo/URL, janela responsiva, controles, faixas e prova real de backend. M2: bibliotecas Plex/Jellyfin com reuso dos contratos existentes, fila/retomada/histórico. M3: refinamento nativo, acessibilidade completa, HDR/multimonitor, instalador e atualização assinada. A ordem limita risco, não reduz o objetivo do app. Não substituir produção por protótipo.
