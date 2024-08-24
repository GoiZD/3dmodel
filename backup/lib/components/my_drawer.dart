import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  // logout user
  void logout() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              //drawer header
              DrawerHeader(
                child: Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),

              const SizedBox(height: 25),

              // home tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                    leading: Icon(
                      Icons.home,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                    title: const Text("H O M E"),
                    onTap: () {
                      //this is already the home screen so just pop drawer
                      Navigator.of(context, rootNavigator: true).pop();
                    }),
              ),
              const SizedBox(height: 25),
              // product category tile

              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                    leading: Icon(
                      Icons.category,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                    title: const Text("P R O D U C T C A T E G O R Y"),
                    onTap: () {
                      //pop drawer
                      Navigator.of(context, rootNavigator: true).pop();

                      //navigate to profile page
                      Navigator.pushNamed(context, '/product_category_screen');
                    }),
              ),
              const SizedBox(height: 25),
              // product rating tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                    leading: Icon(
                      Icons.category,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                    title: const Text("P R O D U C T R A T I N G"),
                    onTap: () {
                      //pop drawer
                      Navigator.of(context, rootNavigator: true).pop();

                      //navigate to profile page
                      Navigator.pushNamed(context, '/rating_screen');
                    }),
              ),
              const SizedBox(height: 25),
            ],
          ),
          //product info scree
        ],
      ),
    );
  }
}
