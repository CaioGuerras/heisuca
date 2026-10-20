// CGFLIX: consultas da Início direto no Jellyfin. É um `part` do jellyfin_client.dart
// (gancho de 1 linha lá) para usar o HTTP e o mapeamento do cliente sem mexer neles.
part of '../../services/jellyfin_client.dart';

extension CgflixJellyfinQueries on JellyfinClient {
  /// Usuário dono da sessão (para separar o cache do aparelho por conta).
  String get cgflixUserId => connection.userId;

  /// `GET /Items` com os campos que os cartões e a prévia usam. [params] vence os padrões.
  /// Devolve o JSON cru (vai para o cache do aparelho); [cgflixMapItems] converte.
  Future<List<Map<String, dynamic>>> cgflixFetchRawItems(Map<String, String> params, {Duration? timeout}) async {
    final query = <String, dynamic>{
      'UserId': connection.userId,
      'Recursive': 'true',
      'Fields': '$_hubRowFields,Genres,ChildCount,RecursiveItemCount',
      'EnableUserData': 'true',
      ...jellyfinImageQueryParameters,
      ...params,
    };
    final response = await _http.get('/Items', queryParameters: query, timeout: timeout ?? const Duration(seconds: 12));
    throwIfHttpError(response);
    return _itemsArray(response.data);
  }

  /// Continuar assistindo + Próximos episódios só da biblioteca [libraryId] (Etapa 1E). Usa as
  /// mesmas consultas do upstream (`Resume` e `/Shows/NextUp` com `ParentId`) e a mesma junção.
  Future<List<MediaItem>> cgflixFetchContinueWatchingIn(String libraryId, {int count = 20}) async {
    var libraries = _loadedLibraryViews;
    if (libraries == null) {
      libraries = await _fetchLibraries();
      _loadedLibraryViews ??= libraries;
    }
    final library = libraries.where((l) => l.id == libraryId).firstOrNull;
    if (library == null) return const [];
    final rows = await _continueWatchingRows(count: count, library: library);
    return _mergeContinueWatchingAndNextUp(resume: rows.resume, nextUp: rows.nextUp, limit: count);
  }

  /// Endereço em uso do servidor (Etapa 1E: o Seerr é procurado ao lado dele).
  String get cgflixBaseUrl => _http.baseUrl;

  /// Aprova um código do Quick Connect com o token da própria pessoa (Etapa 1E: entrada
  /// automática nos Pedidos, sem tela de login).
  Future<void> cgflixAuthorizeQuickConnect(String code) async {
    final response = await _http.post(
      '/QuickConnect/Authorize',
      queryParameters: {'code': code, 'userId': connection.userId},
      timeout: const Duration(seconds: 10),
    );
    throwIfHttpError(response);
  }

  List<MediaItem> cgflixMapItems(Iterable<Map<String, dynamic>> raw) => _mapItems(raw);

  /// Gêneros de filmes e séries do usuário (já vêm em português do servidor).
  /// Com [parentId], só os da biblioteca (chip ativo na Início).
  Future<List<Map<String, dynamic>>> cgflixFetchRawGenres({String? parentId, String? itemTypes}) async {
    final response = await _http.get(
      '/Genres',
      queryParameters: {
        'UserId': connection.userId,
        'IncludeItemTypes': itemTypes ?? 'Movie,Series',
        'ParentId': ?parentId,
        'Recursive': 'true',
        'SortBy': 'SortName',
        'Fields': 'ItemCounts',
        'EnableImages': 'false',
      },
      timeout: const Duration(seconds: 12),
    );
    throwIfHttpError(response);
    return _itemsArray(response.data);
  }

  /// JSON servido pelo próprio servidor do CGFLIX (ex.: `/cgflix/emalta.json`). Aceita
  /// corpo já decodificado ou texto. Erros de rede/HTTP sobem para quem chamou.
  Future<Object?> cgflixGetJson(String path) async {
    final response = await _http.get(path, timeout: const Duration(seconds: 8), allowEndpointFailover: false);
    throwIfHttpError(response);
    final data = response.data;
    if (data is String) return data.trim().isEmpty ? null : jsonDecode(data);
    return data;
  }

  // -------------------------------------------------------------------------
  // Minha conta (1.5.0): a própria pessoa troca foto e senha, sem admin. Primeiro a rota nova
  // (`/UserImage`, `/Users/Password`, testadas pelo CGFLIX Lite no 10.11.11); se o servidor não
  // conhecer (404/405, Jellyfin antigo), a rota clássica `/Users/{id}/...`.

  /// Nome e etiqueta da foto (`PrimaryImageTag`) da pessoa logada, direto do servidor.
  Future<({String name, String? imageTag})> cgflixFetchMe() async {
    final response = await _http.get(paths.currentUser, timeout: const Duration(seconds: 10));
    throwIfHttpError(response);
    final data = response.data;
    if (data is! Map<String, dynamic>) return (name: connection.userName, imageTag: null);
    return (
      name: (data['Name'] as String?) ?? connection.userName,
      imageTag: JellyfinConnection.readPrimaryImageTag(data),
    );
  }

  /// Foto nova (JPEG já recortado), enviada em base64 como o Jellyfin espera.
  Future<void> cgflixUploadUserImage(List<int> jpeg) async {
    final body = base64Encode(jpeg);
    const headers = {'content-type': 'image/jpeg'};
    const timeout = Duration(seconds: 30);
    final uid = connection.userId;
    var response = await _http.post(
      '/UserImage',
      queryParameters: {'userId': uid},
      headers: headers,
      body: body,
      timeout: timeout,
    );
    if (_cgflixRouteMissing(response.statusCode)) {
      response = await _http.post(
        '/Users/${Uri.encodeComponent(uid)}/Images/Primary',
        headers: headers,
        body: body,
        timeout: timeout,
      );
    }
    throwIfHttpError(response);
    await checkHealth(); // atualiza a etiqueta da foto: o avatar do menu troca na hora
  }

  Future<void> cgflixDeleteUserImage() async {
    final uid = connection.userId;
    const timeout = Duration(seconds: 15);
    var response = await _http.delete('/UserImage', queryParameters: {'userId': uid}, timeout: timeout);
    if (_cgflixRouteMissing(response.statusCode)) {
      response = await _http.delete('/Users/${Uri.encodeComponent(uid)}/Images/Primary', timeout: timeout);
    }
    throwIfHttpError(response);
    await checkHealth();
  }

  /// Troca de senha. Devolve o código HTTP (204 = trocou; 401/403 = senha atual errada).
  /// O servidor derruba as OUTRAS sessões da pessoa; a deste aparelho continua valendo.
  Future<int> cgflixChangePassword({required String current, required String newPassword}) async {
    final uid = connection.userId;
    final body = {'CurrentPw': current, 'NewPw': newPassword, 'ResetPassword': false};
    const timeout = Duration(seconds: 15);
    var response = await _http.post('/Users/Password', queryParameters: {'userId': uid}, body: body, timeout: timeout);
    if (_cgflixRouteMissing(response.statusCode)) {
      response = await _http.post('/Users/${Uri.encodeComponent(uid)}/Password', body: body, timeout: timeout);
    }
    return response.statusCode;
  }

  static bool _cgflixRouteMissing(int status) => status == 404 || status == 405;
}
