# Heisuca Android V2 — fase 1b: sessão de mídia

Base `c99e9fb6bb0a94497ca9206f32dadc7a9d1d0d2d`, ramo `codex/heisuca-v2-sessao`, worktree próprio.
Código e runs: serão consolidados após a primeira execução do Actions.
Versão preservada **2.0.34+2047**. Nenhum merge/rebase, release/AAB ou distribuição de APK.

## Implementação

- Pacote nativo isolado `app.heisuca.sessao`: MediaSessionService, MediaSession e SimpleBasePlayer únicos.
  O adapter recebe o retrato do transporte Dart, independente de mpv/ExoPlayer, e devolve comandos ao mesmo dono.
- Vídeo e música compartilham a ponte `app.heisuca.sessao/metodos` e `/eventos`; API pública do manager/router mantida.
  Identidade inclui servidor e item. Lease impede publicar/limpar/consumir comandos por dono antigo; recuperação
  da posse invalida geração, timer e cache de disponibilidade.
- Carregamento, fim e erro reais publicados pelos streams atuais. Adjacência real determina Próximo.
- `os_media_controls` removido do pubspec/lock e registrantes gerados. Nenhuma segunda sessão legada permanece.
- Arte nativa com BitmapLoader: HTTPS, sem redirecionamento, até 8 MiB de entrada, redução a 512 px,
  cache privado limitado. Metadados e persistência não publicam URLs autenticadas nem bitmaps grandes pela ponte.
- Notificação padrão da Media3 com contexto pt-BR. Serviço recebe apenas controladores confiáveis/mesmo app.
  Clear libera sessão/foreground imediatamente; MediaPlaybackPolicy consulta a classe nova. Sem permissão nova.
  Evento AUDIO_BECOMING_NOISY preserva pausa autorizada, com receiver dinâmico privado e fechamento idempotente.
- PiP API31+: ações Tocar/Pausar, Voltar 10 segundos, Avançar 10 segundos e Próximo quando disponível.
  Ações voltam à mesma sessão; mudança de estado atualiza params. SourceRectHint conserva o retângulo da imagem;
  AutoEnter só é verdadeiro com vídeo tocando e player pronto na tela.
- Sem alterações em design/, heisuca/, features/, motores, superfície nativa, applicationIds, minSdk,
  assinatura, versão ou workflows. Só novos testes foram acrescentados ao portão, sem tirar testes existentes.
- Changelog: “Controles do sistema refeitos: tela de bloqueio, fone e janela flutuante com botões.”

## Provas locais e negativas

- Teste novo da ponte escrito antes: manager da base envia ao canal antigo, teste recebe zero chamadas e falha.
  Log `ultron-v2-sessao-dart-red.log`. Teste de carregamento também falhou antes (publicava paused).
- Prova adicional de identidade por servidor falhou antes: dois IDs iguais em origens distintas colidiam.
  Agora usa globalKey, sem misturar posição/retomada entre servidores.
- Testes originais do manager mantêm todos os asserts; só mudou o nome do canal. Outros imports/canais foram migrados.
- Kotlin: **14 testes passaram / zero falhas, erros ou pulados**: sessão3, arte/retomada5, rota de áudio1 e PiP5.
  Testes escritos antes; logs negativos Kotlin/áudio preservados. Teste de imagem inválida exige decoder nativo
  do Robolectric; assert mantido, sem aceitar bytes inválidos pelo shadow antigo.
- Host: dez testes de sessão/PiP + quatro de manifesto, negativos antes e verdes depois. Recusa sessões duplicadas,
  estado/título/posição/ações erradas, botão invisível/desabilitado e sequência de protocolo inválida.
- Análise geral:40 avisos/info; núcleo alterado analisado estritamente sem diagnóstico. Não chamar análise geral verde.
- **Portão amplo falhou**:192 Python passaram;2353 Flutter passaram/3 pulados/1 falha.
  Falha: `heisuca_marca_2026_test.dart: tokens gerados são cópias exatas da fonte da marca`.
  Comprovadamente já está em c99: HeisucaBase recebeu dez tokens de movimento, sem atualizar a cópia em docs/marca.
  Os dois arquivos continuam byte a byte iguais à base. Não corrigi arquivo protegido nem afrouxei o teste.
  Por set-e, esse portão não chegou às etapas Impeller/Kotlin; provas separadas são identificadas como separadas.
- Validação focada final: **118 passaram**, incluindo todos os testes originais do manager, router, música,
  estados reais e isolamento por servidor. Impeller separado: aguardando conclusão do log local.

## Bancada do HUD e sessão

Novos casos acoplados ao target/driver existentes sem alterar asserts anteriores. Protocolo host captura screencap
real, dumpsys e XML, verifica uma sessão/título/posição/ações, pausa por comando de mídia, resposta dos botões PiP
visíveis e encerramento de sessão/foreground. Rejeita fallback Exo→mpv como prova do Exo.
As capturas comparam o mesmo quadro pausado, nos modos sem faixa/desfoque/degradê; FrameTiming é coletado
com vídeo tocando por três segundos/modo (build/raster/total, mediana/pior, pelo menos30quadros).
**Capturas e tempos reais ainda pendentes do Actions. Não afirmar que o desfoque funciona ou não antes da prova.**
Build/segurança aceitam automaticamente o ramo novo. Bancada exige disparo manual no mesmo ref por filtro existente.
O workflow de build terá a mesma falha herdada dos tokens; não alterar workflow/gate para ocultá-la.

## Limites e riscos

- onPlaybackResumption recupera título, arte privada e posição. Retoma apenas com transporte Dart vivo e mesmo item.
  Com processo/motor encerrado, falha explicitamente; **retomada de reprodução nesse cenário continua pendente**.
  Isso é limite desta integração, não prova de que o Android proíbe. Não gravei URL de mídia/credenciais nem criei
  motor headless, Activity automática ou promessa de retomada que não existe. Teste cobre apresentação e recusa.
- A documentação Android distingue callback de retomada de carrossel de retomada do System UI: este exige
  MediaLibraryService; o escopo pedido usa MediaSessionService. Não substituí o tipo de serviço.
- Android trunca ações PiP acima de getMaxNumPictureInPictureActions; em aparelhos com máximo3, Próximo fica
  depois dos três transportes prioritários e pode não aparecer. A bancada consulta o limite real e registra isso.
- Bluetooth, fone físico, carro e aparelho real não testados. Teste de broadcast não substitui desconectar fone real.
- Portas nativas de controles fora do Android não foram implementadas/validadas após retirar o plugin multiplataforma.
- Sem aprovação independente nem distribuição; código para revisão, com pendências explícitas.

## Fontes técnicas

- [MediaSessionService, ciclo, autorização e retomada](https://developer.android.com/media/media3/session/background-playback).
- [SimpleBasePlayer](https://developer.android.com/reference/androidx/media3/common/SimpleBasePlayer).
- [Limite das ações PiP](https://developer.android.com/reference/android/app/PictureInPictureParams.Builder#setActions(java.util.List%3Candroid.app.RemoteAction%3E)).

## Arquivos e desfazer

Lista exata de criados/alterados será consolidada com a SHA de código. Nenhum arquivo rastreado apagado;
remoção do plugin é de dependência e registro. Provas completas privadas em
`~/cgflix/handoffs/PROVAS_ULTRON_V2_SESSAO_2026-11-10/`.
Desfazer: reverter apenas os commits desta fase no ramo de trabalho; outros ramos/produção intocados.
