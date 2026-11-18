import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract interface class DesktopConnectionVault {
  bool get persistent;
  Future<List<Map<String, dynamic>>> read();
  Future<void> write(List<Map<String, dynamic>> entries);
}

/// Application-owned copy only; platform and JSON errors can contain secrets.
class DesktopVaultException implements Exception {
  const DesktopVaultException(this.message);
  final String message;
  @override
  String toString() => message;
}
const _vaultFailure = DesktopVaultException('Não foi possível acessar as conexões protegidas.');
const _maxPlainBytes = 512 * 1024;
const _maxCipherBytes = 1024 * 1024;

Uint8List _encode(List<Map<String, dynamic>> entries) {
  try {
    final encoded = JsonUtf8Encoder().convert(entries);
    final bytes = encoded is Uint8List ? encoded : Uint8List.fromList(encoded);
    if (bytes.length > _maxPlainBytes) {
      bytes.fillRange(0, bytes.length, 0);
      throw _vaultFailure;
    }
    return bytes;
  } on Object { throw _vaultFailure; }
}
List<Map<String, dynamic>> _decode(Uint8List bytes) {
  try {
    if (bytes.length > _maxPlainBytes) throw _vaultFailure;
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! List || decoded.any((entry) => entry is! Map)) throw _vaultFailure;
    return decoded.map((entry) => Map<String, dynamic>.from(entry as Map)).toList();
  } on Object {
    // FormatException.toString includes the input, which can contain tokens.
    throw _vaultFailure;
  }
}
DesktopConnectionVault createDesktopConnectionVault({Future<Directory> Function()? getDirectory, MethodChannel? channel}) {
  if (!kIsWeb && Platform.isWindows) {
    return PlatformWindowsVault(getDirectory: getDirectory, channel: channel);
  }
  return MemoryDesktopConnectionVault();
}
class MemoryDesktopConnectionVault implements DesktopConnectionVault {
  MemoryDesktopConnectionVault([List<Map<String, dynamic>>? initialEntries])
      : _entries = _decode(_encode(initialEntries ?? []));
  List<Map<String, dynamic>> _entries;
  @override
  bool get persistent => false;
  @override
  Future<List<Map<String, dynamic>>> read() async => _decode(_encode(_entries));
  @override
  Future<void> write(List<Map<String, dynamic>> entries) async { _entries = _decode(_encode(entries)); }
}

/// Only the Windows-user-bound DPAPI blob is written to disk.
class PlatformWindowsVault implements DesktopConnectionVault {
  PlatformWindowsVault({Future<Directory> Function()? getDirectory, MethodChannel? channel,
    Future<Uint8List> Function(Uint8List)? protect, Future<Uint8List> Function(Uint8List)? unprotect})
      : _getDirectory = getDirectory ?? getApplicationSupportDirectory,
        _channel = channel ?? const MethodChannel('heisuca/desktop_vault'),
        _protectOverride = protect, _unprotectOverride = unprotect;
  static const fileName = 'desktop-connections.dpapi';
  final Future<Directory> Function() _getDirectory;
  final MethodChannel _channel;
  final Future<Uint8List> Function(Uint8List)? _protectOverride;
  final Future<Uint8List> Function(Uint8List)? _unprotectOverride;
  Future<void> _writeQueue = Future<void>.value();
  int _counter = 0;
  @override
  bool get persistent => true;
  Future<Uint8List> _crypt(String operation, Uint8List bytes) async {
    try {
      final override = operation == 'protect' ? _protectOverride : _unprotectOverride;
      final result = override != null ? await override(bytes) : await _channel.invokeMethod<Uint8List>(operation, bytes);
      if (result == null || result.isEmpty) throw _vaultFailure;
      if (result.length > _maxCipherBytes) {
        if (operation == 'unprotect') result.fillRange(0, result.length, 0);
        throw _vaultFailure;
      }
      return result;
    } on Object { throw _vaultFailure; }
  }
  Future<T> _serialized<T>(Future<T> Function() action) {
    final operation = _writeQueue.then((_) => action());
    _writeQueue = operation.then<void>((_) {}, onError: (Object _) {});
    return operation;
  }
  @override
  Future<List<Map<String, dynamic>>> read() => _serialized(_read);
  Future<List<Map<String, dynamic>>> _read() async {
    try {
      final file = File(p.join((await _getDirectory()).path, fileName));
      if (!await file.exists()) return [];
      if (await file.length() > _maxCipherBytes) throw _vaultFailure;
      final handle = await file.open();
      final Uint8List cipher;
      try { cipher = await handle.read(_maxCipherBytes + 1); }
      finally { await handle.close(); }
      if (cipher.isEmpty || cipher.length > _maxCipherBytes) throw _vaultFailure;
      final plain = await _crypt('unprotect', cipher);
      try { return _decode(plain); }
      finally { plain.fillRange(0, plain.length, 0); }
    } on Object { throw _vaultFailure; }
  }
  @override
  Future<void> write(List<Map<String, dynamic>> entries) {
    // Freeze the request before queuing: its caller may mutate the list.
    final Uint8List plain;
    try { plain = _encode(entries); }
    on Object { return Future<void>.error(_vaultFailure); }
    return _serialized(() async {
      try {
        final cipher = await _crypt('protect', plain);
        final dir = await _getDirectory();
        await dir.create(recursive: true);
        final target = File(p.join(dir.path, fileName));
        final temp = File('${target.path}.tmp_${pid}_${DateTime.now().microsecondsSinceEpoch}_${++_counter}');
        try {
          await temp.writeAsBytes(cipher, flush: true);
          await temp.rename(target.path);
        } on Object {
          if (await temp.exists()) await temp.delete();
          throw _vaultFailure;
        }
      } on Object { throw _vaultFailure; }
      finally { plain.fillRange(0, plain.length, 0); }
    });
  }
}
