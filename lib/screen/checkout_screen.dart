import 'package:flutter/material.dart';
import 'package:productdb/helper/cart_item.dart';

class CheckoutScreen extends StatelessWidget {
  final List<CartItem> cartItems;

  CheckoutScreen({required this.cartItems});

  @override
  Widget build(BuildContext context) {
    // Calculate total price considering the quantity of each item
    double total =
        cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: Image.network(item.imageUrl, width: 50),
                      title: Text(item.name),
                      subtitle: Text(
                          'RM${item.price.toStringAsFixed(2)} x ${item.quantity}'),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Text('Select Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Implement payment method
                  },
                  icon: Icon(Icons.credit_card),
                  label: Text('Credit/Debit Card'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Implement payment method
                  },
                  icon: Icon(Icons.account_balance),
                  label: Text('Bank Islam'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order Amount', style: TextStyle(fontSize: 18)),
                Text('RM${total.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18)),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Implement place order functionality
              },
              child: Text('Place Order'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
