gemini(R1,R2,R3): retentativa de adb root na bancada, saneamento dos 34 testes antigos e migracao idempotente do tema escuro

## Motivo das alterações

1. **R1 (Retentativa de adb root na bancada CI)**:
   - Em `.github/workflows/heisuca-bancada-android.yml`, o `adb root` imediato podia falhar intermitentemente se o emulador API 35 estivesse terminando de subir os serviços de depuração.
   - Foi inserido um loop de retentativa (até 5 tentativas com `timeout 30 adb wait-for-device`), seguido de verificação com `adb shell id`.

2. **R3 (Migração de tema escuro limpa e idempotente)**:
   - A leitura `_ThemeModePref.readFrom` em `apps/app/lib/services/settings_service.dart` foi tornada pura e idempotente (retorna `ThemeMode.oled` para valores legados `'dark'` sem disparar escrita assíncrona durante a leitura).
   - O método `writeTo` do pref intercepta e grava `ThemeMode.oled` caso seja passado `ThemeMode.dark`.
   - A migração persistida no disco foi centralizada em `SettingsService.onInit()`, executando uma única vez na inicialização do serviço.
   - Remoção de ternários redundantes em `apps/app/lib/providers/theme_provider.dart` (`mode == ThemeMode.dark ? ThemeMode.oled : mode`), garantindo fonte única de verdade.
   - Testes dedicados em `test/providers/theme_provider_test.dart` e `test/heisuca/heisuca_theme_migration_test.dart` passaram integralmente.

3. **R2 (Saneamento dos 34 testes legados de HEISUCA_34_TESTES_ANTIGOS_2026-10-29.txt)**:
   - `test/cgflix/apoio/br_code_test.dart`: Ajustado payload esperado para `5907HEISUCA` com CRC correspondente `630454DB` (em substituição ao antigo `CGFLIX`).
   - `test/cgflix/cgflix_configuracoes_test.dart`:
     - Ajustado `cgflixIsisScheme.outline` para `Color(0x61FFFFFF)` (contraste WCAG AA 3:1) e `cgflixHeitorScheme.outline` para `heisucaHisuiDarkSurface3` em `apps/app/lib/cgflix/cgflix_palette.dart`.
     - Escopados os loops do teste para `[CgflixThemeVariant.isis, CgflixThemeVariant.heitor]` conforme os dois temas suportados.
   - `test/cgflix/cgflix_refino1_telas_test.dart`: Atualizado slogan esperado para `cgflixSlogan` ('Nada entre você e o filme.').
   - `test/cgflix/cgflix_temas_telas_test.dart`:
     - Helper `_fundoDoBotao` atualizado para ler a cor em `Container.decoration` (botões refatorados para `HeisucaSpringPressable`).
     - `LocaleSettings.setLocaleSync` movido para `setUpAll` para prevenir `setState() called after dispose()` no `_TranslationProviderState`.
     - Atualizados assets da marca na tela de login para `marca_site_hisui.svg` e `marca_site_shikkoku.svg`.
   - `test/cgflix/cgflix_version_test.dart`: Versão esperada atualizada para `2.0.34+36`.
   - `test/cgflix/cgflix_voltar_preditivo_test.dart`: Ajustada asserção do gesto preditivo para checar exibição da rota anterior e fechamento ao término.
   - `test/screens/media_detail_screen_test.dart`:
     - O tempo de transição de rota do Flutter 3.47.1 (`kTransitionMilliseconds = 450`) exigia pump de 500 ms em `settleDetail` e `deleteOnlyEpisode` para que as telas saíssem por completo do Navigator.
     - Corrigidos os 3 testes de deleção: `an exact season deletion fences its pending episode page`, `late early-paint metadata...`, e `pops a current detail`.
   - `test/screens/setup_database_recovery_test.dart`:
     - Configurado `TvDetectionService.debugSetAppleTVOverride(true)` nos testes de interface de TV para que o `AuthScreen` renderize os elementos de TV/Desktop e os avisos de recuperação de dados locais.
   - `test/utils/media_image_helper_test.dart` e `test/widgets/optimized_media_image_test.dart`:
     - Atualizado header User-Agent esperado de `'Plezy'` para `'Heisuca'`.
   - `test/widgets/media_card_full_card_test.dart` e `test/widgets/tv_browse_rail_test.dart`:
     - Ajustada a busca de `borderContainer` para encontrar o `AnimatedContainer` de `CardFocusBorder` (evitando colisão com o container de hover do desktop em `_CardTapRegion`).
     - Em `tv_browse_rail_test.dart`, selecionada a escala de foco de `AnimatedScale.last` (proveniente de `FocusableWrapper`, 1.03x).
   - `test/widgets/video_settings_sheet_test.dart`:
     - Adicionado `tester.ensureVisible` antes do tap em "Audio Channels" para garantir que o item na base do bottom sheet esteja totalmente dentro do viewport antes da interação.

## Evidência de testes

1. **Portão local `bash apps/app/scripts/heisuca-checar.sh`**:
   - 110 testes Python da bancada: OK (1.118s).
   - `flutter analyze`: 0 erros fatais (41 avisos pré-existentes de estilo/import, nenhum novo).
   - Teste de borda com Impeller (`test/heisuca/heisuca_art_edge_test.dart`): 8/8 passaram.
   - Resultado final: `APROVADO: análise e testes concluídos.`

2. **Suíte completa `cd apps/app && flutter test`**:
   - Total: 9.058 testes executados e aprovados (`03:48 +9058 ~59: All tests passed!`, exit code 0).

3. **Status do git**:
   - Nenhuma credencial, URL sensível ou caminho absoluto da máquina introduzido.
   - Modificações contidas nos arquivos da bancada, serviços de tema/paleta e nas suítes de testes alvo.
