# Heisuca Desktop — decisão e plano de execução (18/11/2026)

## Decisão inicial auditada pela Jocasta
Windows primeiro; Linux e macOS conservam caminho de evolução. Flutter + libmpv, com um entrypoint desktop próprio: reaproveitar protocolo/decodificação e refazer a experiência de desktop. Não há evidência que justifique reescrever clientes estáveis em Rust, C++ ou C# nesta etapa. Essa decisão é de engenharia, não uma alegação de superioridade medida.

A pesquisa foi dividida em oito frentes e uma auditoria de código, com cinco contas Carbon e quatro Flash. Os relatórios brutos ficam em ~/cgflix/desktop/pesquisas/2026-11-18. Parte das pesquisas Gemini só conseguiu resultados de busca, sem abrir URLs: são pistas, não prova. Alegações quantitativas, arquitetura atual de concorrentes e links reconstruídos não são aceitos sem conferência. Não inferir que todos os usuários preferem algo com base numa issue.

Fontes primárias já abertas pelo auditor: documentação Flutter de build Windows (https://docs.flutter.dev/platform-integration/windows/building), manual mpv (https://mpv.io/manual/stable/), upstream Plezy (https://github.com/edde746/plezy), engine fork (https://github.com/edde746/flutter-plezy), workflow upstream e acessibilidade Microsoft (https://learn.microsoft.com/en-us/windows/apps/design/accessibility/accessibility-overview). Source base Heisuca b61c7dda, Stable 2.0.45+3030.

## Fatias e ordem
1. Player local utilizável sem cadastro: abrir arquivos/URL HTTP(S), controles de teclado, seek/volume, faixas de áudio/legenda, carregar SRT/ASS externo, tempo/erro/buffering legíveis, estado sem falso sucesso.
2. Shell próprio Heisuca: hierarquia visual sóbria Sora/Inter, layout desktop responsivo, foco visível, redução de movimento, sem conteúdo fictício, sem anúncios, sem onboarding bloqueante. Arquivo local funciona sem servidor.
3. Integração Plex/Jellyfin usando contratos existentes, fonte identificada, busca/paginação/retomada e ações coerentes. Não usar login web improvisado nem token na URL visível. Essa fatia não pode ser declarada pronta com apenas botões vazios.
4. Windows nativo/CI: identidade Heisuca, engine DComp compatível e fixado, bundle ZIP autocontido, licenças e hashes, build em runner Windows padrão. Sem alterar canais Android, sem Microsoft Store ou certificado pago nesta etapa.
5. Auditoria independente, análise estática/testes e prova real de reprodução com mídia livre/sintética. Só entregar artefato que de fato compilou; marcar hardware/HDR/passthrough como não verificados até prova.

## Riscos descobertos no código
O runner exige engine Flutter com DirectComposition; Flutter oficial compilar não prova overlays funcionando. O script windows/tool/install-patched-engine.ps1 deve ser auditado e utilizado no CI. O player já suporta macOS via PlayerNative (não há necessidade comprovada de classe PlayerMacOS dedicada). O Android main.dart e protocolos existentes permanecem fora do escopo das primeiras mudanças.

## Critérios de aceite
Análise e testes novos passam; abertura sem login/offline; caminho Unicode/espaços, cancelamento e arquivo inválido; falha não fica eternamente carregando; concorrência de abrir/fechar não pode ressuscitar sessão antiga; seleção real de faixas e desligamento; atalhos não capturam digitação; sem credenciais em diagnóstico. CI Windows precisa confirmar frame renderizado e relógio avançando, além do exit code. DPI 100/125/150%, multimonitor, HDR10 e áudio HDMI continuam sem certificação até teste correspondente.

## Isolamento e reversão
Ramo gemini/heisuca-desktop-windows, checkout isolado em ~/TMP. Geminis geram arquivos/patches, Jocasta audita/aplica e outro Gemini revisa. Nenhuma escrita simultânea no mesmo arquivo. Reverter commits desktop desfaz a implementação. Sem promoção Estável, sem alteração do site/Android ou de acervo.

## Resposta à revisão independente do plano

A revisão Carbon09 apontou conflitos com uma proposta anterior da auditoria de base: prevalece este plano com M1 local e M2 remoto, não há promessa de Plex/Jellyfin no primeiro artefato. Donos e contrato foram fixados antes da geração: Core01, UX02, Native03; Codex aplica/corrige, revisão independente02/09. O script da engine foi lido: versão3.47.1, engine5d531788, SHA256 fixado no próprio script. O factory Player tem ramo macOS -> PlayerNative; a inferência de que faltaria PlayerMacOS foi rejeitada pelo código completo. Os métodos dispose/stop/selectSubtitleTrack existem. Não haverá migração de banco, pubspec ou assets Android nesta fatia.

A bancada configura somente no teste: hwdec=no, D3D11 WARP e ao=null para rodar no runner Windows sem GPU/saída física. Isso não certifica hardware ou som nos alto-falantes. Um resultado positivo exige frame, relógio e faixas no backend real, e ainda não prova que o overlay está visualmente correto. DPI/HDR continuam pendentes de prova separada. Nenhum relatório poderá substituir essas limitações por “funciona em qualquer PC”.
