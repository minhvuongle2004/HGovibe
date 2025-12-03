import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Header cho admin panel
class AdminHeader extends StatelessWidget {
  final VoidCallback onLogout;

  const AdminHeader({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search bar (optional, có thể thêm sau)
          Expanded(
            child: Container(),
          ),
          // User info
          Row(
            children: [
              // User email
              Text(
                user?.email ?? 'Admin',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 16),
              // Logout button
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Xác nhận đăng xuất'),
                      content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onLogout();
                          },
                          child: const Text(
                            'Đăng xuất',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: 'Đăng xuất',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

