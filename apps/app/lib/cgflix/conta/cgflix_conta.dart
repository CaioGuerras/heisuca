// CGFLIX (Minha conta, 1.5.0): a própria pessoa troca a foto e a senha no Jellyfin, sem admin.
// Vale no servidor inteiro (app, site, TV). Só existe com um servidor Jellyfin conectado; no
// Plex e sem conexão, o menu não oferece a tela.
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../providers/multi_server_provider.dart';
import '../../services/file_picker_service.dart';
import '../../services/jellyfin_client.dart';
import '../../services/jellyfin_mappers.dart';
import '../../utils/app_logger.dart';

/// Nome e foto da pessoa logada. [fotoUrl] nulo = sem foto no servidor.
class CgflixPerfil {
  const CgflixPerfil({required this.nome, this.fotoUrl});
  final String nome;
  final String? fotoUrl;
}

/// Resultado da troca de senha, já pensado para a mensagem em português.
enum CgflixSenhaResultado { ok, senhaAtualErrada, falhou }

/// O que a tela "Minha conta" precisa do servidor (os testes usam um falso).
abstract interface class CgflixConta {
  Future<CgflixPerfil> perfil();
  Future<void> trocarFoto(Uint8List jpeg);
  Future<void> removerFoto();
  Future<CgflixSenhaResultado> trocarSenha({required String atual, required String nova});

  /// Conta do Jellyfin conectado agora, ou nulo (Plex, sem conexão).
  static CgflixConta? of(BuildContext context) {
    if (debugOverride case final fake?) return fake;
    final MultiServerProvider? servers;
    try {
      servers = Provider.of<MultiServerProvider?>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
    final client = servers?.serverManager.visibleOnlineClients.values.whereType<JellyfinClient>().firstOrNull;
    return client == null ? null : CgflixJellyfinConta(client);
  }

  /// Testes: conta falsa no lugar do servidor.
  static CgflixConta? debugOverride;
}

class CgflixJellyfinConta implements CgflixConta {
  CgflixJellyfinConta(this.client);
  final JellyfinClient client;

  @override
  Future<CgflixPerfil> perfil() async {
    final me = await client.cgflixFetchMe();
    return CgflixPerfil(
      nome: me.name,
      // a etiqueta muda a cada foto nova: o cache nunca mostra a antiga
      fotoUrl: jellyfinUserImageUrl(
        baseUrl: client.cgflixBaseUrl,
        userId: client.cgflixUserId,
        tag: me.imageTag,
        maxSize: 384,
      ),
    );
  }

  @override
  Future<void> trocarFoto(Uint8List jpeg) => client.cgflixUploadUserImage(jpeg);

  @override
  Future<void> removerFoto() => client.cgflixDeleteUserImage();

  @override
  Future<CgflixSenhaResultado> trocarSenha({required String atual, required String nova}) async {
    final status = await client.cgflixChangePassword(current: atual, newPassword: nova);
    if (status >= 200 && status < 300) return CgflixSenhaResultado.ok;
    if (status == 401 || status == 403) return CgflixSenhaResultado.senhaAtualErrada;
    appLogger.w('CGFLIX: troca de senha respondeu $status');
    return CgflixSenhaResultado.falhou;
  }
}

/// Foto escolhida no seletor do sistema (sem permissão de armazenamento), já como quadrado
/// central de 512 px em JPEG. Nulo = a pessoa desistiu. Os testes trocam por um falso.
typedef CgflixEscolherFoto = Future<Uint8List?> Function();

CgflixEscolherFoto cgflixEscolherFoto = _escolherFotoDoSistema;

const _photoChannel = MethodChannel('br.com.docaio.cgflix/photo');

Future<Uint8List?> _escolherFotoDoSistema() async {
  final picked = await FilePickerService.instance.pickFiles(type: FileType.image);
  final path = picked?.files.firstOrNull?.path;
  if (path == null) return null;
  return _photoChannel.invokeMethod<Uint8List>('squareJpeg', {'path': path});
}
