# Atualizador do Heisuca (fora da Play Store) — spec de desenho

Data: 08/11/2026. Autor: Visão Branco (Claude), a pedido do operador Misterioso 013. Decisor: Caio.
Estado: **rascunho para revisão do operador**. Nada implementado. Implementação = pacote D do Ultron, depois do pacote C.

## 1. Objetivo
Quem instalou o Heisuca fora da Play Store (APK baixado) atualiza pelo próprio app, como no SmartTube:
item **Atualizações** no menu (só aparece com versão nova) → Baixar (progresso) → Instalar → confirmar a fonte → app atualiza.
Vale para **todos os usuários**, não só para testadores. O que nos diferencia é o canal **beta**, aberto e opcional.
Prioridades: estabilidade, simplicidade, TV com controle remoto (direcional) e nenhum dado enviado a terceiros.

Origem do pedido (operador, TV TCL Android, único aparelho Android TV da equipe): atualizar sem depender de página web com login.

## 2. Fora de escopo
- Instalação silenciosa (exige root/privilégio de sistema; não funciona na TCL).
- Atualizador na variante da Play Store (a Play atualiza sozinha; a permissão de instalar é restrita lá).
- iOS, Windows, macOS e Linux.
- Release automático: nada publica sozinho. Promover versão é ação manual do Caio.
- Telemetria. O app só fala com o nosso host de atualização.

## 3. Canais
| Canal | Quem vê | Acesso |
|---|---|---|
| `estavel` | Todos (padrão) | `latest.json` público, sem login |
| `beta` | Quem ligar em Ajustes → Atualizações → "Receber versões beta" | público, aberto, com aviso "pode ter falhas" |
| `teste` | Só Caio e Rosiel | link com token longo e secreto, trocável; nunca listado |

Como o canal `teste` é ligado: Ajustes → Atualizações → "Código do canal de teste" (campo de texto; o Caio/Rosiel digitam ou colam o código uma vez). O código é o token e fica só no aparelho; o feed vira `https://HOST/teste/<código>/latest.json`. Sem código, o canal não existe na interface.

Promoção: `teste → beta → estavel`. Cada passo copia o APK e troca o JSON do canal; **não gera build nova**.
Isso mantém a regra do CGSERVER "build nova só em teste, exclusiva para o Caio, até ele aprovar".
Quem está no beta recebe o maior build entre `beta` e `estavel`. Quem está no estável vê só o `estavel`.

## 4. Servidor e feed
Cada canal tem `latest.json` e uma pasta de APKs. Exemplo (os valores são ilustrativos):

```json
{
  "canal": "estavel",
  "versao": "2.0.35",
  "build": 41,
  "notas": "Texto curto em PT-BR.",
  "assinatura_sha256": "d415544dae728cd8d402827f1bf17b6af00b2443295b3bad8b463d65d3acd4c1",
  "apks": [
    {"abi": "arm64-v8a", "url": "https://HOST/estavel/heisuca-2.0.35-arm64.apk", "bytes": 99051445, "sha256": "…"},
    {"abi": "universal", "url": "https://HOST/estavel/heisuca-2.0.35-universal.apk", "bytes": 179639635, "sha256": "…"}
  ]
}
```

- `build` é o número depois do `+` no `pubspec.yaml` e vira o `versionCode`. Só atualiza se `build` > instalado. Nunca faz downgrade.
- `assinatura_sha256` é o SHA-256 do certificado de assinatura esperado.
- Publicar/promover é feito por script (extensão do `~/cgflix/bin/cgf-apk-teste`), que calcula tamanho e SHA-256 do arquivo.
  O script grava o JSON só depois de enviar o APK, para o feed nunca apontar para arquivo ausente.
- Nginx: caminho público para `estavel` e `beta`; `teste` em caminho com token. Arquivos `Content-Disposition: attachment`, `X-Robots-Tag: noindex`.

### Decisões que dependem do Caio ([C])
1. Domínio/host público do feed (exemplo: um subdomínio de `docaio.com.br`; **não inventar**, o Caio escolhe).
2. Onde ficam os APKs estáveis: VPS (cada atualização baixa ~99 MB; banda da VPS) ou fora dela (por exemplo, Releases do GitHub, com o `latest.json` apontando para lá).
3. Abrir o caminho público no nginx e criar o token do canal `teste`.
4. Promover cada versão de `teste` para `beta` e `estavel`.

## 5. No app (pacote D)
Unidades pequenas, com uma função cada:

- **`UpdateFeedClient`**: baixa e valida o `latest.json` (só HTTPS, só o host do feed configurado no build, tamanho máximo do JSON, campos obrigatórios). Os URLs dos APKs só podem estar no host do feed ou em uma lista de hosts de APK também configurada no build (por exemplo, o host de Releases do GitHub, se o Caio escolher essa hospedagem). Qualquer outro host é rejeitado.
- **`UpdateChecker`**: decide se há versão nova. Roda uma vez ao abrir, no máximo uma por dia, **nunca durante reprodução**. Falha de rede ou servidor = silêncio.
- **`UpdateDownloader`**: baixa para o cache do app com progresso e cancelamento; confere tamanho e SHA-256; em falha apaga o arquivo e permite tentar de novo.
- **`ApkInstaller` (Kotlin)**: escolhe o APK pela ABI do aparelho (`Build.SUPPORTED_ABIS`, `universal` como reserva); confere o certificado do APK baixado contra `assinatura_sha256`; se o app não pode instalar apps desconhecidos, abre a tela do sistema para liberar; entrega o APK ao instalador do sistema com um `Intent` `ACTION_INSTALL_PACKAGE` e um URI do `FileProvider` (já existe no manifest). Não usa sessão de `PackageInstaller`: o Intent mostra a tela de confirmação do próprio Android, que é o fluxo do SmartTube. **A confirmação final é sempre do usuário.**
- **Tela "Atualizações"**: versão atual → nova, notas, botão **Baixar**, depois **Instalar**; barra de progresso; todo o fluxo por direcional. Item de menu só aparece com versão nova. Em Ajustes: chave "Receber versões beta" e "Verificar agora".
- **Estado**: canal escolhido, data da última verificação e ABI ficam em `SettingsService` (local).

### Variantes de build
- **Direta** (APK do nosso site): contém o atualizador e `REQUEST_INSTALL_PACKAGES`.
- **Play**: sem atualizador e sem a permissão; o item de menu não existe.
- O host do feed vem de configuração explícita de build (`--dart-define`); sem ela o atualizador fica desligado. Isso cumpre a regra do `apps/app/CLAUDE.md` ("feed nativo só mediante configuração própria explícita").
- O validador de APK do CI passa a **falhar** se a variante Play tiver `REQUEST_INSTALL_PACKAGES`.
- Não alterar applicationIds.

## 6. Segurança
- HTTPS apenas; redirecionamento só entre hosts permitidos (feed e hosts de APK da seção 5).
- SHA-256 do arquivo + certificado esperado + verificação do próprio Android (APK com outra chave não instala por cima).
- Sem instalação automática, sem downgrade, sem identificador de usuário, sem telemetria. O servidor enxerga só IP e a requisição.
- Token do canal `teste` nunca vai para código, log, workflow ou `latest.json` público.

## 7. Erros e limites conhecidos
- Sem rede/servidor: nenhuma mensagem. "Verificar agora" mostra "Não foi possível verificar".
- SHA-256 ou certificado não confere: apaga o arquivo e mostra "Arquivo corrompido ou inválido. Tente de novo."
- Pouco espaço: avisa antes de baixar (tamanho do APK + folga).
- Permissão negada: leva à tela do sistema; se o firmware da TV não tiver essa tela, mostra o caminho manual em texto.
- Ao atualizar, o Android encerra o app. Reabrir automaticamente **não é garantido** (Android 10+ limita abrir telas em segundo plano). A bancada decide; o texto da tela deve dizer "abra o app de novo".
- A ABI da TCL é desconhecida. O `arm64` (~99 MB) serve se a TV for 64 bits; senão usa o `universal` (~180 MB). O app registra a ABI no log local.
- Primeira instalação com atualizador é manual (página de APK de teste, navegador da TV ou Downloader). Depois disso, o app se atualiza.

## 8. Testes
- Unitários: comparação de build, leitura/validação do feed (campos faltando, host errado, HTTP), escolha de canal (estável × beta), limite de uma consulta por dia, escolha de ABI, SHA-256 inválido, certificado inválido, nenhum downgrade.
- Widget: direcional percorre a tela de Atualizações; item de menu oculto sem versão nova; nenhuma consulta durante reprodução.
- CI: APK da variante Play não tem `REQUEST_INSTALL_PACKAGES`; APK direto tem.
- Bancada TV: feed de teste → baixar → instalar → versão nova; cancelamento; permissão negada.
- Aparelho real: Rosiel na TCL, com o canal `teste`.

## 9. Entrega
1. Pacote C do Ultron (diagnóstico do player) termina. Claude revisa A, B e C juntos e publica o APK de teste pela página atual.
2. Caio decide os itens [C] da seção 4.
3. Ordem de serviço do pacote D (Ultron) + script de publicar/promover (Claude) + nginx (Claude, com OK do Caio).
4. Revisão da entrega D (`revisar-entrega-ultron`), APK de teste, teste do Rosiel na TCL, promoção manual até o estável.

## 10. Revisão interna
- Sem pendências em aberto no desenho; as únicas decisões abertas são as da seção 4 ([C]) e a ABI da TCL (seção 7).
- Escopo cabe em um pacote (D) mais o script e o nginx; o app e o servidor não dependem um do outro para serem testados (feed de teste local).
