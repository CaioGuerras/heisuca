# Segurança do app Heisuca — P5 (28/10/2026)

Formato: ameaça → teste → resultado (antes/depois), com o caminho do teste e o commit.
Os caminhos de teste são relativos a `apps/app/`. Regra da etapa: todo defeito vira teste que falha antes do conserto.
O "antes" foi observado rodando o teste novo antes do conserto (ex.: caso 1 com 12 falhas, caso 2 com 5, caso 4 com 4,
cofre com 5 de 8); onde o teste já passava de início, a tabela diz "já estava certo". Nada foi testado em aparelho.

Ramo `claude/heisuca-p`, commits `b7cd4be..6a5aece`. Suíte Dart inteira local: nenhuma falha nova em relação à base
d6813e0 (comparação por nome).

## 1. Manifesto e deep links

| Ameaça | Teste | Resultado |
|---|---|---|
| Android 12+ ignora `allowBackup=false` na transferência entre aparelhos e levaria `shared_prefs` (onde ficava a chave do cofre) | `test/android/manifest_security_test.dart` (backup) | Antes: falhava (sem `dataExtractionRules` nem `fullBackupContent`). Depois: passa. Commit 86bcdd0 (`data_extraction_rules.xml` exclui os 9 domínios em nuvem e em transferência) |
| Componente exportado a mais, provider/receiver exportado, `debuggable` ligado, intent-filter aceitando http/https/file/content/intent | `test/android/manifest_security_test.dart` | Já estava certo: só `.MainActivity`, `.IconeIsis` e `.IconeHeitor` exportados; só `plezy://play` e `plezy://live`, sem BROWSABLE. Teste trava para não regredir (86bcdd0) |
| `root-path` do FileProvider emitiria URI para `shared_prefs` e `databases` | `android/app/src/test/kotlin/app/heisuca/ExternalFileContainmentTest.kt` (11 casos JVM: `../`, symlink para `databases`, caminho direto em `shared_prefs`, cartão SD, vazio) e a checagem "contenção antes de `getUriForFile`" em `manifest_security_test.dart` | Antes: sem contenção (o teste JVM não compilava sem a classe). Depois: passa. Commit a7f8cbf. O `root-path` ficou, porque os downloads padrão estão em `app_flutter/downloads` e o cartão SD precisa dele; a trava está no emissor (`ExternalFileContainment`, caminho canônico) |
| Link malicioso em `plezy://live` (javascript:, file:, content:, intent:, `../`, 1 MB, `%00`, URI malformada) | `test/utils/live_tv_deep_link_fuzz_test.dart` (entradas fixas + 500 aleatórias, semente 20261028) | Nunca lança; só `plezy://live` válido é aceito; `../` vira só texto de busca. Commit 28a66a8 |
| `plezy://play` com `content_id` hostil | mesmo arquivo (`SystemShelfService.parseContentId`) | Antes: `plezy__x` lançava `ArgumentError` fora de try/catch. Depois: devolve null. Commit 28a66a8 |

## 2. Credenciais (Keystore, logs, logout)

| Ameaça | Teste | Resultado |
|---|---|---|
| Chave do cofre em `shared_prefs` (legível em backup, root, ou pela contenção antes ausente) | `test/services/credential_vault_secure_store_test.dart` (chave nova direto ao armazenamento seguro; migração v1 grava, confere e só então remove; falha do store mantém a chave legada) | Depois: chave `credential_vault_key_v2` no Keystore; falha nunca perde a chave. Commit 61684bf |
| Erro do armazenamento seguro vazar a chave no log | mesmo arquivo ("só o tipo" no log) | Passa. Commit 61684bf |
| Diálogo de reparo dizia que os logins se perdiam mesmo com a chave no Keystore | mesmo arquivo (`signInsSurviveRepair`: sobrevive, regra antiga, erro vira "não sei") | Corrigido. Commit c934f85 |
| Logout deixava sobras (sessões do Seerr, sessões sem escopo nas prefs) | `test/screens/profile/profile_teardown_test.dart` ("logout total não deixa credencial: Drift, prefs, sessões do Seerr e Keystore") | Antes: sobras. Depois: apagado. Commit 61684bf |

## 3. Servidor malicioso (servidor Jellyfin falso em `test/security/malicious_server_harness.dart`)

| Caso e ameaça | Teste | Resultado |
|---|---|---|
| 1. JSON hostil: tipos errados, campos gigantes, NaN/infinito, corpo sem teto | `test/security/servidor_malicioso_json_test.dart` (5bb19f2) | Antes: `TypeError` nos casts do mapper, NaN derrubava ticks, corpo em memória sem teto. Depois: leitura tolerante, teto de texto e de corpo de 64 MiB. Conserto 86788dc |
| 2. Caminhos de download vindos do servidor (`../`, absolutos, separadores) | `test/security/servidor_malicioso_caminhos_test.dart` (bfc2a7b) | Depois: um saneador por componente e contenção final sob a raiz. Conserto c5303af |
| 3. HTML/script em título e sinopse; links | `test/security/servidor_malicioso_texto_test.dart` (a06cab2) | Texto literal, sem renderizador HTML. Antes: link externo do catálogo abria sem checar; depois: só http(s) com host. Conserto 20de26e |
| 4. URLs de imagem/legenda/stream de outra origem, rede interna, token vazando | `test/security/servidor_malicioso_urls_test.dart` (4ba07f7; reescrito em 2c2ed46) | Antes: token e pedidos iam a qualquer host. Depois: `resolveSameOrigin` (1e0801b) e política única `resolveServerUrl` (26263d0): mesma origem leva token; outra origem http(s) sem token; rede interna só se o servidor também for interno; `https→http` e `user:senha@` descartados; cliente HTTP tira cabeçalhos de credencial de URL de outra origem. Testes antigos de `jellyfin_client_urls` atualizados (368ead3) |
| 5. Redirecionamento em laço, para outro host, outro esquema, com token | `test/security/servidor_malicioso_redirect_test.dart` (8bd7aa4) | Depois: redirecionamento manual, máx. 5 saltos, credencial só para o mesmo host, sem rebaixar https. Conserto 86788dc |
| 6. TLS autoassinado | `test/security/servidor_malicioso_tls_test.dart` (3413e56; certificado só de teste) | Recusado. Sem conserto necessário |

Ajuste dos testes antigos à regra só-HTTPS do b3513e7: a2c8337 (seerr_connect, add_jellyfin), 5d97ed1 (diálogo do relay).

## 4. Varreduras no CI

Workflow `.github/workflows/heisuca-seguranca.yml` (gitleaks e osv-scanner) e job MobSF no `heisuca-android.yml`; portões em
`apps/app/scripts/seguranca/` (gitleaks_gate, osv_gate, mobsf_gate, com testes Python) e listas de aceitos, cada item com motivo,
em `apps/app/security/`. Binários baixados com sha256 conferido; MobSF com tag fixa. Estados verde / ATENÇÃO / vermelho no resumo do run.
Modos: gitleaks bloqueia achado novo na árvore; MobSF em **bloquear** desde 2bdc957 (achado alto fora dos aceitos = vermelho);
osv e gitleaks em bloquear desde 6a5aece. Commits 7474ed0, a0ce46d, b326bfc, 6fbd8d2, 2bdc957, 6a5aece.

1º run (40660383164 Segurança; 40660383049 Build/MobSF):
- gitleaks: 5 achados na árvore e 233 no histórico, todos falsos positivos: fixtures TLS de teste; nomes de preferência
  `heisuca.kids.v1` e `plezy_legacy_prefs_migrated_v1`; 226 campos "Key" (`UserData.Key` numérico/GUID do servidor falso no
  ramo falso-dados). Allowlists estreitas em 6fbd8d2.
- osv-scanner: 46 achados CVSS ≥ 7 eram do classpath de ferramenta de build (bouncycastle, netty, protobuf: lint/AGP).
  O portão passa a olhar só `releaseRuntimeClasspath` (6fbd8d2).
- MobSF v4.5.3: binários nativos sem canary/RELRO (AAR do mpv/ffmpeg, fora do escopo; `libapp.so` AOT do Dart); CBC numa classe
  ofuscada de biblioteca (não é o nosso Kotlin); minSdk 25; CA do usuário; texto claro só em localhost; 79 "secrets" são
  cabeçalhos PEM e constantes.

2º run, commit 2bdc957: Build 40662869898, Segurança 40662869872 e Bancada 40662870083, todos com sucesso.
- gitleaks: **verde**. Árvore 0, histórico 0 fora das allowlists.
- MobSF: **ATENÇÃO** em modo bloquear. 97 achados altos, todos na lista de aceitos com motivo; nenhum fora dela.
- osv-scanner, só com o runtime do APK (137 dependências): **3 avisos reais**, em dependências transitivas:
  - `protobuf-javalite` 3.22.3: CVE-2024-7254, DoS, CVSS 8,7, corrigido em 3.25.5;
  - `guava` 33.3.1-android: CVE-2026-102554, desserialização, CVSS 8,2, corrigido em 33.7.2;
  - `play-services-basement` 18.0.0: CVE-2022-2390, CVSS 6,1, corrigido em 18.0.2.

  Os de ferramenta de build (bouncycastle, netty) ficam só como informação.

Conserto, commit 2a0f042. `constraints` em `android/app/build.gradle.kts`, com `because`:
- `protobuf-javalite` 3.25.5, puxado por cronet-embedded e cronet-shared;
- `guava` 33.7.2-android, puxado por media3-common 1.11.0;
- `play-services-basement` 18.0.2, puxado por cronet-api via media3-datasource-cronet.

Nenhuma dependência direta nossa tinha versão nova que já trouxesse as corrigidas. O `releaseRuntimeClasspath` resolve as versões
novas. APK de release local compilou e os testes JVM do CI passaram. Ainda não foi testado em aparelho: falta exercitar rede real
(Cronet/HTTP2). osv e gitleaks passaram para **bloquear** no commit 6a5aece.

3º run, commit 6a5aece: Build 40665861908, Segurança 40665861842 e Bancada 40665861844, todos com sucesso.
- gitleaks: **verde** (0/0).
- osv: **verde** em modo bloquear. 137 dependências de runtime, 0 avisos.
- MobSF: **ATENÇÃO** em modo bloquear. 97 achados altos, todos aceitos; nenhum novo depois da troca das dependências.

## 5. Limites conhecidos

- Rebinding de DNS (nome público que passa a resolver para IP interno) não é detectado.
- `https→http` real não foi testado de ponta a ponta (precisa de TLS confiável no teste).
- `downloadFile` sem teto de tamanho (é mídia).
- WinHTTP pode seguir redirecionamento sozinho (Windows fora do escopo).
- Listas de gêneros e de pessoas não são cortadas.
- `acceptUntrustedCertificates` está dormente no `background_downloader` vendorizado.
- O Kotlin da contenção do FileProvider só tem teste JVM; nada foi testado em aparelho. A bancada adb de deep link
  (`am start -d`) fica para a P6/bancada.

## 6. Decisões do Caio (28/10: "mantém tudo")

1. Só HTTPS também na LAN: Jellyfin descoberto que anuncia só `http://` não conecta (mostra "Use um endereço https://").
2. Seerr em `http://host:5055` na LAN não conecta (mesma regra).
3. A CA instalada pelo usuário continua aceita (servidores com CA privada).
4. O logout mantém os downloads (arquivos locais) e apaga todas as credenciais.
5. A chave do cofre continua no Keystore depois do logout (os tokens somem; a chave não decifra nada sozinha).

## 7. Como reproduzir

Dentro de `apps/app`, com o Flutter local:

    flutter test test/android test/utils/live_tv_deep_link_fuzz_test.dart
    flutter test test/security test/services/credential_vault_secure_store_test.dart test/screens/profile/profile_teardown_test.dart
    cd android && ./gradlew :app:testDebugUnitTest --tests app.heisuca.ExternalFileContainmentTest -PtargetAbi=arm64-v8a

    python3 -m unittest discover -s scripts/seguranca -p 'test_*.py'

O Gradle precisa de rede (com `--offline` falta `io.flutter:x86_64_debug`). As varreduras rodam no Actions
(`Heisuca Segurança` e o job MobSF do `Heisuca Android Build`); os relatórios ficam nos artifacts `heisuca-gitleaks`,
`heisuca-osv` e `heisuca-mobsf`. Aceitos do MobSF: `scripts/seguranca/gerar_aceitos_mobsf.py` (depois de triar).

## Fora da P5, mas achado

- 6+1 testes de `test/screens/settings` estavam desatualizados desde b3513e7 (só-HTTPS).
- O CI roda só uma amostra da suíte Dart. Sugestão: rodar a suíte inteira no CI depois de zerar as falhas conhecidas locais.
