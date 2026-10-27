import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Informações reportadas pelo Android, sem inferir recursos de reprodução.
class HeisucaDeviceProfile {
  final String? deviceName;
  final String? chipset;
  final int? totalMemBytes;
  final double? maxRefreshRateHz;
  final double? currentRefreshRateHz;
  final String? renderer;
  final bool? lowMemory;

  const HeisucaDeviceProfile({this.deviceName, this.chipset, this.totalMemBytes, this.maxRefreshRateHz, this.currentRefreshRateHz, this.renderer, this.lowMemory});

  factory HeisucaDeviceProfile.fromMap(Map<Object?, Object?> data) {
    String? text(String key) {
      final value = data[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }
    final memory = data['totalMemBytes'];
    final refresh = data['maxRefreshRateHz'];
    return HeisucaDeviceProfile(
      deviceName: text('deviceName'),
      currentRefreshRateHz: (data['currentRefreshRateHz'] as num?)?.toDouble(),
      renderer: text('renderer'), lowMemory: data['lowMemory'] as bool?,
      chipset: text('chipset'),
      totalMemBytes: memory is num && memory > 0 ? memory.toInt() : null,
      maxRefreshRateHz: refresh is num && refresh.isFinite && refresh > 0 ? refresh.toDouble() : null,
    );
  }

  String get hardwareSummary {
    final details = <String>[
      if (chipset != null) chipset!,
      if (totalMemBytes != null) '${(totalMemBytes! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GiB RAM utilizável',
      if (maxRefreshRateHz != null) 'Tela até ${maxRefreshRateHz!.round()} Hz',
    ];
    return details.isEmpty ? 'Informações não fornecidas pelo sistema' : details.join(' • ');
  }
}

class HeisucaDeviceService extends ChangeNotifier {
  HeisucaDeviceService._();
  static final HeisucaDeviceService instance = HeisucaDeviceService._();
  static const _channel = MethodChannel('app.heisuca/device');
  HeisucaDeviceProfile _profile = const HeisucaDeviceProfile();
  HeisucaDeviceProfile get profile => _profile;

  Future<void> initialize() async {
    try {
      final data = await _channel.invokeMapMethod<Object?, Object?>('getHeisucaDeviceProfile');
      _profile = HeisucaDeviceProfile.fromMap(data ?? const {});
    } on MissingPluginException {
      _profile = const HeisucaDeviceProfile();
    } on PlatformException {
      _profile = const HeisucaDeviceProfile();
    }
    notifyListeners();
  }
}
