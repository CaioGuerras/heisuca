import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/forma.dart';
import '../../design/movimento.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../heisuca/theme/heisuca_base.dart';
import '../../heisuca/tv/heisuca_tv_pecas.dart';
import '../../i18n/strings.g.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_avatar.dart';
import 'moldura_da_conta_tv.dart';

/// A identidade e as ações continuam ligadas ao mesmo provedor e à mesma verificação de PIN do app.
class PerfilDaTv {
  const PerfilDaTv({
    required this.perfil,
    required this.foco,
    required this.ativo,
    required this.fontes,
    this.avatarUrl,
    this.aoEscolher,
    this.aoGerenciar,
    this.aoExcluir,
    this.aoSair,
  });

  final Profile perfil;
  final FocusNode foco;
  final bool ativo;
  final List<String> fontes;
  final String? avatarUrl;
  final VoidCallback? aoEscolher;
  final VoidCallback? aoGerenciar;
  final VoidCallback? aoExcluir;
  final VoidCallback? aoSair;
}

/// Trocar perfil pelo controle remoto: avatares e cartões da TV, ações claras e nenhum alvo só de toque.
class TelaPerfisTv extends StatelessWidget {
  const TelaPerfisTv({
    super.key,
    required this.perfis,
    required this.carregando,
    required this.aoAdicionar,
    required this.aoVoltar,
  });

  final List<PerfilDaTv> perfis;
  final bool carregando;
  final VoidCallback? aoAdicionar;
  final VoidCallback aoVoltar;

  void _mostrarFoco(BuildContext context) => unawaited(
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: Movimento.tempo(context, Movimento.toque),
      curve: Movimento.padrao,
    ),
  );

  @override
  Widget build(BuildContext context) => MolduraDaContaTv(
    titulo: t.screens.switchProfile,
    conteudo: (context) {
      final tema = TemaHeisuca.de(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (carregando)
            const Center(child: CircularProgressIndicator())
          else if (perfis.isEmpty) ...[
            Text(t.messages.noProfilesAvailable, style: tvTexto(Tipo.subtitulo(tema))),
            Text(t.messages.contactAdminForProfiles, style: tvTexto(Tipo.texto(tema))),
          ] else
            LayoutBuilder(
              builder: (context, limites) {
                const colunas = 3;
                final largura = (limites.maxWidth - Forma.espaco6 * (colunas - 1)) / colunas;
                return Wrap(
                  spacing: Forma.espaco6,
                  runSpacing: HeisucaBase.espaco8,
                  children: [
                    for (final (i, perfil) in perfis.indexed)
                      SizedBox(
                        key: ValueKey('perfil-grupo-tv-${perfil.perfil.id}'),
                        width: largura,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CartaoTv(
                              key: ValueKey('perfil-tv-${perfil.perfil.id}'),
                              largura: largura,
                              alturaDaArte: Forma.toqueMinimo * 4,
                              titulo: perfil.perfil.displayName,
                              legenda: perfil.ativo
                                  ? t.profiles.active
                                  : (perfil.perfil.isPinProtected ? 'Protegido por PIN' : null),
                              destaque: perfil.ativo,
                              redondo: true,
                              arte: (_, tamanho) => Center(
                                child: ProfileAvatar(
                                  profile: perfil.perfil,
                                  size: tamanho.height,
                                  avatarUrl: perfil.avatarUrl,
                                  // O círculo recortaria o selo no canto; o estado de PIN já está na legenda.
                                  showLockBadge: false,
                                ),
                              ),
                              aoTocar: perfil.aoEscolher,
                              focusNode: perfil.foco,
                              autofocus: i == 0,
                              aoFocar: (focado) {
                                final contexto = perfil.foco.context;
                                if (focado && contexto != null) _mostrarFoco(contexto);
                              },
                            ),
                            const SizedBox(height: Forma.espaco4),
                            if (perfil.ativo && perfil.perfil.isPinProtected) ...[
                              Text(
                                'Protegido por PIN',
                                textAlign: TextAlign.center,
                                style: tvTexto(Tipo.pequeno(tema)),
                              ),
                              const SizedBox(height: Forma.espaco4),
                            ],
                            Text(
                              perfil.fontes.isEmpty ? t.profiles.noConnections : perfil.fontes.join(' · '),
                              textAlign: TextAlign.center,
                              style: tvTexto(Tipo.pequeno(tema)),
                            ),
                            const SizedBox(height: Forma.espaco4),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: Forma.espaco4,
                              runSpacing: Forma.espaco4,
                              children: [
                                if (perfil.aoGerenciar != null) _acao(context, t.profiles.manage, perfil.aoGerenciar!),
                                if (perfil.aoExcluir != null) _acao(context, t.profiles.delete, perfil.aoExcluir!),
                                if (perfil.aoSair != null) _acao(context, t.profiles.signOut, perfil.aoSair!),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: HeisucaBase.espaco8),
          Wrap(
            spacing: Forma.espaco6,
            runSpacing: Forma.espaco6,
            alignment: WrapAlignment.center,
            children: [
              Builder(
                builder: (context) => BotaoTv(
                  rotulo: t.profiles.addHeisucaProfile,
                  icone: Symbols.person_add_rounded,
                  compacto: true,
                  autofocus: !carregando && perfis.isEmpty,
                  aoTocar: aoAdicionar,
                  aoFocar: () => _mostrarFoco(context),
                ),
              ),
              _acao(context, 'Voltar', aoVoltar),
            ],
          ),
        ],
      );
    },
  );

  Widget _acao(BuildContext context, String rotulo, VoidCallback acao) => Builder(
    builder: (context) => BotaoTv(rotulo: rotulo, compacto: true, aoTocar: acao, aoFocar: () => _mostrarFoco(context)),
  );
}
