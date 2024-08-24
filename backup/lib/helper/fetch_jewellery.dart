// fetch_watch.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<List<Map<String, dynamic>>> fetchJewellery() async {
  List<Map<String, dynamic>> jewelleryList = [];

  try {
    var classicFuture = FirebaseFirestore.instance
        .collection('products')
        .doc('jewellery')
        .collection('theClassicsCollection')
        .get();

    var snapshots = await Future.wait([classicFuture]);

    for (var doc in snapshots[0].docs) {
      Map<String, dynamic> jewelleryData = doc.data();
      jewelleryData['productId'] = doc.id;
      jewelleryData = await fetchImageUrl(jewelleryData);
      jewelleryList.add(jewelleryData);
    }
  } catch (e) {
    print('Error fetching watches: $e');
  }

  return jewelleryList;
}

Future<Map<String, dynamic>> fetchImageUrl(
    Map<String, dynamic> jewelleryData) async {
  if (jewelleryData.containsKey('imagePath') &&
      jewelleryData['imagePath'] != null) {
    String gsPath = jewelleryData['imagePath'];
    try {
      String imageUrl =
          await FirebaseStorage.instance.refFromURL(gsPath).getDownloadURL();
      jewelleryData['imageUrl'] = imageUrl;
    } catch (e) {
      print('Error fetching image URL for $gsPath: $e');
      jewelleryData['imageUrl'] = null;
    }
  } else {
    jewelleryData['imageUrl'] = null;
  }
  return jewelleryData;
}
