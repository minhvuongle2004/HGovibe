import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_travel_app/providers/auth/user_provider.dart';
import 'package:smart_travel_app/screens/home/home_screen.dart';
import 'sign_in_screen.dart';

/// AuthGate chịu trách nhiệm:
/// - Lắng nghe UserProvider (bao quát auth + profile)
/// - Hiển thị Splash khi đang kiểm tra trạng thái
/// - Điều hướng HomeScreen khi đã đăng nhập
/// - Điều hướng SignInScreen khi chưa đăng nhập
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: userProvider.isLoading
          ? const Scaffold(
              key: ValueKey('loading'),
              body: Center(child: CircularProgressIndicator()),
            )
          : userProvider.isLoggedIn
          ? const HomeScreen(key: ValueKey('home'))
          : const SignInScreen(key: ValueKey('signin')),
    );
  }
}
