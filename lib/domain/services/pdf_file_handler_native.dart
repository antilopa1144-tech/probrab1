import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Сохранить PDF-файл локально и вернуть путь.
Future<String> savePdfToFile(Uint8List data, String fileName) async {
  Directory? directory;

  if (Platform.isAndroid) {
    directory = await getExternalStorageDirectory();
    if (directory != null) {
      final downloadsPath = directory.path.replaceFirst(
        RegExp(r'/Android/data/[^/]+/files'),
        '/Download',
      );
      directory = Directory(downloadsPath);
      // ignore: avoid_slow_async_io
      if (!await directory.exists()) {
        directory = await getApplicationDocumentsDirectory();
      }
    }
  } else if (Platform.isIOS) {
    directory = await getApplicationDocumentsDirectory();
  } else {
    directory =
        await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  }

  directory ??= await getApplicationDocumentsDirectory();

  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(data);

  return filePath;
}

/// Открыть PDF-файл системным просмотрщиком.
Future<void> openPdfFile(String filePath) async {
  await OpenFilex.open(filePath);
}

/// Поделиться PDF-файлом через системный share sheet.
Future<void> sharePdfFile(Uint8List data, String fileName) async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$fileName');
  await file.writeAsBytes(data);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], text: fileName),
  );
}
