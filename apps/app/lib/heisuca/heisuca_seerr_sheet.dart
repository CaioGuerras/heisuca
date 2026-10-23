import 'package:flutter/material.dart';
import '../cgflix/requests/cgflix_requests_ui.dart';

/// Usa a busca, autenticação Quick Connect e confirmação HTTP reais do Seerr.
/// A pessoa escolhe o resultado correto; o nome sozinho não autoriza um pedido.
class HeisucaSeerrSheet extends StatelessWidget {
  const HeisucaSeerrSheet({super.key, required this.title, this.year});
  final String title;
  final int? year;

  static Future<void> show(BuildContext context, {required String title, int? year}) =>
    showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true,
      builder: (_) => HeisucaSeerrSheet(title: title, year: year));

  @override
  Widget build(BuildContext context) => SizedBox(height: MediaQuery.sizeOf(context).height * 0.72,
    child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (year != null) Text('$year'),
        const SizedBox(height: 12),
        const Text('Confira o título e as temporadas antes de confirmar seu pedido.'),
        CgflixRequestSection(query: title),
      ],
    )));
}
