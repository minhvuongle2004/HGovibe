import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/destination.dart';
import '../providers/favorites_provider.dart';
import '../providers/user_provider.dart';
import 'animated_favorite_button.dart';
import 'favorite_snackbar.dart';

/// Widget hiển thị card của một destination
/// Style giống với thiết kế mẫu
class DestinationCard extends StatelessWidget {
  final Destination destination;
  final VoidCallback? onTap;

  const DestinationCard({
    super.key,
    required this.destination,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: destination.thumbnail,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  // Location tag overlay
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[700]?.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            destination.location.city,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Heart icon overlay ở góc trên phải
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _FavoriteButton(destination: destination),
                  ),
                ],
              ),
            ),
            // Thông tin destination
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    destination.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Rating và Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Rating
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 18,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${destination.rating.toStringAsFixed(1)}(${_formatReviewCount(destination.reviewCount)})',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      // Price (nếu có)
                      if (destination.formattedPrice != null)
                        Text(
                          destination.formattedPrice!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format số lượng reviews (ví dụ: 110, 1.2k, 1.4k)
  String _formatReviewCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 10000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    } else {
      return '${(count / 1000).toStringAsFixed(0)}k';
    }
  }
}

/// Widget nút trái tim để toggle favorite
class _FavoriteButton extends StatefulWidget {
  final Destination destination;

  const _FavoriteButton({required this.destination});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool _isToggling = false;

  Future<void> _handleToggleFavorite() async {
    final userProvider = context.read<UserProvider>();
    final favoritesProvider = context.read<FavoritesProvider>();

    // Kiểm tra đăng nhập
    if (!userProvider.isLoggedIn || userProvider.user == null) {
      if (mounted) {
        FavoriteSnackbar.showInfo(
          context,
          'Vui lòng đăng nhập để thêm vào yêu thích',
        );
      }
      return;
    }

    if (widget.destination.id == null || widget.destination.id!.isEmpty) {
      return;
    }

    setState(() {
      _isToggling = true;
    });

    try {
      final wasAdded = await favoritesProvider.toggleFavorite(
        userId: userProvider.user!.uid,
        destinationId: widget.destination.id!,
      );

      if (mounted) {
        FavoriteSnackbar.showSuccess(
          context,
          wasAdded
              ? 'Đã thêm vào yêu thích'
              : 'Đã xóa khỏi yêu thích',
        );
      }
    } catch (e) {
      if (mounted) {
        FavoriteSnackbar.showError(
          context,
          'Lỗi: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isToggling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isFavorite = widget.destination.id != null &&
        favoritesProvider.isFavorite(widget.destination.id!);

    return AnimatedFavoriteButton(
      isFavorite: isFavorite,
      isLoading: _isToggling,
      onTap: _handleToggleFavorite,
      size: 18,
    );
  }
}

