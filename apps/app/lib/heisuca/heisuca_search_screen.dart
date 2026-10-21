import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'heisuca_design_system.dart';
import 'heisuca_seerr_sheet.dart';
import 'heisuca_theme.dart';

/// Tela de Busca Unificada Flagship Heisuca (炳素華)
/// Filosofia: "Nada entre você e o filme."
/// Pesquisa instantânea no acervo local e integração direta com o Seerr para pedidos externos.
class HeisucaSearchScreen extends StatefulWidget {
  const HeisucaSearchScreen({super.key});

  @override
  State<HeisucaSearchScreen> createState() => _HeisucaSearchScreenState();
}

class _HeisucaSearchScreenState extends State<HeisucaSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasQuery = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final has = _searchController.text.trim().isNotEmpty;
      if (has != _hasQuery) {
        setState(() => _hasQuery = has);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HeisucaTheme.roxoFundo,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de Busca em Vidro Translúcido
            Padding(
              padding: const EdgeInsets.only(top: 14.0, left: 20.0, right: 20.0, bottom: 12.0),
              child: Container(
                height: 48.0,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                  border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Row(
                  children: [
                    const Icon(Symbols.search_rounded, color: Color(0xFFA99FBB), size: 22.0),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          fontFamily: HeisucaTheme.fonteTexto,
                          fontSize: 14.5,
                          color: Color(0xFFF4F1FA),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Buscar filmes, séries, animes ou atores...',
                          hintStyle: TextStyle(
                            fontFamily: HeisucaTheme.fonteTexto,
                            fontSize: 13.5,
                            color: Color(0xFF8E859E),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_hasQuery)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          HapticFeedback.lightImpact();
                        },
                        child: const Icon(Symbols.close_rounded, color: Color(0xFFA99FBB), size: 18.0),
                      ),
                  ],
                ),
              ),
            ),

            // Resultados de Busca
            Expanded(
              child: ListView(
                physics: const HeisucaSpringPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                children: [
                  // Seção 1: No seu Acervo
                  const Text(
                    'No seu Acervo',
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTitulo,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF4F1FA),
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  _buildLocalResultTile('Duna: Parte 2', '2024 • Ficção Científica', '4K HDR Atmos'),
                  _buildLocalResultTile('Oppenheimer', '2023 • Drama Histórico', '4K HDR'),

                  const SizedBox(height: 24.0),

                  // Seção 2: Não Encontrado no Acervo? Pedir no Seerr
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7A40F2).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                      border: Border.all(color: const Color(0xFF7A40F2).withOpacity(0.3), width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Symbols.cloud_download_rounded, color: Color(0xFFA78BFA), size: 22.0),
                            SizedBox(width: 8.0),
                            Text(
                              'Disponível no Seerr',
                              style: TextStyle(
                                fontFamily: HeisucaTheme.fonteTitulo,
                                fontSize: 15.0,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF4F1FA),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6.0),
                        const Text(
                          'Título não disponível no momento. Deseja enviar um pedido para o download automático?',
                          style: TextStyle(
                            fontFamily: HeisucaTheme.fonteTexto,
                            fontSize: 12.5,
                            color: Color(0xFFC7BED8),
                          ),
                        ),
                        const SizedBox(height: 14.0),
                        HeisucaSpringPressable(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            HeisucaSeerrSheet.show(
                              context,
                              title: _hasQuery ? _searchController.text.trim() : 'Gladiador II',
                              year: 2024,
                            );
                          },
                          child: Container(
                            height: 42.0,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7A40F2), Color(0xFF5A25D0)],
                              ),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: const Center(
                              child: Text(
                                'Pedir no Seerr',
                                style: TextStyle(
                                  fontFamily: HeisucaTheme.fonteTexto,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 120.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalResultTile(String title, String subtitle, String quality) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: HeisucaSpringPressable(
        onTap: () {
          HapticFeedback.lightImpact();
        },
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
            border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.6),
          ),
          child: Row(
            children: [
              Container(
                width: 48.0,
                height: 70.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF231C30),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: const Center(
                  child: Icon(Symbols.movie_rounded, color: Colors.white24, size: 20.0),
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF4F1FA),
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 12.0,
                        color: Color(0xFFA99FBB),
                      ),
                    ),
                    const SizedBox(height: 5.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                      child: Text(
                        quality,
                        style: const TextStyle(
                          fontFamily: HeisucaTheme.fonteTexto,
                          fontSize: 9.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDCD7E8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Symbols.play_circle_rounded, color: Color(0xFF7A40F2), size: 26.0),
            ],
          ),
        ),
      ),
    );
  }
}
