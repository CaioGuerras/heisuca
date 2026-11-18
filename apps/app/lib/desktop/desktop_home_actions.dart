import 'desktop_preferences.dart';

/// Ações do shell preservam seletores, atalhos e histórico já existentes.
class DesktopHomeActions {
  const DesktopHomeActions({required this.openFile, required this.openUrl, required this.openLibrary,
    required this.openSettings, required this.openRecent, this.error, required this.dismissError});
  final void Function() openFile, openUrl, openLibrary, openSettings, dismissError;
  final void Function(DesktopRecentFile) openRecent;
  final String? error;
}
