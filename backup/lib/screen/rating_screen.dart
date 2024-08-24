import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingScreen extends StatefulWidget {
  final String productID;
  final String category;

  const RatingScreen(
      {required this.productID, required this.category, Key? key})
      : super(key: key);

  @override
  _RatingScreenState createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  TextEditingController _reviewController = TextEditingController();

  Widget _buildStar(int index) {
    return IconButton(
      icon: Icon(
        index < _rating ? Icons.star : Icons.star_border,
        color: Colors.orange,
        size: 40,
      ),
      onPressed: () {
        setState(() {
          _rating = index + 1;
        });
      },
    );
  }

  void _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a rating.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection(widget.category) // Use the category passed in
          .doc(widget.productID)
          .update({
        'ratings': FieldValue.arrayUnion([
          {
            'rating': _rating,
            'comment': _reviewController.text.isEmpty
                ? 'No review provided'
                : _reviewController.text,
            'timestamp': Timestamp.now(),
          }
        ])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review submitted successfully!')),
      );

      // Clear the input fields
      setState(() {
        _rating = 0;
        _reviewController.clear();
      });
    } catch (e) {
      print('Error submitting review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rating and Review'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'What is your rate?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => _buildStar(index)),
            ),
            SizedBox(height: 20),
            Text(
              'Please share your opinion about the product',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Your review (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Background color
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: Text('SEND REVIEW', style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
