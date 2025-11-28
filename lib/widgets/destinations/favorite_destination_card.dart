import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_travel_app/models/destinations/destination.dart';
import 'package:smart_travel_app/providers/auth/user_provider.dart';
import 'package:smart_travel_app/providers/favorites/favorites_provider.dart';
import 'package:smart_travel_app/screens/destinations/destination_detail_screen.dart';
import 'package:smart_travel_app/widgets/destinations/favorite_snackbar.dart';

/// Card hiển thị một địa điểm yêu thích trong danh sách người dùng
class FavoriteDestinationCard extends StatelessWidget {
  final Destination destination;
  final VoidCallback? onRemove;

  const FavoriteDestinationCard({
    super.key,
    required this.destination,
    this.onRemove,
  });

  Future<void> _handleRemove(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    final favoritesProvider = context.read<FavoritesProvider>();

    if (!userProvider.isLoggedIn || userProvider.user == null) {
      FavoriteSnackbar.showError(
        context,
        'Bạn cần đăng nhập để chỉnh sửa danh sách yêu thích',
      );
      return;
    }

    try {
      await favoritesProvider.toggleFavorite(
        userId: userProvider.user!.uid,
        destinationId: destination.id ?? '',
      );
      if (context.mounted) {
        FavoriteSnackbar.showSuccess(context, 'Đã xóa khỏi yêu thích');
      }
      onRemove?.call();
    } catch (error) {
      if (context.mounted) {
        FavoriteSnackbar.showError(context, 'Có lỗi xảy ra: $error');
      }
    }
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => DestinationDetailScreen(
          destination: destination,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.visibility_outlined),
                  title: const Text('Xem chi tiết'),
                  onTap: () {
                    Navigator.pop(context);
                    _openDetail(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Chia sẻ'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tính năng chia sẻ sẽ có trong bản sau'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Xóa khỏi yêu thích',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _handleRemove(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Địa điểm yêu thích: ${destination.name}',
      button: true,
      child: Dismissible(
        key: Key('favorite_${destination.id ?? destination.name}'),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white, size: 28),
        ),
        confirmDismiss: (_) async {
          final shouldRemove = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xóa khỏi yêu thích?'),
                  content: Text(
                    'Bạn có chắc muốn xóa "${destination.name}" khỏi danh sách yêu thích?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              ) ??
              false;
          if (shouldRemove) {
            await _handleRemove(context);
          }
          return shouldRemove;
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _openDetail(context),
            onLongPress: () => _showContextMenu(context),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (destination.verified)
                              _buildTag('Đặt ngay hôm nay', Colors.blue),
                            if (destination.verified)
                              _buildTag('Xác nhận tức thời', Colors.green),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${destination.rating.toStringAsFixed(1)}'
                              '(${destination.reviewCount})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_formatNumber(destination.visitCount)}+ Đã đặt',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (destination.entranceFee != null)
                              Text(
                                'Từ ₫ ${_formatPrice(destination.entranceFee!)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              )
                            else
                              const Text(
                                'Miễn phí',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            if (destination.verified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Sale',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final imageUrl = destination.thumbnail.isNotEmpty
        ? destination.thumbnail
        : (destination.images.isNotEmpty ? destination.images.first : '');

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        bottomLeft: Radius.circular(12),
      ),
      child: Stack(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: imageUrl.isEmpty
                ? Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.photo, color: Colors.white70),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error_outline),
                    ),
                  ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite,
                size: 18,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}

