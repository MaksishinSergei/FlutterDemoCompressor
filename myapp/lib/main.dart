import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'package:theme_provider/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final Brightness platformBrightness =
      WidgetsBinding.instance.window.platformBrightness;
  final String initialThemeId = platformBrightness == Brightness.dark
      ? "dark"
      : "light";

  runApp(ConvertApp(initialThemeId: initialThemeId));
}

class ConvertApp extends StatelessWidget {
  final String initialThemeId;

  const ConvertApp({super.key, required this.initialThemeId});

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      saveThemesOnChange: false,
      defaultThemeId: initialThemeId,
      themes: [
        AppTheme(
          id: "light",
          description: "Светлая тема",
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            scaffoldBackgroundColor: Colors.white,
          ),
        ),
        AppTheme(
          id: "dark",
          description: "Тёмная тема",
          data: ThemeData.dark().copyWith(
            primaryColor: Colors.blueGrey,
            scaffoldBackgroundColor: Colors.grey[900],
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePage(),
        builder: (context, child) {
          return ThemeConsumer(child: child!);
        },
      ),
    );
  }
}
