import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class MyPermissionHandler {
  static Future<bool> checkGalleryPermission(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        // Для Android 10+ (API 29+) используем новый подход
        if (sdkInt >= 29) {
          // На Android 10+ разрешение на хранилище не требуется для выбора файлов
          // Но нужно добавить QUERY_ALL_PACKAGES в AndroidManifest.xml
          return true;
        } else {
          // Для старых версий
          final status = await Permission.storage.status;
          if (!status.isGranted) {
            final result = await Permission.storage.request();
            return result.isGranted;
          }
          return true;
        }
      }
      return true; // Для iOS
    } catch (e) {
      print('Permission error: $e');
      return false;
    }
  }

  static void showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Требуется доступ'),
        content: const Text(
          'Для работы с галереей необходимо предоставить разрешение',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Настройки'),
          ),
        ],
      ),
    );
  }
}

class MediaPicker {
  static final ImagePicker _picker = ImagePicker();

  /// Выбор изображения из галереи
  static Future<XFile?> pickImage() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );
  }

  /// Выбор видео из галереи
  static Future<XFile?> pickVideo() async {
    return await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 10),
    );
  }

  /// Выбор любого медиафайла (изображение или видео)
  static Future<XFile?> pickMedia() async {
    return await _picker.pickMedia();
  }

  /// Сделать фото с камеры
  static Future<XFile?> takePhoto() async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 90,
    );
  }
}
