import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_travel_app/models/destinations/destination.dart';
import 'package:smart_travel_app/providers/favorites/favorites_provider.dart';
import 'package:smart_travel_app/providers/auth/user_provider.dart';
import 'package:smart_travel_app/widgets/common/image_carousel_widget.dart';
import 'package:smart_travel_app/widgets/destinations/animated_favorite_button.dart';
import 'package:smart_travel_app/widgets/destinations/favorite_snackbar.dart';
import 'package:smart_travel_app/widgets/destinations/specialties_section.dart';
import 'package:smart_travel_app/widgets/destinations/activities_section.dart';
import 'package:smart_travel_app/screens/home/map_screen.dart';

class DestinationDetailScreen extends StatefulWidget {
  final Destination destination;
  final WidgetBuilder? mapScreenBuilder;

  const DestinationDetailScreen({
    super.key,
    required this.destination,
    this.mapScreenBuilder,
  });

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  bool _isDescriptionExpanded = false;
  bool _isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    // Load favorites khi màn hình được mở
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      UserProvider? userProvider;
      FavoritesProvider? favoritesProvider;
      try {
        userProvider = context.read<UserProvider>();
      } on ProviderNotFoundException {
        userProvider = null;
      }
      try {
        favoritesProvider = context.read<FavoritesProvider>();
      } on ProviderNotFoundException {
        favoritesProvider = null;
      }
      if (userProvider != null &&
          favoritesProvider != null &&
          userProvider.isLoggedIn &&
          userProvider.user != null) {
        favoritesProvider.loadFavorites(userProvider.user!.uid);
      }
    });
  }

  Future<void> _handleToggleFavorite() async {
    UserProvider? userProvider;
    FavoritesProvider? favoritesProvider;
    try {
      userProvider = context.read<UserProvider>();
    } on ProviderNotFoundException {
      userProvider = null;
    }
    try {
      favoritesProvider = context.read<FavoritesProvider>();
    } on ProviderNotFoundException {
      favoritesProvider = null;
    }

    if (userProvider == null || favoritesProvider == null) {
      if (mounted) {
        FavoriteSnackbar.showInfo(
          context,
          'Chức năng yêu thích tạm thời không khả dụng.',
        );
      }
      return;
    }

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

    setState(() {
      _isTogglingFavorite = true;
    });

    try {
      final wasAdded = await favoritesProvider.toggleFavorite(
        userId: userProvider.user!.uid,
        destinationId: widget.destination.id ?? '',
      );

      if (mounted) {
        FavoriteSnackbar.showSuccess(
          context,
          wasAdded ? 'Đã thêm vào yêu thích' : 'Đã xóa khỏi yêu thích',
        );
      }
    } catch (e) {
      if (mounted) {
        FavoriteSnackbar.showError(context, 'Lỗi: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingFavorite = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    FavoritesProvider? favoritesProvider;
    try {
      favoritesProvider = context.watch<FavoritesProvider>();
    } on ProviderNotFoundException {
      favoritesProvider = null;
    }
    final isFavorite =
        widget.destination.id != null &&
        (favoritesProvider?.isFavorite(widget.destination.id!) ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destination.name),
        actions: [
          // Nút trái tim với animation
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AnimatedFavoriteButton(
              isFavorite: isFavorite,
              isLoading: _isTogglingFavorite,
              onTap: _handleToggleFavorite,
              size: 24,
            ),
          ),
          // Nút share (placeholder)
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tính năng chia sẻ sẽ được thêm sau'),
                ),
              );
            },
          ),
          // Nút cart (placeholder)
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              // TODO: Implement cart functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tính năng đặt vé sẽ được thêm sau'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image carousel
            ImageCarouselWidget(
              images: widget.destination.images,
              thumbnail: widget.destination.thumbnail,
              height: 300,
            ),
            // Card thông tin (màu trắng, rounded top)
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge "PARTNER AWARDS" (nếu verified)
                    if (widget.destination.verified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  'K',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'PARTNER AWARDS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '2024 Best of Vietnam',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (widget.destination.verified) const SizedBox(height: 12),
                    // Tên địa điểm
                    Text(
                      widget.destination.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Rating + số đánh giá + số lượt đặt
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.destination.rating.toStringAsFixed(1)}/5',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.destination.reviewCount} Đánh giá',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatNumber(widget.destination.visitCount)}+ Đã đặt',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Vị trí
                    InkWell(
                      onTap: () {
                        final builder =
                            widget.mapScreenBuilder ??
                            (_) => MapScreen(
                              initialDestination: widget.destination,
                              showBackToDetail: true,
                            );
                        Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: builder));
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.destination.location.address.isNotEmpty
                                  ? widget.destination.location.address
                                  : '${widget.destination.location.city}, ${widget.destination.location.country}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Mô tả
                    if (widget.destination.description.isNotEmpty) ...[
                      Text(
                        widget.destination.description,
                        maxLines: _isDescriptionExpanded ? null : 3,
                        overflow: _isDescriptionExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      if (widget.destination.description.length > 150)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isDescriptionExpanded = !_isDescriptionExpanded;
                            });
                          },
                          child: Text(
                            _isDescriptionExpanded ? 'Thu gọn' : 'Xem thêm',
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                    // Section "Ưu đãi cho bạn" (nếu có tags hoặc verified)
                    if (widget.destination.tags.isNotEmpty ||
                        widget.destination.verified) ...[
                      const Text(
                        'Ưu đãi cho bạn',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            if (widget.destination.verified)
                              _buildOfferChip('Sale', Colors.red),
                            if (widget.destination.tags.isNotEmpty)
                              ...widget.destination.tags
                                  .take(3)
                                  .map(
                                    (tag) =>
                                        _buildOfferChip(tag, Colors.orange),
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Section "Đặc sản & Ẩm thực"
                    if (widget.destination.specialties.isNotEmpty) ...[
                      SpecialtiesSection(
                        specialties: widget.destination.specialties,
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Section "Hoạt động & Trải nghiệm"
                    if (widget.destination.activities.isNotEmpty) ...[
                      ActivitiesSection(
                        activities: widget.destination.activities,
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Giá và nút "Chọn"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.destination.entranceFee != null) ...[
                              Text(
                                'Từ ₫ ${_formatPrice(widget.destination.entranceFee!)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              // Giá gốc gạch ngang (nếu có sale)
                              if (widget.destination.verified)
                                Text(
                                  '₫ ${_formatPrice((widget.destination.entranceFee! * 1.2).toInt())}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ] else
                              const Text(
                                'Miễn phí',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement booking
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Tính năng đặt vé sẽ được thêm sau',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_drop_down),
                          label: const Text('Chọn'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
    );
  }

  Widget _buildOfferChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
