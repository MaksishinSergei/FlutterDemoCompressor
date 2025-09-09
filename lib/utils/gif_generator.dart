import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

class GifGenerator {
  /// Создает GIF из видео
  static Future<Uint8List?> createGifFromVideo(
    File videoFile, {
    int startTime = 0,
    int duration = 3,
    int width = 190,
    int height = 400,
    int fps = 10,
    int loop = 0,
  }) async {
    File? tempInputFile;
    File? tempOutputFile;
    
    try {
      // 1. Проверяем существование файла
      if (!await videoFile.exists()) {
        print('Видео файл не найден: ${videoFile.path}');
        return null;
      }

      // 2. Копируем файл в доступную директорию
      final tempDir = await getTemporaryDirectory();
      tempInputFile = File('${tempDir.path}/temp_video_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await videoFile.copy(tempInputFile.path);

      // 3. Создаем выходной файл
      tempOutputFile = File('${tempDir.path}/gif_${DateTime.now().millisecondsSinceEpoch}.gif');
      
      // 4. Формируем команду БЕЗ переносов строк
      final command = 
          '-ss $startTime -t $duration -i "${tempInputFile.path}" '
          '-vf "fps=$fps,scale=$width:$height:force_original_aspect_ratio=increase,crop=$width:$height" '
          '-loop $loop -y "${tempOutputFile.path}"';

      print('FFmpeg команда: $command');
      
      // 5. Выполняем команду с детальным логированием
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      
      if (ReturnCode.isSuccess(returnCode)) {
        if (await tempOutputFile.exists() && await tempOutputFile.length() > 0) {
          final gifBytes = await tempOutputFile.readAsBytes();
          print('GIF успешно создан, размер: ${gifBytes.length} bytes');
          return gifBytes;
        } else {
          print('GIF файл не был создан или пуст');
          return null;
        }
      } else {
        print('FFmpeg ошибка: ${returnCode?.getValue()}');
        return null;
      }
      
    } catch (e, stackTrace) {
      print('Ошибка при создании GIF: $e');
      print('Стек вызовов: $stackTrace');
      return null;
    } finally {
      // 6. Очищаем временные файлы
      await _deleteTempFile(tempInputFile);
      await _deleteTempFile(tempOutputFile);
    }
  }

  /// Упрощенная команда для тестирования
  static Future<Uint8List?> testSimpleCommand(File videoFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempInputFile = File('${tempDir.path}/test_video.mp4');
      await videoFile.copy(tempInputFile.path);
      
      final tempOutputFile = File('${tempDir.path}/test.gif');
      
      // Простейшая команда для тестирования
      final simpleCommand = '-i "${tempInputFile.path}" -t 2 -vf "scale=320:-1" -y "${tempOutputFile.path}"';
      
      print('Тестовая команда: $simpleCommand');
      
      final session = await FFmpegKit.execute(simpleCommand);
      final returnCode = await session.getReturnCode();
      final output = await session.getOutput();
      
      print('Тест - Код возврата: ${returnCode?.getValue()}');
      print('Тест - Вывод: $output');
      
      if (ReturnCode.isSuccess(returnCode) && await tempOutputFile.exists()) {
        return await tempOutputFile.readAsBytes();
      }
      
      return null;
    } catch (e) {
      print('Тестовая ошибка: $e');
      return null;
    }
  }

  static Future<void> _deleteTempFile(File? file) async {
    if (file != null && await file.exists()) {
      try {
        await file.delete();
      } catch (e) {
        print('Ошибка при удалении временного файла: $e');
      }
    }
  }
}