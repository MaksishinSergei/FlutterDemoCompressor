import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:compressor/utils/gif_generator.dart';
import 'package:compressor/utils/compression_calculate.dart'; 
import 'package:compressor/utils/ffmpeg_compress_video.dart'; 
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

class MediaViewScreen extends StatefulWidget {
  final String filePath;
  final File? videoFile;

  const MediaViewScreen({super.key, required this.filePath, required this.videoFile});

  @override
  State<MediaViewScreen> createState() => _MediaViewScreenState();
}

class _MediaViewScreenState extends State<MediaViewScreen> with SingleTickerProviderStateMixin {

  
  List<Widget> settingsButtons = <Widget>[];
  //Для видео
  bool _isVideo = false;
  Uint8List? _gifData;
  bool _isLoading = false;
  String? _errorMessage;
  String sizeFileOriginal = "0 B";
  String sizeFileCompress = "0 B";
  String minSizeFileCompress = "0 B";
  double sliderSizeFile = 0.0;
  bool isEditVideo = false;
  CompressionPlan? _compressionPlan;
  bool _isAnalyzing = false;
  final List<bool> selectedSize = <bool>[false, false, true];
  List<Widget> size = <Widget>[];
  final List<bool> selectedRatio = <bool>[true, false, false];
  final List<Widget> ratio = <Widget>[Text('Низкая'), Text('Средняя'), Text('Высокая')];
  final List<String> ratioValues = ['low', 'medium', 'high'];
  final List<bool> selectedQuality = <bool>[false, false, true, false, false];
  final List<Widget> quality = <Widget>[Text('144p'), Text('360p'), Text('480p'), Text('720p'), Text('1080p')];
  final List<String> qualityValues = ['144p', '360p', '480p', '720p', '1080p'];
  final List<bool> _selectedSettings = <bool>[false, false, true];
  //Для фото
  bool isEditImg = false;
  final List<bool> selectedSizeImage = <bool>[false, false, true];
  List<Widget> sizeImage = <Widget>[];
  final List<bool> selectedSpeedImage = <bool>[false, true, false];
  final List<Widget> speedImage = <Widget>[Text('Быстро'), Text('Авто'), Text('Медленно')];
  final List<String> ratioValuesImage = ['fast', 'auto', 'low'];
  final List<bool> selectedQualityImage = <bool>[false, true, false];
  final List<Widget> qualityImage = <Widget>[Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [Text('Низкое', style: TextStyle(fontWeight: FontWeight.bold),), Text("~30-40 %", style: TextStyle(fontSize: 12),)],), Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [Text('Среднее', style: TextStyle(fontWeight: FontWeight.bold),), Text("~60-75 %", style: TextStyle(fontSize: 12),)],), Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [Text("Высокое", style: TextStyle(fontWeight: FontWeight.bold),), Text("~80-90 %", style: TextStyle(fontSize: 12),)],)];
  final List<String> qualityValuesImage = ['Низкое', 'Среднее', 'Высокое'];
  final List<bool> _selectedSettingsImage = <bool>[true, false];
  late AnimationController _animationController;
  int _currentIndex = 1;
  int _previousIndex = 1;
  double _indicatorPosition = 0.0;
  double _indicatorWidth = 0.0;
  late double currentValue;
  double _currentSliderValueVideo = 20;
  double _currentSliderValueImg = 75;
  
  bool year2023 = true;

  @override
  void initState() {
    super.initState();
    final path = widget.filePath.toLowerCase();
    _isVideo = path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi');
    if (_isVideo) {
      settingsButtons = [
    _SettingsButtons(text: "Степень сжатия", icon: Icons.clear_all),
    _SettingsButtons(text: "Размер видео", icon: Icons.aspect_ratio),
    _SettingsButtons(text: "Качество", icon: Icons.hd_outlined)];
    }
    else {
      settingsButtons = [
    _SettingsButtons(text: "Скорость сжатия", icon: Icons.clear_all),
    _SettingsButtons(text: "Качество", icon: Icons.hd_outlined)];
    _currentIndex = 0;
    }

    _loadFileSize();
    _initializeDefaultSizes();
    // if (_isVideo) {
    //   _analyzeVideo();
    // }
    sizeFileCompress = minSizeFileCompress;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        setState(() {
          // Плавное перемещение индикатора
          final screenWidth = MediaQuery.of(context).size.width;
          final buttonWidth = screenWidth / settingsButtons.length;
          final startPosition = buttonWidth * _previousIndex;
          final endPosition = buttonWidth * _currentIndex;
          
          _indicatorPosition = startPosition + (endPosition - startPosition) * _animationController.value;
          _indicatorWidth = buttonWidth * 0.6;
        });
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isVideo && _gifData == null && !_isLoading) {
      _loadGifPreview();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      final buttonWidth = screenWidth / settingsButtons.length;
      setState(() {
        _indicatorPosition = buttonWidth * _currentIndex;
        _indicatorWidth = buttonWidth * 0.6;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeDefaultSizes() {
    size = <Widget>[Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [Text('85 mB', style: TextStyle(fontWeight: FontWeight.bold),), Text("VK", style: TextStyle(fontSize: 12),)],), Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [Text('25 mB', style: TextStyle(fontWeight: FontWeight.bold),), Text("Mail.ru", style: TextStyle(fontSize: 12),)],), Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [Text('2 mB', style: TextStyle(fontWeight: FontWeight.bold),), Text("Min", style: TextStyle(fontSize: 12),)],)];
  }

  // Future<void> _analyzeVideo() async {
  //   if (_isAnalyzing) return;
    
  //   setState(() {
  //     _isAnalyzing = true;
  //   });
    
  //   try {
  //     final plan = await VideoCompressionCalculator.calculateCompressionPlan(
  //       widget.filePath,
  //       targetQuality: 'very_low',
  //       useChewie: true
  //     );
  //     print("PLAN COMPRESSION: $plan");
  //     if (mounted) {
  //       setState(() {
  //         _compressionPlan = plan;

  //         _isAnalyzing = false;
  //         minSizeFileCompress = _formatFileSize((plan.minTheoreticalSizeMB * 1024 * 1024).toInt());
  //         _currentSliderValueVideo = (plan.recommendedSizeMB * 1024 * 1024);
  //         _updateSizeButtons(plan);
  //       });
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       setState(() {
  //         _isAnalyzing = false;
  //         print('Ошибка анализа видео: $e');
  //       });
  //     }
  //   }
  // }

  // void _updateSizeButtons(CompressionPlan plan) {
  //   final String minSizeMB = _formatFileSize((plan.minTheoreticalSizeMB * 1024 * 1024).toInt());;

  //   size = <Widget>[Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [Text('85 МБ', style: TextStyle(fontWeight: FontWeight.bold),), Text("VK", style: TextStyle(fontSize: 12),)],), Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [Text('25 МБ', style: TextStyle(fontWeight: FontWeight.bold),), Text("Mail.ru", style: TextStyle(fontSize: 12),)],), Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [Text(minSizeMB, style: TextStyle(fontWeight: FontWeight.bold),), Text("Min", style: TextStyle(fontSize: 12),)],)];
  // }

  Future<int> _getFileSize() async {
    final file = File(widget.filePath);
    return await file.length();
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    
    const suffixes = ["Б", "КБ", "МБ", "ГБ", "ТБ"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  Future<void> _loadFileSize() async {
    try {
      final size = await _getFileSize();
      if (mounted) {
        setState(() {
          sizeFileOriginal = _formatFileSize(size);
          sliderSizeFile = size.toDouble();
        });
      }
    } catch (e) {
      print('Error getting file size: $e');
    }
  }

  Future<void> _loadGifPreview() async {
    if (widget.videoFile == null) {
      setState(() {
        _errorMessage = 'Файл видео не доступен';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      final gifBytes = await GifGenerator.createGifFromVideo(
        widget.videoFile!,
        width: screenWidth.toInt(),
        height: (screenHeight * 0.5).toInt(), 
      );
      
      if (mounted) {
        setState(() {
          _gifData = gifBytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error creating GIF: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка при создании GIF: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildVideoPreview() {
    final isDarkTheme = ThemeProvider.controllerOf(context).currentThemeId == "dark";
    final tooltipTextColor = isDarkTheme ? Colors.cyanAccent : Colors.white;
    final progressIndicatorLoading = isDarkTheme ? Colors.cyanAccent : Colors.indigoAccent;
    final textLoading = isDarkTheme ? Colors.cyanAccent : Colors.black;
    final textColor = isDarkTheme ? Colors.cyanAccent : Colors.black;
    final btnColor = isDarkTheme ? Colors.cyanAccent : Colors.indigoAccent;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: progressIndicatorLoading,),
            SizedBox(height: 16),
            Text('Создание GIF...', style: TextStyle(color: textLoading)),
          ],
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
          ],
        ),
      );
    }
    
    if (_isAnalyzing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: progressIndicatorLoading),
            SizedBox(height: 16),
            Text('Анализ видео...', style: TextStyle(color: textLoading)),
          ],
        ),
      );
    }

    if (_gifData != null) {
      return Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              width: double.infinity,
              child: Stack(
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(_gifData!,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter),
                  ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Tooltip(
                    triggerMode: TooltipTriggerMode.tap,
                    margin: EdgeInsets.only(left: 55),
                    message: "Это 5-секундный\nпредпросмотр\nвашего видео",
                    waitDuration: Duration(milliseconds: 500),
                    showDuration: Duration(seconds: 3),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(0),     
                        topRight: Radius.circular(8),   
                        bottomRight: Radius.circular(8),  
                        bottomLeft: Radius.circular(8)
                      ),
                    ),
                    textStyle: TextStyle(
                      color: tooltipTextColor,
                      fontSize: 14,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),     
                          topRight: Radius.circular(0),   
                          bottomRight: Radius.circular(20),  
                          bottomLeft: Radius.circular(0)
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.new_releases_outlined, color: tooltipTextColor, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "Превью", 
                            style: TextStyle(
                              color: tooltipTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),     
                        topRight: Radius.circular(0),   
                        bottomRight: Radius.circular(20),  
                        bottomLeft: Radius.circular(0)
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Размер: $sizeFileOriginal", 
                              style: TextStyle(
                                color: tooltipTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: tooltipTextColor,),
                            Text("~$sizeFileCompress", 
                              style: TextStyle(
                                color: tooltipTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
            ),
            const SizedBox(height: 10),
            Text('Параметры сжатия', 
              style: TextStyle(
                fontSize: 14,
                fontFamily: "",
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center
            ),
            const SizedBox(height: 5),
            
            // Анимированный ToggleButtons
            _buildAnimatedToggleButtons(),
            const SizedBox(
              height: 5,
            ),
            _currentIndex == 1
              ? _buildToggleButtonsSize()
              : _currentIndex == 2
                ? _buildToggleButtonsQuality()
                : _buildToggleButtonsRatio(),
            OutlinedButton.icon(
              label: Text(
                'Сжать и сохранить',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                _compressAndSave();
              },
              icon: Icon(Icons.save_rounded),
              style: OutlinedButton.styleFrom(
                foregroundColor: btnColor,
                side: BorderSide(color: btnColor),
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                iconSize: 24,
              ),
            ),
          ],
        ),
      );
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('Создание GIF...'),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCompressionSettings() {
      // Получаем выбранную степень сжатия
      String compressionRatio = 'medium';
      for (int i = 0; i < selectedRatio.length; i++) {
        if (selectedRatio[i]) {
          compressionRatio = ratioValues[i];
          break;
        }
      }

      String quality = '480p';
      for (int i = 0; i < selectedQuality.length; i++) {
        if (selectedQuality[i]) {
          quality = qualityValues[i];
          break;
        }
      }

      double targetSizeMB = 0;
      if (isEditVideo) {
        targetSizeMB = _currentSliderValueVideo / (1024 * 1024);
      } else {
        // Иначе берем из выбранной кнопки размера
        for (int i = 0; i < selectedSize.length; i++) {
          if (selectedSize[i]) {
            switch (i) {
              case 0:
                targetSizeMB = 85.0;
                break;
              case 1:
                targetSizeMB = 25.0;
                break;
              case 2:
                targetSizeMB = _compressionPlan?.minTheoreticalSizeMB ?? 2.0;
                break;
            }
            break;
          }
        }
      }

      return {
        'ratio': compressionRatio,
        'quality': quality,
        'targetSizeMB': targetSizeMB,
        'isCustomSize': isEditVideo,
      };
    }

  Future<void> _compressAndSave() async {
    final settings = _getCompressionSettings();

    print('Настройки сжатия:');
    print('Степень сжатия: ${settings['ratio']}');
    print('Качество: ${settings['quality']}');
    print('Целевой размер: ${settings['targetSizeMB']} MB');
    print('Пользовательский размер: ${settings['isCustomSize']}');

    final result = await VideoCompressor.compressVideo(
      inputVideoPath: widget.filePath,
      settings: CompressionSettings(
        ratio: settings['ratio'],
        size: settings['targetSizeMB'].toString(),
        quality: settings['quality'],
      ),
    );
    print("Результаты сжатия: $result");
  }

  Widget _buildAnimatedToggleButtons() {
    final isDarkTheme = ThemeProvider.controllerOf(context).currentThemeId == "dark";
    final buttonsIndicate = isDarkTheme ? Colors.cyanAccent : Colors.blue[700];
    return SizedBox(
      height: 63,
      child: Stack(
        children: [
          Row(
            children: List.generate(settingsButtons.length, (index) {
              return Expanded(
                child: InkWell(
                  onTap: () => _isVideo ? _handleTabSelectionVideo(index) : _handleTabSelectionImage(index),
                  splashColor: Colors.transparent,    
                  hoverColor: Colors.transparent,  
                  highlightColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(5.0),
                    child: Opacity(
                      opacity: _currentIndex == index ? 1.0 : 0.6,
                      child: settingsButtons[index],
                    ),
                  ),
                ),
              );
            }),
          ),
          
          // Анимированный индикатор
          Positioned(
            left: _indicatorPosition + (MediaQuery.of(context).size.width / settingsButtons.length - _indicatorWidth) / 2,
            bottom: 10,
            child: Container(
              width: _indicatorWidth,
              height: 3,
              decoration: BoxDecoration(
                color: buttonsIndicate,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: buttonsIndicate!.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTabSelectionVideo(int index) {
    if (_currentIndex != index) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = index;
        
        for (int i = 0; i < _selectedSettings.length; i++) {
          _selectedSettings[i] = i == index;
        }
      });
      
      _animationController.forward(from: 0.0);
    }
  }

  void _handleTabSelectionImage(int index) {
    if (_currentIndex != index) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = index;
        
        for (int i = 0; i < _selectedSettingsImage.length; i++) {
          _selectedSettingsImage[i] = i == index;
        }
      });
      
      _animationController.forward(from: 0.0);
    }
  }

Widget _buildToggleButtonsRatio() {
  final isDarkTheme = ThemeProvider.controllerOf(context).currentThemeId == "dark";
  final selectedBorderColor = isDarkTheme ? Colors.cyanAccent : Colors.blue[700];
  final toggleFillColor = isDarkTheme ? Colors.cyanAccent : Colors.blue[300];

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ToggleButtons(
              direction: Axis.horizontal,
              isSelected: selectedRatio,
              onPressed: (int index) {
                setState(() {
                  for (int i = 0; i < selectedRatio.length; i++) {
                    selectedRatio[i] = i == index;
                  }
                });
              },
              borderWidth: 2.0,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              selectedBorderColor: selectedBorderColor,
              borderColor: selectedBorderColor,
              selectedColor: Colors.white,
              fillColor: toggleFillColor,
              color: Colors.grey,
              constraints: const BoxConstraints(minHeight: 35.0, minWidth: 70.0),
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              children: ratio,
            ),
          ],
        ),
      ),
      const SizedBox(height: 48), // Отступ добавляется после ToggleButtons
    ],
  );
}

Widget _buildToggleButtonsSpeedImage() {
  final isDarkTheme = ThemeProvider.controllerOf(context).currentThemeId == "dark";
  final selectedBorderColor = isDarkTheme ? Colors.cyanAccent : Colors.blue[700];
  final toggleFillColor = isDarkTheme ? Colors.cyanAccent : Colors.blue[300];
  final tooltipTextColor = isDarkTheme ? Colors.cyanAccent : Colors.white;

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ToggleButtons(
              direction: Axis.horizontal,
              isSelected: selectedSpeedImage,
              onPressed: (int index) {
                setState(() {
                  for (int i = 0; i < selectedSpeedImage.length; i++) {
                    selectedSpeedImage[i] = i == index;
                  }
                });
              },
              borderWidth: 2.0,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              selectedBorderColor: selectedBorderColor,
              borderColor: selectedBorderColor,
              selectedColor: Colors.white,
              fillColor: toggleFillColor,
              color: Colors.grey,
              constraints: const BoxConstraints(minHeight: 35.0, minWidth: 80.0),
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              children: speedImage,
            ),
          ],
        ),
      ),
      Tooltip(
        triggerMode: TooltipTriggerMode.tap,
        preferBelow: false,
        message: "Пресеты для сжатия.\nБыстро-меньше качество, быстрее скорость\nКачественно-лучшее качество, медленнее",
        waitDuration: Duration(milliseconds: 500),
        showDuration: Duration(seconds: 3),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          color: tooltipTextColor,
          fontSize: 14,
        ),
        child: Icon(Icons.question_mark_rounded, color: Colors.grey),
            ),
      const SizedBox(height: 38), // Отступ добавляется после ToggleButtons
    ],
  );
}

  Widget _buildToggleButtonsQuality() {
    final isDarkTheme = ThemeProvider.controllerOf(context).currentThemeId == "dark";
    final selectedBorderColor = isDarkTheme ? Colors.cyanAccent : Colors.blue[700];
    final toggleFillColor = isDarkTheme ? Colors.cyanAccent : Colors.blue[300];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ToggleButtons(
            direction: Axis.horizontal,
            isSelected: selectedQuality,
            onPressed: (int index){
              setState(() {
                for (int i = 0; i < selectedQuality.length; i++){
                  selectedQuality[i] = i == index;
                }
              });
            },
            borderWidth: 2.0,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            selectedBorderColor: selectedBorderColor,
            borderColor: selectedBorderColor,
            selectedColor: Colors.white,
            fillColor: toggleFillColor,
            color: Colors.grey,
            constraints: const BoxConstraints(minHeight: 35.0, minWidth: 50.0),
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            children: quality),
            
        ],
      ),
    ),
    const SizedBox(height: 48)
      ],
    );
  }

  Widget _buildToggleButtonsQualityImage() {
    final isDarkTheme = ThemeProvider.controllerOf(context).currentThemeId == "dark";
    final selectedBorderColor = isDarkTheme ? Colors.cyanAccent : Colors.blue[700];
    final toggleFillColor = isDarkTheme ? Colors.cyanAccent : Colors.blue[300];
    final tooltipTextColor = isDarkTheme ? Colors.cyanAccent : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Tooltip(
            triggerMode: TooltipTriggerMode.tap,
            preferBelow: false,
            message: "Пресеты для сжатия.\nЧем ниже качество,\nтем меньше размер файла",
            margin: EdgeInsets.only(left: 95),
            waitDuration: Duration(milliseconds: 500),
            showDuration: Duration(seconds: 3),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: TextStyle(
              color: tooltipTextColor,
              fontSize: 14,
            ),
            child: Icon(Icons.question_mark_rounded, color: Colors.grey),
                ),
          const SizedBox(width: 7),
          ToggleButtons(
            direction: Axis.horizontal,
            isSelected: selectedQualityImage,
            onPressed: (int index){
              setState(() {
                for (int i = 0; i < selectedQualityImage.length; i++){
                  selectedQualityImage[i] = i == index;
                }
              });
            },
            borderWidth: 2.0,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            selectedBorderColor: selectedBorderColor,
            borderColor: selectedBorderColor,
            selectedColor: Colors.white,
            fillColor: toggleFillColor,
            color: Colors.grey,
            constraints: const BoxConstraints(minHeight: 35.0, minWidth: 70.0),
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            children: qualityImage),
            IconButton(
              onPressed: () {
                setState(() {
                  isEditImg = true;
                  currentValue = _currentSliderValueImg;
                  for (int i = 0; i < selectedQualityImage.length; i++) {
                    selectedQualityImage[i] = false;
                  }
                });
              },
              icon: const Icon(Icons.edit_outlined, color: Colors.grey,)),
        ],
      ),
    ),
    if (isEditImg) _buildEditSlider() else const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildToggleButtonsSize() {
    final isDarkTheme = ThemeProvider.controllerOf(context).currentThemeId == "dark";
    final selectedBorderColor = isDarkTheme ? Colors.cyanAccent : Colors.blue[700];
    final toggleFillColor = isDarkTheme ? Colors.cyanAccent : Colors.blue[300];

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ToggleButtons(
            direction: Axis.horizontal,
            isSelected: selectedSize,
            onPressed: (int index){
              setState(() {
                for (int i = 0; i < selectedSize.length; i++){
                  selectedSize[i] = i == index;
                }
                isEditVideo = false;
                index == 0 ? sizeFileCompress = "85.00 МБ"
                  : index == 1 ?  sizeFileCompress = "25.00 МБ"
                    : sizeFileCompress = minSizeFileCompress;
              });
            },
            borderWidth: 2.0,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            selectedBorderColor: selectedBorderColor,
            borderColor: selectedBorderColor,
            selectedColor: Colors.white,
            fillColor: toggleFillColor,
            color: Colors.grey,
            constraints: const BoxConstraints(minHeight: 35.0, minWidth: 70.0),
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            children: size),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  isEditVideo = true;
                  currentValue = _currentSliderValueVideo;
                  for (int i = 0; i < selectedSize.length; i++) {
                    selectedSize[i] = false;
                  }
                  sizeFileCompress = _formatFileSize(_currentSliderValueVideo.toInt());
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('изменить'),
            ),
        ],
      ),
        if (isEditVideo) _buildEditSlider() else const SizedBox(height: 48),
        ],
      )
    );
  }

Widget _buildEditSlider() {
  final isDarkTheme = ThemeProvider.controllerOf(context).currentThemeId == "dark";
  final sliderColor = isDarkTheme ? Colors.cyanAccent : Colors.blue[700];

  
  
  return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        Expanded(
          flex: 4, // Большая часть для слайдера
          child: Slider(
            value: currentValue,
            min: 0,
            max: _isVideo ? sliderSizeFile : isEditImg ? 100 : 0,
            onChanged: (double value) {
              setState(() {
                currentValue = value;
                if (_isVideo) sizeFileCompress = _formatFileSize(value.toInt());
              });
            },
            activeColor: sliderColor,
          ),
        ),
        Text(_isVideo ? _formatFileSize(currentValue.toInt()) : "${currentValue.toStringAsFixed(0)} %"),
        Expanded(
          flex: 1, // Меньшая часть для кнопки
          child: IconButton(
            onPressed: () {
              setState(() {
                if (_isVideo) {
                  isEditVideo = false;
                  if (!selectedSize.contains(true)) {
                    selectedSize[2] = true;
                  }
                  sizeFileCompress = minSizeFileCompress;
                }
                else{
                  isEditImg = false;
                  if (!selectedQualityImage.contains(true)) {
                    selectedQualityImage[1] = true;
                  }
                }
              });
            },
            icon: Icon(Icons.close, size: 20),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ),
      ],
    );
}


  Widget _buildImageView() {
    final isDarkTheme = ThemeProvider.controllerOf(context).currentThemeId == "dark";
    final tooltipTextColor = isDarkTheme ? Colors.cyanAccent : Colors.white;
    final textColor = isDarkTheme ? Colors.cyanAccent : Colors.black;
    final btnColor = isDarkTheme ? Colors.cyanAccent : Colors.indigoAccent;

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    File(widget.filePath),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    ),
                ),
                Positioned(
                  top: 0,
                  child: Tooltip(
                    triggerMode: TooltipTriggerMode.tap,
                    margin: EdgeInsets.only(left: 80),
                    message: "Это предпросмотр\nвашего изображения",
                    waitDuration: Duration(milliseconds: 500),
                    showDuration: Duration(seconds: 3),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(0),     
                        topRight: Radius.circular(8),   
                        bottomRight: Radius.circular(8),  
                        bottomLeft: Radius.circular(8)
                      ),
                    ),
                    textStyle: TextStyle(
                      color: tooltipTextColor,
                      fontSize: 14,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(0),     
                          topRight: Radius.circular(0),   
                          bottomRight: Radius.circular(20),  
                          bottomLeft: Radius.circular(20)
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.new_releases_outlined, color: tooltipTextColor, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "Превью", 
                            style: TextStyle(
                              color: tooltipTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),     
                        topRight: Radius.circular(20),   
                        bottomRight: Radius.circular(0),  
                        bottomLeft: Radius.circular(0)
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Размер: $sizeFileOriginal", 
                              style: TextStyle(
                                color: tooltipTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: tooltipTextColor,),
                            Text("~$sizeFileCompress", 
                              style: TextStyle(
                                color: tooltipTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 10),
            Text('Параметры сжатия', 
              style: TextStyle(
                fontSize: 14,
                fontFamily: "",
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center
            ),
            const SizedBox(height: 5),
            
            // Анимированный ToggleButtons
            _buildAnimatedToggleButtons(),
            const SizedBox(
              height: 5,
            ),
            _currentIndex == 0
              ? _buildToggleButtonsSpeedImage()
              : _buildToggleButtonsQualityImage(),
            OutlinedButton.icon(
              label: Text(
                'Сжать и сохранить',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                _compressAndSave();
              },
              icon: Icon(Icons.save_rounded),
              style: OutlinedButton.styleFrom(
                foregroundColor: btnColor,
                side: BorderSide(color: btnColor),
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                iconSize: 24,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDarkTheme ? Colors.black : Colors.indigoAccent;
    final appBarTextColor = isDarkTheme ? Colors.cyanAccent : Colors.white;
    

    return Scaffold(
      appBar: AppBar(
        title: Text(_isVideo ? "Сжатие видео" : "Сжатие фото", style: TextStyle(color: appBarTextColor)),
        backgroundColor: appBarColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: appBarTextColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isVideo ? _buildVideoPreview() : _buildImageView(),
    );
  }
}

class _SettingsButtons extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SettingsButtons({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22),
        const SizedBox(height: 4),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}


      // child: SizedBox(
      //   width: 300,
      //   height: 350,
      //   child: Image.file(
      //     File(widget.filePath),
      //     fit: BoxFit.contain,
      //     errorBuilder: (context, error, stackTrace) {
      //       return Center(
      //         child: Column(
      //           mainAxisAlignment: MainAxisAlignment.center,
      //           children: [
      //             Icon(Icons.error_outline, size: 48, color: Colors.red),
      //             SizedBox(height: 8),
      //             Text('Ошибка загрузки изображения'),
      //           ],
      //         ),
      //       );
      //     },
      //   ),
      // )