import 'dart:convert';

/// Texto local; não há transporte nem endpoint de diagnóstico.
const int maxDiagnosticTextBytes = 256 * 1024;

/// Trims [logs] from the front so `header + logs` fits [maxBytes], keeping the
/// header intact and never splitting a UTF-8 sequence or a log line.
String constrainDiagnosticText({required String header, required String logs, int maxBytes = maxDiagnosticTextBytes}) {
  if (maxBytes <= 0) return '';

  final headerBytes = utf8.encode(header);
  if (headerBytes.length >= maxBytes) {
    var end = maxBytes;
    while (end > 0 && end < headerBytes.length && (headerBytes[end] & 0xC0) == 0x80) {
      end--;
    }
    return utf8.decode(headerBytes.sublist(0, end));
  }

  final logBytes = utf8.encode(logs);
  final availableLogBytes = maxBytes - headerBytes.length;
  if (logBytes.length <= availableLogBytes) return '$header$logs';

  var start = logBytes.length - availableLogBytes;
  while (start < logBytes.length && (logBytes[start] & 0xC0) == 0x80) {
    start++;
  }
  final nextLine = logBytes.indexOf(0x0A, start);
  if (nextLine >= 0 && nextLine + 1 < logBytes.length) {
    start = nextLine + 1;
  }
  return header + utf8.decode(logBytes.sublist(start));
}

