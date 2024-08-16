import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:productdb/helper/cart_item.dart';

class CartManager {
  final String userId;

  CartManager({this.userId = 'C001'});

  Future<void> addToCart(Map<String, dynamic> productData) async {
    try {
      DocumentReference cartDoc =
          FirebaseFirestore.instance.collection('carts').doc(userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(cartDoc);

        if (!snapshot.exists) {
          transaction.set(cartDoc, {
            'cart': [productData]
          });
        } else {
          List<dynamic> cart = List.from(
              (snapshot.data() as Map<String, dynamic>)['cart'] ?? []);
          cart.add(productData);
          transaction.update(cartDoc, {'cart': cart});
        }
      });
    } catch (e) {
      print('Error adding to cart: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCart() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<dynamic> cartList = data['cart'] as List<dynamic>;
        return {
          for (int i = 0; i < cartList.length; i++) 'cart${i + 1}': cartList[i]
        };
      } else {
        return {};
      }
    } catch (e) {
      print('Error fetching cart: $e');
      return {};
    }
  }

  Future<void> updateCart(Map<String, dynamic> updatedCart) async {
    try {
      await FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .update({'cart': updatedCart.values.toList()});
    } catch (e) {
      print('Error updating cart: $e');
      rethrow;
    }
  }

  addItemToCart(CartItem cartItem) {}
}
