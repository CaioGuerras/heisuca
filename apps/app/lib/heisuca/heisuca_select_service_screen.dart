import 'dart:async';
import 'package:flutter/material.dart';
import 'heisuca_theme.dart';
import 'heisuca_logo.dart';
import 'heisuca_service_type.dart';
import 'heisuca_add_webdav_screen.dart';
import 'heisuca_add_smb_screen.dart';
import '../media/media_browser_dialect.dart';
import '../screens/settings/add_jellyfin_screen.dart';
import '../navigation/profile_session_screen.dart';
import '../utils/navigation_transitions.dart';

/// Portal de entrada cinematográfico do Heisuca com suporte Multi-Serviço
class HeisucaSelectServiceScreen extends StatelessWidget {
  final ValueChanged<HeisucaServiceType>? onSelectService;

  const HeisucaSelectServiceScreen({
    super.key,
    this.onSelectService,
  });

  void _handleServiceSelection(BuildContext context, HeisucaServiceType type) {
    if (onSelectService != null) {
      onSelectService!(type);
      return;
    }

    switch (type) {
      case HeisucaServiceType.jellyfin:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const HeisucaLoginScreen(),
          ),
        );
        break;

      case HeisucaServiceType.plex:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conexão Plex selecionada. Redirecionando para autenticação Plex...'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, HeisucaServiceType.plex);
        break;

      case HeisucaServiceType.webdav:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HeisucaAddWebDavScreen()),
        );
        break;

      case HeisucaServiceType.smb:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HeisucaAddSmbScreen()),
        );
        break;

      case HeisucaServiceType.local:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arquivos Locais: selecione a pasta ou mídia no armazenamento do aparelho.'),
            duration: Duration(seconds: 3),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    const HeisucaLogo(height: 52),
                    const SizedBox(height: 12),
                    Text(
                      'Nada entre você e o filme.',
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 14.5,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Conectar Fonte de Mídia',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 19,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Escolha o servidor ou armazenamento para reproduzir em alta fidelidade.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.55),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final type = HeisucaServiceType.values[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _ServiceCard(
                        type: type,
                        onTap: () => _handleServiceSelection(context, type),
                      ),
                    );
                  },
                  childCount: HeisucaServiceType.values.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final HeisucaServiceType type;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isJellyfin = type == HeisucaServiceType.jellyfin;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HeisucaTheme.raioCard),
        splashColor: HeisucaTheme.roxoPrimaria.withOpacity(0.12),
        highlightColor: HeisucaTheme.roxoPrimaria.withOpacity(0.06),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: HeisucaTheme.roxoSuperficie,
            borderRadius: BorderRadius.circular(HeisucaTheme.raioCard),
            border: Border.all(
              color: isJellyfin
                  ? HeisucaTheme.roxoPrimaria.withOpacity(0.4)
                  : HeisucaTheme.roxoLinha,
              width: isJellyfin ? 1.5 : 1.0,
            ),
            boxShadow: isJellyfin
                ? [
                    BoxShadow(
                      color: HeisucaTheme.roxoPrimaria.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isJellyfin
                      ? HeisucaTheme.roxoPrimaria.withOpacity(0.18)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  type.icone,
                  color: isJellyfin ? HeisucaTheme.roxoPrimaria : Colors.white70,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          type.nome,
                          style: const TextStyle(
                            fontFamily: HeisucaTheme.fonteTitulo,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isJellyfin
                                ? HeisucaTheme.roxoPrimaria.withOpacity(0.2)
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            type.badge,
                            style: TextStyle(
                              fontFamily: HeisucaTheme.fonteTexto,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isJellyfin ? HeisucaTheme.roxoPrimaria : Colors.white60,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type.descricao,
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.55),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.35),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
