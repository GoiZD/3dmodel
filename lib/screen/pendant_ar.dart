import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FaceDetectionPage(cameras: cameras),
    );
  }
}

class FaceDetectionPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const FaceDetectionPage({Key? key, required this.cameras}) : super(key: key);

  @override
  _FaceDetectionPageState createState() => _FaceDetectionPageState();
}

class _FaceDetectionPageState extends State<FaceDetectionPage> {
  late CameraController _controller;
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  List<Face> _faces = [];
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeFaceDetector();
    _loadImage();
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
    final ByteData data = await rootBundle.load('assets/qnet_j2.png');
    final Uint8List bytes = data.buffer.asUint8List();
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

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container();
    }
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final previewRatio = _controller.value.aspectRatio;

    return Scaffold(
      appBar: AppBar(title: Text('Face Landmark Detection')),
      body: Stack(
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
                true, // Pass true for front camera
              ),
            ),
        ],
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
    faces.forEach((face) {
      final boundingBox = _scaleBoundingBox(face.boundingBox);
      final bottomMostPoint = Offset(
        boundingBox.left + boundingBox.width / 2,
        boundingBox.bottom
      );

      // Draw the image based on bounding box size
      _drawImageAtPoint(canvas, bottomMostPoint, boundingBox.width, boundingBox.height);
    });
  }

  Rect _scaleBoundingBox(Rect boundingBox) {
    final double scaleX = widgetSize.width / imageSize.width;
    final double scaleY = widgetSize.height / imageSize.height;

    double left = boundingBox.left * scaleX;
    double top = boundingBox.top * scaleY;
    double right = boundingBox.right * scaleX;
    double bottom = boundingBox.bottom * scaleY;

    if (isFrontCamera) {
      final double temp = left;
      left = widgetSize.width - right;
      right = widgetSize.width - temp;
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  void _drawImageAtPoint(Canvas canvas, Offset point, double faceWidth, double faceHeight) {
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    
    // Adjust these values to fine-tune the scaling
    final double baseScaleFactor = 0.22;
    final double minScaleFactor = 0.1;
    final double maxScaleFactor = 0.35;
    
    // Calculate scale factor based on face width
    double scaleFactor = baseScaleFactor * (faceWidth / widgetSize.width);
    scaleFactor = scaleFactor.clamp(minScaleFactor, maxScaleFactor);

    double scaledWidth = imageSize.width * scaleFactor;
    double scaledHeight = imageSize.height * scaleFactor;

    double x = point.dx - scaledWidth / 2;
    double y = point.dy - scaledHeight / 2;

    // Adjust vertical position based on scale factor
    if (scaleFactor == baseScaleFactor) {
      y += 45;
    } else if (scaleFactor == minScaleFactor) {
      y += 25;
    } else if (scaleFactor == maxScaleFactor) {
      y += 70;
    } else {
      // Interpolate for intermediate values
      double t = (scaleFactor - minScaleFactor) / (maxScaleFactor - minScaleFactor);
      y += 30 + t * 50; // Interpolate between 20 and 50
    }

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(x, y, scaledWidth, scaledHeight),
      Paint(),
    );
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faces != faces || oldDelegate.isFrontCamera != isFrontCamera;
  }
}
