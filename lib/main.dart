import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyDTae0z_U6O_6YkyblADZgUMytWIIAipZA",
      authDomain: "vcon-app-2024.firebaseapp.com",
      projectId: "vcon-app-2024",
      storageBucket: "vcon-app-2024.appspot.com",
      messagingSenderId: "382422564484",
      appId: "1:382422564484:web:06c310489199aa2d350cd1",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProductPage(),
    );
  }
}

class ProductPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
      ),
      body: Center(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('products') // Root collection
              .doc('watches') // Document inside the root collection
              .collection('leClassiqueCollection') // Subcollection under the 'watches' document
              .doc('A2KL9aEw0zURyJfb99k0') // Specific document within the subcollection
              .get(),
          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text("Product not found");
            }

            var data = snapshot.data!.data() as Map<String, dynamic>;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.network(
                  data['coverImage'],
                  height: 200,
                ),
                SizedBox(height: 20),
                Text(
                  data['productName'],
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Category: ${data['category']}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 10),
                Text(
                  'Retail Price: \$${data['retailPrice']}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 10),
                Text(
                  'Sales Price: \$${data['salesPrice']}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 10),
                Text(
                  'Product ID: ${data['productID']}',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
