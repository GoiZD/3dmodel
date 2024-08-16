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

    // Search in all collections
    QuerySnapshot watchesSnapshot = await FirebaseFirestore.instance
        .collection('Watches')
        .where('productName', isGreaterThanOrEqualTo: query)
        .where('productName', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    QuerySnapshot wellnessSnapshot = await FirebaseFirestore.instance
        .collection('Wellness')
        .where('productName', isGreaterThanOrEqualTo: query)
        .where('productName', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    setState(() {
      _searchResults = watchesSnapshot.docs + wellnessSnapshot.docs;
      _isLoading = false;
    });
  }

  Widget _buildProductList(
      BuildContext context, List<DocumentSnapshot> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
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

  Widget _buildProductTile(String name, double price, String imageUrl) {
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
            child: SizedBox(
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
