import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';

class JewelleryARScreen extends StatefulWidget {
  final String productID;

  const JewelleryARScreen({Key? key, required this.productID}) : super(key: key);

  @override
  _CombinedARScreenState createState() => _CombinedARScreenState();
}

class _CombinedARScreenState extends State<JewelleryARScreen> {
  late Future<List<String>> _watchImagesFuture;
  late CameraController _controller;
  late dynamic _detector;
  bool _isDetecting = false;
  List<dynamic> _detections = [];
  String _currentGitURL = '';
  String _productName = '';
  bool _isJewellery = false;

  @override
  void initState() {
    super.initState();
    _watchImagesFuture = fetchWatchImages();
    _initializeCamera();
    _initializeDetector();
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
    final docRef = FirebaseFirestore.instance.collection('Jewellery').doc(widget.productID);
    final doc = await docRef.get();
    if (doc.exists) {
      setState(() {
        _currentGitURL = doc.data()?['gitURL'] ?? '';
        _productName = doc.data()?['productName'] ?? '';
        _isJewellery = widget.productID.startsWith('JE');
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

  void _initializeDetector() {
    if (widget.productID.startsWith('JE')) {
      final options = FaceDetectorOptions(
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.fast,
      );
      _detector = FaceDetector(options: options);
    } else if (widget.productID.startsWith('JN')) {
      final options = PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
      );
      _detector = PoseDetector(options: options);
    }
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

    final detections = await _detector.processImage(inputImage);

    setState(() {
      _detections = detections;
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
                  painter: _isJewellery
                      ? FacePainter(
                          _detections.cast<Face>(),
                          Size(
                            _controller.value.previewSize?.height ?? 0,
                            _controller.value.previewSize?.width ?? 0,
                          ),
                          MediaQuery.of(context).size,
                          true,
                          _currentGitURL,
                        )
                      : PosePainter(
                          _detections.cast<Pose>(),
                          Size(
                            _controller.value.previewSize?.height ?? 0,
                            _controller.value.previewSize?.width ?? 0,
                          ),
                          MediaQuery.of(context).size,
                          true,
                          _currentGitURL,
                        ),
                ),
                ..._isJewellery
                    ? FacePainter(
                        _detections.cast<Face>(),
                        Size(
                          _controller.value.previewSize?.height ?? 0,
                          _controller.value.previewSize?.width ?? 0,
                        ),
                        MediaQuery.of(context).size,
                        true,
                        _currentGitURL,
                      ).modelWidgets
                    : PosePainter(
                        _detections.cast<Pose>(),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Photo taken')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _detector.close();
    super.dispose();
  }
}

// Include the FacePainter and PosePainter classes here (unchanged from the original files)

// Include the FacePainter and PosePainter classes here (unchanged from the original files)

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final Size widgetSize;
  final bool isFrontCamera;
  final String gitURL;

  PosePainter(this.poses, this.imageSize, this.widgetSize, this.isFrontCamera, this.gitURL);

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
        child: ModelViewer(
          src: gitURL,
          autoRotate: false,
          cameraControls: true,
        ),
      ),
    );
  }

  Size _calculateModelSize(double shoulderDistance) {
    final double baseScaleFactor = 0.22;
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
    return oldDelegate.poses != poses || oldDelegate.isFrontCamera != isFrontCamera || oldDelegate.gitURL != gitURL;
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
