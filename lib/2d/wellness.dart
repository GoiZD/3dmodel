import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';

class WellnessARScreen extends StatefulWidget {
  final String productID;

  const WellnessARScreen({Key? key, required this.productID}) : super(key: key);

  @override
  _ARScreenState createState() => _ARScreenState();
}

class _ARScreenState extends State<WellnessARScreen> {
  GlobalKey _globalKey = GlobalKey();
  late Future<List<String>> _watchImagesFuture;
  late CameraController _controller;
  late PoseDetector _poseDetector;
  bool _isDetecting = false;
  List<Pose> _poses = [];
  String _currentImagePath = '';
  String _productName = '';

  @override
  void initState() {
    super.initState();
    _watchImagesFuture = fetchWatchImages();
    _initializeCamera();
    _initializePoseDetector();
    _fetchProductDetails();
  }

  Future<List<String>> fetchWatchImages() async {
    final storage = FirebaseStorage.instance;
    final ListResult result = await storage.ref('watchimage').listAll();
    final List<String> urls = [];

    for (var ref in result.items) {
      final String url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  void _fetchProductDetails() async {
    final docRef = FirebaseFirestore.instance.collection('Wellness').doc(widget.productID);
    final doc = await docRef.get();
    if (doc.exists) {
      setState(() {
        _currentImagePath = doc.data()?['imagePath'] ?? '';
        _productName = doc.data()?['productName'] ?? '';
      });
    }
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    _controller = CameraController(frontCamera, ResolutionPreset.high);
    await _controller.initialize();
    if (mounted) {
      setState(() {});
      _controller.startImageStream(_processCameraImage);
    }
  }

  void _initializePoseDetector() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
    );
    _poseDetector = PoseDetector(options: options);
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

    final poses = await _poseDetector.processImage(inputImage);

    setState(() {
      _poses = poses;
    });

    _isDetecting = false;
  }

  Future<void> _takeScreenshot(BuildContext context) async {
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
        
        // Clean up the temp file
        await tempFile.delete();
      }
    } catch (e) {
      print('Error capturing photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error capturing photo')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_productName),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          RepaintBoundary(
            key: _globalKey,
            child: _currentImagePath.isEmpty
                ? Center(child: CircularProgressIndicator())
                : Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      if (_controller.value.isInitialized)
                        CameraPreview(_controller),
                      CustomPaint(
                        painter: PosePainter(
                          _poses,
                          Size(
                            _controller.value.previewSize?.height ?? 0,
                            _controller.value.previewSize?.width ?? 0,
                          ),
                          MediaQuery.of(context).size,
                          true,
                          _currentImagePath,
                        ),
                      ),
                      ...PosePainter(
                        _poses,
                        Size(
                          _controller.value.previewSize?.height ?? 0,
                          _controller.value.previewSize?.width ?? 0,
                        ),
                        MediaQuery.of(context).size,
                        true,
                        _currentImagePath,
                      ).modelWidgets,
                    ],
                  ),
          ),
          Positioned(
            bottom: 20,
            left: MediaQuery.of(context).size.width / 2 - 30,
            child: FloatingActionButton(
              onPressed: () => _takeScreenshot(context),
              child: Icon(Icons.camera_alt),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _poseDetector.close();
    super.dispose();
  }
}

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final Size widgetSize;
  final bool isFrontCamera;
  final String imagePath;

  PosePainter(this.poses, this.imageSize, this.widgetSize, this.isFrontCamera, this.imagePath);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.transparent;

    for (var pose in poses) {
      pose.landmarks.forEach((_, landmark) {
        final point = _scalePoint(
          point: landmark.x,
          y: landmark.y,
          imageSize: imageSize,
          widgetSize: widgetSize,
          isFrontCamera: isFrontCamera,
        );

        canvas.drawCircle(point, 2, paint);
      });
    }
  }

  List<Widget> get modelWidgets {
    List<Widget> widgets = [];
    for (var pose in poses) {
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

      if (leftShoulder != null && rightShoulder != null) {
        final midPoint = Offset(
          (leftShoulder.x + rightShoulder.x) / 2,
          (leftShoulder.y + rightShoulder.y) / 2,
        );

        final scaledMidPoint = _scalePoint(
          point: midPoint.dx,
          y: midPoint.dy,
          imageSize: imageSize,
          widgetSize: widgetSize,
          isFrontCamera: isFrontCamera,
        );

        final shoulderDistance = (leftShoulder.x - rightShoulder.x).abs();
        final scaledShoulderDistance = shoulderDistance * (widgetSize.width / imageSize.width);

        final modelSize = _calculateModelSize(scaledShoulderDistance);

        widgets.add(_createModelWidget(scaledMidPoint, modelSize));
      }
    }
    return widgets;
  }

  Widget _createModelWidget(Offset point, Size modelSize) {
    double x = point.dx - modelSize.width / 2;
    double y = point.dy - modelSize.height / 2 - 10;

    return Positioned(
      left: x,
      top: y,
      child: SizedBox(
        width: modelSize.width,
        height: modelSize.height,
        child: Image.network(
          imagePath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Size _calculateModelSize(double shoulderDistance) {
    const double baseScaleFactor = 0.22;
    final double minScaleFactor = 0.1;
    final double maxScaleFactor = 0.35;

    double scaleFactor = baseScaleFactor * (shoulderDistance / widgetSize.width);
    scaleFactor = scaleFactor.clamp(minScaleFactor, maxScaleFactor);

    return Size(widgetSize.width * scaleFactor, widgetSize.width * scaleFactor);
  }

  Offset _scalePoint({
    required double point,
    required double y,
    required Size imageSize,
    required Size widgetSize,
    required bool isFrontCamera,
  }) {
    final double scaleX = widgetSize.width / imageSize.width;
    final double scaleY = widgetSize.height / imageSize.height;

    double scaledX = point * scaleX;
    double scaledY = y * scaleY;

    if (isFrontCamera) {
      scaledX = widgetSize.width - scaledX;
    }

    return Offset(scaledX, scaledY);
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) {
    return oldDelegate.poses != poses || oldDelegate.isFrontCamera != isFrontCamera || oldDelegate.imagePath != imagePath;
  }
}