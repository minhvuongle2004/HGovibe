import 'package:flutter/material.dart';

class AuthSecondaryButton extends StatelessWidget {
  final String question;
  final String actionLabel;
  final VoidCallback? onPressed;

  const AuthSecondaryButton({
    super.key,
    required this.question,
    required this.actionLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(question),
        const SizedBox(width: 4),
        TextButton(
          onPressed: onPressed,
          child: Text(
            actionLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
