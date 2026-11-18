# Heisuca Windows — instalador e experiência desktop

Base técnica Heisuca 2.0.45+3030. Ramo gemini/heisuca-desktop-windows. Sem alterações de Android, site, feeds ou Estável.

## Marcos com prova

- M2 b1d1580f: CI44325345100 aprovado,171 testes Windows +4 nativos. ZIP M2 preservado.
- Empacotamento751bfaed: CI44334448984 aprovado. Gerador Inno do CGFLIX reaproveitado e parametrizado; AppId, nomes e pasta Heisuca próprios. Teste real instala, reinstala, reproduz do executável instalado e desinstala, preservando arquivo do usuário e a fixture de registro CGFLIX. Não é teste de migração de uma instalação CGFLIX real.
- Acabamento atual: temas e marca oficiais, ajustes/privacidade/licenças, arquivos recentes com retomada, velocidade, arte/progresso das fichas/cartões e interação Toque. IPC de arquivo na instância existente, espera por janela que ainda inicia e arrastar vídeo/legenda. Esta revisão exige novo CI da ponta para validar os deltas nativos e pacotes finais.

## Distribuições

Instalador Inno por usuário, com desinstalação e atualização por cima. O Heisuca não assume a identidade nem o registro do CGFLIX. Abrir com é opcional e não muda o aplicativo padrão do Windows. O ZIP contém o mesmo runtime e funciona extraído sem instalação. Seu histórico, ajustes e cofre continuam no perfil do Windows: o ZIP não é um modo de dados inteiramente transportável. Tokens de conexão ficam somente no cofre DPAPI.

## Provas exigidas na ponta

Análise sem ocorrências; testes desktop/design e regressões dos serviços compartilhados; backend Windows real, SQLite e DPAPI; instalador real e hash do binário instalado; vídeo com quadro/relógio/faixas/legenda/seek/velocidade; handoff com dono oculto temporariamente reproduz a corrida de inicialização; histórico confirma a nova fonte; dados do perfil preservados após desinstalar. Capturas nativas de vídeo e das três aparências ficam nos artifacts; uma captura Flutter local é só prévia visual.

## Limites de homologação

Sem homologação em PC físico, GPU/HDR/passthrough, múltiplos monitores e configurações dos servidores particulares de cada pessoa. x64 é o alvo compilado; preservar suporte do gerador ARM64 não comprova uma build ARM64. Atualização automática Windows e publicação pública de uma versão Estável não estão ligadas. Fila de múltiplos arquivos e refinamentos de integração com o sistema seguem critérios do plano; o picker/drag desta etapa atende um vídeo por vez.

Reversão: voltar por novo commit ao marco b1d1580f ou usar o pacote M2 preservado, mantendo cópia dos dados. Nenhum force push ou alteração do produto CGFLIX em produção.
