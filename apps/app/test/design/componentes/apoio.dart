import 'package:flutter/material.dart';
import 'package:heisuca/design/tema.dart';

/// Monta [filho] dentro do tema da V2, como uma tela real.
Widget naTela(Widget filho, {TemaHeisuca tema = TemaHeisuca.shikkoku, bool semAnimacao = false}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: tema.paraMaterial(),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: semAnimacao),
      child: Scaffold(body: Center(child: filho)),
    ),
  ),
);
