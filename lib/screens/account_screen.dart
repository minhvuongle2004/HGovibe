import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../widgets/main_bottom_nav.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    if (user == null) {
      // Fallback: nếu vì lý do nào đó guard chưa bắt kịp, điều hướng về AuthGate
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/', (route) => false);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: userProvider.refreshUser,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileHeader(context, userProvider),
            const SizedBox(height: 16),
            if (!(user.emailVerified))
              _buildVerifyEmailCard(context, userProvider),
            _buildAccountActions(context, userProvider),
            const SizedBox(height: 32),
            _buildDangerZone(context),
          ],
        ),
      ),
      bottomNavigationBar: buildMainBottomNavigationBar(context, 4),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserProvider provider) {
    final user = provider.user!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              child: Text(
                (user.displayName ?? user.email ?? 'U')
                    .substring(0, 1)
                    .toUpperCase(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'Chưa có tên hiển thị',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.profile?.bio ?? 'Cập nhật bio để giới thiệu về bạn!',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showEditNameDialog(context, provider),
              icon: const Icon(Icons.edit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyEmailCard(
      BuildContext context, UserProvider provider) {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Email chưa được xác thực',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy xác thực email để bảo vệ tài khoản và đồng bộ dữ liệu trên nhiều thiết bị.',
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                try {
                  await provider.sendEmailVerification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã gửi email xác thực!'),
                      ),
                    );
                  }
                } on ThrottleException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Vui lòng thử lại sau ${_formatDuration(e.remaining)}',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Gửi email xác thực'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions(
      BuildContext context, UserProvider provider) {
    final user = provider.user!;
    final providerIds = user.providerIds;
    final isGoogleLinked = providerIds.contains('google.com');
    final isFacebookLinked = providerIds.contains('facebook.com');
    final canUnlink = providerIds.length > 1;
    final providersInfo = FirebaseAuth.instance.currentUser?.providerData ?? [];

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Chỉnh sửa tên hiển thị'),
            subtitle: Text(user.displayName ?? 'Chưa có tên hiển thị'),
            onTap: () => _showEditNameDialog(context, provider),
          ),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Đặt lại mật khẩu'),
            subtitle: Text(user.email ?? ''),
            onTap: () async {
              try {
                await provider.sendPasswordReset();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã gửi email đặt lại mật khẩu'),
                    ),
                  );
                }
              } on ThrottleException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Vui lòng thử lại sau ${_formatDuration(e.remaining)}',
                      ),
                    ),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Phương thức đăng nhập hiện tại'),
            subtitle: Text(_formatProviderSummary(providerIds)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => _buildProvidersSheet(providersInfo),
              );
            },
          ),
          if (!isGoogleLinked)
            ListTile(
              leading: const Icon(Icons.g_mobiledata),
              title: const Text('Liên kết với Google'),
              onTap: () => _handleProviderAction(
                context,
                provider.linkGoogleAccount,
                'Đã liên kết thành công với Google',
              ),
            )
          else
            ListTile(
              leading: const Icon(Icons.g_mobiledata),
              title: const Text('Hủy liên kết Google'),
              subtitle: canUnlink
                  ? null
                  : const Text('Cần giữ ít nhất một phương thức đăng nhập'),
              enabled: canUnlink,
              onTap: canUnlink
                  ? () => _handleProviderAction(
                        context,
                        () => provider.unlinkProvider('google.com'),
                        'Đã hủy liên kết Google',
                      )
                  : null,
            ),
          if (!isFacebookLinked)
            ListTile(
              leading: const Icon(Icons.facebook),
              title: const Text('Liên kết với Facebook'),
              onTap: () => _handleProviderAction(
                context,
                provider.linkFacebookAccount,
                'Đã liên kết thành công với Facebook',
              ),
            )
          else
            ListTile(
              leading: const Icon(Icons.facebook),
              title: const Text('Hủy liên kết Facebook'),
              subtitle: canUnlink
                  ? null
                  : const Text('Cần giữ ít nhất một phương thức đăng nhập'),
              enabled: canUnlink,
              onTap: canUnlink
                  ? () => _handleProviderAction(
                        context,
                        () => provider.unlinkProvider('facebook.com'),
                        'Đã hủy liên kết Facebook',
                      )
                  : null,
            ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(color: Colors.red),
        ),
        onTap: () async {
          await AuthService.instance.signOut();
          if (context.mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false);
          }
        },
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, UserProvider provider) {
    final controller =
        TextEditingController(text: provider.user?.displayName ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cập nhật tên hiển thị'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Tên mới',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;
                await provider.updateDisplayName(newName);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã cập nhật tên hiển thị'),
                    ),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return seconds > 0 ? '$minutes phút ${seconds}s' : '$minutes phút';
    }
    return '${seconds}s';
  }

  String _formatProviderSummary(List<String> providerIds) {
    if (providerIds.isEmpty) return 'Email & mật khẩu';
    final displayNames =
        providerIds.map(_providerDisplayName).toSet().toList();
    return displayNames.join(', ');
  }

  Widget _buildProvidersSheet(List<UserInfo> providers) {
    if (providers.isEmpty) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Bạn đang đăng nhập bằng Email & mật khẩu'),
        ),
      );
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Các phương thức đăng nhập',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...providers.map(
            (p) => ListTile(
              leading: Icon(
                p.providerId == 'google.com'
                    ? Icons.g_mobiledata
                    : p.providerId == 'facebook.com'
                        ? Icons.facebook
                        : Icons.lock,
              ),
              title: Text(
                _providerDisplayName(p.providerId),
              ),
              subtitle: Text(p.email ?? p.providerId),
            ),
          ),
        ],
      ),
    );
  }

  String _providerDisplayName(String providerId) {
    switch (providerId) {
      case 'google.com':
        return 'Google';
      case 'facebook.com':
        return 'Facebook';
      case 'password':
        return 'Email & mật khẩu';
      default:
        return providerId;
    }
  }

  Future<void> _handleProviderAction(
    BuildContext context,
    Future<void> Function() action,
    String successMessage,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await action();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Lỗi: ${e.code}'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra: $error'),
          ),
        );
      }
    }
  }
}

