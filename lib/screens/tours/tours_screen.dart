import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_app/models/tours/tour_package.dart';
import 'package:smart_travel_app/providers/tours/tour_package_provider.dart';
import 'package:smart_travel_app/widgets/tours/tour_card.dart';
import 'package:smart_travel_app/screens/tours/tour_detail_screen.dart';
import 'package:smart_travel_app/widgets/common/main_bottom_nav.dart';

/// Screen danh sách tours với filter và search
class ToursScreen extends StatefulWidget {
  const ToursScreen({super.key});

  @override
  State<ToursScreen> createState() => _ToursScreenState();
}

class _ToursScreenState extends State<ToursScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedDestination;
  String? _selectedSort;
  int? _selectedDuration;
  TourType? _selectedType;

  final List<String> _destinations = [
    'Tất cả',
    'Đà Nẵng',
    'Hạ Long',
    'Phú Quốc',
    'Nha Trang',
    'Đà Lạt',
    'Sapa',
    'Mũi Né',
    'Tà Xùa',
  ];

  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'rating', 'label': 'Đánh giá cao nhất'},
    {'value': 'price_low', 'label': 'Giá thấp đến cao'},
    {'value': 'price_high', 'label': 'Giá cao đến thấp'},
    {'value': 'popular', 'label': 'Phổ biến nhất'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDestination = 'Tất cả';
    _selectedSort = 'rating';
    _loadTours();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadTours() {
    final provider = context.read<TourPackageProvider>();
    provider.loadTours(
      status: TourStatus.active,
      destination: _selectedDestination == 'Tất cả' ? null : _selectedDestination,
    );
  }

  void _onSearch(String query) {
    final provider = context.read<TourPackageProvider>();
    if (query.trim().isEmpty) {
      _loadTours();
    } else {
      provider.searchTours(query);
    }
  }

  void _applyFilters() {
    _loadTours();
  }

  List<TourPackage> _sortTours(List<TourPackage> tours) {
    final sorted = List<TourPackage>.from(tours);
    switch (_selectedSort) {
      case 'rating':
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'price_low':
        sorted.sort((a, b) => a.basePrice.compareTo(b.basePrice));
        break;
      case 'price_high':
        sorted.sort((a, b) => b.basePrice.compareTo(a.basePrice));
        break;
      case 'popular':
        sorted.sort((a, b) => b.bookingCount.compareTo(a.bookingCount));
        break;
    }
    return sorted;
  }

  List<TourPackage> _filterTours(List<TourPackage> tours) {
    var filtered = tours;
    
    // Filter theo duration
    if (_selectedDuration != null) {
      filtered = filtered.where((tour) {
        if (_selectedDuration == 1) return tour.durationDays <= 3;
        if (_selectedDuration == 2) return tour.durationDays >= 4 && tour.durationDays <= 7;
        if (_selectedDuration == 3) return tour.durationDays >= 8;
        return true;
      }).toList();
    }
    
    // Filter theo type
    if (_selectedType != null) {
      filtered = filtered.where((tour) => tour.type == _selectedType).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tours'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tours...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _onSearch,
            ),
          ),
          // Filter chips
          _buildFilterChips(),
          // Tours list
          Expanded(
            child: Consumer<TourPackageProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.tours.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Lỗi: ${provider.error}',
                          style: TextStyle(color: Colors.red[700]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTours,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                var tours = provider.tours;
                tours = _filterTours(tours);
                tours = _sortTours(tours);

                if (tours.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'Không tìm thấy tour nào',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await provider.refresh();
                  },
                  child: ListView.builder(
                    itemCount: tours.length,
                    itemBuilder: (context, index) {
                      final tour = tours[index];
                      return TourCard(
                        tour: tour,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TourDetailScreen(tour: tour),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: buildMainBottomNavigationBar(context, 0),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip(
            label: 'Sắp xếp: ${_sortOptions.firstWhere((e) => e['value'] == _selectedSort)['label']}',
            onTap: () => _showSortDialog(),
          ),
          const SizedBox(width: 8),
          if (_selectedDuration != null)
            _buildChip(
              label: _getDurationLabel(_selectedDuration!),
              onTap: () => setState(() => _selectedDuration = null),
              showClose: true,
            ),
          if (_selectedType != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildChip(
                label: _getTypeLabel(_selectedType!),
                onTap: () => setState(() => _selectedType = null),
                showClose: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required VoidCallback onTap,
    bool showClose = false,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (showClose) ...[
            const SizedBox(width: 4),
            const Icon(Icons.close, size: 16),
          ],
        ],
      ),
      selected: showClose,
      onSelected: (_) => onTap(),
      selectedColor: Colors.orange[100],
      checkmarkColor: Colors.orange[700],
    );
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sắp xếp theo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ..._sortOptions.map((option) {
                final isSelected = _selectedSort == option['value'];
                return ListTile(
                  title: Text(option['label']),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.orange)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedSort = option['value'];
                    });
                    Navigator.pop(context);
                    _applyFilters();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bộ lọc',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedDestination = 'Tất cả';
                              _selectedDuration = null;
                              _selectedType = null;
                            });
                          },
                          child: const Text('Đặt lại'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Địa điểm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _destinations.map((dest) {
                        final isSelected = _selectedDestination == dest;
                        return FilterChip(
                          label: Text(dest),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              _selectedDestination = dest;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Số ngày',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildDurationChip(1, '1-3 ngày', setModalState),
                        _buildDurationChip(2, '4-7 ngày', setModalState),
                        _buildDurationChip(3, '8+ ngày', setModalState),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Loại tour',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTypeChip(TourType.group, 'Tour nhóm', setModalState),
                        _buildTypeChip(TourType.private, 'Tour riêng', setModalState),
                        _buildTypeChip(TourType.selfGuided, 'Tự túc', setModalState),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Áp dụng bộ lọc'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDurationChip(int value, String label, StateSetter setModalState) {
    final isSelected = _selectedDuration == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          _selectedDuration = selected ? value : null;
        });
      },
    );
  }

  Widget _buildTypeChip(TourType type, String label, StateSetter setModalState) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          _selectedType = selected ? type : null;
        });
      },
    );
  }

  String _getDurationLabel(int duration) {
    switch (duration) {
      case 1:
        return '1-3 ngày';
      case 2:
        return '4-7 ngày';
      case 3:
        return '8+ ngày';
      default:
        return '';
    }
  }

  String _getTypeLabel(TourType type) {
    switch (type) {
      case TourType.group:
        return 'Tour nhóm';
      case TourType.private:
        return 'Tour riêng';
      case TourType.selfGuided:
        return 'Tự túc';
    }
  }
}
