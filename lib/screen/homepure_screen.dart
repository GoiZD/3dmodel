import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:productdb/screen/product_info_screen.dart';

class HomePureScreen extends StatefulWidget {
  @override
  _HomePureScreenState createState() => _HomePureScreenState();
}

class _HomePureScreenState extends State<HomePureScreen> {
  late Future<List<Map<String, dynamic>>> _homepureFuture;

  @override
  void initState() {
    super.initState();
    _homepureFuture = _fetchHomePure();
  }

  Future<List<Map<String, dynamic>>> _fetchHomePure() async {
    List<Map<String, dynamic>> homepureList = [];

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('HomePure').get();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> homepureData = doc.data();
        homepureData['productId'] = doc.id;

        if (homepureData['imagePath'] != null) {
          String gsPath = homepureData['imagePath'];
          String imageUrl = await FirebaseStorage.instance
              .refFromURL(gsPath)
              .getDownloadURL();
          homepureData['imageUrl'] = imageUrl;
        } else {
          homepureData['imageUrl'] = null;
        }

        homepureList.add(homepureData);
      }
    } catch (e) {
      print('Error fetching homepure: $e');
    }

    return homepureList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HomePure'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _homepureFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No homepure found'));
          } else {
            final homepures = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: homepures.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final homepure = homepures[index];

                double price = 0.0;
                if (homepure.containsKey('salesPrice') &&
                    homepure['salesPrice'] > 0) {
                  price = homepure['salesPrice'] is int
                      ? (homepure['salesPrice'] as int).toDouble()
                      : homepure['salesPrice'];
                } else {
                  price = homepure['irPrice'] is int
                      ? (homepure['irPrice'] as int).toDouble()
                      : homepure['irPrice'] ?? 0.0;
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductInformation(
                          productID: homepure['productId'],
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
                              homepure['imageUrl'] ?? '',
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
                              homepure['productName'] ?? 'Unknown',
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