import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:vcon_testing/firebase_options.dart';
import 'package:vcon_testing/screen/home_page.dart';
import 'package:vcon_testing/screen/product_category_screen.dart';
// import 'package:productdbb/screen/home_page.dart';
// import 'package:productdbb/screen/product_category_screen.dart';
// import 'package:productdbb/theme/dark_mode.dart';
// import 'package:productdbb/theme/light_mode.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
      // theme: lightMode,
      // darkTheme: darkMode,
      routes: {
        '/product_category_screen': (context) => const ProductsCategoryPage(),
      },
    );
  }
}