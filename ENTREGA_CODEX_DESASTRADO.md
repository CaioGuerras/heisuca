# Entrega — Usuário desastrado — 16/11/2026

Worktree exclusivo: `/mnt/nvme4n1/caioguerras/TMP/heisuca-desastrado`.
Ramo recebido: `claude/heisuca-v2-desastrado`; base `6677c9a20b8ca7d636a9c9c51ae0dc3c43e273b7` (2.0.40+3025).
Sem push, merge, publicação ou alteração do app em produção. Não testado em aparelho/emulador nesta sessão.
Revisão independente por Visão/outra IA ainda pendente; os testes abaixo são execução técnica local.

## Resultado

1. A pilha completa foi recuperada do artefato do run **43678744729**: o erro vem de
   `_CgflixFavoritesScreenState._refresh`, `cgflix_favorites_screen.dart:109`.
   **A base recebida já contém a correção**, em `7f5819c11c5b6900626f09d157e77ae1c59f17d2`.
   Não foi necessário alterar código do aplicativo. Foi acrescentada uma guarda estática em
   `apps/app/test/heisuca/set_state_sincrono_test.dart`, coberta pelo portão existente.
2. O run **43772302000** realmente terminou a recuperação no launcher. Não foi determinada com segurança
   a causa de o relançamento falhar. Nenhuma alteração especulativa no Android ou na bancada.

## Cada setState encontrado com o defeito

| Arquivo e linha | Antes, no run antigo | Depois, já presente em 6677c9a2 |
| --- | --- | --- |
| `apps/app/lib/cgflix/you/cgflix_favorites_screen.dart:109` (antigo), `:110` (base atual) | `setState(() => _future = next);` | `setState(() { _future = next; });` |

`final next = _load();` já executa a operação fora do callback. O bloco apenas atribui o Future ao estado;
o `await next` permanece fora do `setState`. Não confundir atribuir um Future com devolvê-lo ao Flutter.

Trecho do artefato `logcat-app.log`, linhas 351–356:

```text
11-15 05:06:38.207 ... Unhandled Exception: setState() callback argument returned a Future.
11-15 05:06:38.207 ... The setState() method on _CgflixFavoritesScreenState#c707f ...
#2 _CgflixFavoritesScreenState._refresh (package:heisuca/cgflix/you/cgflix_favorites_screen.dart:109:5)
```

O checkout real do primeiro run era `9fef52a0da55eb4e154eb26446bcd0c9e8df1b58`, ramo
`claude/heisuca-exp-c`, anterior à correção. A confirmação do ancestral foi feita com
`git merge-base --is-ancestor 7f5819c1 HEAD` (exit 0).

## Varredura e teste novo

Foi usado `grep -rnE 'setState\(' apps/app/lib`, seguido de buscas por setas, async e callbacks por nome,
com leitura dos trechos. A análise sintática e de tipos examina **797 chamadas em 181 arquivos resolvidos**
de `lib/`, incluindo V2, telas herdadas, componentes e partes do player.

A guarda confere callbacks async, tipo da expressão em seta (inclusive atribuições), `return` em blocos,
Future/FutureOr e métodos passados por nome, inclusive `void async`. Ignora os retornos das funções aninhadas.
Os exemplos do próprio teste distinguem 8 casos proibidos e 6 callbacks síncronos.

O único callback concreto por nome, `setState(_reload)` em
`lib/cgflix/requests/cgflix_requests_ui.dart:540`, chama `void _reload()` síncrono (`:531`): ele atribui `_future`,
mas não o devolve. Os outros três casos por nome repassam `VoidCallback` (`fn`) em wrappers existentes.
Também foram lidos os métodos síncronos invocados pelas setas de metadados, editor mpv e seletor de coleção.

Limite: esta guarda não é uma prova de fluxo interprocedural para valores `dynamic` ou callbacks assíncronos
apagados por conversões a `VoidCallback` em outros pontos do programa. A varredura manual complementa a guarda.

## Prova negativa

**O teste na base solicitada passa: ela já estava corrigida.** Não há saída honesta de falha dessa base
pelo defeito descrito. Para comprovar o detector e reproduzir o incidente, foi usado temporariamente
somente o arquivo de Favoritos do checkout exato do run, obtido por:

```sh
git show 9fef52a0da55eb4e154eb26446bcd0c9e8df1b58:apps/app/lib/cgflix/you/cgflix_favorites_screen.dart
flutter test --no-pub --reporter expanded test/heisuca/set_state_sincrono_test.dart --plain-name 'nenhum callback'
```

Saída (exit **1**, falha esperada):

```text
setState: 797 chamadas em 181 arquivos resolvidos.
Expected: empty
Actual: [.../lib/cgflix/you/cgflix_favorites_screen.dart:109: setState(() => _future = next)]
Some tests failed.
```

O teste de widget já existente também falhou com o arquivo histórico (exit **1**):

```sh
flutter test --no-pub --reporter expanded test/heisuca/heisuca_round9_test.dart --plain-name 'puxar para atualizar'
```

```text
setState() callback argument returned a Future.
The test description was: puxar para atualizar os favoritos recarrega sem erro de setState
Some tests failed.
```

O arquivo atual foi restaurado byte a byte em `finally`; `git diff --name-only` não registra alteração em `lib/`.
Os testes positivos e o portão foram executados depois da restauração.

## Item 2 — como relança e evidências

Fontes, somente leitura: `apps/app/scripts/bancada/ui.py:103` e `:212`,
`apps/app/scripts/bancada/desastrado.py:130`, `.github/workflows/heisuca-desastrado-android.yml`.

- `abrir_app()` executa `adb shell monkey -p <pacote> -c android.intent.category.LAUNCHER 1`.
- A recuperação aceita primeiro plano + tela conhecida; caso contrário, tenta Voltar cinco vezes,
  relançar e Home + relançar. Aguarda três segundos após cada ação (e um segundo entre Home e relançar).
- Não faz force-stop nem limpa dados nesse caminho. O retorno/erro das chamadas ao launcher não fica no artefato.
- O detector consulta `dumpsys activity activities` e busca `topResumedActivity`/`mResumedActivity`
  (`desastre.py:233`). A hierarquia e `02-final.png` confirmam o launcher neste incidente.

Checkout do segundo run: `d06ade0ce44eedce54cd5ba219965cfd3d682ab3`, ramo `claude/heisuca-v2`.
O relatório registra 5.000 eventos injetados, um PID do app durante o monkey/recuperação e nenhum achado de crash
ou ANR do app. `marco_final` termina como `inicio`, pois o script sobrescreve esse campo após o roteiro de caos
(`desastrado.py:166`). Isso não desfaz o vermelho da recuperação anterior, após o monkey, comprovado pela captura
do launcher. O campo final, portanto, não demonstra que aquela tentativa de relançamento funcionou.

Evidências do `logcat-app.log`:

- `23:12:08.635`: visibilidade `true → false`.
- `23:12:09.094`: visibilidade `false → true`.
- `23:12:10.433`: `AutofillManager: onActivityFinishing()`.
- `23:12:10.519`: `ExoPlayerPlugin: Detached from activity`.

O código permite saída voluntária pelo Voltar na raiz (`main_screen.dart:1459`), que chama
`AppExitService.requestExit()` (`:1503`). No Android, o canal posta `finishAndRemoveTask()`
(`MainActivity.kt:1026`). Isso é compatível com o fechamento observado, mas não prova por que o launcher
não conseguiu reabrir. Não foi alterado.

Hipóteses, sem diagnóstico fechado:

1. **Troca de alias do ícone durante a saída/retomada.** O manifest usa `IconeIsis`, `IconeHeitor`, `IconeSumi`;
   `CgflixAppIconChannel.kt:49–59` habilita o novo antes de desabilitar os demais, com `DONT_KILL_APP`, e aplica
   ao parar a última Activity (`:80`). Há visibilidade oscilando e registro de `IconeHeitor` no caos posterior;
   o nome inicial foi saneado no artefato, portanto isso não comprova troca de alias.
   Falta o componente resolvido/retorno de cada relançamento para provar relação causal.
2. **Saída pelo Voltar e ordenação do relançamento com a tarefa encerrando.** Existe o caminho explícito acima e
   há `onActivityFinishing`; faltam os eventos do ActivityTaskManager e horários das ações de recuperação.
3. **Atraso/foco no emulador.** Há `Dropping event (no window focus)`, pressão de memória e quadros de vários
   segundos; a recuperação só aguarda três segundos por ação. O relatório e a captura provam a falha observada,
   mas não distinguem atraso do sistema de defeito persistente do aplicativo. Não foi reclassificado como verde.
4. **Falha em restauração/arranque com estado salvo.** Investigados `onCreate`, `onNewIntent`, `onResume`,
   `onStart`, `onStop`, bootstrap e manifest (`singleTop`). Nenhum `finish()` automático nesses callbacks,
   nem exceção de arranque no log disponível. Hipótese sem apoio suficiente para correção.

Para fechar a causa em execução futura, seriam necessários retorno/stdout/stderr e horário do launcher,
componente resolvido, estado dos aliases e ActivityTaskManager completo durante a recuperação.
Isso é proposta para a frente da bancada: nenhum script/workflow foi modificado aqui.

## Validação

Ambiente isolado para evitar escrita em SDK/cache compartilhados:

```sh
export PATH=/tmp/heisuca-desastrado-flutter/bin:$PATH
export PUB_CACHE=/tmp/heisuca-desastrado-pub-cache
export TMPDIR=/tmp
```

Foi preciso copiar o SDK e o cache: os originais ficam somente para leitura no sandbox. O primeiro ensaio
do Flutter também encontrou TMPDIR fora da área gravável; os comandos efetivos usam `/tmp`.
O script do portão prefixa outro SDK no PATH; uma função shell exportada `flutter()` encaminhou as invocações
para `/tmp/heisuca-desastrado-flutter/bin/flutter`, sem editar o script.

Resultados:

| Comando | Resultado |
| --- | --- |
| `dart format --output=none --set-exit-if-changed -l 120 lib/design test/design test/heisuca/set_state_sincrono_test.dart` | 36 arquivos, nenhuma alteração; exit 0. Modo de conferência para respeitar a proibição de editar `lib/design/`. |
| `flutter test --no-pub --reporter expanded test/design` | 155 aprovados; exit 0. |
| `flutter test --no-pub --reporter expanded test/heisuca` | 1.540 aprovados; exit 0. |
| `flutter analyze --no-pub test/heisuca/set_state_sincrono_test.dart` | `No issues found!`; exit 0. |
| `bash scripts/heisuca-checar.sh` | Duas execuções completas aprovadas. A última, após a prova negativa final e restauração: 181 testes Python (`OK`), 2.783 Flutter (1min44s) e 8 Impeller (31s), `APROVADO: análise e testes concluídos.`; exit 0. |

Os três casos optativos de captura visual já marcados na base como dependentes de `HEISUCA_SNAPSHOT=1`
ficaram inativos nos comandos prescritos. Não foi acrescentado nem alterado nenhum `skip`.
A análise completa final registra 42 avisos/informações em arquivos existentes, sem erros; nenhum diagnóstico
no arquivo novo. A primeira passagem tinha quatro informações de estilo no teste novo, corrigidas antes
da última prova negativa e da última execução do portão.

Logs locais completos: `/tmp/heisuca-desastrado-negativo-final.log`,
`/tmp/heisuca-desastrado-negativo-widget.log`, `/tmp/heisuca-desastrado-design.log`,
`/tmp/heisuca-desastrado-heisuca.log`, `/tmp/heisuca-desastrado-analise-guarda.log`,
`/tmp/heisuca-desastrado-portao.log`, `/tmp/heisuca-desastrado-portao-final.log`.

## Commits e restrição do ambiente

O Git deste worktree aponta para `/mnt/nvme4n1/caioguerras/TMP/heisuca-visao/.git/worktrees/heisuca-desastrado`.
O sandbox só permite escrita neste worktree e em `/tmp`; o índice compartilhado está somente para leitura.
Até `git add --dry-run` falhou ao criar `index.lock`. Nenhum metadado do outro worktree foi alterado.
A pasta externa pedida para a entrega também está fora das raízes graváveis.
A tentativa de copiar este relatório para o destino solicitado falhou com `Read-only file system`.

O relatório fica neste worktree como `ENTREGA_CODEX_DESASTRADO.md`.

Para entregar commits revisáveis apesar dessa restrição, foi criado um repositório **isolado** em
`/tmp/heisuca-desastrado-entrega.git`, com a mesma base e o mesmo nome do ramo. Ele lê os objetos da base,
mas não escreve no Git compartilhado. **O ramo original continua em 6677c9a2, sem commits novos**;
os commits desta entrega estão no bundle, e os dois arquivos novos permanecem visíveis como não rastreados
no worktree original.

- Commit de testes: **`eb7d5203c1374223152c39395729a7e3b514e021`** —
  `Adiciona guarda contra callbacks de setState que devolvem Future`.
- O commit seguinte registra este relatório; seu hash consta em `ENTREGA_CODEX_DESASTRADO.commits.txt`.
- `ENTREGA_CODEX_DESASTRADO.bundle`: commits e objetos novos, tendo `6677c9a2` como pré-requisito.
- `ENTREGA_CODEX_DESASTRADO.patch`: os mesmos dois commits em formato de revisão/aplicação.
- `ENTREGA_CODEX_DESASTRADO.commits.txt`: hashes completos e assunto dos commits.

Todos esses arquivos ficam na raiz deste worktree. O bundle pode ser conferido, sem alterar o ramo, com
`git bundle verify ENTREGA_CODEX_DESASTRADO.bundle`. A incorporação fica para o revisor em ambiente com
permissão de escrita no Git. Não foi tentado contornar o bloqueio do sandbox.

## Riscos, o que não foi feito e como desfazer

- Nenhuma nova correção no app: o único erro de setState comprovado já estava corrigido na base.
- O item 2 continua aberto e vermelho; não foi inventada causa nem afrouxado detector.
- Sem edição de `scripts/bancada/`, workflows, versão, applicationId, `lib/design/`, tokens ou outros worktrees.
- Sem push, merge, gasto, publicação, leitura de segredos ou envio por Telegram.
- A guarda acrescenta resolução de tipos à suíte Heisuca; o custo foi medido nos testes locais.
- Desfazer a entrega consiste em reverter o commit de testes quando ele for incorporado. O comportamento do app
  não muda. Os arquivos de entrega podem ser arquivados; SDK/cache/logs isolados estão em `/tmp`.
