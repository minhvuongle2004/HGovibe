import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_travel_app/providers/auth/user_provider.dart';

/// Wrapper để đảm bảo người dùng đã đăng nhập trước khi xem nội dung.
/// Nếu chưa đăng nhập, tự động điều hướng về route `/` (AuthGate + SignIn).
class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    if (userProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!userProvider.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!Navigator.of(context).mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return child;
  }
}
