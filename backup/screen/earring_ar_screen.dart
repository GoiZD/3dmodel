import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/services.dart' show rootBundle, NetworkAssetBundle;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final cameras = await availableCameras();
  runApp(EarringARScreen(cameras: cameras, productID: 'your_product_id_here'));
}

class EarringARScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  final String productID;

  const EarringARScreen({Key? key, required this.cameras, required this.productID}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FaceDetectionPage(cameras: cameras, productID: productID),
    );
  }
}

class FaceDetectionPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String productID;

  const FaceDetectionPage({Key? key, required this.cameras, required this.productID}) : super(key: key);

  @override
  _FaceDetectionPageState createState() => _FaceDetectionPageState();
}

class _FaceDetectionPageState extends State<FaceDetectionPage> {
  late CameraController _controller;
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  List<Face> _faces = [];
  ui.Image? _image;
  String _imageUrl = '';
  GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _initializeCamera();
    _initializeFaceDetector();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    await _fetchImageUrl();
  }

  Future<void> _fetchImageUrl() async {
    try {
      final docRef = FirebaseFirestore.instance.collection('Jewellery').doc(widget.productID);
      final doc = await docRef.get();
      if (doc.exists) {
        final gsUrl = doc.data()?['arJewelleryImage'] ?? '';
        if (gsUrl.isNotEmpty) {
          final ref = FirebaseStorage.instance.refFromURL(gsUrl);
          final downloadUrl = await ref.getDownloadURL();
          setState(() {
            _imageUrl = downloadUrl;
          });
          await _loadImage();
        }
      }
    } catch (e) {
      print("Error fetching image URL: $e");
    }
  }

  void _initializeCamera() {
    final frontCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    _controller = CameraController(frontCamera, ResolutionPreset.high);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _controller.startImageStream(_processCameraImage);
    });
  }

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<void> _loadImage() async {
    if (_imageUrl.isEmpty) return;
    final response = await NetworkAssetBundle(Uri.parse(_imageUrl)).load(_imageUrl);
    final bytes = response.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo fi = await codec.getNextFrame();
    setState(() {
      _image = fi.image;
    });
  }

  void _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final InputImageRotation imageRotation = InputImageRotation.rotation270deg;

    final InputImageFormat inputImageFormat = InputImageFormat.nv21;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      inputImageData: inputImageData,
    );

    final faces = await _faceDetector.processImage(inputImage);

    setState(() {
      _faces = faces;
    });

    _isDetecting = false;
  }

  Future<void> _takeScreenshot() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final buffer = byteData.buffer;
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png');
        await tempFile.writeAsBytes(buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        
        final result = await GallerySaver.saveImage(tempFile.path);
        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Photo saved to gallery')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save photo')));
        }
        
        await tempFile.delete();
      }
    } catch (e) {
      print('Error capturing photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error capturing photo')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container();
    }
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: Text('Face Landmark Detection')),
      body: RepaintBoundary(
        key: _globalKey,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CameraPreview(_controller),
            if (_image != null)
              CustomPaint(
                painter: FacePainter(
                  _faces,
                  Size(
                    _controller.value.previewSize!.height,
                    _controller.value.previewSize!.width,
                  ),
                  size,
                  _image!,
                  true,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takeScreenshot,
        child: Icon(Icons.camera_alt),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _faceDetector.close();
    super.dispose();
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final Size widgetSize;
  final ui.Image image;
  final bool isFrontCamera;

  FacePainter(this.faces, this.imageSize, this.widgetSize, this.image, this.isFrontCamera);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();

    for (var i = 0; i < faces.length; i++) {
      final face = faces[i];

      face.landmarks.forEach((type, landmark) {
        if (landmark != null) {
          final point = _scalePoint(
            point: landmark.position,
            imageSize: imageSize,
            widgetSize: widgetSize,
            isFrontCamera: isFrontCamera,
          );

          final double eulerY = face.headEulerAngleY ?? 0;
          final boundingBox = _scaleRect(rect: face.boundingBox, imageSize: imageSize, widgetSize: widgetSize);

          if ((type == FaceLandmarkType.leftEar || type == FaceLandmarkType.rightEar) && eulerY.abs() < 10) {
            _drawImageAtPoint(canvas, point, paint, boundingBox, moveUp: 15);
          } else if (type == FaceLandmarkType.leftEar && eulerY > 10) {
            _drawImageAtPoint(canvas, point, paint, boundingBox);
          } else if (type == FaceLandmarkType.rightEar && eulerY < -10) {
            _drawImageAtPoint(canvas, point, paint, boundingBox);
          }
        }
      });
    }
  }

  void _drawImageAtPoint(Canvas canvas, Offset point, Paint paint, Rect boundingBox, {double moveUp = 0}) {
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
   
    final faceWidthRatio = boundingBox.width / widgetSize.width;
   
    final double baseScaleFactor = 0.14;
    final double minScaleFactor = 0.05;
    final double maxScaleFactor = 0.21;
   
    double scaleFactor = baseScaleFactor * faceWidthRatio;
    scaleFactor = scaleFactor.clamp(minScaleFactor, maxScaleFactor);

    double scaledWidth = imageSize.width * scaleFactor;
    double scaledHeight = imageSize.height * scaleFactor;

    double x = point.dx - scaledWidth / 2;
    double y = point.dy - scaledHeight / 2 - 10 - moveUp;

    if (scaleFactor == baseScaleFactor) {
      y -= 10;
    } else if (scaleFactor == maxScaleFactor) {
      y -= 18;
    }

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(x, y, scaledWidth, scaledHeight),
      paint,
    );
  }

  Offset _scalePoint({required Point<int> point, required Size imageSize, required Size widgetSize, required bool isFrontCamera}) {
    final double scaleX = widgetSize.width / imageSize.width;
    final double scaleY = widgetSize.height / imageSize.height;
    double x = point.x * scaleX;
    double y = point.y * scaleY;

    if (isFrontCamera) {
      x = widgetSize.width - x;
    }

    return Offset(x, y);
  }

  Rect _scaleRect({required Rect rect, required Size imageSize, required Size widgetSize}) {
    final double scaleX = widgetSize.width / imageSize.width;
    final double scaleY = widgetSize.height / imageSize.height;

    double left = rect.left * scaleX;
    double right = rect.right * scaleX;

    if (isFrontCamera) {
      double temp = left;
      left = widgetSize.width - right;
      right = widgetSize.width - temp;
    }

    return Rect.fromLTRB(
      left,
      rect.top * scaleY,
      right,
      rect.bottom * scaleY,
    );
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faces != faces || oldDelegate.isFrontCamera != isFrontCamera;
  }
}