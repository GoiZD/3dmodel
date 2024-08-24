import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vcon_testing/screen/product_info_screen.dart';
import 'package:vcon_testing/helper/fetch_wellness.dart';

class WellnessScreen extends StatefulWidget {
  @override
  _WellnessScreenState createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  late Future<List<Map<String, dynamic>>> _wellnessFuture;

  @override
  void initState() {
    super.initState();
    _wellnessFuture = fetchWellness();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wellness'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _wellnessFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No wellness products found'));
          } else {
            final wellnesses = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: wellnesses.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final wellness = wellnesses[index];
                double price = 0.0;
                if (wellness.containsKey('salesPrice') &&
                    wellness['salesPrice'] > 0) {
                  price = wellness['salesPrice'] is int
                      ? (wellness['salesPrice'] as int).toDouble()
                      : wellness['salesPrice'];
                } else {
                  price = wellness['irPrice'] is int
                      ? (wellness['irPrice'] as int).toDouble()
                      : wellness['irPrice'] ?? 0.0;
                }
                return GestureDetector(
  onTap: () {
    // Print productID, collection, and doc name to the console
    print('Navigating to productID: ${wellness['productId']}');
    print('Collection: products/wellness/amezcuaCollection');
    print('Doc name: ${wellness['productId']}');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductInformation(
          productID: wellness['productId'],
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
                              wellness['imageUrl'] ?? '',
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
                              wellness['productName'] ?? 'Unknown',
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
