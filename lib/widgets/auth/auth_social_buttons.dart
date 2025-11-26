import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_form_provider.dart';
import '../../services/exceptions/auth_exceptions.dart';
import 'auth_snackbar.dart' show showAuthSnackBar;

class AuthSocialButtons extends StatelessWidget {
  const AuthSocialButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final formProvider = context.watch<AuthFormProvider>();
    final isLoading = formProvider.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[300])),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('Hoặc tiếp tục với'),
            ),
            Expanded(child: Divider(color: Colors.grey[300])),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SocialButton(
              icon: Icons.g_mobiledata,
              label: 'Google',
              isLoading: isLoading,
              onPressed: () async {
                formProvider.clearMessages();
                try {
                  await formProvider.signInWithGoogle();
                } catch (e) {
                  if (context.mounted) {
                    // Hiển thị error message trong form
                    // AuthFormProvider đã set errorMessage
                    // Nếu là AccountExistsWithDifferentCredentialException, 
                    // hiển thị snackbar để user dễ thấy hơn
                    if (e is AccountExistsWithDifferentCredentialException) {
                      showAuthSnackBar(
                        context,
                        e.toString(),
                        isError: true,
                      );
                    }
                  }
                }
              },
            ),
            _SocialButton(
              icon: Icons.facebook,
              label: 'Facebook',
              isLoading: isLoading,
              onPressed: () async {
                formProvider.clearMessages();
                try {
                  await formProvider.signInWithFacebook();
                } catch (e) {
                  if (context.mounted) {
                    if (e is AccountExistsWithDifferentCredentialException) {
                      showAuthSnackBar(
                        context,
                        e.toString(),
                        isError: true,
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: Icon(icon),
      label: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.grey),
        ),
      ),
    );
  }
}


