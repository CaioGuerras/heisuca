import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../cgflix/apoio/apoio.dart';
import '../../cgflix/apoio/cgflix_apoio_screen.dart';
import '../../cgflix/cgflix_navigation.dart';
import '../../cgflix/cgflix_user_menu.dart' show cgflixUserMenuDebugOnline;
import '../../cgflix/conta/cgflix_conta.dart';
import '../../cgflix/conta/cgflix_minha_conta_screen.dart';
import '../../design/forma.dart';
import '../../heisuca/heisuca_security.dart';
import '../../heisuca/heisuca_settings_screen.dart';
import '../../heisuca/heisuca_source_scope.dart';
import '../../heisuca/kids/heisuca_kids.dart';
import '../../heisuca/kids/heisuca_kids_flow.dart';
import '../../heisuca/kids/heisuca_kids_identity.dart';
import '../../i18n/strings.g.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile_avatar.dart';
import '../../providers/multi_server_provider.dart';
import '../../screens/profile/profile_switch_screen.dart';
import '../../screens/profile/profile_teardown.dart';
import '../../screens/settings/about_screen.dart';
import '../../screens/updates/update_settings_screen.dart';
import '../../services/updates/update_controller.dart';
import '../../utils/dialogs.dart';
import '../tema_da_v2.dart';
import 'tela_voce.dart';

/// O que cada cartão da Você faz. Tudo já existia nas telas antigas: aqui só se liga.
///
/// Os testes trocam estas ações; no app valem as de [AcoesDaVoce.padrao].
class AcoesDaVoce {
  const AcoesDaVoce({
    required this.minhaConta,
    required this.meusPedidos,
    required this.perfis,
    required this.modoInfantil,
    required this.perfilInfantil,
    required this.sairDoModoInfantil,
    required this.configuracoes,
    required this.atualizacoes,
    required this.sobre,
    required this.trocarUsuario,
    required this.servidores,
    required this.confirmarSaida,
    required this.sair,
    required this.apoie,
  });

  /// As ações das telas antigas, sem mudar nada nelas.
  const AcoesDaVoce.padrao()
    : minhaConta = _minhaConta,
      meusPedidos = _meusPedidos,
      perfis = _perfis,
      modoInfantil = _modoInfantil,
      perfilInfantil = _perfilInfantil,
      sairDoModoInfantil = _sairDoModoInfantil,
      configuracoes = _configuracoes,
      atualizacoes = _atualizacoes,
      sobre = _sobre,
      trocarUsuario = _trocarUsuario,
      servidores = _servidores,
      confirmarSaida = _confirmarSaida,
      sair = _sair,
      apoie = _apoie;

  final void Function(BuildContext context) minhaConta;
  final void Function(BuildContext context) meusPedidos;
  final void Function(BuildContext context, String idDoPerfil) perfis;
  final void Function(BuildContext context) modoInfantil;
  final void Function(BuildContext context, HeisucaKidsRecord perfil) perfilInfantil;
  final void Function(BuildContext context) sairDoModoInfantil;
  final void Function(BuildContext context) configuracoes;
  final void Function(BuildContext context) atualizacoes;
  final void Function(BuildContext context) sobre;
  final void Function(BuildContext context) trocarUsuario;

  /// Lista os servidores salvos, troca entre eles e adiciona outro sem sair do atual.
  final void Function(BuildContext context) servidores;

  /// Pergunta se quer mesmo sair. `true` confirma.
  final Future<bool> Function(BuildContext context) confirmarSaida;

  /// Encerra a sessão em todos os perfis. Só roda depois do "sim".
  final Future<void> Function(BuildContext context) sair;
  final void Function(BuildContext context) apoie;

  static void _minhaConta(BuildContext context) {
    final conta = CgflixConta.of(context);
    if (conta != null) cgflixAbrirMinhaConta(context, conta);
  }

  static void _meusPedidos(BuildContext context) => unawaited(cgflixOpenMyRequests(context));

  static void _perfis(BuildContext context, String idDoPerfil) => unawaited(
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => HeisucaSecurityScreen(parentId: idDoPerfil))),
  );

  static void _modoInfantil(BuildContext context) => unawaited(heisucaEnterKids(context));

  static void _perfilInfantil(BuildContext context, HeisucaKidsRecord perfil) => unawaited(
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => HeisucaKidsIdentityScreen(record: perfil))),
  );

  static void _sairDoModoInfantil(BuildContext context) => unawaited(heisucaExitKids(context));

  static void _configuracoes(BuildContext context) =>
      unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HeisucaSettingsScreen())));

  static void _atualizacoes(BuildContext context) =>
      unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const UpdateSettingsScreen())));

  static void _sobre(BuildContext context) =>
      unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AboutScreen())));

  static void _trocarUsuario(BuildContext context) => unawaited(
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfileSwitchScreen())),
  );

  static void _servidores(BuildContext context) => unawaited(heisucaChooseSource(context));

  static Future<bool> _confirmarSaida(BuildContext context) => showConfirmDialog(
    context,
    title: t.common.logout,
    message: t.messages.logoutConfirm,
    confirmText: t.common.logout,
    isDestructive: true,
  );

  static Future<void> _sair(BuildContext context) => logoutAllProfiles(context);

  static void _apoie(BuildContext context) => unawaited(cgflixAbrirApoio(context));
}

/// Liga a tela Você ao app: perfil em uso, servidor, modo infantil e as ações de sempre.
///
/// Abre pela pílula do perfil no topo da casca.
class LigacaoDaVoce extends StatelessWidget {
  const LigacaoDaVoce({super.key, this.folgaInferior = Forma.espaco6, this.acoes = const AcoesDaVoce.padrao()});

  final double folgaInferior;
  final AcoesDaVoce acoes;

  /// Há servidor conectado? Sem ele, "Minha conta" e "Meus pedidos" não têm para onde ir.
  static bool _servidorOnline(BuildContext context) {
    if (cgflixUserMenuDebugOnline case final forcado?) return forcado;
    try {
      final servidores = context.watch<MultiServerProvider?>();
      return servidores?.serverManager.visibleOnlineClients.isNotEmpty ?? false;
    } on ProviderNotFoundException {
      return false;
    }
  }

  Future<void> _pedirParaSair(BuildContext context) async {
    final confirmou = await acoes.confirmarSaida(context);
    if (confirmou && context.mounted) await acoes.sair(context);
  }

  @override
  Widget build(BuildContext context) {
    final perfis = context.watch<ActiveProfileProvider?>();
    final ativo = perfis?.active;
    final kids = context.watch<HeisucaKids?>() ?? HeisucaKids.instance;
    final infantil = kids.isKids(ativo?.id);
    final perfilInfantil = kids.forParent(ativo?.id);
    final atualizacoes = context.watch<UpdateController?>();
    final online = _servidorOnline(context);
    final conta = online ? CgflixConta.of(context) : null;
    final apoio = cgflixApoioAtual.disponivel;

    final List<List<ItemDaVoce>> grupos;
    if (infantil) {
      grupos = [
        [
          ItemDaVoce(
            chave: 'sair-do-modo-infantil',
            icone: Symbols.lock_open_rounded,
            titulo: 'Sair do modo infantil',
            subtitulo: 'Pede o PIN do responsável',
            aoTocar: () => acoes.sairDoModoInfantil(context),
          ),
        ],
      ];
    } else {
      grupos = [
        [
          if (conta != null)
            ItemDaVoce(
              chave: 'minha-conta',
              icone: Symbols.manage_accounts_rounded,
              titulo: 'Minha conta',
              subtitulo: 'Foto e senha',
              aoTocar: () => acoes.minhaConta(context),
            ),
          if (online)
            ItemDaVoce(
              chave: 'meus-pedidos',
              icone: Symbols.playlist_add_check_rounded,
              titulo: 'Meus pedidos',
              subtitulo: 'Filmes e séries que você pediu',
              aoTocar: () => acoes.meusPedidos(context),
            ),
          ItemDaVoce(
            chave: 'trocar-usuario',
            icone: Symbols.switch_account_rounded,
            titulo: 'Trocar usuário',
            subtitulo: 'Entrar com outro perfil salvo',
            aoTocar: () => acoes.trocarUsuario(context),
          ),
          ItemDaVoce(
            chave: 'servidores',
            icone: Symbols.dns_rounded,
            titulo: 'Servidores',
            subtitulo: 'Trocar de servidor ou adicionar outro',
            aoTocar: () => acoes.servidores(context),
          ),
        ],
        [
          if (ativo != null)
            ItemDaVoce(
              chave: 'perfis',
              icone: Symbols.fingerprint_rounded,
              titulo: 'Perfis e PIN',
              subtitulo: 'Bloqueio do app e saída do modo infantil',
              aoTocar: () => acoes.perfis(context, ativo.id),
            ),
          ItemDaVoce(
            chave: 'modo-infantil',
            icone: Symbols.child_care_rounded,
            titulo: 'Modo infantil',
            subtitulo: perfilInfantil != null
                ? 'Entrar no perfil ${perfilInfantil.name}'
                : 'Só desenhos e filmes para crianças',
            aoTocar: () => acoes.modoInfantil(context),
          ),
          if (perfilInfantil != null)
            ItemDaVoce(
              chave: 'perfil-infantil',
              icone: Symbols.edit_rounded,
              titulo: 'Perfil infantil',
              subtitulo: '${perfilInfantil.name}: nome, foto, tema e PIN',
              aoTocar: () => acoes.perfilInfantil(context, perfilInfantil),
            ),
        ],
        [
          ItemDaVoce(
            chave: 'configuracoes',
            icone: Symbols.tune_rounded,
            titulo: 'Configurações',
            subtitulo: 'Reprodução, vídeo, áudio e legendas',
            aoTocar: () => acoes.configuracoes(context),
          ),
          // Só na versão baixada pelo site: na loja quem atualiza é a própria loja.
          if (atualizacoes?.permiteAjustes == true)
            ItemDaVoce(
              chave: 'atualizacoes',
              icone: Symbols.system_update_rounded,
              titulo: 'Atualizações',
              subtitulo: atualizacoes?.oferta != null ? 'Há uma versão nova' : 'Buscar versão nova e escolher o canal',
              aoTocar: () => acoes.atualizacoes(context),
            ),
          ItemDaVoce(
            chave: 'sobre',
            icone: Symbols.info_rounded,
            titulo: 'Sobre o Heisuca',
            subtitulo: 'Novidades, versão e licenças',
            aoTocar: () => acoes.sobre(context),
          ),
          if (apoio)
            ItemDaVoce(
              chave: 'apoie',
              icone: Symbols.favorite_rounded,
              titulo: 'Apoie',
              subtitulo: 'Ajude a manter o Heisuca',
              aoTocar: () => acoes.apoie(context),
            ),
        ],
        [
          ItemDaVoce(
            chave: 'sair',
            icone: Symbols.logout_rounded,
            titulo: 'Sair',
            subtitulo: 'Encerrar a sessão neste aparelho',
            perigoso: true,
            aoTocar: () => unawaited(_pedirParaSair(context)),
          ),
        ],
      ];
    }

    return SobOTemaDaV2(
      child: TelaVoce(
        nome: ativo?.displayName ?? '',
        avatar: ativo == null
            ? null
            : ProfileAvatar(
                profile: ativo,
                size: TelaVoce.ladoDoAvatar,
                showLockBadge: false,
                avatarUrl: perfis?.avatarUrlFor(ativo.id),
              ),
        grupos: grupos,
        aoVoltar: Navigator.of(context).canPop() ? () => unawaited(Navigator.of(context).maybePop()) : null,
        folgaInferior: folgaInferior,
      ),
    );
  }
}
