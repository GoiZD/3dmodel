import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Watch3DViewerScreen extends StatefulWidget {
  @override
  _Watch3DViewerScreenState createState() => _Watch3DViewerScreenState();
}

class _Watch3DViewerScreenState extends State<Watch3DViewerScreen> {
  List<Map<String, String>> models = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchModels();
  }

  void fetchModels() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('Watches').get();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String? gitURL = data['gitURL'] as String?;
        String? gitText = data['gitText'] as String?;
        String? productName = data['productName'] as String?;
        if (gitURL != null && gitURL.isNotEmpty && 
            gitText != null && gitText.isNotEmpty && 
            productName != null && productName.isNotEmpty) {
          setState(() {
            models.add({
              'gitURL': gitURL,
              'gitText': gitText,
              'productName': productName
            });
          });
        } else {
          print("Document ${doc.id} is missing 'gitURL', 'gitText', or 'productName' or they are empty.");
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching models: $e";
      });
      print(errorMessage);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('3D Model Viewer'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : models.isEmpty
                  ? Center(child: Text("No 3D models available"))
                  : ListView.builder(
                      itemCount: models.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(models[index]['productName']!),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ModelViewerPage(
                                  modelUrl: models[index]['gitURL']!,
                                  textModelUrl: models[index]['gitText']!,
                                  productName: models[index]['productName']!,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}

class ModelViewerPage extends StatelessWidget {
  final String modelUrl;
  final String textModelUrl;
  final String productName;

  ModelViewerPage({
    required this.modelUrl,
    required this.textModelUrl,
    required this.productName
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(productName),
      ),
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.4,
                child: modelUrl.isNotEmpty
                    ? ModelViewer(
                        src: modelUrl,
                        autoRotate: true,
                        autoPlay: true,
                        backgroundColor: const Color.fromARGB(0xFF, 0xFF, 0xFF, 0xFF),
                        cameraControls: true,
                        disableZoom: false,
                        // scale parameter removed to allow model to fit container
                      )
                    : Text('No watch model URL provided'),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: textModelUrl.isNotEmpty
                    ? ModelViewer(
                        src: textModelUrl,
                        autoRotate: false,
                        backgroundColor: Colors.transparent,
                        autoPlay: false,
                        cameraControls: false,
                        disableZoom: false,
                        // scale parameter removed to allow text to fit container
                      )
                    : Text('No text model URL provided'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Watch3DViewerScreen(),
  ));
}