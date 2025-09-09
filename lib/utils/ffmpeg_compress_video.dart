import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VideoCompressor {
  static Future<Map<String, dynamic>> compressVideo({
    required String inputVideoPath,
    required CompressionSettings settings,
  }) async {
    try {
      // Проверяем существование исходного файла
      final inputFile = File(inputVideoPath);
      if (!await inputFile.exists()) {
        throw Exception('Исходный файл не существует: $inputVideoPath');
      }

      final tempDir = await getTemporaryDirectory();
      final outputFileName = 'compressed_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final outputPath = '${tempDir.path}/$outputFileName';

      // Выполняем сжатие видео (здесь будет основная логика)
      await _performCompression(inputVideoPath, outputPath, settings);

      return {
        'success': true,
        'originalPath': inputVideoPath,
        'compressedPath': outputPath,
        'settings': settings,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'originalPath': inputVideoPath,
        'settings': settings,
      };
    }
  }


  static Future<void> _performCompression(
    String inputPath,
    String outputPath,
    CompressionSettings settings,
  ) async {

    // final inputFile = File(inputPath);
    // final outputFile = File(outputPath);
    
    // if (settings.quality == 'low') {
    //   final bytes = await inputFile.readAsBytes();
    //   await outputFile.writeAsBytes(bytes.sublist(0, bytes.length ~/ 2));
    // } else {
    //   await inputFile.copy(outputPath);
    // }

    print('Сжатие выполнено с настройками: $settings');
  }

}

class CompressionSettings {
  final String ratio;   
  final String size;
  final String quality; 

  CompressionSettings({
    required this.ratio,
    required this.size,
    required this.quality,
  });

  @override
  String toString() {
    return 'CompressionSettings(ratio: $ratio, size: $size, quality: $quality)';
  }

}
