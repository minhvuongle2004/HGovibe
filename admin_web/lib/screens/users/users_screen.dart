import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/users/app_user.dart';
import '../../services/users/admin_user_service.dart';

/// Screen quản lý users
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final AdminUserService _userService = AdminUserService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  bool? _bannedFilter; // null = all, true = banned, false = active
  List<AppUser> _users = [];
  bool _isLoading = false;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _users = [];
        _lastDocument = null;
        _hasMore = true;
      });
    }

    if (!_hasMore && !refresh) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _userService.getAllUsers(
        limit: 20,
        startAfter: refresh ? null : _lastDocument,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        banned: _bannedFilter,
      );

      setState(() {
        if (refresh) {
          _users = users;
        } else {
          _users.addAll(users);
        }
        _hasMore = users.length == 20;
        if (users.isNotEmpty) {
          // Note: We need to track last document for pagination
          // This is simplified - in production, track the last document snapshot
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách users: $e')),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == query) {
        _loadUsers(refresh: true);
      }
    });
  }

  void _onFilterChanged(bool? value) {
    setState(() {
      _bannedFilter = value;
    });
    _loadUsers(refresh: true);
  }

  Future<void> _handleBanUser(AppUser user) async {
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
          const SnackBar(content: Text('Đã ban user thành công')),
        );
        _loadUsers(refresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi ban user: $e')),
        );
      }
    }
  }

  Future<void> _handleUnbanUser(AppUser user) async {
    try {
      await _userService.unbanUser(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã unban user thành công')),
        );
        _loadUsers(refresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi unban user: $e')),
        );
      }
    }
  }

  Future<void> _handleDeleteUser(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa user'),
        content: Text('Bạn có chắc chắn muốn xóa user ${user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _userService.deleteUser(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa user thành công')),
        );
        _loadUsers(refresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quản lý người dùng',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Export CSV - sẽ implement sau
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export CSV - Coming soon')),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Export CSV'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Search and Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo email, tên...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 16),
                // Filter chips
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: _bannedFilter == null,
                  onSelected: (_) => _onFilterChanged(null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Đang hoạt động'),
                  selected: _bannedFilter == false,
                  onSelected: (_) => _onFilterChanged(false),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Đã ban'),
                  selected: _bannedFilter == true,
                  onSelected: (_) => _onFilterChanged(true),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Users table
            Expanded(
              child: _isLoading && _users.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? const Center(
                          child: Text('Không có user nào'),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadUsers(refresh: true),
                          child: ListView.builder(
                            itemCount: _users.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _users.length) {
                                // Load more
                                _loadUsers();
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final user = _users[index];
                              return _buildUserCard(user);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    final isBanned = user.profile?.banned ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.photoUrl != null
              ? NetworkImage(user.photoUrl!)
              : null,
          child: user.photoUrl == null
              ? Text(
                  (user.displayName ?? user.email ?? 'U')[0].toUpperCase(),
                )
              : null,
        ),
        title: Text(
          user.displayName ?? user.email ?? 'No name',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isBanned ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email ?? 'No email'),
            if (user.profile?.createdAt != null)
              Text(
                'Tạo: ${_formatDate(user.profile!.createdAt!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isBanned ? Colors.red[100] : Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isBanned ? 'Banned' : 'Active',
                style: TextStyle(
                  fontSize: 12,
                  color: isBanned ? Colors.red[700] : Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Actions
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    context.push('/users/${user.uid}');
                    break;
                  case 'ban':
                    _handleBanUser(user);
                    break;
                  case 'unban':
                    _handleUnbanUser(user);
                    break;
                  case 'delete':
                    _handleDeleteUser(user);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 8),
                      Text('Xem chi tiết'),
                    ],
                  ),
                ),
                if (isBanned)
                  const PopupMenuItem(
                    value: 'unban',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 20),
                        SizedBox(width: 8),
                        Text('Unban'),
                      ],
                    ),
                  )
                else
                  const PopupMenuItem(
                    value: 'ban',
                    child: Row(
                      children: [
                        Icon(Icons.block, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Ban', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
