import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:productdb/components/my_back_button.dart';
import 'package:productdb/screen/jewellery_screen.dart';
import 'package:productdb/screen/product_info_screen.dart';
import 'package:productdb/screen/cart_screen.dart'; // Import your CartScreen here
import 'package:productdb/screen/watch_screen.dart';
import 'package:productdb/screen/wellness_screen.dart';
import 'package:productdb/screen/search_screen.dart';
import 'package:productdb/screen/homepure_screen.dart';

class ProductsCategoryPage extends StatefulWidget {
  const ProductsCategoryPage({super.key});
  @override
  _ProductsCategoryPageState createState() => _ProductsCategoryPageState();
}

class _ProductsCategoryPageState extends State<ProductsCategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(
                  top: 50.0,
                  left: 25,
                ),
                child: Row(
                  children: [
                    MyBackButton(),
                  ],
                ),
              ),
              // VCON icon and cart icon
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        FutureBuilder<String>(
                          future: _getIconUrl(
                              'icon/VCON.jpeg'), // Path to VCON icon in Firebase Storage
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircleAvatar(
                                radius: 24,
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return CircleAvatar(
                                radius: 24,
                                child: Icon(Icons.error),
                              );
                            } else {
                              return CircleAvatar(
                                backgroundImage: NetworkImage(snapshot.data!),
                                radius: 24,
                              );
                            }
                          },
                        ),
                        SizedBox(width: 8),
                        Text(
                          'VCON',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.shopping_cart),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  CartScreen()), // Link to your CartScreen
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name or category',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        final query = _searchController.text;
                        if (query.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchScreen(query: query),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Categories
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Categories',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              _buildCategories(context),
              // Featured products
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Featured products',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              _buildFeaturedProducts(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    // Example categories with Firebase Storage paths
    final categories = [
      {
        'name': 'Watches',
        'iconPath': 'icon/Watch.jpg',
        'collection': 'Watches'
      },
      {
        'name': 'Jewellery',
        'iconPath': 'icon/Jewellery.jpg',
        'collection': 'Jewellery'
      },
      {
        'name': 'HomePure',
        'iconPath': 'icon/Homepure.jpg',
        'collection': 'HomePure'
      },
      {
        'name': 'Wellness',
        'iconPath': 'icon/Wellness.jpg',
        'collection': 'Wellness'
      },
      {
        'name': 'SkinCare',
        'iconPath': 'icon/Skincare.jpg',
        'collection': 'SkinCare'
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 4.0,
        runSpacing: 6.0,
        children: categories.map((category) {
          return FutureBuilder<String>(
            future: _getIconUrl(category['iconPath'] as String),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircleAvatar(
                  radius: 30,
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.error),
                );
              } else {
                return GestureDetector(
                  onTap: () {
                    final collection = category['collection'] as String;
                    switch (collection) {
                      case 'Watches':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WatchScreen(),
                          ),
                        );
                        break;
                      case 'Wellness':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WellnessScreen(),
                          ),
                        );
                        break;
                      case 'Jewellery':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JewelleryScreen(),
                          ),
                        );
                        break;
                      case 'HomePure':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePureScreen(),
                          ),
                        );
                        break;
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(snapshot.data!),
                      ),
                      SizedBox(height: 8),
                      Text(category['name'] as String),
                    ],
                  ),
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Future<String> _getIconUrl(String iconPath) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(iconPath);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error fetching icon URL: $e');
      return '';
    }
  }

  Widget _buildFeaturedProducts(BuildContext context) {
    final List<String> featuredProductIDs = [
      'W031',
      'W032',
      'W033',
      'WN001',
      'WN002',
      'WN003'
    ]; // List of productIDs you want to feature

    return FutureBuilder<Map<String, List<DocumentSnapshot>>>(
      future: _fetchFeaturedProducts(featuredProductIDs),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final wellnessProducts = snapshot.data?['Wellness'] ?? [];
        final watchProducts = snapshot.data?['Watches'] ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildProductList(context, wellnessProducts),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildProductList(context, watchProducts),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, List<DocumentSnapshot>>> _fetchFeaturedProducts(
      List<String> featuredProductIDs) async {
    List<DocumentSnapshot> allWellnessProducts = [];
    List<DocumentSnapshot> allWatchProducts = [];

    // Fetch from Watches collection
    QuerySnapshot watchesSnapshot = await FirebaseFirestore.instance
        .collection('Watches')
        .where('productID', whereIn: featuredProductIDs)
        .get();
    allWatchProducts.addAll(watchesSnapshot.docs);

    // Fetch from Wellness collection
    QuerySnapshot wellnessSnapshot = await FirebaseFirestore.instance
        .collection('Wellness')
        .where('productID', whereIn: featuredProductIDs)
        .get();
    allWellnessProducts.addAll(wellnessSnapshot.docs);

    return {
      'Wellness': allWellnessProducts,
      'Watches': allWatchProducts,
    };
  }

  Widget _buildProductList(
      BuildContext context, List<DocumentSnapshot> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics:
          NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 3 / 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index].data() as Map<String, dynamic>?;

        // Ensure the fields exist before accessing them
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
    // Format the price with a currency symbol using NumberFormat
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
              height: 40, // Fixed height for the text
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
}

class ProductListScreen extends StatelessWidget {
  final String collection;

  const ProductListScreen({Key? key, required this.collection})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$collection Products'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection(collection).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading products'));
          }
          final products = snapshot.data?.docs ?? [];

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

              // Ensure the fields exist before accessing them
              String name = product?['productName'] ?? 'Unknown';
              double price = (product?['irPrice'] is int
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
                          builder: (context) => ProductInformation(
                              productID: product?['productID']),
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
        },
      ),
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
    final NumberFormat currencyFormat = NumberFormat.currency(symbol: '\$');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
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
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                )),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(currencyFormat.format(price),
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
