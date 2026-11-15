# Entrega — Baixados V2 — 15/11/2026

Ramo: `claude/heisuca-v2-baixados`. Base: `0dca15c7`.
Implementado localmente, sem push, APK ou publicação. Não testado em aparelho.
A revisão independente continua pendente.

## O que foi feito

- Tela pura `TelaBaixados`, com dados e callbacks em modelos próprios, sem providers ou rede.
- Agrupamento por série e servidor; filmes separados. Pôster local, título, contagem de episódios e bytes baixados.
- Total de bytes baixados pelo app, incluindo downloads de outros perfis, pelo snapshot público do provider.
- Progresso, espera, pausa, retomada de pausados e tentativa de novo após falha, pelas operações existentes.
- Reprodução das cópias baixadas pelo fluxo de reprodução existente.
- “Apagar vistos” remove apenas episódios completos e vistos do grupo.
- “Manter 1/3/5” guarda a preferência por perfil + servidor + série via `SettingsService` e seu cache compartilhado de preferências.
  Preserva os primeiros N episódios não vistos em ordem de temporada/episódio; remove os completos além desse limite e os vistos.
  Downloads incompletos contam na ordem, mas não são cancelados pela limpeza.
  Reaplica a regra ao montar a ligação e quando o provider notifica enquanto a tela está montada.
- Operações em série param ao trocar perfil; callbacks de uma tela anterior também são recusados.
- Lista vazia com ação Explorar, ligada à aba de bibliotecas da casca.
- Aba Baixados usa a ligação nova quando `cgflixUseYouTab` está ativo; mantém o acesso ao perfil no cabeçalho.
- Fundo tingido, tokens e componentes de toque existentes. Layout rolável e ações em quebra de linha para letra grande.

## Arquivos

- `apps/app/lib/features/baixados/modelo.dart`
- `apps/app/lib/features/baixados/tela_baixados.dart`
- `apps/app/lib/features/baixados/ligacao.dart`
- `apps/app/lib/screens/main_screen.dart`
- `apps/app/test/heisuca/baixados_v2_test.dart`
- Este relatório.

Nenhuma alteração em `lib/design/`, `test/design/`, marca, applicationId, downloader ou pacotes.
Nenhuma versão foi incrementada: não foi gerado APK.

## Validação

O SDK solicitado está em área somente para leitura e seu inicializador tentou criar
`bin/cache/engine.stamp.tmp.*`. Foi copiado sem alteração de versão para `/tmp/heisuca-baixados-flutter`.
O cache de pacotes existente também foi copiado para `/tmp/heisuca-baixados-pub-cache`;
`TMPDIR=/tmp` evita a pasta temporária padrão protegida. Não houve atualização de dependências.

No diretório `apps/app`, ambiente usado:

```sh
export PATH=/tmp/heisuca-baixados-flutter/bin:$PATH
export PUB_CACHE=/tmp/heisuca-baixados-pub-cache
export TMPDIR=/tmp
dart format -l 120 lib/features/baixados test/heisuca/baixados_v2_test.dart
flutter analyze lib/features/baixados test/heisuca/baixados_v2_test.dart
flutter test test/heisuca/baixados_v2_test.dart --reporter expanded
flutter test test/design test/heisuca --reporter expanded
```

Saídas já concluídas:

```text
$ dart format -l 120 lib/features/baixados test/heisuca/baixados_v2_test.dart
Formatted 4 files (0 changed) in 0.03 seconds.

$ flutter analyze lib/features/baixados test/heisuca/baixados_v2_test.dart
Analyzing 2 items...
No issues found! (ran in 26.2s)

$ flutter test test/heisuca/baixados_v2_test.dart --reporter expanded
00:02 +18: manter N preserva baixa em andamento e usa sua posição na fila
00:02 +19: séries agrupam por servidor; filmes e metadados ausentes ficam separados
00:02 +20: All tests passed!
```

Também passou a análise incluindo `lib/screens/main_screen.dart`, sem apontamentos.
Execução final da suíte completa (código final, processo terminou com saída 0):

```text
$ flutter test test/design test/heisuca --reporter expanded
01:41 +1656 ~3: …/test/heisuca/heisuca_p3_matrix_test.dart: (tearDownAll)
01:41 +1656 ~3: All tests passed!
```

Logs completos desta sessão: `/tmp/baixados-format.log`, `/tmp/baixados-analyze.log`,
`/tmp/baixados-focused.log` e `/tmp/baixados-suite-final.log`. `git diff --check` sem apontamentos.
Os três skips existentes são capturas condicionais de abertura infantil, ficha e HUD (`HEISUCA_SNAPSHOT=1`);
nenhum teste foi apagado, alterado ou pulado por esta implementação.

## Limites e pendências

- O total é o volume de downloads registrado pelo downloader, não uma medição de todos os dados do aplicativo pelo Android
  (banco, cache e imagens). A interface o identifica como “em baixados no app”.
- A regra de retenção atua sobre episódios que já estão na fila/baixados. Não busca nem baixa episódios novos automaticamente,
  não instala tarefa em segundo plano e não substitui as regras de sincronização existentes.
- Testes da ligação usam providers controlados; não comprovam transferências, permissões SAF ou reprodução em aparelho.
- Sem comparação visual em aparelho e sem homologação de Caio. Outra IA deve revisar antes de publicação.
- Commits locais impedidos pelo isolamento do ambiente: `.git` aponta para
  `/mnt/nvme4n1/caioguerras/TMP/heisuca-visao/.git/worktrees/heisuca-baixados`, que está somente para leitura.
  Tentativa de `git add` devolveu:
  `fatal: Unable to create '…/index.lock': Read-only file system`.
  Não foi criado outro ramo nem repositório para contornar a proteção.
- O destino solicitado `/mnt/nvme4n1/caioguerras/cgflix/handoffs/` também fica fora das áreas graváveis;
  este arquivo é a cópia de entrega dentro do repositório. A tentativa de copiar para o destino devolveu
  `cp: cannot create regular file '…/ENTREGA_CODEX_BAIXADOS_2026-11-15.md': Read-only file system`.

## Registrar depois da revisão, em ambiente com escrita no Git

Separação sugerida dos commits locais, ambos com autor `CGSERVER Bot <cguerras1001@gmail.com>`:

1. `Baixados V2: tela, regras por série e testes` — pasta da feature e teste novo.
2. `Casca V2: abrir Baixados pela barra flutuante` — `main_screen.dart` e este relatório.

Copiar este relatório para o destino solicitado antes de encerrar a revisão.
Não fazer push ou publicação sem nova instrução de Caio.

## Como desfazer

Antes de desfazer, preservar estes arquivos e o diff em uma pasta de obsoletos autorizada.
Restaurar somente a importação e o caso `NavigationTabId.downloads` de `main_screen.dart` a partir de `0dca15c7`;
mover a pasta nova e o teste novo para o arquivo de obsoletos. Não usar limpeza global do worktree.
As preferências `heisuca_v2_baixados_manter:*` ficam sem consumidor se a feature for retirada;
não alteram as preferências legadas nem as regras de sincronização.

## Correção

Solicitação: `PROMPT_CODEX_BAIXADOS_CORRECAO_2026-11-15.md`, sobre `5c5085a4`,
no mesmo ramo `claude/heisuca-v2-baixados`. Esta seção substitui o comportamento de retenção
registrado na primeira entrega: downloads incompletos não contam em N e não vistos nunca
são apagados automaticamente.

- Limpeza automática usa apenas episódios completos e vistos de grupos com regra ligada.
  N só conta episódios completos e não vistos, em ordem de temporada/episódio.
- Ao tocar em Manter 1/3/5, o diálogo informa quantos não vistos seriam apagados e oferece
  Cancelar/Apagar. A confirmação autoriza somente as chaves contadas naquele momento;
  downloads que chegam depois ficam preservados. Cancelar preserva os não vistos;
  a escolha de limpeza de vistos permanece salva.
- A ligação usa `DownloadProvider.downloads`, que já filtra por propriedade do perfil ativo
  (`_ownedDownloadKeys`). Reconfere pertencimento, conclusão e estado de visto antes de
  cada exclusão. Troca de perfil invalida callbacks e confirmações pendentes.
  `deleteDownload` já preserva a cópia física quando há outros donos.
- “Não limpar” remove a preferência por perfil/série, com seleção visual e semântica.
- Filmes e episódios têm “Apagar”, com confirmação, usando `deleteDownload` existente.
- Nome do grupo vem de `grandparentTitle` ou dos metadados da série; sem esse nome, usa
  “Série baixada”, sem promover o título de um episódio a nome da série.
- Episódios apresentados em ordem de temporada/episódio; carregamento esconde os grupos;
  pôster tem semântica de imagem com título; folga inferior usa `Casca.reserva`.
- Diálogo com `Botao`, tema V2 e tokens existentes. Nada alterado na Fundação ou no downloader.

### Provas e validação

Antes da correção, os dois testes ajustados falharam no código anterior (saída 1):

```text
manter N conta somente completos não vistos [E]
Expected: ['casa:1-3']
  Actual: ['casa:1-2', 'casa:1-3']
Some tests failed.
Failing tests:
  ...: Manter N pede confirmação; remontar nunca apaga não vistos
  ...: manter N conta somente completos não vistos
```

No log anterior o primeiro teste ainda tinha o nome histórico
“ligação grava Manter N e reaplica depois de remontar a tela”.
Evidência: `/tmp/baixados-correcao-antes.log`.

Os testes cobrem cancelar/confirmar, novas notificações, remontagem, limpeza de vistos,
desativação com remoção real da preferência, exclusão avulsa de filme e episódio,
troca de perfil durante confirmação, nome/ordem pela ligação real, carregamento,
semântica do pôster e rolagem até o filme e sua última ação com letra em 200%.
O teste de propriedade usa o provider real, banco em memória e estado de download
injetado: trocar para um perfil com regra não remove o download do anterior.
Não comprova transferência ou exclusão de arquivo real.

Ambiente: `/tmp/heisuca-baixados-flutter`,
`PUB_CACHE=/tmp/heisuca-baixados-pub-cache`, `TMPDIR=/tmp`.
Comandos no diretório `apps/app`, todos concluídos com saída 0:

```text
$ dart format -l 120 lib/features/baixados test/heisuca/baixados_v2_test.dart
Formatted apps/app/lib/features/baixados/ligacao.dart
Formatted 4 files (1 changed) in 0.04 seconds.

$ flutter analyze lib/features/baixados lib/screens/main_screen.dart test/heisuca/baixados_v2_test.dart
Analyzing 3 items...
No issues found! (ran in 27.4s)

$ flutter test test/design test/heisuca --reporter expanded
01:46 +1663 ~3: /mnt/nvme4n1/caioguerras/TMP/heisuca-baixados/apps/app/test/heisuca/heisuca_p3_matrix_test.dart: (tearDownAll)
01:46 +1663 ~3: All tests passed!
```

Suíte final: 1663 testes passaram; 3 skips preexistentes, sem novos skips.
Logs: `/tmp/baixados-correcao-format.log`, `/tmp/baixados-correcao-analyze-final.log`
e `/tmp/baixados-correcao-suite.log`. `git diff --check` sem apontamentos.
Os 27 testes de Baixados também passaram dentro da suíte completa com o código final.

### Entrega e limites

Arquivos alterados: `lib/features/baixados/{ligacao,modelo,tela_baixados}.dart`,
`test/heisuca/baixados_v2_test.dart` (em `apps/app/`) e este relatório.
Sem alteração em `main_screen.dart`, versão, applicationId, Fundação ou downloader.
Sem push, APK ou publicação. **Não testado em aparelho.** Revisão independente pendente.

O Git deste worktree aponta para área somente para leitura; não é possível gravar
`index.lock` nem criar os commits locais pedidos. Mudanças preservadas no worktree.
A cópia do relatório em `cgflix/handoffs/` e o marcador global de andamento também
ficam fora das áreas graváveis; a entrega atual é este arquivo no repositório.
Não houve pedido de ampliação de permissão nem contorno do isolamento.

### Como desfazer a correção

O diff do código está preservado em `/tmp/baixados-correcao-2026-11-15.patch`.
Para desfazer em ambiente autorizado, primeiro guardar cópia dos quatro arquivos alterados
e deste relatório; então restaurar somente esses quatro arquivos a partir de `5c5085a4`.
**Essa reversão reintroduz o comportamento de perda de dados reprovado na revisão.**
Não requer alterar regras do downloader, serviços, versão ou dados dos perfis.
