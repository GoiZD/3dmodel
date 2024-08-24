import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<List<Map<String, dynamic>>> fetchHomeLiving() async {
  List<Map<String, dynamic>> homelivingList = [];

  try {
    var homepureFuture = FirebaseFirestore.instance
        .collection('products')
        .doc('homeLiving')
        .collection('homePureCollection')
        .get();

    var snapshots = await Future.wait([homepureFuture]);

    for (var doc in snapshots[0].docs) {
      Map<String, dynamic> homelivingData = doc.data();
      homelivingData['productId'] = doc.id;
      homelivingData = await fetchImageUrl(homelivingData);
      homelivingList.add(homelivingData);
    }
  } catch (e) {
    print('Error fetching watches: $e');
  }

  return homelivingList;
}

Future<Map<String, dynamic>> fetchImageUrl(
    Map<String, dynamic> homelivingData) async {
  if (homelivingData.containsKey('imagePath') &&
      homelivingData['imagePath'] != null) {
    String gsPath = homelivingData['imagePath'];
    try {
      String imageUrl =
          await FirebaseStorage.instance.refFromURL(gsPath).getDownloadURL();
      homelivingData['imageUrl'] = imageUrl;
    } catch (e) {
      print('Error fetching image URL for $gsPath: $e');
      homelivingData['imageUrl'] = null;
    }
  } else {
    homelivingData['imageUrl'] = null;
  }
  return homelivingData;
}
