import 'package:flutter/material.dart';
import 'package:productdb/helper/cart_manager.dart';
import 'package:productdb/screen/checkout_screen.dart';
import 'package:productdb/helper/cart_item.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    Map<String, dynamic> cart = await CartManager().getCart();
    setState(() {
      cartItems = cart.values.map((e) => e as Map<String, dynamic>).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Cart'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteSelectedItems,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Card(
  margin: const EdgeInsets.all(8.0),
  child: ListTile(
    leading: item['imagePath'] != null
        ? Image.network(item['imagePath'], width: 50)
        : null,
    title: Text(item['productName']),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RM${item['irPrice'].toStringAsFixed(2)}'),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: () {
                setState(() {
                  if (item['quantity'] > 1) {
                    item['quantity']--;
                  }
                });
              },
            ),
            Text('${item['quantity']}'),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                setState(() {
                  item['quantity'] = (item['quantity'] ?? 1) + 1;
                });
              },
            ),
          ],
        ),
      ],
    ),
    trailing: Checkbox(
      value: item['isSelected'] ?? false,
      onChanged: (bool? value) {
        setState(() {
          item['isSelected'] = value ?? false;
        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          _buildSummarySection(),
        ],
      ),
    );
  }

 Widget _buildSummarySection() {
  double total = cartItems
      .where((item) => item['isSelected'] == true)
      .fold(0, (sum, item) => sum + (item['irPrice'] * (item['quantity'] ?? 1)));

  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: Colors.black, width: 0.5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subtotal:', style: TextStyle(fontSize: 18)),
            Text('RM${total.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18)),
          ],
        ),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            // Filter selected items and navigate to checkout screen
            List<CartItem> selectedItems = cartItems
                .where((item) => item['isSelected'] == true)
                .map((item) => CartItem(
                      name: item['productName'],
                      price: item['irPrice'],
                      imageUrl: item['imagePath'],
                      quantity: item['quantity'] ?? 1,
                    ))
                .toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckoutScreen(cartItems: selectedItems),
              ),
            );
          },
          child: Text(
              'Check Out (${cartItems.where((item) => item['isSelected'] == true).length})'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.black, // Set the background color to black
            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          ),
        ),
      ],
    ),
  );
}


  void _deleteSelectedItems() {
    setState(() {
      cartItems.removeWhere((item) => item['isSelected'] == true);
      _updateCartInFirestore();
    });
  }

 Future<void> _updateCartInFirestore() async {
  Map<String, dynamic> updatedCart = {};
  for (int i = 0; i < cartItems.length; i++) {
    updatedCart['cart${i + 1}'] = cartItems[i];
  }

  await CartManager().updateCart(updatedCart);
}
}
