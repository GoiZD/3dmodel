// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:productdb/screen/ar_screen.dart'; // Import the ARScreen for AR try-on

// class TryOnScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Try-On Area'),
//       ),
//       body: FutureBuilder<QuerySnapshot>(
//         future: FirebaseFirestore.instance.collection('Watches').get(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text('Error loading products'));
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return Center(child: Text('No products available'));
//           }

//           final products = snapshot.data!.docs;
//           return GridView.builder(
//             padding: EdgeInsets.all(16.0),
//             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               crossAxisSpacing: 16.0,
//               mainAxisSpacing: 16.0,
//               childAspectRatio: 0.7,
//             ),
//             itemCount: products.length,
//             itemBuilder: (context, index) {
//               final product = products[index];
//               return _buildProductCard(context, product);
//             },
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildProductCard(BuildContext context, DocumentSnapshot product) {
//     final productData = product.data() as Map<String, dynamic>;
//     String name = productData['productName'] ?? 'Unknown';
//     double price = (productData['irPrice'] is int)
//         ? (productData['irPrice'] as int).toDouble()
//         : (productData['irPrice'] ?? 0.0);
//     String imageUrl = productData['imagePath'] ?? '';

//     return FutureBuilder<String>(
//       future: _getImageUrl(imageUrl),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Card(
//             child: Center(child: CircularProgressIndicator()),
//           );
//         }
//         if (snapshot.hasError) {
//           return Card(
//             child: Center(child: Text('Error loading image')),
//           );
//         }
//         return Card(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               if (snapshot.hasData)
//                 Container(
//                   height: 150,
//                   decoration: BoxDecoration(
//                     image: DecorationImage(
//                       image: NetworkImage(snapshot.data!),
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 ),
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         name,
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         'RM${price.toStringAsFixed(2)}',
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.black,
//                         ),
//                       ),
//                       SizedBox(height: 8),
//                       Spacer(),
//                       ElevatedButton(
//                         onPressed: () {
//                           // Navigate to ARScreen to try on the product
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => ARScreen(),
//                             ),
//                           );
//                         },
//                         child: Text('Try'),
//                         style: ElevatedButton.styleFrom(
//                           minimumSize:
//                               Size(double.infinity, 36), // Button full width
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Future<String> _getImageUrl(String imageUrl) async {
//     if (imageUrl.startsWith('gs://')) {
//       final ref = FirebaseStorage.instance.refFromURL(imageUrl);
//       return await ref.getDownloadURL();
//     }
//     return imageUrl;
//   }
// }
