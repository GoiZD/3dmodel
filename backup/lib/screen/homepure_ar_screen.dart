import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class HomePureARScreen extends StatefulWidget {
  final String productID;

  const HomePureARScreen({Key? key, required this.productID}) : super(key: key);

  @override
  _HomePureARScreenState createState() => _HomePureARScreenState();
}

class _HomePureARScreenState extends State<HomePureARScreen> {
  late CameraController _controller;
  String _currentGitURL = '';
  String _productName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _fetchProductDetails();
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    final rearCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );
    _controller = CameraController(rearCamera, ResolutionPreset.high);
    await _controller.initialize();
    if (!mounted) return;
    setState(() {});
  }

  void _fetchProductDetails() async {
    try {
      final docRef = FirebaseFirestore.instance.collection('HomePure').doc(widget.productID);
      final doc = await docRef.get();
      if (doc.exists) {
        setState(() {
          _currentGitURL = doc.data()?['gitURL'] ?? '';
          _productName = doc.data()?['productName'] ?? '';
          _isLoading = false;
        });
      } else {
        print('Document does not exist');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching product details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_controller.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(_productName)),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_productName)),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CameraPreview(_controller),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 200, // Adjust the height as needed
              child: ModelViewer(
                src: _currentGitURL,
                alt: "A 3D model",
                ar: true,
                autoRotate: true,
                cameraControls: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}