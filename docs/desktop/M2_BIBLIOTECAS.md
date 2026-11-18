# Windows M2 — bibliotecas e sessões

A entrada `lib/main_desktop.dart` usa um grafo próprio de sessões desktop. Abrir arquivo e URL continua disponível sem login. Em Bibliotecas, o usuário conecta Plex pelo navegador/PIN ou Jellyfin pelo endereço e credenciais. O desktop reutiliza os clientes, modelos e protocolo de progresso existentes.

As conexões Windows ficam num blob DPAPI associado ao usuário do Windows (`desktop-connections.dpapi`, pasta de suporte do app). Falha de proteção não resulta em arquivo de credenciais em texto puro: a sessão pode continuar na memória com aviso. O blob não deve ser copiado como mecanismo de migração para outra máquina/usuário. DPAPI protege o armazenamento em repouso, não um processo já comprometido. No Linux/macOS desta etapa, conexões são apenas em memória; esses sistemas ainda não foram homologados.

A navegação consulta páginas de 50 itens, identifica servidor/backend, distingue erro de acervo vazio e permite navegar séries/temporadas/episódios, pesquisar e escolher versões. A reprodução resolve série/temporada para episódio, preserva headers, offset e legendas externas informados pelo cliente. Cada abertura tem época própria; negociação atrasada não toma posse de uma mídia sucessora.

O progresso usa `PlaybackProgressTracker`. Só começa após saída real do player. Stop captura posição da sessão anterior e o fechamento da janela tem prazo limitado. Fim do vídeo encerra heartbeat; replay pode abrir uma nova sessão de progresso. Não há reprodução automática do próximo episódio nesta etapa.

## Validação

Testes de unidade/widget cobrem navegação, paginação, erro, troca de servidor, layout pequeno/texto 200%, cancelamento de login e negociação, restauração, cofre, seleção de episódio, relatórios e reprodução local. O workflow Windows deve compilar o executável Release, executar o backend libmpv com mídia sintética, verificar DPAPI real e capturar a janela com vídeo em movimento. Só um run concluído é prova desse último grupo.

PlexAuthService ganhou parâmetro opcional de identidade. O desktop envia Heisuca; o valor padrão legado permanece CGFLIX e possui teste de regressão. Não muda o entrypoint Android nem a distribuição Estável. O pacote Windows é ZIP portátil nesta etapa; não há instalador, assinatura comercial nem atualização automática desktop.

## Limites de entrega

Sem certificação de HDR, áudio passthrough, GPU física, alto DPI/múltiplos monitores ou acesso aos servidores de cada usuário. O teste sintético evita expor acervo particular. Login real de usuário e reprodução em seus servidores precisam de validação adicional, separada dos testes com clientes simulados. Não considerar uma captura do layout Flutter como prova de composição nativa Windows.
