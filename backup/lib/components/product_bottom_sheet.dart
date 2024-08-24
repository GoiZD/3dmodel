// components/product_bottom_sheet.dart
import 'package:flutter/material.dart';

class ProductBottomSheet extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(int) onBuyNow;

  ProductBottomSheet({required this.product, required this.onBuyNow});

  @override
  _ProductBottomSheetState createState() => _ProductBottomSheetState();
}

class _ProductBottomSheetState extends State<ProductBottomSheet> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    double price = 0.0;
    if (widget.product.containsKey('salesPrice') &&
        widget.product['salesPrice'] != null &&
        widget.product['salesPrice'] > 0) {
      price = (widget.product['salesPrice'] as num).toDouble();
    } else {
      price = (widget.product['irPrice'] as num).toDouble();
    }

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: [
              Image.network(
                widget.product['imageUrl'] ?? '',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.product['productName'] ?? 'Unknown'),
                    Text('RM $price'),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: () {
                  if (quantity > 1) {
                    setState(() {
                      quantity--;
                    });
                  }
                },
              ),
              Text('$quantity'),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    quantity++;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          ElevatedButton(
            child: Text('Buy Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => widget.onBuyNow(quantity),
          ),
        ],
      ),
    );
  }
}
