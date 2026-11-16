# Entrega Jocasta — Media3/PiP sobre a V2 de 16/11/2026

## Parecer

**Candidato local para revisão; não recomendo juntar à V2 principal ainda.** O merge é tecnicamente viável e preserva a V2 atual. Falta a prova Android do menu/botões PiP, que reprovou o ramo em 11/11, e a revisão independente do Visão. Não testado em aparelho. Sem push, publicação, alteração de feed ou distribuição de APK.

Base: `6677c9a20b8ca7d636a9c9c51ae0dc3c43e273b7`. Origem incorporada: `5004ae949245308e47ecf6e6dc715ce21e0463ec`, 16 commits exclusivos. Nome do ramo local: `claude/heisuca-v2-sessao-merge`. Versão mantida: **2.0.40+3025**.

Commit do merge: 05eecc01e5b25cff764ba6af29c2f0093090a890.

## O que é função para o usuário

As mudanças funcionais concentram-se em `a9cd95c9`; as seguintes reforçam os testes e o diagnóstico. Inventário completo por arquivo em `.verificacao-sessao/inventario-ramo.txt`: 23 arquivos Dart/Android de função, 16 de ferramenta/CI; demais são dependências, registrantes, testes e documentação.

| Função | Implementação incorporada | Limite |
| --- | --- | --- |
| Vídeo e música usam uma sessão Media3 compartilhada | `lib/services/sessao_media.dart`, manager/router e `android/.../sessao/` substituem `os_media_controls`; identidade inclui servidor/item e o proprietário anterior não pode limpar ou consumir o transporte do atual | Troca real vídeo↔música ainda precisa de prova Android |
| Notificação e controles do sistema seguem o estado do motor | `HeisucaSessaoService`, `PortaSessaoPlayer`, estados de buffering/fim/erro nos serviços de vídeo e música | Isso não muda o motor mpv/Exo nem promete nova capacidade de codec |
| Botões na janela PiP | `HeisucaPipParams`, `MainActivity`, `SessaoAcaoReceiver`: Tocar/Pausar, voltar/avançar 10 s e Próximo quando disponível | Apenas API 31+ publica a lista de ações; limite de ações do aparelho pode esconder Próximo |
| PiP automático vinculado ao vídeo pronto e tocando | Estado da sessão participa de `buildPipParams`; retângulo de origem e `seamlessResize=false` preservados | Timing entre Dart, Activity e serviço precisa de aparelho/emulador |
| Pausa quando a saída de áudio desaparece | Receiver privado `AUDIO_BECOMING_NOISY`, condicionado ao estado/comando autorizado | Não equivale a teste com Bluetooth/fone físico nem a nova implementação completa de foco de áudio |
| Arte e último item nos controles | Arte HTTPS sem redirecionamento, entrada até 8 MiB, bitmap reduzido até 512 px, cache privado; persistência de título/posição sem URL de mídia | Arte HTTP não é carregada; retomada de reprodução com processo/motor morto **não foi implementada** |
| Serviço foreground real | `MediaPlaybackPolicy` passa a reconhecer `HeisucaSessaoService`; Media3 controla a promoção pelo estado do transporte | Corrida de promoção e restrições Android/OEM precisam de teste em segundo plano |

Além do código Dart/Android: dependência `media3-session`, manifesto e retirada do plugin/registrantes antigos. Remover o plugin também retira os controles nativos dele nas outras plataformas; não há implementação substituta fora do Android neste ramo.

## O que é apenas ferramenta de teste

- `integration_test/sessao_media_hud_test.dart`, registro no target/driver existente e host `scripts/bancada/sessao_media.py`: prova de sessão única, ações, posição, botões PiP, capturas do HUD e FrameTiming em mpv/Exo.
- `HeisucaPipClose.java` e `compilar_ui.py`: UiAutomation, espera de raízes, abertura do menu, procura de botão na mesma conexão, XML/diagnósticos/tempos e inclusão das classes auxiliares no DEX.
- Workflow da bancada: espelhos de ffmpeg, prazos limitados e restauração da lista original. Isso não modifica o aplicativo instalado.
- Contratos Python, validação de manifesto/APK, testes Dart/Kotlin e dumps de referência. Os commits posteriores ao funcional não são novas funcionalidades do produto.
- A prova adicional continua obrigatória no target/host incorporado: não foi removida, tornada opcional nem substituída pelo percurso PiP antigo já verde da V2.

Evidência anterior lida: `docs/HANDOFF_ULTRON_V2_SESSAO_2026-11-11.md`, run **43060805478**: leitor válido, 73 nós e botão Pausar ausente após 8 s. A falha estava na abertura/exposição do menu; ela não prova por si só defeito do transporte Media3. Não houve nova bancada Android nesta sessão.

## Conflitos e preservação da V2

Houve **um conflito textual**, em `apps/app/scripts/heisuca-checar.sh`. Mantida a lista completa da V2, incluindo `test/features`; acrescentados os testes da ponte, router e manifesto e a etapa Kotlin do ramo. Nenhum teste da V2 foi removido ou afrouxado. Nenhuma outra ferramenta de bancada apresentou conflito textual; as mudanças desses arquivos vieram por merge automático, preservando o percurso V2 existente.

Conferência do diff: nenhuma alteração em `lib/features/`, `lib/design/`, `test/design/`, `lib/heisuca/` ou `docs/marca_2026-11-09/`. Telas novas, canais Estável/Beta e applicationIds preservados. A nota de controles foi movida da seção histórica 2.0.34 para a seção atual 2.0.40, sem mudar a versão.

## Validação local

Todos os comandos Flutter foram executados em `apps/app`. O SDK solicitado foi copiado, sem troca de versão, para `/tmp/heisuca-sessao-flutter`, porque o original tenta atualizar `bin/cache` fora da área gravável. `PUB_CACHE=/tmp/heisuca-sessao-pub-cache`, `TMPDIR=/tmp`, Gradle em `/tmp/heisuca-sessao-gradle`, Java 21 do servidor; `JAVA_TOOL_OPTIONS='-XX:ActiveProcessorCount=6 -Duser.home=/tmp/heisuca-sessao-java'`. O diretório de usuário **da JVM**, separado do HOME do shell, evita locks do Robolectric fora da área permitida. Cópias temporárias de ferramentas não são mudanças do app.

| Comando | Resultado |
| --- | --- |
| `flutter pub get` | rc 0, `Got dependencies!`; sem atualização deliberada de versões |
| `dart format -l 120 lib/design test/design` | rc 0, 35 arquivos, zero alterações |
| `flutter analyze` | rc 1, **42 diagnósticos** (7 avisos e 35 informações), zero erros; exatamente os mesmos 42 da base `6677c9a2`, normalizadas apenas as linhas deslocadas pelo import. Comparação em `.verificacao-sessao/comparacao-analyze.json` |
| `flutter test test/heisuca` | rc 0, **1.538 passaram**; 3 capturas opcionais preexistentes condicionadas a `HEISUCA_SNAPSHOT=1` não executadas |
| `flutter test test/design` | rc 0, **155 passaram** |
| Suíte adicional de música e seis arquivos alterados do player | rc 0, **144 passaram**; comando exato abaixo |
| Gradle da sessão/PiP | rc 0, **15 testes**, zero falhas, erros ou pulos; inclui compilação Kotlin do app e testes Robolectric |
| `bash scripts/heisuca-checar.sh` | rc 0, `APROVADO: análise e testes concluídos.`; **226 Python**, **2.796 Flutter** (3 capturas opcionais preexistentes), **8 Impeller** e etapa Kotlin verde (15 testes comprovados na execução nativa separada; etapa final reutilizou resultado Gradle) |

As três capturas opcionais já possuem `skip: !heisucaSnapshotEnabled` na base: abertura kids, HUD e ficha. Nenhum `skip`, redução de assert ou tolerância nova foi introduzido. A análise não foi declarada estritamente verde e suas opções não foram afrouxadas: o portão mantém as opções que já existiam na V2. O pacote local `wakelock_plus` precisou de `flutter pub get` próprio para disponibilizar `pigeon` e `mocktail` na análise geral; sem isso a primeira tentativa teve erros de preparação do pacote. Arquivos de dependências rastreados desse pacote não foram alterados.

```bash
flutter test test/services/music \
  test/screens/video_player/live_media_session_test.dart \
  test/screens/video_player/media_control_skip_burst_test.dart \
  test/screens/video_player/playback_open_failure_test.dart \
  test/screens/video_player/playback_open_throw_test.dart \
  test/screens/video_player/ambient_lighting_startup_restore_test.dart \
  test/screens/video_player/reload_first_frame_source_test.dart

cd android
./gradlew --no-daemon --max-workers=2 :app:testDirectDebugUnitTest \
  --tests 'app.heisuca.sessao.*' --tests app.heisuca.HeisucaPipParamsTest \
  -PtargetAbi=arm64-v8a -PheisucaPreview=true \
  -Pkotlin.compiler.execution.strategy=in-process
```

Para executar o portão sem mudar seu PATH compartilhado, foi exportada uma função shell `flutter() { /tmp/heisuca-sessao-flutter/bin/flutter "$@"; }`; o script e seus critérios permaneceram rastreados conforme o diff descrito. Logs completos em `.verificacao-sessao/`: `pub-get.log`, `format.log`, `analyze-final.log`, `analyze-base.log`, `test-heisuca.log`, `test-design.log`, `test-sessao-musica.log`, `kotlin-final.log` e `portao-final.log`. Tentativas anteriores com erro de filesystem foram preservadas em logs separados; não são tratadas como aprovação.

## Riscos e próximo aceite

1. **PiP:** provar menu e cada botão visível, primeiro mpv e depois Exo, sem contornar a falha original. Revalidar também 13-home-pip … 21-imagem-apos-audio, fechar PiP, voltar ao app e autoentrada apenas no vídeo pronto/tocando.
2. **Música/fundo:** provar notificação, posição, próximo/anterior, fim/carregamento/erro, troca música→vídeo→música e limpeza do dono antigo; testar tela apagada, saída do app e promoção foreground real. O `setBackgroundMode` nativo agora deixa a decisão para Media3.
3. **Ciclo Android:** destruição da Activity/engine chama `SessaoBridge.detach()` e limpa a sessão. Retomada com processo morto é limitada, explicitamente; não prometer áudio headless ou retomada plena.
4. **Saída/foco de áudio:** testar fone físico, Bluetooth e interrupções; receiver e testes unitários não substituem esse aceite.
5. **Outras plataformas:** a retirada multiplataforma de `os_media_controls` precisa de decisão explícita antes de levar o mesmo conjunto a desktop/iOS.

Não considero o merge inviável pelo conflito de código. A menor entrega segura imediata é **este candidato local**, isolado da V2 publicada. Se a revisão decidir dividir: levar primeiro a ponte Media3 e seus testes de contrato, mantendo a prova de PiP obrigatória antes da integração do transporte; ferramentas de ffmpeg/UiAutomation podem ser revisadas separadamente. Só os botões PiP não são uma fatia independente: dependem da nova ponte/serviço. Não recomendo selecionar commits de ferramenta e anunciar a função como entregue.

## Restrição do worktree, localização e desfazer

O `git merge` normal falhou antes de modificar a árvore: não pôde criar `.../heisuca-visao/.git/worktrees/heisuca-sessao-merge/ORIG_HEAD.lock` (filesystem somente leitura). Os metadados originais estão fora da área gravável. Não editei `heisuca-visao` nem o arquivo `.git` original.

O merge/commits foram feitos com `git --git-dir=.git-sessao-local`, repositório de metadados **dentro deste worktree**, mesmo nome de ramo e mesmos dois pais do merge solicitado. A referência do worktree original ainda aponta para `6677c9a2`; `git status` comum vê as alterações como não commitadas porque usa o índice original. Use `git --git-dir=.git-sessao-local status` e `log` para conferir a entrega efetivamente commitada.

Bundle portátil: `.verificacao-sessao/sessao-merge.bundle`, contendo os commits locais e os 16 da origem, com pré-requisito `6677c9a2`. Para inspeção sem alterar referência: `git bundle verify .verificacao-sessao/sessao-merge.bundle` e `git --git-dir=.git-sessao-local show --stat HEAD`.

Para o Visão registrar o resultado no worktree original fora deste sandbox, depois de conferir que está no ramo correto e sem alterações adicionais: importar o ramo do bundle com `git fetch .verificacao-sessao/sessao-merge.bundle claude/heisuca-v2-sessao-merge`, conferir `FETCH_HEAD` e usar `git reset --mixed FETCH_HEAD` para alinhar referência/índice aos arquivos já presentes, sem sobrescrevê-los. Isso não é push nem merge na V2 principal.

Desfazer depois de eventual integração: `git revert -m 1 05eecc01e5b25cff764ba6af29c2f0093090a890`, em ramo de revisão autorizado. Antes de integração, basta não importar este candidato: a V2 e a referência original permanecem na base. Preservar os arquivos/logs do candidato se for restaurar a árvore; não usar limpeza destrutiva.

Destino solicitado do relatório: `/mnt/nvme4n1/caioguerras/cgflix/handoffs/NOITE_2026-11-16/ENTREGA_CODEX.md`. O destino externo não é gravável neste sandbox; tentativa de cópia registrada em `.verificacao-sessao/entrega-destino.log`. Este arquivo dentro do worktree é a cópia completa para o Visão colocar no destino solicitado.
