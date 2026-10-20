// Numeração própria do CGFLIX (a do Plezy ficou para trás na Etapa 1B).
// A versão real vem do pubspec.yaml (`version: 1.6.2+811` desde 16/10/2026); aqui só o texto do Sobre.

/// Texto da versão no Sobre, logo abaixo do nome: "Versão 1.6.2" (desde a 1.5.0, sem repetir "CGFLIX").
/// Sem versão (ainda carregando), vazio.
String cgflixVersionLabel(String version) => version.isEmpty ? '' : 'Versão $version';
