// Modo infantil do Heisuca (PLANO_MODO_MARYANNE M2/M3, decisões de 18/10/2026).
// O filtro de conteúdo é do SERVIDOR (usuário-sombra "<nome>-kids" do cgflix-kids, com teto de
// classificação e etiqueta cgf-infantil). Aqui fica só o vínculo no aparelho: qual perfil local é
// infantil, de qual responsável, o tema (Ichigo/Sorairo) e o hash do PIN que libera a saída.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../cgflix/cgflix_palette.dart';
import '../../connection/connection.dart';

@immutable
class HeisucaKidsRecord {
  const HeisucaKidsRecord({required this.parentProfileId, required this.kidsProfileId, required this.variant,
    required this.ceiling, required this.pinHash, required this.name});
  final String parentProfileId, kidsProfileId, ceiling, pinHash, name;
  final CgflixThemeVariant variant;

  Map<String, Object?> toJson() => {'pai': parentProfileId, 'kids': kidsProfileId, 'tema': variant.name,
    'teto': ceiling, 'pin': pinHash, 'nome': name};

  static HeisucaKidsRecord? fromJson(Object? json) {
    if (json is! Map) return null;
    final variant = CgflixThemeVariant.values.where((v) => v.name == json['tema'] && v.isKids).firstOrNull;
    final pai = json['pai'], kids = json['kids'], pin = json['pin'];
    if (variant == null || pai is! String || kids is! String || pin is! String || pin.isEmpty) return null;
    return HeisucaKidsRecord(parentProfileId: pai, kidsProfileId: kids, variant: variant,
      ceiling: json['teto'] == '10' ? '10' : 'livre', pinHash: pin, name: json['nome'] is String ? json['nome'] as String : 'Criança');
  }
}

/// Registro dos perfis infantis deste aparelho (SharedPreferences). Notifica o tema do app.
class HeisucaKids extends ChangeNotifier {
  HeisucaKids._();
  static final instance = HeisucaKids._();
  static const _key = 'heisuca.kids.v1';

  final Map<String, HeisucaKidsRecord> _byKids = {};
  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _byKids.clear();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw);
        if (list is List) {
          for (final item in list) {
            final r = HeisucaKidsRecord.fromJson(item);
            if (r != null) _byKids[r.kidsProfileId] = r;
          }
        }
      } on FormatException { /* registro corrompido: começa vazio, nunca trava a abertura */ }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final r in _byKids.values) r.toJson()]));
  }

  HeisucaKidsRecord? forKids(String? profileId) => profileId == null ? null : _byKids[profileId];
  HeisucaKidsRecord? forParent(String? profileId) =>
      profileId == null ? null : _byKids.values.where((r) => r.parentProfileId == profileId).firstOrNull;
  bool isKids(String? profileId) => forKids(profileId) != null;

  /// Tema forçado do app enquanto o perfil ativo é infantil; nulo = tema escolhido pela pessoa.
  CgflixThemeVariant? variantFor(String? activeProfileId) => forKids(activeProfileId)?.variant;

  Future<void> save(HeisucaKidsRecord record) async {
    _byKids.removeWhere((_, r) => r.parentProfileId == record.parentProfileId);
    _byKids[record.kidsProfileId] = record;
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String kidsProfileId) async {
    if (_byKids.remove(kidsProfileId) == null) return;
    await _persist();
    notifyListeners();
  }

  @visibleForTesting
  void debugReset() { _byKids.clear(); _loaded = false; }
}

/// Conexão do usuário infantil criado pelo cgflix-kids (contrato do servidor: nome "<pessoa>-kids").
/// Nunca é emprestada nem ligada a um perfil adulto.
bool heisucaIsKidsConnection(Connection connection) =>
    connection is JellyfinConnection && connection.userName.toLowerCase().endsWith('-kids');
