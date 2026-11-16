import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:flutter_test/flutter_test.dart';

// O tipo contextual VoidCallback pode esconder o retorno de uma seta. Por isso
// conferimos a expressão do corpo, além do tipo dos métodos passados por nome.
bool _devolveFuture(DartType? tipo) =>
    tipo != null &&
    (tipo.isDartAsyncFuture ||
        tipo.isDartAsyncFutureOr ||
        (tipo is InterfaceType && tipo.allSupertypes.any((t) => t.isDartAsyncFuture)));

bool _expressaoDevolveFuture(Expression? expressao) {
  if (_devolveFuture(expressao?.staticType)) return true;
  // async void também produz Future em execução, apesar do tipo declarado.
  if (expressao is MethodInvocation) {
    final metodo = expressao.methodName.element;
    return metodo is ExecutableElement && metodo.firstFragment.isAsynchronous;
  }
  return false;
}

class _Retornos extends RecursiveAstVisitor<void> {
  bool devolveFuture = false;

  @override
  void visitReturnStatement(ReturnStatement node) {
    devolveFuture |= _expressaoDevolveFuture(node.expression);
  }

  // O retorno de uma função aninhada não é o retorno do callback do setState.
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

class _Callbacks extends RecursiveAstVisitor<void> {
  final ResolvedUnitResult unidade;
  final problemas = <String>[];
  int chamadas = 0;

  _Callbacks(this.unidade);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'setState' && node.argumentList.arguments.length == 1) {
      chamadas++;
      var argumento = node.argumentList.arguments.single;
      while (argumento is ParenthesizedExpression) {
        argumento = argumento.expression;
      }
      var invalido = false;
      if (argumento is FunctionExpression) {
        final corpo = argumento.body;
        invalido = corpo.isAsynchronous;
        if (corpo is ExpressionFunctionBody) {
          invalido |= _expressaoDevolveFuture(corpo.expression);
        } else {
          final retornos = _Retornos();
          corpo.accept(retornos);
          invalido |= retornos.devolveFuture;
        }
      } else {
        final tipo = argumento.staticType;
        invalido = tipo is FunctionType && _devolveFuture(tipo.returnType);
        final elemento = switch (argumento) {
          SimpleIdentifier(element: final elemento) => elemento,
          PrefixedIdentifier(identifier: final identificador) => identificador.element,
          PropertyAccess(propertyName: final propriedade) => propriedade.element,
          _ => null,
        };
        // Também cobre um método declarado como void, mas marcado async.
        if (elemento is ExecutableElement) {
          invalido |= elemento.firstFragment.isAsynchronous;
        }
      }
      if (invalido) {
        final linha = unidade.lineInfo.getLocation(node.offset).lineNumber;
        problemas.add('${unidade.path}:$linha: ${node.toSource()}');
      }
    }
    super.visitMethodInvocation(node);
  }
}

void main() {
  late AnalysisContextCollection contextos;
  late Directory temporario;

  setUpAll(() {
    // flutter_tester não é o executável Dart; localiza o SDK pelo pacote Flutter
    // que este projeto realmente usa, inclusive quando o SDK fica isolado.
    final config = File('.dart_tool/package_config.json').absolute;
    final pacotes = (jsonDecode(config.readAsStringSync()) as Map<String, dynamic>)['packages'] as List;
    final flutter = pacotes.cast<Map<String, dynamic>>().singleWhere((p) => p['name'] == 'flutter');
    final raizFlutter = Directory.fromUri(config.uri.resolve(flutter['rootUri'] as String)).parent.parent;
    temporario = Directory.systemTemp.createTempSync('heisuca-set-state-');
    contextos = AnalysisContextCollection(
      includedPaths: [Directory('lib').absolute.path, temporario.path],
      sdkPath: '${raizFlutter.path}/bin/cache/dart-sdk',
    );
  });
  tearDownAll(() async {
    await contextos.dispose();
    temporario.deleteSync(recursive: true);
  });

  Future<_Callbacks> conferir(File arquivo) async {
    final resultado = await contextos
        .contextFor(arquivo.absolute.path)
        .currentSession
        .getResolvedUnit(arquivo.absolute.path);
    expect(resultado, isA<ResolvedUnitResult>(), reason: arquivo.path);
    final unidade = resultado as ResolvedUnitResult;
    final auditor = _Callbacks(unidade);
    unidade.unit.accept(auditor);
    return auditor;
  }

  test('guarda distingue async, setas, atribuições, retornos e métodos de callbacks síncronos', () async {
    final arquivo = File('${temporario.path}/exemplos.dart')
      ..writeAsStringSync('''
import 'dart:async';
void setState(void Function() callback) {}
Future<void> carregar() async {}
void carregarSemTipo() async {}
void sincrono() {}
void exemplos(bool condicao) {
  Future<void>? pendente;
  setState(() async { await carregar(); });
  setState(() => carregar());
  setState(() => pendente = carregar());
  setState(carregar);
  setState(carregarSemTipo);
  setState(() => carregarSemTipo());
  setState(() { if (condicao) return carregar(); });
  setState((() => carregar()));
  setState(() { pendente = carregar(); });
  setState(() { unawaited(carregar()); });
  setState(sincrono);
  setState(() { final callback = () async { await carregar(); }; callback(); });
  setState(() { Future<void> interna() async {} interna(); });
  setState(() => condicao = false);
}
''');
    final auditor = await conferir(arquivo);
    expect(auditor.chamadas, 14);
    expect(auditor.problemas, hasLength(8), reason: auditor.problemas.join('\n'));
  });

  test('nenhum callback de setState em lib devolve Future', () async {
    final problemas = <String>[];
    var arquivos = 0;
    var chamadas = 0;
    for (final arquivo in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!arquivo.path.endsWith('.dart') || !arquivo.readAsStringSync().contains('setState')) continue;
      final auditor = await conferir(arquivo);
      arquivos++;
      chamadas += auditor.chamadas;
      problemas.addAll(auditor.problemas);
    }
    expect(arquivos, greaterThan(150), reason: 'a guarda precisa ler as telas e componentes compartilhados');
    expect(chamadas, greaterThan(750), reason: 'a guarda precisa visitar os callbacks reais');
    // Registro útil para conferir se a varredura continua cobrindo o aplicativo.
    stderr.writeln('setState: $chamadas chamadas em $arquivos arquivos resolvidos.');
    expect(problemas, isEmpty, reason: problemas.join('\n'));
  }, timeout: const Timeout(Duration(minutes: 5)));
}
