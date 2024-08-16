import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:productdb/screen/product_info_screen.dart';

class WatchScreen extends StatefulWidget {
  @override
  _WatchScreenState createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  late Future<List<Map<String, dynamic>>> _watchesFuture;

  @override
  void initState() {
    super.initState();
    _watchesFuture = _fetchWatches();
  }

  Future<List<Map<String, dynamic>>> _fetchWatches() async {
    List<Map<String, dynamic>> watchList = [];

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('Watches').get();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> watchData = doc.data();
        watchData['productId'] = doc.id;

        if (watchData['imagePath'] != null) {
          String gsPath = watchData['imagePath'];
          String imageUrl = await FirebaseStorage.instance
              .refFromURL(gsPath)
              .getDownloadURL();
          watchData['imageUrl'] = imageUrl;
        } else {
          watchData['imageUrl'] = null;
        }

        watchList.add(watchData);
      }
    } catch (e) {
      print('Error fetching watches: $e');
    }

    return watchList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Watches'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _watchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No watches found'));
          } else {
            final watches = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: watches.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final watch = watches[index];

                double price = 0.0;
                if (watch.containsKey('salesPrice') &&
                    watch['salesPrice'] > 0) {
                  price = watch['salesPrice'] is int
                      ? (watch['salesPrice'] as int).toDouble()
                      : watch['salesPrice'];
                } else {
                  price = watch['irPrice'] is int
                      ? (watch['irPrice'] as int).toDouble()
                      : watch['irPrice'] ?? 0.0;
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductInformation(
                          productID: watch['productId'],
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            child: Image.network(
                              watch['imageUrl'] ?? '',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey,
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 40, // Fixed height for the text
                            child: Text(
                              watch['productName'] ?? 'Unknown',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            NumberFormat.currency(symbol: 'RM').format(price),
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
