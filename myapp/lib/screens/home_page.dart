import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';
import '../utils/gallery_picker.dart';
import './media_veiw_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Brightness? _currentBrightness;

  @override
  void initState() {
    super.initState();
    _currentBrightness = WidgetsBinding.instance.window.platformBrightness;
    WidgetsBinding.instance.window.onPlatformBrightnessChanged = () {
      final newBrightness = WidgetsBinding.instance.window.platformBrightness;
      if (_currentBrightness != newBrightness) {
        _currentBrightness = newBrightness;
        final newThemeId = newBrightness == Brightness.dark ? "dark" : "light";
        if (mounted) {
          ThemeProvider.controllerOf(context).setTheme(newThemeId);
        }
      }
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.window.onPlatformBrightnessChanged = null;
    super.dispose();
  }

  Future<void> _openGallery() async {
    final hasPermission = await MyPermissionHandler.checkGalleryPermission(
      context,
    );
    if (!hasPermission) {
      if (!mounted) return;
      MyPermissionHandler.showPermissionDialog(context);
      return;
    }
    try {
      final file = await MediaPicker.pickMedia();
      if (file != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaViewScreen(filePath: file.path),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      print('Ошибка: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при открытии галереи')),
        );
      }
    }
  }

  void _toggleTheme(BuildContext context) {
    final themeController = ThemeProvider.controllerOf(context);
    final newThemeId = themeController.currentThemeId == "light"
        ? "dark"
        : "light";
    themeController.setTheme(newThemeId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme =
        ThemeProvider.controllerOf(context).currentThemeId == "dark";

    final textColor = isDarkTheme ? Colors.cyanAccent : Colors.black;
    final appBarColor = isDarkTheme ? Colors.black : Colors.indigoAccent;
    final appBarTextColor = isDarkTheme ? Colors.cyanAccent : Colors.white;
    final btnColor = isDarkTheme ? Colors.cyanAccent : Colors.indigoAccent;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: const Icon(Icons.menu),
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              color: appBarTextColor,
            );
          },
        ),
        title: Text("Compressor", style: TextStyle(color: appBarTextColor)),
        centerTitle: true,
        backgroundColor: appBarColor,
        actions: [
          IconButton(
            onPressed: () => _toggleTheme(context),
            icon: const Icon(Icons.settings_brightness),
            color: appBarTextColor,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100, // задаём нужный размер
                  child: Image(
                    image: AssetImage("assets/folder_image.png"),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 250,
                  child: Text(
                    'Выберете изображение или видео для сжатия из вашей галереи',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: "",
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 25, // Отступ от правого края
            bottom: 25, // Отступ от нижнего края
            child: OutlinedButton.icon(
              label: Text(
                'Выбрать',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                await _openGallery();
              },
              icon: Icon(Icons.photo_library_outlined),
              style: OutlinedButton.styleFrom(
                foregroundColor: btnColor,
                side: BorderSide(color: btnColor),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: appBarColor),
              child: Text('Меню', style: TextStyle(color: appBarTextColor)),
            ),
            ListTile(
              leading: Icon(Icons.brightness_4, color: textColor),
              title: Text('Сменить тему', style: TextStyle(color: textColor)),
              onTap: () {
                _toggleTheme(context);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Пункт 1', style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Пункт 2', style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
