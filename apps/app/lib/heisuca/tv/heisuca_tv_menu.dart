import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../cgflix/you/cgflix_retrospectiva.dart';
import '../../cgflix/you/cgflix_retrospectiva_screen.dart';
import '../../design/forma.dart';
import '../../design/movimento.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../features/navegacao_tv/trilho_da_tv.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile_avatar.dart';
import '../../screens/profile/profile_switch_screen.dart';
import '../../services/updates/update_controller.dart';
import '../kids/heisuca_kids_flow.dart';

/// Menu oficial do Heisuca na TV: o trilho que entra pela esquerda (avatar no topo, ou ← na borda do conteúdo).
///
/// Destinos: Início, Filmes, Séries, Animes, Buscar. Abaixo da linha: modo infantil, retrospectiva, Trocar perfil,
/// Ajustes e, quando há versão nova, Atualizações. A escolha de um destino volta por [onSelectDestination].
class HeisucaTvMenu extends StatefulWidget {
  const HeisucaTvMenu({super.key, required this.onSelectDestination, this.initialDestination = 'Início', this.onClose});

  final ValueChanged<String> onSelectDestination;

  /// Onde a pessoa está: recebe o foco ao abrir e a marca de "você está aqui".
  final String initialDestination;
  final VoidCallback? onClose;

  /// Destinos que a tela principal sabe abrir (o resto são ações do próprio menu).
  static const destinos = ['Início', 'Filmes', 'Séries', 'Animes', 'Buscar'];

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<String> onSelectDestination,
    String initialDestination = 'Início',
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar o menu',
      // O véu do próprio trilho escurece a beirada; o resto da tela continua à vista.
      barrierColor: Colors.transparent,
      transitionDuration: Movimento.tela,
      pageBuilder: (ctx, _, _) => Align(
        alignment: Alignment.centerLeft,
        child: HeisucaTvMenu(
          onSelectDestination: (dest) {
            Navigator.of(ctx).pop();
            onSelectDestination(dest);
          },
          initialDestination: initialDestination,
          onClose: () => Navigator.of(ctx).pop(),
        ),
      ),
      transitionBuilder: (ctx, animacao, _, filho) {
        final curva = CurvedAnimation(parent: animacao, curve: Movimento.entra, reverseCurve: Movimento.sai);
        // Com "remover animações", o trilho só aparece, sem deslizar.
        if (Movimento.reduzido(ctx)) return FadeTransition(opacity: curva, child: filho);
        return FadeTransition(
          opacity: curva,
          child: SlideTransition(
            position: Tween(begin: const Offset(-0.08, 0), end: Offset.zero).animate(curva),
            child: filho,
          ),
        );
      },
    );
  }

  @override
  State<HeisucaTvMenu> createState() => _HeisucaTvMenuState();
}

class _HeisucaTvMenuState extends State<HeisucaTvMenu> {
  static const _icones = <String, IconData>{
    'Início': Symbols.home_rounded,
    'Filmes': Symbols.movie_rounded,
    'Séries': Symbols.tv_rounded,
    'Animes': Symbols.animation_rounded,
    'Buscar': Symbols.search_rounded,
  };

  void _fechar() {
    final fechar = widget.onClose;
    if (fechar != null) {
      fechar();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  /// Fecha o menu e roda [acao] no contexto da tela de baixo (o do menu morre com a rota).
  void _depoisDeFechar(void Function(BuildContext contexto) acao) {
    final navigator = Navigator.of(context);
    navigator.pop();
    acao(navigator.context);
  }

  ItemDoTrilhoTv _destino(String nome) => ItemDoTrilhoTv(
    key: ValueKey('tv-menu-$nome'),
    chave: nome,
    rotulo: nome,
    icone: _icones[nome]!,
    aoTocar: () => widget.onSelectDestination(nome),
  );

  @override
  Widget build(BuildContext context) {
    final atualizacao = context.watch<UpdateController?>();
    final kids = heisucaKidsActive(context);
    // Retrospectiva do ano (24/11): fora do kids e só com Jellyfin conectado (é onde ficam os dados).
    final retrospectiva = kids ? null : CgflixRetrospectivaFonte.of(context);
    final temPerfil = context.watch<ActiveProfileProvider?>()?.active != null;

    final extras = <ItemDoTrilhoTv>[
      if (temPerfil)
        ItemDoTrilhoTv(
          key: const ValueKey('tv-menu-infantil'),
          chave: 'infantil',
          rotulo: kids ? 'Sair do modo infantil' : 'Modo infantil',
          icone: kids ? Symbols.logout_rounded : Symbols.child_care_rounded,
          aoTocar: () => _depoisDeFechar(
            (contexto) => unawaited(kids ? heisucaExitKids(contexto).then((_) {}) : heisucaEnterKids(contexto)),
          ),
        ),
      if (retrospectiva != null)
        ItemDoTrilhoTv(
          key: const ValueKey('tv-menu-retrospectiva'),
          chave: 'retrospectiva',
          rotulo: 'Minha retrospectiva',
          icone: Symbols.auto_awesome_rounded,
          aoTocar: () => _depoisDeFechar((contexto) => cgflixOpenRetrospectiva(contexto, retrospectiva)),
        ),
      ItemDoTrilhoTv(
        key: const ValueKey('tv-menu-trocar-perfil'),
        chave: 'Trocar perfil',
        rotulo: 'Trocar perfil',
        icone: Symbols.switch_account_rounded,
        // Fecha esta rota antes de empilhar o perfil; maybePop é assíncrono.
        aoTocar: () {
          final navigator = Navigator.of(context);
          navigator.pop();
          navigator.push(MaterialPageRoute(builder: (_) => const ProfileSwitchScreen(requireSelection: false)));
        },
      ),
      ItemDoTrilhoTv(
        key: const ValueKey('tv-menu-Ajustes'),
        chave: 'Ajustes',
        rotulo: 'Ajustes',
        icone: Symbols.settings_rounded,
        aoTocar: () => widget.onSelectDestination('Ajustes'),
      ),
      if (atualizacao?.oferta != null)
        ItemDoTrilhoTv(
          key: const ValueKey('tv-menu-Atualizações'),
          chave: 'Atualizações',
          rotulo: 'Atualizações',
          icone: Symbols.system_update_rounded,
          aoTocar: () => widget.onSelectDestination('Atualizações'),
        ),
    ];

    return SizedBox(
      height: double.infinity,
      child: TrilhoDaTv(
        cabecalho: const _PerfilDoTrilho(),
        destinos: [for (final nome in HeisucaTvMenu.destinos) _destino(nome)],
        extras: extras,
        selecionado: widget.initialDestination,
        focoInicial: widget.initialDestination,
        aoFechar: _fechar,
      ),
    );
  }
}

/// Perfil ativo no topo do trilho: foto (ou inicial) e nome. Só informa; trocar fica na lista.
class _PerfilDoTrilho extends StatelessWidget {
  const _PerfilDoTrilho();

  static const double _tamanho = 48;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final perfis = context.watch<ActiveProfileProvider?>();
    final ativo = perfis?.active;
    final nome = ativo?.displayName ?? 'Família';
    final inicial = nome.isNotEmpty ? nome.characters.first.toUpperCase() : 'F';
    return Semantics(
      header: true,
      label: 'Perfil: $nome',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4),
        child: Row(
          children: [
            SizedBox.square(
              dimension: _tamanho,
              child: ClipOval(
                child: ativo != null
                    ? ProfileAvatar(profile: ativo, size: _tamanho, avatarUrl: perfis?.avatarUrlFor(ativo.id))
                    : ColoredBox(
                        color: tema.superficie2,
                        child: Center(
                          child: Text(inicial, style: Tipo.subtitulo(tema).copyWith(fontWeight: FontWeight.w700)),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: Forma.espaco3),
            Expanded(
              child: Text(
                nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Tipo.subtitulo(tema).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
