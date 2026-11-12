import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/cor_poster/cor_poster_cache.dart';
import '../design/cor_poster/paleta_poster.dart';
import '../design/cor_poster/temas_cor_poster.dart';
import '../design/movimento.dart';
import '../design/tema.dart';

/// A parede das telas da V2: o fundo tingido pela cor do pôster, nos três temas.
///
/// O pôster tinge o fundo e as superfícies de quem está dentro ([TemaHeisuca.superficie] e
/// [TemaHeisuca.superficie2]); texto e acento continuam os do tema. Sem [hash], ou enquanto a cor
/// não chega, vale a paleta neutra do tema. A troca de cor é animada e respeita "remover animações".
class FundoTingido extends StatefulWidget {
  const FundoTingido({super.key, required this.hash, required this.child, this.preparar = const [], this.cores});

  /// BlurHash da arte que tinge a tela agora.
  final String? hash;

  /// Outros BlurHash que a tela pode pedir em seguida: a cor deles fica pronta antes.
  final List<String> preparar;

  /// De onde sai a cor do pôster; por padrão, o cache do app.
  final CorPosterCache? cores;

  final Widget child;

  @override
  State<FundoTingido> createState() => _FundoTingidoState();
}

class _FundoTingidoState extends State<FundoTingido> {
  CorPosterCache get _cores => widget.cores ?? CorPosterCache.global;

  @override
  void initState() {
    super.initState();
    _cores.addListener(_mudou);
    _aquecer();
  }

  @override
  void didUpdateWidget(FundoTingido antigo) {
    super.didUpdateWidget(antigo);
    final antes = antigo.cores ?? CorPosterCache.global;
    if (antes != _cores) {
      antes.removeListener(_mudou);
      _cores.addListener(_mudou);
    }
    if (antes != _cores || antigo.hash != widget.hash || !identical(antigo.preparar, widget.preparar)) _aquecer();
  }

  @override
  void dispose() {
    _cores.removeListener(_mudou);
    super.dispose();
  }

  void _mudou() {
    if (mounted) setState(() {});
  }

  void _aquecer() {
    final hashes = [?widget.hash, ...widget.preparar];
    if (hashes.isNotEmpty) _cores.aquecer(hashes);
  }

  @override
  Widget build(BuildContext context) {
    final base = TemaHeisuca.de(context);
    final papel = TemasCorPoster.de(base.nome);
    final paleta = _cores.ler(widget.hash, papel) ?? PaletaPoster.neutra(papel);
    final tingido = base.copyWith(superficie: Color(paleta.superficie), superficie2: Color(paleta.superficie2));
    final material = Theme.of(context);
    final tempo = Movimento.tempo(context, Movimento.tema);
    final tamanho = MediaQuery.sizeOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: base.brilho == Brightness.dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: base.brilho,
      ),
      child: AnimatedTheme(
        duration: tempo,
        curve: Movimento.padrao,
        data: material.copyWith(
          extensions: [
            for (final extensao in material.extensions.values)
              if (extensao is! TemaHeisuca) extensao,
            tingido,
          ],
        ),
        child: ColoredBox(
          color: base.fundo,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // O fundo não rola: é a parede da tela, e muda de cor com o pôster.
              ExcludeSemantics(
                child: AnimatedContainer(
                  duration: tempo,
                  curve: Movimento.padrao,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [for (final cor in paleta.degrade()) Color(cor)],
                    ),
                  ),
                  foregroundDecoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      // O raio do degradê é fração do lado menor; o alcance do halo é fração da altura.
                      // Janela sem tamanho (0 px) daria 0/0; aí o halo simplesmente não tem raio.
                      radius: tamanho.shortestSide > 0 ? paleta.alcanceHalo * tamanho.height / tamanho.shortestSide : 0,
                      colors: [Color(paleta.halo), Color(paleta.halo).withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
              widget.child,
            ],
          ),
        ),
      ),
    );
  }
}
