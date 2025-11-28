import 'package:flutter/material.dart';

class AuthValidationText extends StatelessWidget {
  final String? message;

  const AuthValidationText({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(message!, style: const TextStyle(color: Colors.redAccent));
  }
}
