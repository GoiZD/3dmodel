import 'package:flutter/material.dart';

// display error message to user
void displayMessageToUser(String message, BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  });
}
