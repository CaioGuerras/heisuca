# Estado funcional do Heisuca Android

> Registro da primeira etapa (PR #1). Para o estado posterior da Home, APK 2.0.2,
> identidade de teste e pendências atuais, leia [HANDOFF_ANDROID_2026-10-22.md](HANDOFF_ANDROID_2026-10-22.md).

Correção iniciada em 22/10/2026, sobre `gemini/heisuca-plex-home`, commit
`0580ca6093f40795092fb3bf99daf75e1b361401`. PR: https://github.com/CaioGuerras/heisuca/pull/1

## Implementação nesta alteração

- A tela de configurações lê e grava `SettingsService`, o mesmo serviço consumido pelo player. A qualidade usa os presets reais; o buffer usa os perfis do ExoPlayer quando esse motor está ativo. No libmpv, o controle fica desabilitado e informa o gerenciamento automático nativo. Não existe um controle arbitrário de MB nem uma opção que prometa Vulkan.
- Abertura automática usa os marcadores disponíveis. Não se deve assumir uma abertura de duração fixa.
- A preferência local por português é opcional. A seleção manual carregada pela navegação permanece prioritária. Sem uma faixa correspondente, o fluxo do servidor/perfil é preservado.
- O cartão de hardware consulta fabricante/modelo, memória reportada pelo sistema, SoC quando disponível e modos de tela no Android. Frequência máxima de tela não significa frequência ativa de reprodução. HDR, Vulkan e tipo do painel não são inferidos do nome comercial.
- SMB informa indisponibilidade e não coleta credenciais. WebDAV oferece apenas um teste PROPFIND e não anuncia uma biblioteca adicionada. O proxy não é iniciado por um teste de acesso.
- O workflow exige análise e testes antes do APK. Falhas das ferramentas não são convertidas em aprovação por busca de palavras em logs.

## Ainda não implementado ou validado

`heisuca_player_screen.dart` é um protótipo visual com dados simulados e não está no caminho de reprodução. A Home/ficha usa `cgflixPlay` → `navigateToVideoPlayer` → `VideoPlayerScreen`. Não conectar o protótipo substituindo esse caminho: faltam superfície de vídeo, ciclo de vida, faixas reais, posição, marcadores e tratamento de erros. A integração visual deve preservar os controles e callbacks do motor existente.

SMB precisa de transporte, autenticação, catálogo persistente, resolução de URLs/streaming e testes reais com NAS. WebDAV ainda precisa interpretar a listagem, persistir a fonte e encaminhar arquivos ao player. Um HTTP 207 isolado não comprova esse fluxo.

Nenhuma captura de widget, compilação ou teste unitário comprova reprodução em aparelho físico. Não declarar a migração visual completa nem suporte comprovado a Dolby Vision, HDR10+ ou zero-copy a partir desses resultados.

## Teste no aparelho de Caio antes de merge

1. Conferir o modelo exibido e mudar abertura, áudio, buffer e decodificação. Fechar o app e conferir persistência.
2. Reproduzir um filme e um episódio no Jellyfin, com transcodificação de vídeo desativada no servidor. Conferir Direct Play/remux nos dados da sessão.
3. Conferir áudio em português quando presente, fallback quando ausente e seleção manual de outra faixa.
4. Conferir anime com ASS, retomada, busca na linha do tempo, pausa, rotação, retorno do segundo plano e fim do episódio.
5. Conferir abertura com e sem marcadores, sem saltos por duração inventada.
6. Conferir ajuste de frequência em dispositivo compatível; comparar movimento e troca de modo. A capacidade anunciada da tela não basta.
7. Conferir limite de duas sessões, erro de rede e credenciais inválidas com mensagens compreensíveis.
8. Conferir Shikkoku e Hisui em telefone pequeno e no aparelho principal.

O APK desta branch é para avaliação. Não fazer merge, substituir aplicativos instalados dos demais usuários nem publicar uma release automaticamente.
