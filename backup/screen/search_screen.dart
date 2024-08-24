import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'product_info_screen.dart';

class SearchScreen extends StatefulWidget {
  final String query;

  const SearchScreen({super.key, required this.query});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<DocumentSnapshot> _searchResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchProducts(widget.query);
  }

  void _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    List<String> categories = [
      'Watches',
      'wellness',
      'jewellery',
      'homeliving',
      'personalCareBeauty'
    ];
    List<DocumentSnapshot> allResults = [];

    for (String category in categories) {
      try {
        QuerySnapshot snapshot =
            await FirebaseFirestore.instance.collection(category).get();

        print(
            'Searching in $category: ${snapshot.docs.length} documents found');

        allResults.addAll(snapshot.docs.where((doc) {
          String productName =
              (doc.data() as Map<String, dynamic>)['productName'] ?? '';
          String productCategory =
              (doc.data() as Map<String, dynamic>)['category'] ?? '';

          bool matchesName =
              productName.toLowerCase().contains(query.toLowerCase());
          bool matchesCategory =
              productCategory.toLowerCase().contains(query.toLowerCase()) ||
                  category.toLowerCase().contains(query.toLowerCase());

          // Special case for "watch" vs "watches"
          if (category == 'Watches') {
            matchesCategory = matchesCategory ||
                'watch'.contains(query.toLowerCase()) ||
                query.toLowerCase().contains('watch');
          }

          return matchesName || matchesCategory;
        }));
      } catch (e) {
        print('Error searching in $category: $e');
      }
    }

    setState(() {
      _searchResults = allResults;
      _isLoading = false;
    });

    print('Total search results: ${_searchResults.length}');
  }

  Widget _buildProductList(
      BuildContext context, List<DocumentSnapshot> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index].data() as Map<String, dynamic>?;

        String name = product?['productName'] ?? 'Unknown';
        double price = (product?['salesPrice'] ?? 0) > 0
            ? (product?['salesPrice'] is int
                ? (product?['salesPrice'] as int).toDouble()
                : product?['salesPrice'])
            : (product?['irPrice'] is int
                    ? (product?['irPrice'] as int).toDouble()
                    : product?['irPrice']) ??
                0.0;
        String imagePath = product?['imagePath'] ?? '';
        String category = products[index].reference.parent.id;

        return FutureBuilder<String>(
          future: _getImageUrl(imagePath),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading image'));
            }
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductInformation(productID: product?['productID']),
                  ),
                );
              },
              child: _buildProductTile(
                name,
                price,
                snapshot.data ?? '',
                category,
              ),
            );
          },
        );
      },
    );
  }

  Future<String> _getImageUrl(String imagePath) async {
    if (imagePath.isEmpty) return '';
    try {
      final ref = FirebaseStorage.instance.refFromURL(imagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      return '';
    }
  }

  Widget _buildProductTile(
      String name, double price, String imageUrl, String category) {
    final NumberFormat currencyFormat = NumberFormat.currency(symbol: 'RM');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                SizedBox(
                  height: 40,
                  child: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(
              currencyFormat.format(price),
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results'),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? Center(child: Text('No results found'))
              : _buildProductList(context, _searchResults),
    );
  }
}
