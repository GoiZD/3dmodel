import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:productdb/screen/camera_screen.dart';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:flutter/foundation.dart';

class JewelleryARScreen extends StatefulWidget {
  final String productID;

  const JewelleryARScreen({Key? key, required this.productID}) : super(key: key);

  @override
  _ARScreenState createState() => _ARScreenState();
}

class _ARScreenState extends State<JewelleryARScreen> {
  late Future<List<String>> _watchImagesFuture;
  late CameraController _controller;
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  List<Face> _faces = [];
  String _currentGitURL = '';
  String _productName = '';

  @override
  void initState() {
    super.initState();
    _watchImagesFuture = fetchWatchImages();
    _initializeCamera();
    _initializeFaceDetector();
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
    final docRef = FirebaseFirestore.instance.collection('jewellery').doc(widget.productID);
    final doc = await docRef.get();
    if (doc.exists) {
      setState(() {
        _currentGitURL = doc.data()?['gitURL'] ?? '';
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

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);
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
      body: _currentGitURL.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (_controller.value.isInitialized)
                  CameraPreview(_controller),
                CustomPaint(
                  painter: FacePainter(
                    _faces,
                    Size(
                      _controller.value.previewSize?.height ?? 0,
                      _controller.value.previewSize?.width ?? 0,
                    ),
                    MediaQuery.of(context).size,
                    true,
                    _currentGitURL,
                  ),
                ),
                ...FacePainter(
                  _faces,
                  Size(
                    _controller.value.previewSize?.height ?? 0,
                    _controller.value.previewSize?.width ?? 0,
                  ),
                  MediaQuery.of(context).size,
                  true,
                  _currentGitURL,
                ).modelWidgets,
                Positioned(
                  bottom: 20,
                  left: MediaQuery.of(context).size.width / 2 - 30,
                  child: FloatingActionButton(
                    onPressed: () => _takePhoto(context),
                    child: Icon(Icons.camera_alt),
                  ),
                ),
              ],
            ),
    );
  }

  void _takePhoto(BuildContext context) {
    // This function can be linked to your AR photo capture functionality
    // Here, we just show a snackbar for demonstration
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Photo taken')),
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
  final bool isFrontCamera;
  final String gitURL;

  FacePainter(this.faces, this.imageSize, this.widgetSize, this.isFrontCamera, this.gitURL);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.transparent;

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

          canvas.drawCircle(point, 2, paint);
        }
      });
    }
  }

  List<Widget> get modelWidgets {
    List<Widget> widgets = [];
    for (var face in faces) {
      face.landmarks.forEach((type, landmark) {
        if (landmark != null) {
          final point = _scalePoint(
            point: landmark.position,
            imageSize: imageSize,
            widgetSize: widgetSize,
            isFrontCamera: isFrontCamera,
          );

          final double eulerY = face.headEulerAngleY ?? 0;
          final Size modelSize = _calculateModelSize(face.boundingBox.width, face.boundingBox.height);

          if ((type == FaceLandmarkType.leftEar || type == FaceLandmarkType.rightEar) && eulerY.abs() < 10) {
            widgets.add(_createModelWidget(point, modelSize, isLeftEar: type == FaceLandmarkType.leftEar));
          } else if (type == FaceLandmarkType.leftEar && eulerY > 10) {
            widgets.add(_createModelWidget(point, modelSize, isLeftEar: true));
          } else if (type == FaceLandmarkType.rightEar && eulerY < -10) {
            widgets.add(_createModelWidget(point, modelSize, isLeftEar: false));
          }
        }
      });
    }
    return widgets;
  }

  Widget _createModelWidget(Offset point, Size modelSize, {required bool isLeftEar}) {
    double x = point.dx - modelSize.width / 2;
    double y = point.dy - modelSize.height / 2 - 10;

    if (isLeftEar) {
      x += 14;
    } else {
      x -= 14;
    }

    return Positioned(
      left: x,
      top: y,
      child: SizedBox(
        width: modelSize.width,
        height: modelSize.height,
        child: ModelViewer(
          src: gitURL,
          autoRotate: false,
          cameraControls: true,
        ),
      ),
    );
  }

  Size _calculateModelSize(double faceWidth, double faceHeight) {
    final double scaleFactor = 0.07;
    double modelWidth = faceWidth * scaleFactor;
    double modelHeight = faceHeight * scaleFactor;
    return Size(modelWidth, modelHeight);
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

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faces != faces || oldDelegate.isFrontCamera != isFrontCamera || oldDelegate.gitURL != gitURL;
  }
}
