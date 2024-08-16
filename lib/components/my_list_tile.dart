import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyListTile extends StatelessWidget {
  final String watchName;
  final String watchdescription;
  final double irwatchPrice;
  final String watchcategory;

  const MyListTile({
    super.key,
    required this.watchName,
    required this.watchdescription,
    required this.irwatchPrice,
    required this.watchcategory,
  });

  @override
  Widget build(BuildContext context) {
    // Format the price with a currency symbol using NumberFormat
    final NumberFormat currencyFormat = NumberFormat.currency(symbol: '\$');

    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20, bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          title: Text(
            watchName,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Text(
                watchdescription,
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                currencyFormat.format(irwatchPrice),
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                watchcategory,
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
