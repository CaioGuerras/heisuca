import 'package:flutter/widgets.dart';

import '../inicio/modelo.dart';

/// Dados prontos para a tela, sem dependência de rede ou armazenamento.
class ItemBaixado {
  const ItemBaixado({
    required this.chave,
    required this.titulo,
    required this.estado,
    this.progresso = 0,
    this.aoPausar,
    this.aoRetomar,
    this.aoAssistir,
    this.aoApagar,
  });
  final String chave;
  final String titulo;
  final EstadoDaBaixa estado;
  final int progresso;
  final VoidCallback? aoPausar;
  final VoidCallback? aoRetomar;
  final VoidCallback? aoAssistir;
  final VoidCallback? aoApagar;
}

enum EstadoDaBaixa { esperando, baixando, pausado, interrompido, pronto }

class GrupoBaixado {
  const GrupoBaixado({
    required this.chave,
    required this.titulo,
    required this.serie,
    required this.bytes,
    required this.itens,
    this.arte,
    this.hash,
    this.manter,
    this.aoApagarVistos,
    this.aoManter,
  });
  final String chave;
  final String titulo;
  final bool serie;
  final int bytes;
  final List<ItemBaixado> itens;
  final FazArte? arte;
  final String? hash;
  final int? manter;
  final VoidCallback? aoApagarVistos;
  final ValueChanged<int?>? aoManter;
}

String espacoEmTexto(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1).replaceAll('.', ',')} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} GB';
}
