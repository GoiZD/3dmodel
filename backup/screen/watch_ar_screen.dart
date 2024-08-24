import 'package:vcon_testing/screen/painter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:flutter/rendering.dart';

class WatchARScreen extends StatefulWidget {
  final String productId;

  const WatchARScreen({Key? key, required this.productId}) : super(key: key);

  @override
  State<WatchARScreen> createState() => _WatchARScreenState();
}

class _WatchARScreenState extends State<WatchARScreen> {
  GlobalKey _globalKey = GlobalKey();
  CameraController? _controller;
  List<double> _wristPosition = List.filled(3, 1.0);
  bool _isHandDetected = false;
  double _angle = 0.0;
  double _wristWidth = 0.0;
  ui.Image? _watchImage;
  static const MethodChannel _channel = MethodChannel('alexchan');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadWatchImageFromFirebase();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      print("No cameras available");
      return;
    }
    _controller = CameraController(cameras[1], ResolutionPreset.low);

    try {
      await _controller!.initialize();
      if (!mounted) return;
      _controller!.startImageStream(_processImage);
      setState(() {});
    } on CameraException catch (e) {
      print('Camera initialization error: ${e.description}');
    }
  }

  Future<void> _loadWatchImageFromFirebase() async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection("Watches").doc(widget.productId).get();

      //DocumentSnapShot doc = await _firestore.collection('products').doc('watches').collection('leClassiqueCollection').get();

      if (!doc.exists) {
        print("Document does not exist for productId: ${widget.productId}");
        return;
      }

      String gsUrl = doc.get('arWatchImage') as String;

      if (gsUrl.isEmpty) {
        print("arWatchImage URL is empty for productId: ${widget.productId}");
        return;
      }

      final ref = FirebaseStorage.instance.refFromURL(gsUrl);
      final httpsUrl = await ref.getDownloadURL();

      final ByteData data =
          await NetworkAssetBundle(Uri.parse(httpsUrl)).load("");
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();

      setState(() {
        _watchImage = fi.image;
      });
    } catch (e) {
      print("Error loading image from Firebase: $e");
    }
  }

  void _processImage(CameraImage image) {
    final argbData = _yuv420ToArgb8888(image);
    List<int> intList = argbData.map((byte) => byte.toInt()).toList();
    _sendImageToNative(intList);
  }

  Uint8List _yuv420ToArgb8888(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;

    final Uint8List argb = Uint8List(width * height * 4);

    for (int y = 0; y < height; y++) {
      int pY = y * image.planes[0].bytesPerRow;
      int pUV = (y ~/ 2) * uvRowStride;

      for (int x = 0; x < width; x++) {
        final int uvOffset = pUV + (x ~/ 2) * uvPixelStride;

        final yp = image.planes[0].bytes[pY] & 0xff;
        final up = image.planes[1].bytes[uvOffset] & 0xff;
        final vp = image.planes[2].bytes[uvOffset] & 0xff;

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
          _wristPosition = [
            result[0],
            result[1],
            result[2],
          ];
          _wristWidth = result[3];
          _angle = result[4];
          _isHandDetected = true;
        });
        print("Wrist position and inference time: $result");
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

  Future<void> _takeScreenshot() async {
    try {
      print('Starting screenshot capture');

      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      print('Boundary found');

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      print('Image captured');

      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      print('ByteData obtained');

      if (byteData != null) {
        final buffer = byteData.buffer;
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
            '${tempDir.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png');

        await tempFile.writeAsBytes(
            buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        print('Temp file written');

        final result = await GallerySaver.saveImage(tempFile.path);
        print('GallerySaver result: $result');

        if (result == true) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Photo saved to gallery')));
          _displayCapturedImage(image);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed to save photo')));
        }

        // Clean up the temp file
        await tempFile.delete();
        print('Temp file deleted');
      }
    } catch (e) {
      print('Error capturing photo: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error capturing photo')));
    }
  }

  void _displayCapturedImage(ui.Image image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: 300,
            height: 300,
            child: RawImage(
              image: image,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _watchImage == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("AR camera preview"),
      ),
      body: RepaintBoundary(
        key: _globalKey,
        child: Stack(children: [
          CameraPreview(
            _controller!,
            child: CustomPaint(
              painter: WatchOverlayPainter(
                _watchImage,
                _wristPosition,
                _wristWidth,
                _angle,
                Size(_controller!.value.previewSize!.width,
                    _controller!.value.previewSize!.height),
                _isHandDetected,
              ),
            ),
          ),
          SizedBox(height: 40),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: _takeScreenshot,
                child: Icon(
                  Icons.camera,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}