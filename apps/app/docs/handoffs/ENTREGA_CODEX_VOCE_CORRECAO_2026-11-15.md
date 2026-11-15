# Entrega — correções da tela Você, 15/11/2026

Pedido executado: `~/cgflix/handoffs/PROMPT_CODEX_VOCE_CORRECAO_2026-11-15.md`.
Worktree: `/mnt/nvme4n1/caioguerras/TMP/heisuca-voce`.
Ramo mantido: `claude/heisuca-v2-voce`; base `f84ef15d`.
**Não testado em aparelho. Sem commit, push ou publicação.** O revisor deve conferir e commitar.

Relatório no caminho alternativo autorizado pelo Caio: `~/cgflix` está fora das raízes de escrita do sandbox. Nenhuma tentativa de contornar essa restrição.

## Correções

- `apps/app/lib/features/voce/ligacao.dart`: servidor observado com `context.watch<MultiServerProvider?>()`, mantendo a substituição `cgflixUserMenuDebugOnline` e o comportamento sem provider. Queda e retorno atualizam Minha conta e Meus pedidos com a tela aberta.
- A mesma ligação observa `context.watch<HeisucaKids?>()` e usa essa instância para identificar o modo infantil e o perfil do responsável. Recorre ao singleton somente sem provider.
- `aoVoltar` fica nulo quando `Navigator.of(context).canPop()` é falso.
- `apps/app/lib/features/voce/tela_voce.dart` e ligação: folga inferior = `Forma.espaco6` (24). Topo = `Forma.toqueMinimo + Forma.espaco6` (72); avatar = `Forma.toqueMinimo + Forma.espaco4` (64). Medidas preservadas, derivadas dos tokens existentes; sem alteração na Fundação.
- `apps/app/test/heisuca/voce_v2_test.dart`: fixtures usam Ana; tamanho 412 × 915; cartões inferiores alcançados por `scrollUntilVisible`. Os três temas percorrem todos os cartões até Sair com letra 200 %, verificando ausência de overflow e dimensões de toque >= 48 em altura e largura. Também verificam cabeçalho visível e botão Voltar >= 48.
- Cobertura adicional: queda/retorno do servidor sem reconstrução externa; ausência de provider; perfil infantil criado no provider com tela aberta; gravação real do registro infantil local com tela aberta; fallback ao singleton; Voltar ausente na raiz e funcional em rota empilhada. Mantidas as verificações de ações, confirmação de saída, semântica, teclado e remoção de animações.

## Evidência antes e depois

Antes de corrigir os arquivos de produção, a suíte adaptada reproduziu exatamente três falhas: servidor cai e volta, perfil infantil criado no provider e Voltar na raiz. Resultado: `+21 -3: Some tests failed.` Log: `/tmp/voce_antes.log`.

Após a correção e a inclusão do teste de gravação do registro local: `+25: All tests passed!`, rc=0. Log: `/tmp/voce_depois.log`.

## Ambiente e comandos

O SDK solicitado (`/mnt/nvme4n1/caioguerras/TMP/flutter-sdk/flutter`) falhou ao gravar `bin/cache/engine.stamp.tmp.15` e `engine.realm` com `Read-only file system`. Foi copiado, sem alterar a origem, para `/tmp/flutter-voce-correcao`. Todas as validações usaram essa cópia e `TMPDIR=/tmp`. A resolução de dependências não alterou arquivos versionados. `--no-pub` evita repetir essa resolução.

Comandos executados em `apps/app`:

```sh
TMPDIR=/tmp /tmp/flutter-voce-correcao/bin/dart format -l 120 lib/features/voce test/heisuca/voce_v2_test.dart
TMPDIR=/tmp /tmp/flutter-voce-correcao/bin/flutter analyze --no-pub lib/features/voce test/heisuca/voce_v2_test.dart test/features/casca
TMPDIR=/tmp /tmp/flutter-voce-correcao/bin/flutter test --no-pub test/heisuca/voce_v2_test.dart --reporter expanded
TMPDIR=/tmp /tmp/flutter-voce-correcao/bin/flutter test --no-pub test/design test/heisuca test/features/casca --reporter expanded
```

Formatação final conferida com `--output=none --set-exit-if-changed`: `Formatted 3 files (0 changed)`, rc=0. `git diff --check`: rc=0.

Últimas linhas da análise (`/tmp/voce_analyze.log`, rc=0):

```text
Analyzing 3 items...
No issues found! (ran in 27.9s)
```

Últimas linhas dos testes direcionados (`/tmp/voce_depois.log`, rc=0):

```text
00:03 +23: acessibilidade com "remover animações" tudo continua funcionando
00:03 +24: tela pura grupo vazio não aparece e nome vazio vira "Você"
00:03 +25: All tests passed!
```

Últimas linhas da suíte solicitada (`/tmp/voce_suite.log`, rc=0):

```text
01:41 +1678 ~3: /mnt/nvme4n1/caioguerras/TMP/heisuca-voce/apps/app/test/heisuca/heisuca_p3_matrix_test.dart: (tearDownAll)
01:41 +1678 ~3: All tests passed!
```

**1.678 testes passaram; zero falhas.** Os três testes de captura condicionados a `HEISUCA_SNAPSHOT=1` já estavam desabilitados por padrão (`heisuca_kids_test.dart`, `heisuca_player_hud_test.dart`, `heisuca_title_seasons_real_test.dart`); nenhum skip foi criado ou alterado nesta entrega. Todos os 25 testes da Você executaram e passaram.

## Escopo e como desfazer

Somente os três arquivos de código/teste acima e este relatório foram alterados/criados. Não houve edição em `lib/design/`, `docs/marca_2026-11-09/`, applicationIds ou `integration_test/bancada_android_test.dart`. Não houve mudança de versão, build de APK, serviço, segredo ou envio externo. Os logs que já estavam soltos na raiz (`falhas.log`, `portao_voce.log`, `teste_final.log`) foram preservados.

Para desfazer, após preservar uma cópia do diff, restaurar os três arquivos de código/teste a partir de `f84ef15d` (por exemplo, `git restore --source=f84ef15d -- <os três caminhos acima>`). Preservar este relatório como histórico; nada precisa ser apagado.
