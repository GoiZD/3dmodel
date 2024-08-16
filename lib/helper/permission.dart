import 'package:permission_handler/permission_handler.dart';

Future<void> requestCameraPermission() async {
  if (await Permission.camera.request().isGranted) {
    // Camera permission granted
  } else if (await Permission.camera.isPermanentlyDenied) {
    // Open app settings if permission is permanently denied
    openAppSettings();
  }
}
