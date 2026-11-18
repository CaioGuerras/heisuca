# Heisuca Desktop — marco local em validação

Base: Heisuca 2.0.45+3030 (b61c7dda). Branch: gemini/heisuca-desktop-windows. Este ramo é uma prévia técnica desktop: não é uma nova versão Estável Android, não substitui o site e não muda feeds de atualização.

Implementação inicial por Gemini Hydrogen 01 (controller), Hydrogen 02 (interface), Hydrogen 03 (Windows/CI), Flash05 (integração nativa); Jocasta auditou e corrigiu. Pesquisa em oito frentes, auditoria de base Carbon04, revisão de plano Carbon09 e revisão independente de UI Carbon09. A revisão do controller em Carbon03 não iniciou porque o provedor deixou de listar o modelo nessa conta; redistribuída à conta02, sem créditos extras.

22 testes locais unitários/widget passaram. Análise dos arquivos novos sem erros/avisos. A análise geral da base tinha 95 ocorrências anteriores. Contraprova: o teste novo de fechar durante open nativo que nunca responde falhou antes da correção e passou depois; chamadas/streams da instância interrompida são descartadas. Testes também cobrem caminho Unicode, URL com userinfo, timeout sem frame, erro seguro, cancelamento de seletor, argumentos iniciais, foco em campos e layout800x600 com texto200%.

A bancada Windows ainda precisa executar neste commit. O teste real usa imagem sintética, H264, 2AAC e 2SRT. Som físico/GPU/HDR/DPI/multimonitor/SmartScreen e integração Plex/Jellyfin ainda não têm prova nesta prévia. Nenhum resultado de teste com fake será apresentado como prova de vídeo no Windows.

## Correções de auditoria

- URI do Dart remove userinfo vazio; bloquear @ na autoridade crua antes de analisar.
- Close/open que interrompem abertura não podem cancelar o watchdog e prender a fila. A instância interrompida é aposentada.
- Frame antigo não confirma fonte nova; controller governa a visibilidade. Video usa identidade do player como key.
- Timer de auto-hide agora é cancelado no momento de abrir o menu, não por tear-off antigo.
- Falha de seletor tem aviso seguro; legenda atrasada não pode ir para outro player/título.
- Fechar mídia não espera o gerenciador de tela cheia. Falha de fullscreen não falsifica estado.
- Arrasto da timeline é zerado ao fechar/falhar/trocar mídia; menus devolvem foco.
- Teclas em botões/slider mantêm semântica acessível normal do controle focado; não tratamos isso como defeito. Atalhos de player operam fora de edição/modal.

Abertura por argv funciona na primeira instância; repasse do arquivo à instância já aberta ainda é pendência. Instalador legado não é usado (ainda aponta cgflix.exe); CI entrega ZIP portátil experimental. Sem atualização automática herdada ou assinatura nova.

Reversão: reverter os commits deste ramo; não houve deploy nem migração de banco. Para reproduzir: apps/app, Flutter3.47.1, flutter test test/desktop; flutter build windows --release -t lib/main_desktop.dart após windows/tool/install-patched-engine.ps1 em Windows compatível.
