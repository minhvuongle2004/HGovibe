import 'package:flutter/material.dart';
import '../../models/users/app_user.dart';
import '../../services/users/admin_user_service.dart';

/// Screen chi tiết user
class UserDetailScreen extends StatefulWidget {
  final String userId;

  const UserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final AdminUserService _userService = AdminUserService.instance;
  AppUser? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _userService.getUserById(widget.userId);
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thông tin user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('User không tồn tại')),
        body: const Center(child: Text('User không tồn tại')),
      );
    }

    final user = _user!;
    final profile = user.profile;
    final isBanned = profile?.banned ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết user: ${user.email ?? 'N/A'}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null
                              ? Text(
                                  (user.displayName ?? user.email ?? 'U')[0]
                                      .toUpperCase(),
                                  style: const TextStyle(fontSize: 32),
                                )
                              : null,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName ?? user.email ?? 'No name',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                user.email ?? 'No email',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isBanned
                                      ? Colors.red[100]
                                      : Colors.green[100],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  isBanned ? 'Banned' : 'Active',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isBanned
                                        ? Colors.red[700]
                                        : Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Details
            const Text(
              'Thông tin chi tiết',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDetailRow('Email', user.email ?? 'N/A'),
                    _buildDetailRow('Phone', profile?.phoneNumber ?? 'N/A'),
                    _buildDetailRow('Gender', profile?.gender ?? 'N/A'),
                    _buildDetailRow('Address', profile?.address ?? 'N/A'),
                    if (profile?.createdAt != null)
                      _buildDetailRow(
                        'Ngày tạo',
                        _formatDate(profile!.createdAt!),
                      ),
                    if (profile?.bannedAt != null)
                      _buildDetailRow(
                        'Ngày ban',
                        _formatDate(profile!.bannedAt!),
                      ),
                    if (profile?.banReason != null)
                      _buildDetailRow(
                        'Lý do ban',
                        profile!.banReason!,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Actions
            Row(
              children: [
                if (isBanned)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await _userService.unbanUser(user.uid);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã unban user thành công'),
                              ),
                            );
                            _loadUser();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Unban User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Xác nhận ban user'),
                            content: Text('Bạn có chắc chắn muốn ban user ${user.email}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Ban'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed != true) return;

                        try {
                          await _userService.banUser(user.uid);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã ban user thành công'),
                              ),
                            );
                            _loadUser();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.block),
                      label: const Text('Ban User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}

