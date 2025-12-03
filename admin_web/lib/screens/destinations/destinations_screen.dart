import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/destinations/destination.dart';
import '../../services/destinations/admin_destination_service.dart';

/// Screen quản lý destinations
class DestinationsScreen extends StatefulWidget {
  const DestinationsScreen({super.key});

  @override
  State<DestinationsScreen> createState() => _DestinationsScreenState();
}

class _DestinationsScreenState extends State<DestinationsScreen> {
  final AdminDestinationService _destinationService = AdminDestinationService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String? _categoryFilter;
  String? _cityFilter;
  String? _statusFilter; // Filter theo status
  List<Destination> _destinations = [];
  List<String> _categories = [];
  List<String> _cities = [];
  bool _isLoading = false;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndCities();
    _loadDestinations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoriesAndCities() async {
    final categories = await _destinationService.getCategories();
    final cities = await _destinationService.getCities();
    setState(() {
      _categories = categories;
      _cities = cities;
    });
  }

  Future<void> _loadDestinations({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _destinations = [];
        _lastDocument = null;
        _hasMore = true;
      });
    }

    if (!_hasMore && !refresh) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final destinations = await _destinationService.getAllDestinations(
        limit: 20,
        startAfter: refresh ? null : _lastDocument,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        category: _categoryFilter,
        city: _cityFilter,
        status: _statusFilter, // Có thể null để lấy tất cả
      );

      setState(() {
        if (refresh) {
          _destinations = destinations;
        } else {
          _destinations.addAll(destinations);
        }
        _hasMore = destinations.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách destinations: $e')),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == query) {
        _loadDestinations(refresh: true);
      }
    });
  }

  void _onFilterChanged({String? category, String? city, String? status}) {
    setState(() {
      _categoryFilter = category;
      _cityFilter = city;
      _statusFilter = status;
    });
    _loadDestinations(refresh: true);
  }

  Future<void> _handleDeleteDestination(Destination destination) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa "${destination.name}"?'),
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
      print('🗑️ Deleting destination from UI: ${destination.id}');
      await _destinationService.deleteDestination(destination.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa destination thành công')),
        );
        // Reload destinations để cập nhật danh sách (đã filter deleted)
        await _loadDestinations(refresh: true);
      }
    } catch (e, stackTrace) {
      print('❌ Error deleting destination from UI: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa destination: $e')),
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
                  'Quản lý điểm đến',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
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
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/destinations/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm mới'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Search and Filter
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm theo tên, thành phố...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Status filter
                    DropdownButton<String>(
                      value: _statusFilter,
                      hint: const Text('Tất cả trạng thái'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Tất cả trạng thái')),
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'ai_generated', child: Text('AI Generated')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      ],
                      onChanged: (value) => _onFilterChanged(status: value),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Category filter
                    Expanded(
                      child: DropdownButton<String>(
                        value: _categoryFilter,
                        hint: const Text('Tất cả danh mục'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tất cả danh mục')),
                          ..._categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))),
                        ],
                        onChanged: (value) => _onFilterChanged(category: value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // City filter
                    Expanded(
                      child: DropdownButton<String>(
                        value: _cityFilter,
                        hint: const Text('Tất cả thành phố'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tất cả thành phố')),
                          ..._cities.map((city) => DropdownMenuItem(value: city, child: Text(city))),
                        ],
                        onChanged: (value) => _onFilterChanged(city: value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Destinations grid
            Expanded(
              child: _isLoading && _destinations.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _destinations.isEmpty
                      ? const Center(child: Text('Không có destination nào'))
                      : RefreshIndicator(
                          onRefresh: () => _loadDestinations(refresh: true),
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: _destinations.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _destinations.length) {
                                _loadDestinations();
                                return const Center(child: CircularProgressIndicator());
                              }

                              final destination = _destinations[index];
                              return _buildDestinationCard(destination);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationCard(Destination destination) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Image.network(
                    destination.thumbnail,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 48),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          destination.rating.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    destination.location.city,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => context.push('/destinations/${destination.id}/edit'),
                        tooltip: 'Sửa',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: () => _handleDeleteDestination(destination),
                        tooltip: 'Xóa',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
