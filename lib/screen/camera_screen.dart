import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraWidget extends StatefulWidget {
  const CameraWidget({Key? key}) : super(key: key);

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  CameraController? _controller;
  List<double> _wristPosition = [0.5, 0.5];
  bool _isHandDetected = false;
  static const MethodChannel _channel = MethodChannel('alexchan');

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      print("No cameras available");
      return;
    }
    final firstCamera = cameras.first;
    _controller = CameraController(firstCamera, ResolutionPreset.low);

    try {
      await _controller!.initialize();
      if (!mounted) return;
      _controller!.startImageStream(_processImage);
      setState(() {});
    } on CameraException catch (e) {
      print('Camera initialization error: ${e.description}');
    }
  }

  void _processImage(CameraImage image) {
    //print("Processing image: ${image.width} x ${image.height}");

    final argbData = _yuv420ToArgb8888(image);
    List<int> intList = argbData.map((byte) => byte.toInt()).toList();

    //print("ARGB data size: ${argbData.length}");

    _sendImageToNative(intList);
  }

  Uint8List _yuv420ToArgb8888(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;

    final argb = Uint8List(width * height * 4);

    for (int y = 0; y < height; y++) {
      int pY = y * image.planes[0].bytesPerRow;
      int pUV = (y ~/ 2) * uvRowStride;

      for (int x = 0; x < width; x++) {
        final int uvOffset = pUV + (x ~/ 2) * uvPixelStride;

        final yp = image.planes[0].bytes[pY] & 0xff;
        final up = image.planes[1].bytes[uvOffset] & 0xff;
        final vp = image.planes[2].bytes[uvOffset] & 0xff;

        // Convert YUV to RGB
        int r = (yp + vp * 1436 ~/ 1024 - 179).clamp(0, 255);
        int g = (yp - up * 46 ~/ 1024 - vp * 93 ~/ 1024 + 44).clamp(0, 255);
        int b = (yp + up * 1814 ~/ 1024 - 227).clamp(0, 255);

        final int idx = (y * width + x) * 4;
        argb[idx] = 0xFF; // Alpha
        argb[idx + 1] = r; // Red
        argb[idx + 2] = g; // Green
        argb[idx + 3] = b; // Blue

        pY++;
      }
    }
    return argb;
  }

  Future<void> _sendImageToNative(List<int> imageData) async {
    try {
      final List<dynamic> result =
          await _channel.invokeMethod('sendImage', imageData);

      if (result.isNotEmpty) {
        setState(() {
          _wristPosition = [result[0].toDouble(), result[1].toDouble()];
          _isHandDetected = true;
        });
        print(
            "Wrist position and inference time: $result"); // Print the wrist position and inference time
      } else {
        setState(() {
          _isHandDetected = false;
        });
        print("Failed to get result from native code.");
      }
    } on PlatformException catch (e) {
      setState(() {
        _isHandDetected = false;
      });
      print("Failed to send image: '${e.message}'.");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(
            _controller!,
          ),
          if (_isHandDetected)
            Positioned(
              left: _wristPosition[0] * MediaQuery.of(context).size.width - 25,
              top: _wristPosition[1] * MediaQuery.of(context).size.height - 25,
              child: Image.asset(
                "assets/watch_image.png",
                width: 50,
                height: 50,
              ),
            ),
          Positioned(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hand Detected : $_isHandDetected',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                'Wrist Position: (${_wristPosition[0].toStringAsFixed(2)},${_wristPosition[1].toStringAsFixed(2)})',
                style: TextStyle(color: Colors.white),
              )
            ],
          ))
        ],
      ),
    );
  }
}