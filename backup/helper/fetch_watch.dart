// fetch_watch.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<List<Map<String, dynamic>>> fetchWatches() async {
  List<Map<String, dynamic>> watchList = [];

  try {
    var leClassiqueFuture = FirebaseFirestore.instance
        .collection('products')
        .doc('watches')
        .collection('leClassiqueCollection')
        .get();

    var omniFuture = FirebaseFirestore.instance
        .collection('products')
        .doc('watches')
        .collection('omniCollection')
        .get();

    var specialItemFuture = FirebaseFirestore.instance
        .collection('products')
        .doc('watches')
        .collection('specialItemsCollection')
        .get();

    var snapshots =
        await Future.wait([leClassiqueFuture, omniFuture, specialItemFuture]);

    for (var doc in snapshots[0].docs) {
      Map<String, dynamic> watchData = doc.data();
      watchData['productId'] = doc.id;
      watchData = await fetchImageUrl(watchData);
      watchList.add(watchData);
    }

    for (var doc in snapshots[1].docs) {
      Map<String, dynamic> watchData = doc.data();
      watchData['productId'] = doc.id;
      watchData = await fetchImageUrl(watchData);
      watchList.add(watchData);
    }

    for (var doc in snapshots[2].docs) {
      Map<String, dynamic> watchData = doc.data();
      watchData['productId'] = doc.id;
      watchData = await fetchImageUrl(watchData);
      watchList.add(watchData);
    }
  } catch (e) {
    print('Error fetching watches: $e');
  }

  return watchList;
}

Future<Map<String, dynamic>> fetchImageUrl(
    Map<String, dynamic> watchData) async {
  if (watchData.containsKey('imagePath') && watchData['imagePath'] != null) {
    String gsPath = watchData['imagePath'];
    try {
      String imageUrl =
          await FirebaseStorage.instance.refFromURL(gsPath).getDownloadURL();
      watchData['imageUrl'] = imageUrl;
    } catch (e) {
      print('Error fetching image URL for $gsPath: $e');
      watchData['imageUrl'] = null;
    }
  } else {
    watchData['imageUrl'] = null;
  }
  return watchData;
}
