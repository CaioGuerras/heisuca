<p align="center"><picture>
  <source media="(prefers-color-scheme: dark)" srcset="cgflix-brand/cgflix-marca.svg">
  <img src="cgflix-brand/heitor/cgflix-marca.svg" alt="CGFLIX" width="320">
</picture></p>

# CGFLIX

App completo de streaming (Plex + Jellyfin) para o CGFLIX, o servidor de mídia particular para família e amigos.
Construído com Flutter para oferecer desempenho nativo, interface fluida, suporte multiplataforma e navegação limpa em português do Brasil.

É um fork do [Plezy](https://github.com/edde746/plezy) (GPL-3.0). Tudo o que mudou em relação ao original está detalhado em [CGFLIX.md](CGFLIX.md). O irmão leve para celulares simples e TV boxes é o [`cgflix-lite`](https://github.com/CaioGuerras/cgflix-lite) (fork do Findroid).

---

## Recursos

### 🧭 Navegação e Descoberta
- **Bibliotecas, coleções e listas**: filmes, séries, animes e músicas em um só lugar.
- **Painel Início**: "Continuar assistindo", "A seguir", itens em alta e recomendações personalizadas.
- **Busca integrada**: pesquisa inteligente entre servidores Jellyfin e Plex conectados, incluindo atores e diretores.
- **Identificação visual**: selos de resolução, HDR/Dolby Vision e formato de áudio nos cartões e detalhes.

### 🎬 Reprodução Avançada
- **Amplo suporte a codecs**: HEVC, AV1, VP9, H.264 e mais.
- **Reprodução direta (Direct Play)**: prioriza o fluxo original sem sobrecarregar o servidor; perfis de transcodificação quando necessário.
- **Legendas completas**: suporte integral a legendas ASS/SSA estilizadas (essencial para anime), com ajuste de fonte e sincronia.
- **Áudio e faixas**: memorização de preferências por título ou seguindo a seleção por episódio definida no servidor; suporte a normalização de volume.
- **Sincronização de progresso**: retome exatamente de onde parou em qualquer dispositivo.

### 🔍 Exploração e Pedidos (Seerr)
- **Pedidos integrados**: solicite filmes e séries pelo Seerr diretamente no app, com escolha de temporadas, qualidade (4K/1080p) e acompanhamento de status.
- **Sincronização de listas**: integração com Trakt, MyAnimeList, AniList e Simkl.

### 🎨 Personalização e Temas
- **Dois temas**: **Isis** (escuro, roxo OLED, o padrão) e **Heitor** (claro, verde suave), além do modo automático que acompanha o sistema.
- **Visual limpo**: configurações organizadas em cartões recolhíveis (estilo *omakase*).

---

## Como Instalar

- **APK de Release**: gerado automaticamente pelo workflow do GitHub Actions ("CGFLIX Android") a cada push no branch `main` (artefato `cgflix-apk`).
  - Use `arm64-v8a` para a grande maioria dos celulares modernos.
  - Use `armeabi-v7a` para celulares mais antigos e TV boxes de 32 bits.
- **Releases Oficiais**: tags `v*` (ex.: `v1.4.0`) geram builds versionadas na aba de Releases.

*Nota de segurança*: o app não traz o endereço do servidor pré-configurado. Na primeira abertura, informe a URL do seu servidor Jellyfin ou conecte sua conta Plex.

---

## Compilar a partir do código

### Pré-requisitos
- Flutter SDK 3.47+
- JDK 21 e Android SDK/NDK configurados

### Passo a passo

```bash
# Obter dependências
flutter pub get

# Geração de código e internacionalização
scripts/codegen.sh
dart run slang

# Executar em modo desenvolvimento
flutter run
```

Para gerar o APK dividido por arquitetura:

```bash
flutter build apk --release --split-per-abi
```

---

## Para Desenvolvedores

- **[CGFLIX.md](CGFLIX.md)**: histórico versão por versão de tudo o que foi alterado, arquivos afetados, fluxo de merge com o upstream e próximos passos.
- **[docs/CONFIGURACOES.md](docs/CONFIGURACOES.md)**: documentação detalhada de cada opção de configuração e seus valores padrão.
- O código exclusivo do CGFLIX fica isolado em `lib/cgflix/`. Os arquivos originais do upstream recebem apenas ganchos de poucas linhas para garantir merges limpos.

---

## Créditos e Licença

O CGFLIX é baseado no **Plezy**, criado por [edde746 e colaboradores](https://github.com/edde746/plezy). Todo o reconhecimento pela excelente base de software pertence a eles.

- Licenciado sob a [GNU General Public License v3.0 (GPL-3.0)](LICENSE).
- Construído com [Flutter](https://flutter.dev).
- Motor de reprodução alimentado por [mpv](https://mpv.io), [ExoPlayer](https://developer.android.com/media/media3/exoplayer) e [libass](https://github.com/libass/libass).

---

## English summary

CGFLIX is a client app for Plex and Jellyfin, customized for a Brazilian family-and-friends media server. Built as a fork of [Plezy](https://github.com/edde746/plezy) (GPL-3.0) with localized interface, Seerr request integration, dual purple OLED and light green themes, and streamlined settings. Upstream contributions and credits belong to edde746 and the Plezy community.
