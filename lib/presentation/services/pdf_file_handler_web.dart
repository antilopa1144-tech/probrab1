// ignore_for_file: deprecated_member_use
import 'dart:typed_data';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Скачать PDF через браузер.
Future<String> savePdfToFile(Uint8List data, String fileName) async {
  final blob = html.Blob([data], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
  return fileName;
}

/// На вебе файл скачивается автоматически — отдельное открытие не нужно.
Future<void> openPdfFile(String filePath) async {
  // No-op: браузер сам обрабатывает скачанный PDF
}

/// На вебе «поделиться» = скачать файл.
Future<void> sharePdfFile(Uint8List data, String fileName) async {
  await savePdfToFile(data, fileName);
}
