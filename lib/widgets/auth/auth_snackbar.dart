import 'package:flutter/material.dart';

void showAuthSnackBar(
  BuildContext context,
  String message, {
  bool isError = true,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
    ),
  );
}
