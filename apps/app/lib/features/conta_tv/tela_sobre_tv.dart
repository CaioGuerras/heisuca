import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../cgflix/apoio/apoio.dart';
import '../../cgflix/apoio/cgflix_apoio_screen.dart';
import '../../cgflix/cgflix_about.dart';
import '../../cgflix/cgflix_dicas.dart';
import '../../cgflix/cgflix_version.dart';
import '../../design/forma.dart';
import '../../design/movimento.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../heisuca/heisuca_logo.dart';
import '../../heisuca/heisuca_news.dart';
import '../../heisuca/theme/heisuca_base.dart';
import '../../heisuca/tv/heisuca_tv_pecas.dart';
import '../../i18n/strings.g.dart';
import '../../screens/settings/licenses_screen.dart';
import 'moldura_da_conta_tv.dart';

/// O conteúdo aprovado do Sobre, numa grade de cartões iguais e ações próprias para controle remoto.
class TelaSobreTv extends StatelessWidget {
  const TelaSobreTv({super.key, required this.versao, required this.numeroBuild});

  final String versao;
  final String numeroBuild;

  void _abrir(BuildContext context, Widget tela) =>
      unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => tela)));

  static void _mostrarFoco(BuildContext context) => unawaited(
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: Movimento.tempo(context, Movimento.toque),
      curve: Movimento.padrao,
    ),
  );

  @override
  Widget build(BuildContext context) => MolduraDaContaTv(
    titulo: 'Sobre',
    conteudo: (context) {
      final tema = TemaHeisuca.de(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: HeisucaLogo(height: Forma.toqueMinimo * 2)),
          const SizedBox(height: Forma.espaco4),
          Text('Nada entre você e o filme.', textAlign: TextAlign.center, style: tvTexto(Tipo.subtitulo(tema))),
          Text(
            cgflixVersionLabel(versao, numeroBuild),
            textAlign: TextAlign.center,
            style: tvTexto(Tipo.pequeno(tema)),
          ),
          const SizedBox(height: HeisucaBase.espaco8),
          _fileira([
            _CartaoSobreTv(
              chave: 'dicas',
              titulo: 'Dicas do Heisuca',
              descricao: 'Conheça os recursos do Heisuca.',
              rotulo: 'Abrir dicas',
              icone: Symbols.help_rounded,
              inicial: true,
              aoTocar: () => _abrir(context, const CgflixDicasScreen()),
            ),
            _CartaoSobreTv(
              chave: 'codigo',
              titulo: 'Código aberto',
              subtitulo: 'Licença GPL-3.0',
              descricao: 'O Heisuca é software livre: qualquer pessoa pode ver, estudar e melhorar o código.',
              rotulo: 'Ver o código',
              icone: Symbols.code_rounded,
              aoTocar: () => unawaited(
                launchUrl(Uri.parse('https://github.com/CaioGuerras/heisuca'), mode: LaunchMode.externalApplication),
              ),
            ),
          ]),
          const SizedBox(height: Forma.espaco6),
          Semantics(header: true, child: Text('Agradecimentos', style: tvTexto(Tipo.subtitulo(tema)))),
          const SizedBox(height: Forma.espaco4),
          _fileira([
            _CartaoSobreTv(
              chave: 'rosiel',
              titulo: '🤝 Rosiel Victor',
              descricao: 'Por sempre apoiar a fazer essas coisas rsrs.',
              rotulo: 'all.dev.br',
              icone: Symbols.person_rounded, // o 🤝 já está no título; o ícone não repete o aperto de mão
              aoTocar: () =>
                  unawaited(launchUrl(Uri.parse('https://all.dev.br/'), mode: LaunchMode.externalApplication)),
            ),
            _CartaoSobreTv(
              chave: 'locadora',
              titulo: 'Locadora',
              descricao: 'Por até rir às vezes mas sempre me encorajar a evoluir, mesmo que cheio de HnR no site.',
              rotulo: 'locadora.cc',
              icone: Symbols.movie_filter_rounded,
              aoTocar: () =>
                  unawaited(launchUrl(Uri.parse('https://locadora.cc/'), mode: LaunchMode.externalApplication)),
            ),
          ]),
          const SizedBox(height: Forma.espaco6),
          _fileira([
            _CartaoSobreTv(
              chave: 'licencas',
              titulo: t.about.openSourceLicenses,
              descricao: t.about.viewLicensesDescription,
              rotulo: 'Licenças',
              icone: Symbols.description_rounded,
              aoTocar: () => _abrir(context, const LicensesScreen()),
            ),
            if (heisucaNewsAvailable(context))
              _CartaoSobreTv(
                chave: 'novidades',
                titulo: 'Novidades',
                descricao: 'O que mudou no Heisuca',
                rotulo: 'Novidades',
                icone: Symbols.auto_awesome_rounded,
                aoTocar: () => _abrir(context, const HeisucaNewsScreen()),
              )
            else if (cgflixApoioAtual.disponivel)
              _CartaoSobreTv(
                chave: 'apoio',
                titulo: cgflixApoioTitulo,
                descricao: 'Gorjeta opcional, se você quiser.',
                rotulo: 'Apoiar',
                icone: Symbols.favorite_rounded,
                aoTocar: () => unawaited(cgflixAbrirApoio(context)),
              ),
          ]),
          if (heisucaNewsAvailable(context) && cgflixApoioAtual.disponivel) ...[
            const SizedBox(height: Forma.espaco6),
            _fileira([
              _CartaoSobreTv(
                chave: 'apoio',
                titulo: cgflixApoioTitulo,
                descricao: 'Gorjeta opcional, se você quiser.',
                rotulo: 'Apoiar',
                icone: Symbols.favorite_rounded,
                aoTocar: () => unawaited(cgflixAbrirApoio(context)),
              ),
            ]),
          ],
          const SizedBox(height: HeisucaBase.espaco8),
          Text(cgflixDedicationText, textAlign: TextAlign.center, style: tvTexto(Tipo.pequeno(tema))),
          const SizedBox(height: Forma.espaco2),
          Text(
            '🤖 Em parceria com IA: Claude, Codex e Gemini.',
            textAlign: TextAlign.center,
            style: tvTexto(Tipo.pequeno(tema)),
          ),
          const SizedBox(height: Forma.espaco6),
          Align(
            alignment: Alignment.center,
            child: Builder(
              builder: (context) => BotaoTv(
                rotulo: 'Voltar',
                icone: Symbols.arrow_back_rounded,
                aoFocar: () => _mostrarFoco(context),
                aoTocar: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _fileira(List<Widget> cartoes) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: cartoes.first),
        const SizedBox(width: Forma.espaco6),
        Expanded(child: cartoes.length > 1 ? cartoes[1] : const SizedBox.shrink()),
      ],
    ),
  );
}

class _CartaoSobreTv extends StatelessWidget {
  const _CartaoSobreTv({
    required this.chave,
    required this.titulo,
    this.subtitulo,
    required this.descricao,
    required this.rotulo,
    required this.icone,
    required this.aoTocar,
    this.inicial = false,
  });

  final String chave;
  final String titulo;
  final String? subtitulo;
  final String descricao;
  final String rotulo;
  final IconData icone;
  final VoidCallback aoTocar;
  final bool inicial;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return Container(
      key: ValueKey('sobre-tv-$chave'),
      padding: const EdgeInsets.all(HeisucaBase.espaco8),
      decoration: ShapeDecoration(color: tema.superficie, shape: Forma.superelipse(Forma.raioMedio)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, size: Forma.toqueMinimo, color: tema.texto2),
              const SizedBox(width: Forma.espaco4),
              Expanded(child: Text(titulo, style: tvTexto(Tipo.subtitulo(tema)))),
            ],
          ),
          if (subtitulo != null) Text(subtitulo!, style: tvTexto(Tipo.pequeno(tema))),
          const SizedBox(height: Forma.espaco4),
          Text(descricao, style: tvTexto(Tipo.texto(tema))),
          const SizedBox(height: Forma.espaco6),
          const Spacer(),
          Builder(
            builder: (context) => Align(
              alignment: Alignment.centerLeft,
              child: BotaoTv(
                rotulo: rotulo,
                compacto: true,
                autofocus: inicial,
                aoFocar: () => TelaSobreTv._mostrarFoco(context),
                aoTocar: aoTocar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
