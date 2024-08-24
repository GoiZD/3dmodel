import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Fetch all wellness products
Future<List<Map<String, dynamic>>> fetchWellness() async {
  List<Map<String, dynamic>> wellnessList = [];

  try {
    var amezcuaFuture = FirebaseFirestore.instance
        .collection('products')
        .doc('wellness')
        .collection('amezcuaCollection')
        .get();

    var snapshots = await Future.wait([amezcuaFuture]);

    for (var doc in snapshots[0].docs) {
      Map<String, dynamic> wellnessData = doc.data();
      wellnessData['productId'] = doc.id;
      wellnessData = await fetchImageUrl(wellnessData);
      
      // Fetch arWellnessImage
      if (wellnessData.containsKey('arWellnessImage')) {
        String arImageUrl = await FirebaseStorage.instance
            .refFromURL(wellnessData['arWellnessImage'])
            .getDownloadURL();
        wellnessData['arWellnessImageUrl'] = arImageUrl;
      }

      wellnessList.add(wellnessData);
    }
  } catch (e) {
    print('Error fetching wellness products: $e');
  }

  return wellnessList;
}

// Fetch specific wellness product by productId
Future<Map<String, dynamic>> fetchWellnessProduct(String productId) async {
  try {
    var doc = await FirebaseFirestore.instance
        .collection('products')
        .doc('wellness')
        .collection('amezcuaCollection')
        .doc(productId)
        .get();

    if (doc.exists) {
      Map<String, dynamic> wellnessData = doc.data()!;
      wellnessData['productId'] = doc.id;
      wellnessData = await fetchImageUrl(wellnessData);
      
      // Fetch arWellnessImage
      if (wellnessData.containsKey('arWellnessImage')) {
        String arImageUrl = await FirebaseStorage.instance
            .refFromURL(wellnessData['arWellnessImage'])
            .getDownloadURL();
        wellnessData['arWellnessImageUrl'] = arImageUrl;
      }
      
      return wellnessData;
    } else {
      throw Exception('Product not found');
    }
  } catch (e) {
    print('Error fetching wellness product: $e');
    rethrow;
  }
}

// Helper function to fetch image URLs
Future<Map<String, dynamic>> fetchImageUrl(
    Map<String, dynamic> wellnessData) async {
  if (wellnessData.containsKey('imagePath') &&
      wellnessData['imagePath'] != null) {
    String gsPath = wellnessData['imagePath'];
    try {
      String imageUrl =
          await FirebaseStorage.instance.refFromURL(gsPath).getDownloadURL();
      wellnessData['imageUrl'] = imageUrl;
    } catch (e) {
      print('Error fetching image URL for $gsPath: $e');
      wellnessData['imageUrl'] = null;
    }
  } else {
    wellnessData['imageUrl'] = null;
  }
  return wellnessData;
}
