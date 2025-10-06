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
        if (sdkInt >= 29) {
          return true;
        } else {
          final status = await Permission.storage.status;
          if (!status.isGranted) {
            final result = await Permission.storage.request();
            return result.isGranted;
          }
          return true;
        }
      }
      return true;
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
  static Future<XFile?> pickImage() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );
  }
  static Future<XFile?> pickVideo() async {
    return await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 10),
    );
  }
  static Future<XFile?> pickMedia() async {
    return await _picker.pickMedia();
  }

  static Future<XFile?> takePhoto() async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 90,
    );
  }
}
