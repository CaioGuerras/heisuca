// Dicas do Heisuca (refino 2): explicações curtas, em português simples, para as funções que
// quem não entende de tecnologia não pega de primeira. TODOS os textos ficam aqui, para editar
// sem caçar pelo código:
//   - `resumo`: uma linha que aparece sob o item nas Configurações;
//   - `texto`: 2 a 4 frases, na folha que abre no ícone "?" (help) e em Sobre › Dicas do Heisuca.
// A dica do player (gestos) aparece uma vez só, na primeira vez que um vídeo abre no celular, e
// some sozinha ou com um toque; fica guardada no aparelho (`cgflixDicaPlayerVistaPref`) e pode ser
// revista em Sobre › Dicas do Heisuca. Com "remover animações" ligado, nada se mexe.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../services/settings_service.dart';
import '../widgets/app_icon.dart';
import 'cgflix_palette.dart';
import 'cgflix_style.dart';

/// Cada dica: ícone, título, uma linha de resumo e o texto completo.
enum CgflixDica {
  navegacao(
    Symbols.explore_rounded,
    'Por onde começar',
    'Use Início, Biblioteca, Baixados e Você na barra de baixo.',
    'Na barra de baixo, Início mostra os destaques e Biblioteca abre seu acervo. '
        'Baixados reúne os vídeos para ver sem internet. '
        'Você reúne sua conta, os perfis e as configurações.',
  ),
  pularAbertura(
    Symbols.fast_forward_rounded,
    'Pular abertura e créditos',
    'Pula a abertura e, no fim, vai para o próximo episódio.',
    'Quando o servidor sabe onde fica a abertura, aparece o botão "Pular abertura". '
        'No modo "Automático", o Heisuca pula sozinho depois de alguns segundos. '
        'Nos créditos do fim, o botão leva direto ao próximo episódio. '
        'Para ver tudo, escolha "Desligado".',
  ),
  idiomas(
    Symbols.voice_selection_rounded,
    'Áudio e legenda preferidos',
    'Escolha uma vez e o vídeo já começa no idioma certo.',
    'Escolha o idioma do áudio (por exemplo, português para os dublados) e o da legenda. '
        'Fica salvo na sua conta do servidor, então vale no celular, na TV e no site. '
        'Durante o vídeo, dá para trocar quando quiser no botão de legenda.',
  ),
  qualidade(
    Symbols.high_quality_rounded,
    'Qualidade e dados móveis',
    'Escolha a qualidade e cuide do seu plano de internet.',
    'Escolha Original em Configurações › Qualidade de reprodução para priorizar a qualidade do arquivo no servidor. '
        'Um filme pode gastar vários gigabytes no 4G ou 5G. '
        'Para poupar internet móvel, assista no Wi-Fi ou baixe antes.',
  ),
  downloads(
    Symbols.download_for_offline_rounded,
    'Baixar para ver sem internet',
    'Baixe no Wi-Fi e assista depois, até no avião.',
    'Toque em "Baixar" na página do filme ou do episódio. '
        'Abra Baixados na barra de baixo para assistir sem internet. '
        'Com "Baixar só no Wi-Fi" ligado, nada gasta seus dados móveis. '
        'Para liberar espaço, ligue "Apagar baixados já assistidos".',
  ),
  verNaTv(
    Symbols.tv_rounded,
    'Ver na TV',
    'Veja as opções para sua TV e como entrar com um código.',
    'Na Samsung e na LG, use nossos apps de TV; no Fire TV, Google TV/Android TV, Roku e Apple TV, '
        'use um app compatível com Jellyfin ou Plex.\n\n'
        'No Jellyfin, escolha Quick Connect na TV e autorize o código pelo site do servidor onde você já entrou. '
        'No Plex, abra plex.tv/link no celular, entre na sua conta Plex e digite o código da TV.\n\n'
        'Para espelhar, use a função do seu celular e da TV, como Smart View ou Transmitir tela.',
  ),
  meusPedidos(
    Symbols.playlist_add_check_rounded,
    'Meus pedidos',
    'Peça o que não achou e acompanhe até chegar.',
    'Não achou um filme ou série na busca? Toque em "Pedir", em "Disponível para pedir". '
        'Em Meus pedidos você acompanha cada um: Pedido, Baixando e Disponível. '
        'Quando chegar, aparece no Heisuca como qualquer outro título.',
  ),
  minhaConta(
    Symbols.account_circle_rounded,
    'Minha conta',
    'Atualize a foto e a senha da sua conta.',
    'Com uma fonte Jellyfin conectada, abra Você › Conta › Minha conta: foto e senha. '
        'Ali, você troca a foto e a senha do Jellyfin. '
        'Nos outros aparelhos, entre de novo com a senha nova quando for pedido. '
        'No Plex, gerencie a conta pelo site plex.tv.',
  ),
  gestos(
    Symbols.touch_app_rounded,
    'Gestos na tela do vídeo',
    'Toque duas vezes para avançar ou voltar; deslize para o volume e o brilho.',
    'Toque duas vezes no lado direito do vídeo para avançar e no esquerdo para voltar. '
        'Deslize para cima ou para baixo na beirada direita para o volume e na esquerda para o brilho. '
        'Junte dois dedos para dar zoom. Um toque mostra ou esconde os botões.',
  ),
  travarTela(
    Symbols.lock_rounded,
    'Travar a tela',
    'Trava os toques: ninguém pausa sem querer.',
    'Na tela do vídeo, o cadeado trava os toques: bom para criança assistir sem pausar ou sair sem querer. '
        'Para destravar, toque na tela e segure o dedo no aviso do cadeado.',
  ),
  janelinha(
    Symbols.picture_in_picture_alt_rounded,
    'Janelinha',
    'O vídeo continua numa janelinha enquanto você usa outro app.',
    'Toque no botão da janelinha na tela do vídeo, ou saia do app com o vídeo tocando quando '
        '"Abrir a janelinha ao sair" estiver ligado. '
        'Arraste a janelinha para onde quiser; toque nela para voltar ao Heisuca.',
  ),
  filtrosImagem(
    Symbols.auto_fix_high_rounded,
    'Filtros de imagem',
    'Melhoram a imagem no aparelho. Ficam em Ajustes no player.',
    'Eles melhoram a nitidez da imagem direto no seu aparelho, sem exigir nada a mais do servidor. '
        'No player, abra Ajustes › Filtros de imagem e escolha Anime4K ou ArtCNN para desenhos e animes, ou NVScaler para filmes e séries. '
        'Como usam mais processamento, gastam mais bateria e podem esquentar celulares mais simples; para voltar ao padrão, basta escolher "Desligado".',
  );

  const CgflixDica(this.icone, this.titulo, this.resumo, this.texto);
  final IconData icone;
  final String titulo;
  final String resumo;
  final String texto;
}

/// Guardado no aparelho: a dica do player já foi vista (não volta mais).
const cgflixDicaPlayerVistaPref = BoolPref('cgflix_dica_player_vista');

/// Texto da dica única do player (curto: aparece por cima do vídeo).
const cgflixDicaPlayerTexto =
    'Toque duas vezes nos lados para avançar ou voltar. '
    'Deslize na beirada direita para o volume e na esquerda para o brilho.';

/// Quanto tempo a dica do player fica na tela antes de sumir sozinha.
const cgflixDicaPlayerDuracao = Duration(seconds: 8);

/// Abre a folha inferior com a dica completa.
Future<void> showCgflixDica(BuildContext context, CgflixDica dica) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 560),
    backgroundColor: context.cgflix.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetContext) => CgflixDicaSheet(dica: dica),
  );
}

/// Conteúdo da folha (separado para os testes).
class CgflixDicaSheet extends StatelessWidget {
  const CgflixDicaSheet({super.key, required this.dica});
  final CgflixDica dica;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          key: ValueKey('cgflix-dica-${dica.name}'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(dica.icone, fill: 1, size: 28, color: context.cgflix.accentSoft),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(dica.titulo, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(dica.texto, style: theme.textTheme.bodyLarge?.copyWith(height: 1.4)),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ícone "?" (Material Symbols Rounded `help`, contorno) que abre a dica. Toque de 48 dp.
class CgflixDicaButton extends StatelessWidget {
  const CgflixDicaButton({super.key, required this.dica});
  final CgflixDica dica;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: ValueKey('cgflix-dica-botao-${dica.name}'),
      icon: AppIcon(Symbols.help_rounded, fill: 0, size: 24, color: context.cgflix.textMuted),
      tooltip: 'Saiba mais: ${dica.titulo}',
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: () => showCgflixDica(context, dica),
    );
  }
}

/// Item das Configurações com o "?" ao lado (o item continua igual; o "?" fica à direita).
class CgflixComDica extends StatelessWidget {
  const CgflixComDica({super.key, required this.dica, required this.child});
  final CgflixDica dica;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: child),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: CgflixDicaButton(dica: dica),
        ),
      ],
    );
  }
}

/// Testes: força a dica do player (null = lê a preferência).
@visibleForTesting
bool? cgflixDicaPlayerDebugVista;

bool _dicaPlayerVista() {
  if (cgflixDicaPlayerDebugVista case final forced?) return forced;
  return SettingsService.instanceOrNull?.read(cgflixDicaPlayerVistaPref) ?? true;
}

Future<void> _marcarDicaPlayerVista(bool vista) async {
  if (cgflixDicaPlayerDebugVista != null) {
    cgflixDicaPlayerDebugVista = vista;
    return;
  }
  await SettingsService.instanceOrNull?.write(cgflixDicaPlayerVistaPref, vista);
}

/// Faz a dica do player aparecer de novo no próximo vídeo (Sobre › Dicas do Heisuca).
Future<void> cgflixReverDicaPlayer() => _marcarDicaPlayerVista(false);

/// Dica única do player: um cartão discreto embaixo, por cima do vídeo. Aparece só se ainda não foi
/// vista; some com um toque ou depois de [cgflixDicaPlayerDuracao] e não volta mais.
class CgflixDicaPlayer extends StatefulWidget {
  const CgflixDicaPlayer({super.key});

  @override
  State<CgflixDicaPlayer> createState() => _CgflixDicaPlayerState();
}

class _CgflixDicaPlayerState extends State<CgflixDicaPlayer> {
  late bool _visivel = !_dicaPlayerVista();
  bool _saindo = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_visivel) {
      // Já conta como vista ao aparecer: se o app fechar no meio, não volta.
      unawaited(_marcarDicaPlayerVista(true));
      _timer = Timer(cgflixDicaPlayerDuracao, _fechar);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _fechar() {
    _timer?.cancel();
    if (!mounted || _saindo) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _visivel = false);
    } else {
      setState(() => _saindo = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visivel) return const SizedBox.shrink();
    final reduzir = MediaQuery.disableAnimationsOf(context);
    final cartao = Semantics(
      liveRegion: true,
      button: true,
      label: 'Dica: $cgflixDicaPlayerTexto Toque para fechar.',
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('cgflix-dica-player'),
        behavior: HitTestBehavior.opaque,
        onTap: _fechar,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, minHeight: 48),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            // Player é sempre escuro: cartão escuro translúcido, texto branco.
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: const BorderRadius.all(Radius.circular(16)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(Symbols.touch_app_rounded, fill: 1, size: 28, color: Colors.white),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  cgflixDicaPlayerTexto,
                  style: TextStyle(color: Colors.white, fontSize: 14, height: 1.35, fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(width: 8),
              AppIcon(Symbols.close_rounded, fill: 0, size: 20, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
    return Align(
      // Acima do centro: não cobre o play/pausa nem a barra de tempo.
      alignment: const Alignment(0, -0.42),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: reduzir
            ? cartao
            : AnimatedOpacity(
                opacity: _saindo ? 0 : 1,
                duration: CgflixMotion.medium,
                curve: CgflixMotion.curve,
                onEnd: () {
                  if (_saindo && mounted) setState(() => _visivel = false);
                },
                child: cartao,
              ),
      ),
    );
  }
}

/// Linha "Dicas do Heisuca" do Sobre.
class CgflixDicasAboutTile extends StatelessWidget {
  const CgflixDicasAboutTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: const ValueKey('cgflix-dicas'),
      minTileHeight: 56,
      leading: const AppIcon(Symbols.lightbulb_rounded, fill: 0),
      title: const Text('Dicas do Heisuca'),
      subtitle: const Text('Como usar as funções do app, em poucas palavras'),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: 'cgflix/dicas'),
          builder: (_) => const CgflixDicasScreen(),
        ),
      ),
    );
  }
}

/// Todas as dicas numa tela (Sobre › Dicas do Heisuca), com "Ver de novo a dica do player".
class CgflixDicasScreen extends StatelessWidget {
  const CgflixDicasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Dicas do Heisuca')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
          children: [
            for (final dica in CgflixDica.values)
              ListTile(
                key: ValueKey('cgflix-dicas-${dica.name}'),
                minTileHeight: 56,
                leading: AppIcon(dica.icone, fill: 0, size: 24),
                title: Text(dica.titulo),
                subtitle: Text(dica.resumo),
                trailing: const AppIcon(Symbols.help_rounded, fill: 0),
                onTap: () => showCgflixDica(context, dica),
              ),
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                key: const ValueKey('cgflix-dicas-rever-player'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: const AppIcon(Symbols.replay_rounded, fill: 0),
                label: const Text('Ver de novo a dica dos gestos'),
                onPressed: () async {
                  await cgflixReverDicaPlayer();
                  if (!context.mounted) return;
                  ScaffoldMessenger.maybeOf(
                    context,
                  )?.showSnackBar(const SnackBar(content: Text('Pronto. A dica aparece no próximo vídeo.')));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'A dica dos gestos aparece uma vez, na primeira vez que você abre um vídeo.',
                style: theme.textTheme.bodySmall?.copyWith(color: context.cgflix.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
