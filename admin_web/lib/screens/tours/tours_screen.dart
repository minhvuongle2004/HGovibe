import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/tours/tour_package.dart';
import '../../services/tours/admin_tour_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/page_header.dart';

/// Screen quản lý tours
class ToursScreen extends StatefulWidget {
  const ToursScreen({super.key});

  @override
  State<ToursScreen> createState() => _ToursScreenState();
}

class _ToursScreenState extends State<ToursScreen> {
  final AdminTourService _tourService = AdminTourService.instance;
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  List<TourPackage> _tours = [];
  bool _isLoading = false;
  bool _featuredOnly = false;
  TourStatus? _statusFilter;
  String _searchQuery = '';
  Timer? _debounce;
  final Set<String> _processingTourIds = {};

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadTours({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final tours = await _tourService.getAllTours(
        limit: 40,
        searchQuery: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        status: _statusFilter,
        featured: _featuredOnly ? true : null,
      );

      if (!mounted) return;
      setState(() {
        _tours = tours;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách tours: $e')),
      );
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _searchQuery = query;
      });
      _loadTours();
    });
  }

  void _setStatusFilter(TourStatus? status) {
    setState(() {
      _statusFilter = status;
    });
    _loadTours();
  }

  void _toggleFeatured(bool value) {
    setState(() {
      _featuredOnly = value;
    });
    _loadTours();
  }

  Future<void> _openCreateTour() async {
    final result = await context.push<bool>('/tours/new');
    if (result == true) {
      _loadTours();
    }
  }

  Future<void> _openEditTour(TourPackage tour) async {
    final result = await context.push<bool>('/tours/${tour.id}/edit');
    if (result == true) {
      _loadTours();
    }
  }

  Future<void> _executeTourAction({
    required String tourId,
    required Future<void> Function() action,
    String? successMessage,
    bool reloadAfter = true,
  }) async {
    setState(() {
      _processingTourIds.add(tourId);
    });

    try {
      await action();
      if (reloadAfter) {
        await _loadTours(showLoader: false);
      }
      if (mounted && successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thao tác thất bại: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingTourIds.remove(tourId);
        });
      }
    }
  }

  Future<void> _handleAction(String action, TourPackage tour) async {
    final tourId = tour.id;
    if (tourId == null) return;

    switch (action) {
      case 'activate':
        await _executeTourAction(
          tourId: tourId,
          action: () => _tourService.activateTour(tourId),
          successMessage: 'Đã kích hoạt tour "${tour.title}"',
        );
        break;
      case 'deactivate':
        await _executeTourAction(
          tourId: tourId,
          action: () => _tourService.deactivateTour(tourId),
          successMessage: 'Đã tạm dừng tour "${tour.title}"',
        );
        break;
      case 'soldout':
        await _executeTourAction(
          tourId: tourId,
          action: () => _tourService.markSoldOut(tourId),
          successMessage: 'Đã đánh dấu hết chỗ tour "${tour.title}"',
        );
        break;
      case 'duplicate':
        String? newId;
        await _executeTourAction(
          tourId: tourId,
          action: () async {
            newId = await _tourService.duplicateTour(tourId);
          },
          successMessage: 'Đã nhân bản tour thành công',
        );
        if (mounted && newId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tour mới có ID: $newId')),
          );
        }
        break;
      case 'edit':
        await _openEditTour(tour);
        break;
      case 'delete':
        final confirmed = await _showDeleteDialog(tour);
        if (confirmed != true) return;
        await _executeTourAction(
          tourId: tourId,
          action: () => _tourService.deleteTour(tourId),
          successMessage: 'Đã xóa tour "${tour.title}"',
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tính năng đang phát triển')),
        );
    }
  }

  Future<bool?> _showDeleteDialog(TourPackage tour) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa tour'),
        content: Text(
          'Bạn có chắc chắn muốn xóa tour "${tour.title}"? '
          'Hành động này sẽ ẩn tour khỏi người dùng.',
        ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
              title: 'Quản lý tours',
              subtitle: 'Theo dõi trạng thái, kích hoạt/ẩn và nhân bản tours',
              actions: [
                Tooltip(
                  message: 'Tải lại',
                  child: IconButton(
                    onPressed: () => _loadTours(),
                    icon: const Icon(Icons.refresh),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openCreateTour,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm tour mới'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildFilters(),
            const SizedBox(height: 24),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Tìm theo tên tour, điểm đến, đối tác...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        DropdownButton<TourStatus?>(
          value: _statusFilter,
          hint: const Text('Trạng thái'),
          items: const [
            DropdownMenuItem(
              value: null,
              child: Text('Tất cả trạng thái'),
            ),
            DropdownMenuItem(
              value: TourStatus.active,
              child: Text('Đang hoạt động'),
            ),
            DropdownMenuItem(
              value: TourStatus.inactive,
              child: Text('Tạm dừng'),
            ),
            DropdownMenuItem(
              value: TourStatus.soldOut,
              child: Text('Hết chỗ'),
            ),
          ],
          onChanged: _setStatusFilter,
        ),
        FilterChip(
          selected: _featuredOnly,
          onSelected: _toggleFeatured,
          label: const Text('Chỉ tour nổi bật'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tours.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadTours(showLoader: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AdminEmptyState(
              icon: Icons.search_off,
              title: 'Không có tour nào phù hợp',
              description:
                  'Hãy điều chỉnh bộ lọc hoặc tạo tour mới để bắt đầu.',
              actionLabel: 'Reset bộ lọc',
              onAction: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _statusFilter = null;
                  _featuredOnly = false;
                });
                _loadTours();
              },
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadTours(showLoader: false),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _tours.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildTourCard(_tours[index]),
      ),
    );
  }

  Widget _buildTourCard(TourPackage tour) {
    final isProcessing = _processingTourIds.contains(tour.id);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(tour.thumbnail),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tour.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      if (tour.featured) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Featured',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Điểm đến: ${tour.destination}',
                    style: const TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusChip(tour.status),
                      Chip(
                        label: Text(
                          'Giá từ ${_formatPrice(tour.basePrice)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      Chip(
                        avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                        label: Text(
                          '${tour.rating.toStringAsFixed(1)} / 5 • ${tour.reviewCount} đánh giá',
                          style: const TextStyle(fontSize: 12),
                        ),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      Chip(
                        avatar: const Icon(Icons.people, size: 16),
                        label: Text(
                          '${tour.bookingCount} lượt đặt',
                          style: const TextStyle(fontSize: 12),
                        ),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cập nhật: ${_formatDate(tour.updatedAt)}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              tooltip: 'Thao tác',
              enabled: !isProcessing,
              onSelected: (value) => _handleAction(value, tour),
              itemBuilder: (_) => _buildMenuItems(tour),
              icon: isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.more_vert),
            ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(TourPackage tour) {
    final items = <PopupMenuEntry<String>>[];

    if (tour.status != TourStatus.active) {
      items.add(
        const PopupMenuItem(
          value: 'activate',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.play_circle_outline),
            title: Text('Kích hoạt tour'),
          ),
        ),
      );
    }

    if (tour.status == TourStatus.active) {
      items.add(
        const PopupMenuItem(
          value: 'deactivate',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.pause_circle_outline),
            title: Text('Tạm dừng tour'),
          ),
        ),
      );
    }

    if (tour.status != TourStatus.soldOut) {
      items.add(
        const PopupMenuItem(
          value: 'soldout',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.event_available),
            title: Text('Đánh dấu hết chỗ'),
          ),
        ),
      );
    }

    items.addAll([
      const PopupMenuItem(
        value: 'edit',
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.edit_outlined),
          title: Text('Chỉnh sửa'),
        ),
      ),
      const PopupMenuItem(
        value: 'duplicate',
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.copy),
          title: Text('Nhân bản tour'),
        ),
      ),
      const PopupMenuItem(
        value: 'delete',
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.delete_outline, color: Colors.red),
          title: Text(
            'Xóa tour',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ),
    ]);

    return items;
  }

  Widget _buildThumbnail(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 120,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 120,
        height: 90,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildStatusChip(TourStatus status) {
    Color color;
    String label;

    switch (status) {
      case TourStatus.active:
        color = Colors.green;
        label = 'Đang hoạt động';
        break;
      case TourStatus.inactive:
        color = Colors.orange;
        label = 'Tạm dừng';
        break;
      case TourStatus.soldOut:
        color = Colors.red;
        label = 'Hết chỗ';
        break;
    }

    return Chip(
      backgroundColor: color.withOpacity(0.1),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatPrice(double price) {
    return _currencyFormat.format(price);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
