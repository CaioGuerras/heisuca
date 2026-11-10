// Peças visuais da ficha do título (Esboço 04 + medidas do site, apps/web/src/telas/titulo.css).
// Só apresentação: os dados e as ações vêm de heisuca_title_sheet.dart.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'heisuca_theme.dart';
import '../media/media_file_info.dart';
import '../media/media_item.dart';
import '../utils/language_codes.dart';

/// Medidas do celular no site (`--hs-margem`, `--hs-vao`, `--hs-cartao-paisagem`, `--hs-titulo-secao`).
abstract final class HeisucaTitleMetrics {
  static const margin = 16.0;
  static const gap = 10.0;
  static const landscapeCard = 196.0;
  static const sectionTitle = 17.0;
  static const cardRadius = 10.0;
}

/// Cores da ficha derivadas do fundo da página (tema escuro/claro).
class HeisucaTitleColors {
  const HeisucaTitleColors({required this.page, required this.text, required this.accent, required this.isLight});
  final Color page, text, accent;
  final bool isLight;
  Color get text2 => text.withValues(alpha: isLight ? .68 : .72);
  Color get line => text.withValues(alpha: .12);
  Color get surface => Color.alphaBlend(text.withValues(alpha: isLight ? .05 : .07), page);
}

TextStyle heisucaSectionStyle(HeisucaTitleColors c) => TextStyle(fontFamily: HeisucaTheme.fonteTitulo, fontSize: HeisucaTitleMetrics.sectionTitle,
    fontWeight: FontWeight.w700, letterSpacing: -.17, color: c.text);

class HeisucaSectionTitle extends StatelessWidget {
  const HeisucaSectionTitle(this.title, {super.key, required this.colors, this.top = 28});
  final String title;
  final HeisucaTitleColors colors;
  final double top;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(HeisucaTitleMetrics.margin, top, HeisucaTitleMetrics.margin, 12),
    child: Text(title, style: heisucaSectionStyle(colors)));
}

/// Sinopse com até 4 linhas e o "mais" na própria última linha (Esboço 04), sem botão solto embaixo.
/// [mark] é o prefixo em negrito do episódio, como no site: 「Série·Temp. 4·EP 19」.
class HeisucaSynopsis extends StatefulWidget {
  const HeisucaSynopsis({super.key, required this.text, required this.colors, this.mark});
  final String text;
  final String? mark;
  final HeisucaTitleColors colors;
  @override
  State<HeisucaSynopsis> createState() => _HeisucaSynopsisState();
}

class _HeisucaSynopsisState extends State<HeisucaSynopsis> {
  static const _lines = 4;
  bool _open = false;
  late final _toggle = TapGestureRecognizer()..onTap = () => setState(() => _open = !_open);

  @override
  void dispose() { _toggle.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final base = TextStyle(fontSize: 13.5, height: 1.5, color: c.text2);
    final link = TextStyle(fontSize: 13.5, height: 1.5, color: c.isLight ? c.accent : c.text, fontWeight: FontWeight.w700);
    final mark = widget.mark == null ? null
        : TextSpan(text: '「${widget.mark}」 ', style: base.copyWith(color: c.text, fontWeight: FontWeight.w700));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HeisucaTitleMetrics.margin),
      child: LayoutBuilder(builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context);
        // Mede com o MESMO estilo raiz que o Text vai herdar (fonte do tema); senão o "mais" pode cair numa 5ª linha cortada.
        final root = DefaultTextStyle.of(context).style;
        TextSpan span(String body, {bool more = false, bool less = false}) => TextSpan(style: root, children: [
          ?mark,
          TextSpan(text: body, style: base),
          if (more) ...[TextSpan(text: '… ', style: base), TextSpan(text: 'mais', style: link, recognizer: _toggle)],
          if (less) TextSpan(text: '  menos', style: link, recognizer: _toggle),
        ]);
        bool fits(TextSpan s) {
          final painter = TextPainter(text: s, maxLines: _lines, textDirection: TextDirection.ltr, textScaler: scale)
            ..layout(maxWidth: constraints.maxWidth);
          final exceeded = painter.didExceedMaxLines;
          painter.dispose();
          return !exceeded;
        }
        final full = widget.text.trim();
        if (fits(span(full))) return Text.rich(span(full));
        if (_open) return Text.rich(span(full, less: true));
        // Maior prefixo, cortado em palavra, que cabe nas 4 linhas junto com "… mais".
        var lo = 0, hi = full.length;
        while (lo < hi) {
          final mid = (lo + hi + 1) ~/ 2;
          if (fits(span(full.substring(0, mid), more: true))) { lo = mid; } else { hi = mid - 1; }
        }
        var cut = full.substring(0, lo);
        final space = cut.lastIndexOf(' ');
        if (space > lo * .6) cut = cut.substring(0, space);
        return Text.rich(span(cut.trimRight(), more: true), maxLines: _lines);
      }),
    );
  }
}

/// Cabeçalho "Temporada 4 ⌄ ........ Ver tudo ›", alinhado à margem como os títulos de seção.
class HeisucaSeasonHeader extends StatelessWidget {
  const HeisucaSeasonHeader({super.key, required this.label, required this.colors, this.onChoose, this.onSeeAll});
  final String label;
  final HeisucaTitleColors colors;
  final VoidCallback? onChoose, onSeeAll;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(HeisucaTitleMetrics.margin - 4, 26, HeisucaTitleMetrics.margin - 8, 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Flexible(child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onChoose,
        child: Padding(padding: const EdgeInsets.fromLTRB(4, 6, 4, 6), child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: heisucaSectionStyle(colors))),
          if (onChoose != null) Icon(Icons.keyboard_arrow_down_rounded, size: 24, color: colors.text),
        ])),
      )),
      const Spacer(),
      if (onSeeAll != null) InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onSeeAll,
        child: Padding(padding: const EdgeInsets.fromLTRB(8, 6, 2, 6), child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('Ver tudo', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: colors.text2)),
          Icon(Icons.chevron_right_rounded, size: 20, color: colors.text2),
        ])),
      ),
    ]),
  );
}

/// Cabeçalho de folha contida: título de folha + fechar. Não se confunde com uma opção da lista.
class HeisucaSheetHeader extends StatelessWidget {
  const HeisucaSheetHeader(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 12),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -.2)),
          if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2),
            child: Text(subtitle!, style: TextStyle(fontSize: 12.5, color: scheme.onSurface.withValues(alpha: .65)))),
        ])),
        IconButton(tooltip: 'Fechar', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
      ]),
    );
  }
}

/// Opção da folha de temporadas: cartão com nome, episódios e ano; a escolhida ganha borda e ✓.
class HeisucaSeasonOption extends StatelessWidget {
  const HeisucaSeasonOption({super.key, required this.label, required this.selected, required this.onTap, this.detail});
  final String label;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: selected ? accent.withValues(alpha: .14) : scheme.onSurface.withValues(alpha: .05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? accent : Colors.transparent, width: 1.5)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 14, 12), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              if (detail != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(detail!,
                style: TextStyle(fontSize: 12.5, color: scheme.onSurface.withValues(alpha: .65)))),
            ])),
            if (selected) Icon(Icons.check_rounded, color: accent),
          ])),
        ),
      ),
    );
  }
}

/// "Temporada 1 · 10 episódios · 2016": só o que o servidor informou.
String? heisucaSeasonDetail(MediaItem season) {
  final count = season.leafCount ?? season.childCount;
  final parts = [
    if (count != null && count > 0) count == 1 ? '1 episódio' : '$count episódios',
    if (season.year != null) '${season.year}',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

// ---------------------------------------------------------------------------------------------
// Info mídia: cartões lado a lado (VidHub), Vídeo · Áudio N · Legendas. Nunca mostra o caminho
// do arquivo (expunha a estrutura de pastas do servidor).

String _codec(String? codec) {
  final c = (codec ?? '').toLowerCase();
  return switch (c) {
    'h264' || 'avc' || 'avc1' => 'H.264',
    'hevc' || 'h265' || 'hvc1' || 'hev1' => 'HEVC',
    'av1' => 'AV1', 'vp9' => 'VP9', 'mpeg2video' => 'MPEG-2',
    'aac' => 'AAC', 'ac3' => 'Dolby Digital', 'eac3' => 'Dolby Digital Plus', 'truehd' => 'Dolby TrueHD',
    'dts' => 'DTS', 'flac' => 'FLAC', 'opus' => 'Opus', 'mp3' => 'MP3', 'vorbis' => 'Vorbis',
    'ass' || 'ssa' => 'ASS', 'subrip' || 'srt' => 'SRT', 'webvtt' || 'vtt' => 'WebVTT',
    'hdmv_pgs_subtitle' || 'pgssub' || 'pgs' => 'PGS', 'dvd_subtitle' || 'dvdsub' => 'VobSub',
    '' => '',
    _ => c.toUpperCase(),
  };
}

String _range(MediaVideoRange range, bool? hdr10Plus) => switch (range) {
  MediaVideoRange.sdr => 'SDR',
  MediaVideoRange.hdr || MediaVideoRange.hdr10 => hdr10Plus == true ? 'HDR10+' : 'HDR10',
  MediaVideoRange.hdr10Plus => 'HDR10+',
  MediaVideoRange.hlg => 'HLG',
  MediaVideoRange.dolbyVision => 'Dolby Vision',
  MediaVideoRange.dolbyVisionHdr10 => 'Dolby Vision · HDR10',
  MediaVideoRange.dolbyVisionHlg => 'Dolby Vision · HLG',
  _ => '',
};

String _channels(int? n) => switch (n) {
  null => '', 1 => 'Mono', 2 => 'Estéreo (2.0)', 6 => '5.1', 8 => '7.1', _ => '$n canais',
};

String _language(MediaStreamDetails s) {
  final code = s.languageCode ?? s.language;
  if (code == null || code.isEmpty || code == 'und') return '';
  final name = LanguageCodes.getDisplayName(code);
  return name.isEmpty ? code : name;
}

String _fps(double? fps) {
  if (fps == null || fps <= 0) return '';
  final text = fps == fps.roundToDouble() ? fps.toStringAsFixed(0) : fps.toStringAsFixed(3);
  return text.replaceAll('.', ',');
}

String _bitrate(int? kbps) {
  if (kbps == null || kbps <= 0) return '';
  return kbps >= 1000 ? '${(kbps / 1000).toStringAsFixed(1).replaceAll('.', ',')} Mbps' : '$kbps kbps';
}

typedef HeisucaInfoCard = ({String title, IconData icon, List<(String, String)> rows});

/// Cartões a partir da versão escolhida; linhas sem valor não aparecem (PLANO §1.7 do site).
List<HeisucaInfoCard> heisucaMediaInfoCards(MediaFileVersion version) {
  final streams = [for (final p in version.parts) ...p.streams];
  final video = streams.where((s) => s.kind == MediaStreamKind.video).firstOrNull;
  final audios = streams.where((s) => s.kind == MediaStreamKind.audio).toList();
  final subs = streams.where((s) => s.kind == MediaStreamKind.subtitle).toList();
  List<(String, String)> clean(List<(String, String)> rows) => [for (final r in rows) if (r.$2.trim().isNotEmpty) r];
  final width = video?.width ?? version.width, height = video?.height ?? version.height;
  return [
    (title: 'Vídeo', icon: Icons.videocam_rounded, rows: clean([
      ('Resolução', width != null && height != null ? '$width × $height' : ''),
      ('Codec', [_codec(video?.codec ?? version.videoCodec), ?(video?.profile ?? version.videoProfile)].where((v) => v.isNotEmpty).join(' · ')),
      ('Faixa dinâmica', video == null ? '' : _range(video.videoRange, video.hasHdr10Plus)),
      ('Quadros por segundo', _fps(video?.frameRate)),
      ('Profundidade', video?.bitDepth != null ? '${video!.bitDepth} bits' : ''),
      ('Taxa de bits', _bitrate(version.bitrateKbps)),
      ('Contêiner', (version.container ?? '').toUpperCase()),
    ])),
    for (final (i, a) in audios.indexed)
      (title: audios.length > 1 ? 'Áudio ${i + 1}' : 'Áudio', icon: Icons.graphic_eq_rounded, rows: clean([
        ('Idioma', _language(a)),
        ('Codec', _codec(a.codec)),
        ('Canais', _channels(a.channels)),
        ('Padrão', a.isDefault == null ? '' : a.isDefault! ? 'Sim' : 'Não'),
      ])),
    if (subs.isNotEmpty)
      (title: 'Legendas', icon: Icons.closed_caption_rounded, rows: [
        for (final s in subs.take(8)) (
          _language(s).isEmpty ? (s.title ?? 'Legenda') : _language(s),
          [_codec(s.codec), if (s.isForced == true) 'Forçada', if (s.isDefault == true) 'Padrão', if (s.isExternal == true) 'Externa']
              .where((v) => v.isNotEmpty).join(' · '),
        ),
        if (subs.length > 8) ('Outras', '+${subs.length - 8}'),
      ]),
  ].where((c) => c.rows.isNotEmpty).toList();
}

/// Cartões lado a lado, com rolagem lateral e encaixe, todos com a mesma altura.
class HeisucaMediaInfo extends StatelessWidget {
  const HeisucaMediaInfo({super.key, required this.cards, required this.colors});
  final List<HeisucaInfoCard> cards;
  final HeisucaTitleColors colors;
  @override
  Widget build(BuildContext context) {
    final c = colors;
    final width = (MediaQuery.sizeOf(context).width * .78).clamp(240.0, 340.0);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: HeisucaTitleMetrics.margin),
      child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final (i, card) in cards.indexed) Container(
          width: width,
          margin: EdgeInsets.only(right: i == cards.length - 1 ? 0 : 12),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.text.withValues(alpha: .08))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(card.icon, size: 19, color: c.text),
              const SizedBox(width: 8),
              Text(card.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
            ]),
            const SizedBox(height: 6),
            for (final (j, row) in card.rows.indexed) Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(border: j == 0 ? null : Border(top: BorderSide(color: c.line))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(row.$1, style: TextStyle(fontSize: 12.5, color: c.text2)),
                const SizedBox(width: 14),
                Expanded(child: Text(row.$2, textAlign: TextAlign.right, style: TextStyle(fontSize: 12.5,
                  fontWeight: FontWeight.w500, color: c.text, fontFeatures: const [FontFeature.tabularFigures()]))),
              ]),
            ),
          ]),
        ),
      ])),
    );
  }
}

/// Encaixe magnético por cartão nas fileiras horizontais, com a mola do iOS (estudo de fluidez §4.4):
/// a inércia decide para qual cartão ir e a mola assenta nele, sem parar no meio de um cartão.
class HeisucaSnapPhysics extends BouncingScrollPhysics {
  const HeisucaSnapPhysics({required this.itemExtent, super.parent});
  final double itemExtent;

  @override
  HeisucaSnapPhysics applyTo(ScrollPhysics? ancestor) => HeisucaSnapPhysics(itemExtent: itemExtent, parent: buildParent(ancestor));

  @override
  SpringDescription get spring => const SpringDescription(mass: 1, stiffness: 185, damping: 2 * 0.82 * 13.6);

  double _target(ScrollMetrics position, double velocity) {
    final projected = position.pixels + velocity * 0.28;
    final page = (projected / itemExtent).round();
    return (page * itemExtent).clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (position.outOfRange) return super.createBallisticSimulation(position, velocity);
    final target = _target(position, velocity);
    if ((target - position.pixels).abs() < 0.5 && velocity.abs() < toleranceFor(position).velocity) return null;
    return ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: toleranceFor(position));
  }
}
