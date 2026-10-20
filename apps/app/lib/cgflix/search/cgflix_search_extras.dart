// Busca do celular (Etapa 1C): histórico das últimas buscas e pedidos (Seerr). A tela de busca
// do upstream só envolve os estados vazios com estes widgets e põe a seção de pedidos depois
// dos resultados (Etapa 1E: "Disponível para pedir").
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/app_logger.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/app_icon.dart';
import '../cgflix_palette.dart';
import '../cgflix_style.dart';
import '../home/cgflix_cards.dart';
import '../requests/cgflix_requests_ui.dart';

// ---------------------------------------------------------------------------
// Histórico

const _historyKey = 'cgflix_search_history';
const cgflixSearchHistoryMax = 8;

/// Põe [query] no topo do histórico (sem repetir, ignorando caixa) e corta no máximo.
List<String> cgflixPushHistory(List<String> history, String query) {
  final term = query.trim();
  if (term.length < 2) return history;
  return [term, ...history.where((h) => h.toLowerCase() != term.toLowerCase())].take(cgflixSearchHistoryMax).toList();
}

Future<List<String>> _readHistory() async {
  try {
    final raw = (await SharedPreferences.getInstance()).getString(_historyKey);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw);
    return decoded is List ? decoded.whereType<String>().toList() : const [];
  } catch (e) {
    appLogger.w('CGFLIX: histórico da busca ilegível', error: e);
    return const [];
  }
}

Future<void> _writeHistory(List<String> history) async {
  try {
    await (await SharedPreferences.getInstance()).setString(_historyKey, jsonEncode(history));
  } catch (e) {
    appLogger.w('CGFLIX: não deu para salvar o histórico da busca', error: e);
  }
}

/// Guarda uma busca que achou algo (chamado pela tela de busca).
void cgflixRememberSearch(String query) => unawaited(_remember(query));

Future<void> _remember(String query) async => _writeHistory(cgflixPushHistory(await _readHistory(), query));

/// Antes de digitar: "Buscas recentes" (tocar repete a busca). Sem histórico, ou fora do
/// celular, mostra [child] (a mensagem original).
class CgflixSearchIdle extends StatefulWidget {
  const CgflixSearchIdle({super.key, required this.enabled, required this.onPick, required this.child});
  final bool enabled;
  final ValueChanged<String> onPick;
  final Widget child;

  @override
  State<CgflixSearchIdle> createState() => _CgflixSearchIdleState();
}

class _CgflixSearchIdleState extends State<CgflixSearchIdle> {
  List<String> _history = const [];

  @override
  void initState() {
    super.initState();
    if (widget.enabled) unawaited(_load());
  }

  Future<void> _load() async {
    final history = await _readHistory();
    if (mounted) setState(() => _history = history);
  }

  Future<void> _remove(String term) async {
    final next = _history.where((h) => h != term).toList();
    setState(() => _history = next);
    await _writeHistory(next);
  }

  Future<void> _clear() async {
    setState(() => _history = const []);
    await _writeHistory(const []);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: CgflixMotion.medium,
      switchInCurve: CgflixMotion.curve,
      child: !widget.enabled || _history.isEmpty
          ? KeyedSubtree(key: const ValueKey('vazio'), child: widget.child)
          : SingleChildScrollView(
              key: const ValueKey('historico'),
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 0, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Buscas recentes',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        TextButton(onPressed: _clear, child: const Text('Limpar')),
                      ],
                    ),
                  ),
                  for (final term in _history)
                    ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      leading: AppIcon(Symbols.history_rounded, color: context.cgflix.textMuted),
                      title: Text(term, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        tooltip: 'Tirar do histórico',
                        icon: AppIcon(Symbols.close_rounded, size: 18, color: context.cgflix.textMuted),
                        onPressed: () => _remove(term),
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onPick(term);
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pedir (Seerr)

/// Nada achado no nosso acervo: mostra [child] (a mensagem original, mais compacta) e, logo
/// abaixo, "Disponível para pedir" com os resultados do Seerr (Etapa 1E: pedidos embutidos na
/// busca, sem botão que leve a tela de login). Rola quando falta altura (deitado, teclado aberto).
class CgflixRequestPrompt extends StatelessWidget {
  const CgflixRequestPrompt({super.key, required this.enabled, required this.query, required this.child});
  final bool enabled;
  final String query;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 260, child: child),
          CgflixRequestSection(query: query),
        ],
      ),
    );
  }
}

/// Com resultados no nosso acervo: "Disponível para pedir" vem logo depois deles (celular).
Widget cgflixRequestSliver(BuildContext context, String query) => SliverToBoxAdapter(
  child: CgflixRequestSection(query: query, enabled: PlatformDetector.isMobile(context)),
);

// ---------------------------------------------------------------------------
// Carregando

/// Esqueleto da lista de resultados (no lugar do círculo girando).
class CgflixSearchSkeleton extends StatelessWidget {
  const CgflixSearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      sliver: SliverList.list(
        children: [
          for (var i = 0; i < 6; i++)
            CgflixShimmer(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const CgflixSkeletonBox(width: 64, height: 96),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FractionallySizedBox(
                            widthFactor: i.isEven ? 0.7 : 0.5,
                            child: const CgflixSkeletonBox(width: double.infinity, height: 16, radius: 4),
                          ),
                          const SizedBox(height: 8),
                          const CgflixSkeletonBox(width: 80, height: 12, radius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
