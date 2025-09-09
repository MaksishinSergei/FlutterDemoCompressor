import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

// Создаем собственный класс для разрешения
class VideoResolution {
  final double width;
  final double height;

  VideoResolution(this.width, this.height);

  double get pixels => width * height;

  @override
  String toString() => '${width.toInt()}x${height.toInt()}';
}

class VideoInfo {
  final Duration duration;
  final bool hasAudio;
  final bool hasVideo;
  final VideoResolution resolution;

  VideoInfo({
    required this.duration,
    required this.hasAudio,
    required this.hasVideo,
    required this.resolution,
  });
}

Future<VideoInfo> getVideoInfo(String filePath) async {
  final controller = VideoPlayerController.file(File(filePath));
  ChewieController? chewieController;
  
  try {
    await controller.initialize();
    
    // Создаем ChewieController для лучшей обработки видео
    chewieController = ChewieController(
      videoPlayerController: controller,
      autoPlay: false,
      looping: false,
      showControls: false, // Не показываем контролы для анализа
      allowFullScreen: false,
      allowedScreenSleep: false,
    );

    // Ждем немного для стабилизации
    await Future.delayed(Duration(milliseconds: 100));
    
    // Определяем наличие аудио/видео по трекам
    final hasAudio = await _hasAudioTrack(controller);
    final hasVideo = await _hasVideoTrack(controller);
    
    final videoInfo = VideoInfo(
      duration: controller.value.duration,
      hasAudio: hasAudio,
      hasVideo: hasVideo,
      resolution: VideoResolution(
        controller.value.size.width,
        controller.value.size.height,
      ),
    );
    
    chewieController.dispose();
    controller.dispose();
    return videoInfo;
    
  } catch (e) {
    chewieController?.dispose();
    controller.dispose();
    rethrow;
  }
}

// Вспомогательные методы для определения наличия треков
Future<bool> _hasAudioTrack(VideoPlayerController controller) async {
  try {
    // Для Chewie просто проверяем длительность
    return controller.value.duration > Duration.zero;
  } catch (e) {
    return false;
  }
}

Future<bool> _hasVideoTrack(VideoPlayerController controller) async {
  try {
    // Видео есть, если разрешение не нулевое
    return controller.value.size.width > 0 && controller.value.size.height > 0;
  } catch (e) {
    return false;
  }
}

class CompressionPlan {
  final double originalSizeMB;
  final double minTheoreticalSizeMB;
  final double recommendedSizeMB;
  final Duration duration;
  final bool hasAudio;
  final VideoResolution resolution;
  final double compressionRatio;

  CompressionPlan({
    required this.originalSizeMB,
    required this.minTheoreticalSizeMB,
    required this.recommendedSizeMB,
    required this.duration,
    required this.hasAudio,
    required this.resolution,
    required this.compressionRatio,
  });

  @override
  String toString() {
    return '''
Compression Plan:
- Original Size: ${originalSizeMB.toStringAsFixed(2)} MB
- Minimum Theoretical Size: ${minTheoreticalSizeMB.toStringAsFixed(2)} MB
- Recommended Size: ${recommendedSizeMB.toStringAsFixed(2)} MB
- Compression Ratio: ${compressionRatio.toStringAsFixed(1)}%
- Duration: ${duration.inSeconds} seconds
- Has Audio: $hasAudio
- Resolution: ${resolution.width.toInt()}x${resolution.height.toInt()}
''';
  }
}

class VideoCompressionCalculator {
  static Future<CompressionPlan> calculateCompressionPlan(
    String filePath, {
    String targetQuality = 'medium',
    bool useChewie = true, // Флаг для использования Chewie
  }) async {
    // Получаем информацию о видео
    final VideoInfo videoInfo;
    videoInfo = await getVideoInfo(filePath);
    
    final file = File(filePath);
    final fileSize = await file.length();
    final fileSizeMB = fileSize / (1024 * 1024);
    
    // Рассчитываем минимальный размер
    final minSizeMB = _calculateMinSize(
      videoInfo.duration,
      videoInfo.hasAudio,
      videoInfo.resolution,
    );
    
    // Определяем целевой размер по качеству
    final targetSizeMB = _getTargetSize(minSizeMB, targetQuality);
    
    // Ограничиваем целевой размер исходным размером
    final finalTargetSizeMB = targetSizeMB < fileSizeMB ? targetSizeMB : fileSizeMB;
    
    return CompressionPlan(
      originalSizeMB: fileSizeMB,
      minTheoreticalSizeMB: minSizeMB,
      recommendedSizeMB: finalTargetSizeMB,
      duration: videoInfo.duration,
      hasAudio: videoInfo.hasAudio,
      resolution: videoInfo.resolution,
      compressionRatio: (1 - (finalTargetSizeMB / fileSizeMB)) * 100,
    );
  }
  
  static double _calculateMinSize(
    Duration duration,
    bool hasAudio,
    VideoResolution resolution,
  ) {
    final durationSeconds = duration.inSeconds.toDouble();
    
    if (durationSeconds == 0) {
      return 0.1; // Минимальный размер для очень коротких видео
    }
    
    // Метаданные (фиксированные + пропорциональные)
    double metadata = 0.05 + (durationSeconds * 0.0001);
    
    // Аудио компонент
    double audioSize = hasAudio ? _calculateAudioSize(durationSeconds) : 0;
    
    // Видео компонент (зависит от разрешения)
    double videoSize = _calculateVideoSize(durationSeconds, resolution);
    
    return metadata + audioSize + videoSize;
  }
  
  static double _calculateAudioSize(double durationSeconds) {
    // Минимальный аудиобитрейт: 16kbps для приемлемого качества
    const double minAudioBitrateKbps = 16.0;
    return (minAudioBitrateKbps * durationSeconds) / 8192; // в MB
  }
  
  static double _calculateVideoSize(double durationSeconds, VideoResolution resolution) {
    // Минимальный битрейт зависит от разрешения
    final double pixels = resolution.pixels;
    double minBitrateKbps;
    
    if (pixels > 2000000) { // 1080p+ (1920x1080 = 2,073,600)
      minBitrateKbps = 500.0;
    } else if (pixels > 1000000) { // 720p+ (1280x720 = 921,600)
      minBitrateKbps = 300.0;
    } else if (pixels > 500000) { // 480p+ (854x480 = 409,920)
      minBitrateKbps = 150.0;
    } else if (pixels > 100000) { // 360p+ (640x360 = 230,400)
      minBitrateKbps = 80.0;
    } else { // Очень маленькие разрешения
      minBitrateKbps = 30.0;
    }
    
    return (minBitrateKbps * durationSeconds) / 8192; // в MB
  }
  
  static double _getTargetSize(double minSizeMB, String quality) {
    const Map<String, double> qualityFactors = {
      'very_low': 1.2,
      'low': 1.5,
      'medium': 2.0,
      'high': 3.0,
      'very_high': 4.0,
    };
    
    return minSizeMB * (qualityFactors[quality] ?? 2.0);
  }

  // Вспомогательный метод для проверки возможности сжатия
  static Future<bool> isCompressionWorthwhile(String filePath, {bool useChewie = true}) async {
    try {
      final plan = await calculateCompressionPlan(filePath, 
        targetQuality: 'low',
        useChewie: useChewie,
      );
      // Считаем сжатие целесообразным, если можно уменьшить размер хотя бы на 5%
      return plan.compressionRatio > 5.0;
    } catch (e) {
      return false;
    }
  }

  // Метод для получения рекомендуемого битрейта
  static Future<double> getRecommendedBitrate(String filePath, {
    String quality = 'low',
    bool useChewie = true,
  }) async {
    try {
      final VideoInfo videoInfo;
      videoInfo = await getVideoInfo(filePath);
      
      final durationSeconds = videoInfo.duration.inSeconds.toDouble();
      
      if (durationSeconds == 0) return 1000.0; // Значение по умолчанию
      
      final plan = await calculateCompressionPlan(filePath, 
        targetQuality: quality,
        useChewie: useChewie,
      );
      
      // Рассчитываем битрейт на основе целевого размера
      final targetBitrate = (plan.recommendedSizeMB * 8192) / durationSeconds;
      
      return targetBitrate;
    } catch (e) {
      return 1000.0; // Значение по умолчанию при ошибке
    }
  }
}