# Movimento do celular — 08/11/2026

Ramo: `claude/heisuca-android-movimento`. Alterações locais; sem push.
Commit solicitado **bloqueado pelo sandbox**: `git add` não conseguiu criar
`/mnt/nvme4n1/caioguerras/heisuca/.git/worktrees/heisuca-android-mov/index.lock`
(`Read-only file system`). Nenhum commit foi criado, nem arquivo staged.
Mensagem preparada em `/tmp/heisuca-movimento-commit.txt`.

## Alterações

Tokens de duração, curvas, molas e escada no `HeisucaMotion`. Abas com entrada
320 ms após 60 ms e saída 180 ms; preservam estado e bloqueio de toque
nas abas ocultas. Opacidade usa `padrao`, sem mola nem escala nas abas.
Folhas do celular usam `folhaCelular`; uma rota nativa específica mantém a
folha no destino e aplica só fade no modo reduzido. Menus, abertura, hero,
interações, ajustes e fluxo infantil usam os tokens e respeitam o modo reduzido.
Imagens recebem fade de 200 ms (`padrao`), ou 180 ms com movimento reduzido.
A API opcional de curva da imagem mantém o comportamento dos consumidores antigos.
Nenhum texto novo na interface.

## Fora do escopo

- Árvore `lib/heisuca/tv/`: nenhum arquivo alterado. `duration`, `curve`,
  `sheetStyle` e `durationFor` antigos preservados. Usos compartilhados da
  abertura e dos controles mantêm o caminho anterior na TV.
- Timers de rede, debounce, espera de preload, reprodução e durações longas
  das aberturas: preservados. Só a variante reduzida passa a fade de 180 ms.
- Física de rolagem e encaixe: preservada; rege a inércia do gesto.
- Tokens gerados sem consumidores em `theme/heisuca_base.dart`: preservados;
  não são animações de interface ativas e incluem contratos da TV.
- Versão e distribuição: sem APK gerado, sem alteração de versão ou push.

## Verificação e limites

`git diff --check` e `bash -n apps/app/scripts/heisuca-checar.sh`: passaram.
Conferência estática por Python: tokens legados e corpo de `sheetStyle`
idênticos ao HEAD anterior; nenhuma alteração na árvore TV.
Teste novo de tokens, molas, proteção da TV e folha reduzida incluído no
portão `heisuca-checar.sh`. Testes antigos de abas e abertura atualizados para
o fade reduzido e a ausência de escala.

Flutter e Dart indisponíveis neste ambiente: analyze, testes e compilação
**não executados**. CI aguarda envio posterior por outro responsável.
**Não testado em aparelho.** Revisão independente pendente.

## Como desfazer

Após criar o commit desta tarefa, revertê-lo com `git revert <hash>`. Nenhuma mudança externa foi realizada.

## Arquivos alterados

- `apps/app/lib/heisuca/heisuca_context_menu.dart`
- `apps/app/lib/heisuca/heisuca_design_system.dart`
- `apps/app/lib/heisuca/heisuca_device_status.dart`
- `apps/app/lib/heisuca/heisuca_floating_island.dart`
- `apps/app/lib/heisuca/heisuca_hero.dart`
- `apps/app/lib/heisuca/heisuca_home_screen.dart`
- `apps/app/lib/heisuca/heisuca_login_screen.dart`
- `apps/app/lib/heisuca/heisuca_motion.dart`
- `apps/app/lib/heisuca/heisuca_opening_splash.dart`
- `apps/app/lib/heisuca/heisuca_seerr_sheet.dart`
- `apps/app/lib/heisuca/heisuca_settings_screen.dart`
- `apps/app/lib/heisuca/heisuca_source_scope.dart`
- `apps/app/lib/heisuca/heisuca_title_sheet.dart`
- `apps/app/lib/heisuca/kids/heisuca_kids_flow.dart`
- `apps/app/lib/heisuca/kids/heisuca_kids_opening.dart`
- `apps/app/lib/heisuca/player/heisuca_series_episodes.dart`
- `apps/app/lib/widgets/optimized_media_image.dart`
- `apps/app/scripts/heisuca-checar.sh`
- `apps/app/test/heisuca/heisuca_motion_test.dart`
- `apps/app/test/heisuca/heisuca_opening_brand_test.dart`
- `apps/app/test/heisuca_motion_tokens_test.dart`
