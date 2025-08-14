import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class MediaViewScreen extends StatefulWidget {
  final String filePath;

  const MediaViewScreen({super.key, required this.filePath});

  @override
  State<MediaViewScreen> createState() => _MediaViewScreenState();
}

class _MediaViewScreenState extends State<MediaViewScreen> {
  VideoPlayerController? _videoController;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    // Определяем тип файла
    final path = widget.filePath.toLowerCase();
    _isVideo =
        path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi');

    // Инициализируем видео только если это видеофайл
    if (_isVideo) {
      _initializeVideo();
    }
  }

  void _initializeVideo() async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        throw Exception("Файл не найден");
      }

      _videoController = VideoPlayerController.file(file)
        ..addListener(() {
          if (mounted) setState(() {});
        });

      await _videoController!.initialize();

      // Добавляем обработку ошибок декодирования
      if (!_videoController!.value.isInitialized) {
        throw Exception("Не удалось инициализировать видео");
      }

      if (mounted) {
        setState(() {});
        await _videoController!.play();
      }
    } catch (e) {
      print('Video error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка видео: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDarkTheme ? Colors.black : Colors.indigoAccent;
    final appBarTextColor = isDarkTheme ? Colors.cyanAccent : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text('Просмотр', style: TextStyle(color: appBarTextColor)),
        backgroundColor: appBarColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: appBarTextColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isVideo ? _buildVideoPlayer() : _buildImageView(),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Ограничиваем размер видео
        SizedBox(
          width: 300, // Фиксированная ширина
          height: 350, // Фиксированная высота
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        ),
        VideoProgressIndicator(_videoController!, allowScrubbing: true),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _videoController!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
              onPressed: () {
                setState(() {
                  _videoController!.value.isPlaying
                      ? _videoController!.pause()
                      : _videoController!.play();
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageView() {
    return InteractiveViewer(
      child: Center(
        child: SizedBox(
          width: 400,
          height: 400,
          child: Image.file(
            File(widget.filePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Center(child: Text('Ошибка загрузки изображения')),
          ),
        ),
      ),
    );
  }
}
