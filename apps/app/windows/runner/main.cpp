#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "mpv/display_mode_manager.h"
#include "utils.h"

int APIENTRY
wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev, _In_ wchar_t* command_line, _In_ int show_command) {
  // Heisuca requires the bundled flutter-plezy engine, which presents the
  // Flutter UI on a topmost DirectComposition visual when FLUTTER_WINDOWS_DCOMP
  // is set. The mpv video window is then a plain child composed beneath the UI
  // in the same HWND: window capture (Discord/OBS) works, there is no
  // transparency hack, and min/max animations are native. Must be set before
  // the engine is created. (On a stock engine the flag is a no-op and
  // compositing breaks.)
  ::SetEnvironmentVariableW(L"FLUTTER_WINDOWS_DCOMP", L"1");

  const auto launch_arguments = GetCommandLineArguments();

  HANDLE mutex = CreateMutex(nullptr, TRUE, L"br.com.docaio.heisuca.SingleInstance");
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    const auto deadline = ::GetTickCount64() + 20000;
    while (true) {
      HWND existing = FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Heisuca");
      if (existing && IsWindowVisible(existing)) {
        if (!launch_arguments.empty()) {
          const auto& source = launch_arguments.front();
          if (!source.empty() && source.size() < 65536) {
            COPYDATASTRUCT data{};
            data.dwData = 0x48454953;  // HEIS: bounded UTF-8 source, never a command.
            data.cbData = static_cast<DWORD>(source.size() + 1);
            data.lpData = const_cast<char*>(source.c_str());
            DWORD_PTR accepted = 0;
            const auto forwarded = ::SendMessageTimeout(existing, WM_COPYDATA, 0, reinterpret_cast<LPARAM>(&data),
                SMTO_ABORTIFHUNG | SMTO_BLOCK, 2000, &accepted);
            if (!forwarded || accepted != TRUE) {
              if (mutex) CloseHandle(mutex);
              return EXIT_FAILURE;
            }
          }
        }
        ShowWindow(existing, SW_RESTORE);
        SetForegroundWindow(existing);
        if (mutex) {
          CloseHandle(mutex);
        }
        return EXIT_SUCCESS;
      }
      const DWORD wait = mutex ? WaitForSingleObject(mutex, 100) : WAIT_FAILED;
      if (wait == WAIT_OBJECT_0 || wait == WAIT_ABANDONED) break;
      if (wait == WAIT_FAILED || ::GetTickCount64() >= deadline) {
        if (mutex) CloseHandle(mutex);
        return EXIT_FAILURE;
      }
    }
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM for Win32 libraries and plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");
  project.set_ui_thread_policy(flutter::UIThreadPolicy::RunOnSeparateThread);

  // Keep rendering with Skia. Flutter 3.47 made Impeller the default Windows
  // renderer, but the DirectComposition presentation above is only correct
  // when the frame's per-pixel alpha is exact: DWM blends the UI visual over
  // the mpv video child, so a frame that presents opaque where it should be
  // translucent hides the video outright. Impeller's GLES backend gets that
  // alpha wrong on some drivers - the video area went black for as long as
  // the player OSD was on screen (#2127). Every release up to 2.17.0 rendered
  // with Skia; keep it until Impeller composites the alpha correctly.
  project.set_impeller_switch(flutter::ImpellerSwitch::Disabled);

  std::vector<std::string> command_line_arguments = GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Heisuca", origin, size)) {
    ::CoUninitialize();
    if (mutex) {
      CloseHandle(mutex);
    }
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  // Recover display mode if a prior crash left it changed.
  mpv::DisplayModeManager::RecoverIfNeeded();

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }
  // Required app exit posts WM_QUIT without destroying the window. Tear down
  // the controller and plugins while COM is still initialized.
  window.Destroy();

  ::CoUninitialize();
  if (mutex) {
    CloseHandle(mutex);
  }
  return EXIT_SUCCESS;
}
