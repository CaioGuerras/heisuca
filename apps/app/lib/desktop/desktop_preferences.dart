import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

const _maxBytes = 256 * 1024;
const _maxTime = 365 * 24 * 60 * 60 * 1000;
const _themes = {'system', 'shikkoku', 'hisui', 'sumi'};

@immutable
class DesktopRecentFile {
  const DesktopRecentFile({required this.uri, required this.title,
    required this.positionMs, required this.durationMs});
  final String uri, title;
  final int positionMs, durationMs;
  int get resumePositionMs => durationMs <= 0 || positionMs >= durationMs * .95 ? 0 : positionMs;
  Map<String, Object> toJson() => {'uri': uri, 'title': title, 'positionMs': positionMs, 'durationMs': durationMs};

  static DesktopRecentFile? parse(Object? raw) {
    if (raw is! Map || raw['uri'] is! String || raw['title'] is! String) return null;
    try {
    final source = raw['uri'] as String;
    final uri = Uri.tryParse(source);
    if (source.length > 8192 || uri == null || uri.scheme != 'file' || !uri.hasAbsolutePath ||
        uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment ||
        RegExp(r'^file://[^/]*@', caseSensitive: false).hasMatch(source) ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(Uri.decodeComponent(uri.path))) {
      return null;
    }
    final title = raw['title'] as String;
    if (title.isEmpty || title.length > 200 || RegExp(r'[\x00-\x1f\x7f]').hasMatch(title)) return null;
    final duration = raw['durationMs'] is int ? (raw['durationMs'] as int).clamp(0, _maxTime) : 0;
    final position = raw['positionMs'] is int
        ? (raw['positionMs'] as int).clamp(0, duration > 0 ? duration : _maxTime) : 0;
    return DesktopRecentFile(uri: uri.toString(), title: title, positionMs: position, durationMs: duration);
    } on Object { return null; }
  }
}

/// Only appearance and local file history. Remote URLs/tokens never enter this store.
class DesktopPreferences extends ChangeNotifier {
  DesktopPreferences({Future<File> Function()? file}) : _file = file; // ignore: prefer_initializing_formals
  final Future<File> Function()? _file;
  String _theme = 'shikkoku';
  List<DesktopRecentFile> _recents = [];
  String? _persistenceError;
  Future<void> _queue = Future<void>.value();
  Future<void>? _loading;
  bool _disposed = false, _themeChanged = false, _cleared = false;
  int _temporaryCounter = 0;
  String get theme => _theme;
  List<DesktopRecentFile> get recents => List.unmodifiable(_recents);
  String? get persistenceError => _persistenceError;

  Future<void> load() => _loading ??= _enqueue(() async {
    if (_file == null) return;
    try {
      final file = await _file();
      if (!await file.exists()) return;
      final handle = await file.open();
      final List<int> bytes;
      try { bytes = await handle.read(_maxBytes + 1); }
      finally { await handle.close(); }
      if (bytes.length > _maxBytes) throw const FormatException();
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map || decoded['version'] != 1) throw const FormatException();
      if (!_themeChanged && _themes.contains(decoded['theme'])) _theme = decoded['theme'] as String;
      if (!_cleared && decoded['recents'] is List) {
        final seen = <String>{};
        _recents = [..._recents, ...(decoded['recents'] as List).map(DesktopRecentFile.parse).whereType<DesktopRecentFile>()]
            .where((entry) => seen.add(entry.uri)).take(12).toList();
      }
      _notify();
    } on Object {
      _persistenceError = 'Não foi possível carregar seus ajustes.';
      _notify();
    }
  });

  void setTheme(String theme) {
    if (_disposed || !_themes.contains(theme) || theme == _theme) return;
    _themeChanged = true;
    _theme = theme;
    _notify();
    _save();
  }

  void recordLocal({required String uri, required String title, required int positionMs,
    required int durationMs, bool force = false}) {
    if (_disposed) return;
    final entry = DesktopRecentFile.parse({'uri': uri, 'title': title,
      'positionMs': positionMs, 'durationMs': durationMs});
    if (entry == null) return;
    if (!force && _recents.isNotEmpty && _recents.first.uri == entry.uri &&
        _recents.first.title == entry.title && _recents.first.durationMs == entry.durationMs &&
        (_recents.first.positionMs - entry.positionMs).abs() < 15000) {
      return;
    }
    _recents = [entry, ..._recents.where((old) => old.uri != entry.uri)].take(12).toList();
    _notify();
    _save();
  }

  void clearRecents() {
    if (_disposed) return;
    _cleared = true;
    _recents = [];
    _notify();
    _save();
  }

  Future<void> flush() => _queue;
  Future<void> _enqueue(Future<void> Function() action) {
    final pending = _queue.then((_) => action());
    _queue = pending.then<void>((_) {}, onError: (Object _) {});
    return pending;
  }

  void _save() {
    if (_file == null) return;
    unawaited(_enqueue(() async {
      try {
        // Encode inside the queue: load may still be merging saved history.
        final data = utf8.encode(jsonEncode({'version': 1, 'theme': _theme,
          'recents': _recents.map((entry) => entry.toJson()).toList()}));
        if (data.length > _maxBytes) throw const FormatException();
        final target = await _file();
        await target.parent.create(recursive: true);
        final temporary = File('${target.path}.tmp_${pid}_${++_temporaryCounter}');
        try {
          await temporary.writeAsBytes(data, flush: true);
          await temporary.rename(target.path);
        } finally {
          if (await temporary.exists()) await temporary.delete();
        }
        _persistenceError = null;
      } on Object {
        _persistenceError = 'Não foi possível salvar seus ajustes.';
      }
      _notify();
    }));
  }

  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() { _disposed = true; super.dispose(); }
}
