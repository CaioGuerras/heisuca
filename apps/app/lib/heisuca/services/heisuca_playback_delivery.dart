/// Motivos enviados pelo servidor na URL negociada, nunca inferidos do arquivo.
/// Retém apenas códigos conhecidos; URLs, tokens e textos livres não chegam à UI.
class HeisucaPlaybackDelivery {
  const HeisucaPlaybackDelivery({required this.method, this.reasons = const []});
  final String method;
  final List<String> reasons;
  static const labels = <String, String>{
    'ContainerNotSupported': 'O formato do arquivo precisa ser adaptado.',
    'VideoCodecNotSupported': 'O formato do vídeo precisa ser convertido.',
    'AudioCodecNotSupported': 'O formato do áudio precisa ser convertido.',
    'SubtitleCodecNotSupported': 'A legenda precisa ser incorporada ao vídeo.',
    'ContainerBitrateExceedsLimit': 'O arquivo ultrapassa o limite de qualidade da transmissão.',
    'VideoBitrateNotSupported': 'O vídeo ultrapassa o limite de qualidade da transmissão.',
    'AudioBitrateNotSupported': 'O áudio ultrapassa o limite de qualidade da transmissão.',
    'VideoResolutionNotSupported': 'A resolução do vídeo precisa ser adaptada.',
    'VideoProfileNotSupported': 'O perfil do vídeo precisa ser adaptado.',
    'VideoLevelNotSupported': 'O nível do vídeo precisa ser adaptado.',
    'AudioChannelsNotSupported': 'A quantidade de canais de áudio precisa ser adaptada.',
    'VideoBitDepthNotSupported': 'A profundidade de cor precisa ser adaptada.',
    'VideoRangeTypeNotSupported': 'O formato de cor precisa ser adaptado.',
    'DirectPlayError': 'O servidor informou uma falha ao reproduzir o arquivo diretamente.',
  };
  factory HeisucaPlaybackDelivery.jellyfin({required String method, String? transcodingUrl}) {
    final codes =
        Uri.tryParse(transcodingUrl ?? '')?.queryParameters.entries
            .where((entry) => entry.key.toLowerCase() == 'transcodereasons')
            .expand((entry) => entry.value.split(',')) ??
        const <String>[];
    return HeisucaPlaybackDelivery(
      method: method,
      reasons: method == 'Transcode'
          ? codes
                .where((code) => code.trim().isNotEmpty)
                .map(
                  (code) => labels[code.trim()] ?? 'O servidor informou um motivo que esta versão ainda não reconhece.',
                )
                .whereType<String>()
                .toSet()
                .toList(growable: false)
          : const [],
    );
  }
  String get summary => switch (method) {
    'Transcode' => 'O servidor está convertendo esta reprodução.',
    'DirectPlay' => 'O arquivo está sendo reproduzido sem conversão.',
    'DirectStream' => 'O servidor está adaptando o envio do arquivo.',
    _ => 'O servidor não informou o modo de reprodução.',
  };
  String get explanation => reasons.isEmpty ? 'O servidor não informou o motivo da conversão.' : reasons.join('\n');
}
