# Validacao do Heisuca Desktop (Windows)

## Escopo e arquitetura verificada no codigo
- **Target inicial**: Windows x64 (`windows-latest`), Flutter `3.47.1` (Dart >= 3.12), entrypoint `apps/app/lib/main_desktop.dart`.
- **Engine DirectComposition**: `apps/app/windows/runner/main.cpp` define `FLUTTER_WINDOWS_DCOMP=1` e desabilita Impeller (`ImpellerSwitch::Disabled`, mantendo Skia) para compor o video do `libmpv` sob a UI Flutter sem falha de alpha.
- **Instalacao da engine**: `apps/app/windows/tool/install-patched-engine.ps1` valida `engine.stamp == 5d531788691ec3404cac0cee66ead4007b177363` e SHA-256 `5f3148f48c4974f32d51c9a883ebfaf332b076451cad8849d21a7251d6ff3321` antes de extrair `flutter-plezy-windows-3.47.1.zip`.
- **Dependencias nativas**: `apps/app/windows/CMakeLists.txt` usa `apps/app/mpv-build.lock.json` (`libmpv-2.dll`), Vulkan Runtime `1.4.357.0` (`vulkan-1.dll` + `VulkanRT-License.txt`), `simdutf` `v6.4.2` e `InstallRequiredSystemLibraries` (`msvcp140.dll`, `vcruntime140.dll`).
- **Branding Heisuca**: `BINARY_NAME` e `project(...)` definidos como `heisuca` (`heisuca.exe`); `main.cpp` usa mutex `br.com.docaio.heisuca.SingleInstance` e janela `L"Heisuca"` (incluindo `FindWindow`); `Runner.rc` usa metadados `Heisuca` / `heisuca.exe` com atribuicao GPL-3.0 baseada no Plezy.

## Workflow de CI (`.github/workflows/heisuca-desktop-windows.yml`)
- Dispara em `push` apenas no ramo `gemini/heisuca-desktop-windows` (com filtro de `paths` desktop/Windows/workflow) e em `workflow_dispatch`.
- `permissions: contents: read`, `timeout-minutes: 45`, `runs-on: windows-latest`, `working-directory: apps/app`.
- Sem secrets de assinatura, sem WinSparkle/updater, sem telemetria/Sentry, sem release/publicacao automatica e sem acionar workflows Android.
- **Ordem critica da engine**:
  1. `flutter pub get --no-example`
  2. `flutter analyze` nos alvos desktop (`lib/main_desktop.dart` e, quando presentes, `lib/desktop`, `test/desktop`)
  3. `flutter test --no-pub test/desktop` (quando houver `*_test.dart`, evitando testes de widget que invoquem `FilePicker` ou plugins reais sem mock)
  4. `flutter precache --windows` seguido de `.\windows\tool\install-patched-engine.ps1`
  5. `flutter build windows --release -t lib/main_desktop.dart` (nunca executar `flutter precache --force` ou `flutter upgrade` apos o patch, pois restauram a engine oficial silenciosamente)
- Verifica presenca de `heisuca.exe`, `flutter_windows.dll`, `libmpv-2.dll`, `vulkan-1.dll`, `VulkanRT-License.txt`, `msvcp140.dll`, `vcruntime140.dll`, `data/app.so`, `data/icudtl.dat` e ausencia de `.lib`/`.exp`/`.pdb`.
- Copia `LICENSE`/`COPYING` (GPL) e atribuicoes (`licenses/ATRIBUICOES_HEISUCA.txt`) para o bundle, gera `dist/heisuca-windows-x64.zip` + `.sha256` e publica apenas como artifact (`heisuca-desktop-windows-x64`).

## Pendencias explicitas (NAO validadas pelo CI)
1. **Teste real de playback (PENDENTE)**: o CI atual NAO executa reproducao real de midia nem valida frame renderizado ou relogio avancando. Reproduzir video local e stream HTTP(S) em maquina Windows real (confirmando composicao DComp do video sob o OSD Flutter e captura de janela sem tela preta).
2. **SingleInstance com encaminhamento de argumentos via IPC (PENDENTE)**: o runner preserva apenas `FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Heisuca")` para restaurar e focar a janela ja aberta. Abrir um segundo arquivo/URL com o app ja em execucao nao encaminha `argv` para a instancia ativa (requer implementacao futura de IPC, ex.: `WM_COPYDATA` ou named pipe).
3. **Matriz de exibicao e audio (NAO CERTIFICADA)**: escala DPI 100%, 125% e 150%, multimonitor (incluindo fullscreen nativo), HDR10 e passthrough HDMI permanecem sem verificacao ate teste manual dedicado.
4. **Distribuicao e seguranca de release (FORA DE ESCOPO ATUAL)**: sem assinatura Authenticode, sem empacotamento Microsoft Store e sem auto-atualizador ativo (`EdDSAPub` em `Runner.rc` permanece inalterado da base upstream).
5. **Residuos de registro/canal em `flutter_window.cpp` (OBSERVADO NO CONTEXTO)**: `apps/app/windows/runner/flutter_window.cpp` ainda usa `Software\\Plezy` e canal `plezy/window` — mantido fora desta alteracao para nao quebrar o codigo Dart existente.

## Checklist de validacao manual no Windows
1. Baixar o artifact `heisuca-desktop-windows-x64` do GitHub Actions e conferir o hash em `heisuca-windows-x64.zip.sha256` (`certutil -hashfile heisuca-windows-x64.zip SHA256`).
2. Extrair em caminho com espacos e acentuacao (ex.: `C:\Temp\Teste Heisuca açao\`) e confirmar presenca de `heisuca.exe`, `libmpv-2.dll`, `vulkan-1.dll`, `VulkanRT-License.txt`, `LICENSE*` e `licenses\ATRIBUICOES_HEISUCA.txt`.
3. Executar `heisuca.exe` sem login e sem rede: verificar abertura offline, titulo `Heisuca`, carregamento de arquivo local e comportamento de foco ao abrir segunda vez.
4. Testar seek, volume, troca de faixas de audio/legenda, legenda externa `.srt`/`.ass`, caminho invalido (sem loading infinito) e fechamento limpo do processo.
