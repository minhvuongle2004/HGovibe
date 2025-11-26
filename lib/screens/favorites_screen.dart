import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/main_bottom_nav.dart';
import '../providers/user_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/favorite_destination_card.dart';
import '../widgets/filter_chips_widget.dart';
import '../widgets/recommendation_banner_widget.dart';
import '../widgets/favorite_card_shimmer.dart';
import '../models/destination.dart';

enum SortOption { name, dateAdded, rating, price }

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String? _selectedFilter;
  bool _showRecommendationBanner = true;
  String? _recommendationCity;
  final TextEditingController _searchController = TextEditingController();
  SortOption _sortOption = SortOption.dateAdded;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _isSearching = _searchController.text.trim().isNotEmpty;
    });
  }

  void _loadFavorites() {
    final userProvider = context.read<UserProvider>();
    final favoritesProvider = context.read<FavoritesProvider>();
    
    if (userProvider.isLoggedIn && userProvider.user != null) {
      favoritesProvider.loadFavorites(userProvider.user!.uid);
      // Bắt đầu watch real-time
      favoritesProvider.startWatchingFavorites(userProvider.user!.uid);
      
      // Xác định city cho banner gợi ý (lấy từ favorite đầu tiên hoặc mặc định)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (favoritesProvider.favorites.isNotEmpty) {
          setState(() {
            _recommendationCity = favoritesProvider.favorites.first.location.city;
          });
        } else {
          setState(() {
            _recommendationCity = 'Hà Nội'; // Mặc định
          });
        }
      });
    }
  }

  List<String> _getFilterChips(List<Destination> favorites) {
    final chips = <String>[];
    final cities = <String>{};
    final categories = <String>{};

    for (final dest in favorites) {
      cities.add(dest.location.city);
      categories.add(dest.category);
    }

    chips.addAll(cities.toList()..sort());
    chips.addAll(categories.toList()..sort());

    return chips;
  }

  List<Destination> _getFilteredFavorites(List<Destination> favorites) {
    var filtered = favorites;

    // Filter theo chip
    if (_selectedFilter != null) {
      filtered = filtered.where((dest) {
      return dest.location.city == _selectedFilter ||
          dest.category == _selectedFilter;
    }).toList();
    }

    // Search filter
    if (_isSearching && _searchController.text.trim().isNotEmpty) {
      final query = _searchController.text.trim().toLowerCase();
      filtered = filtered.where((dest) {
        return dest.name.toLowerCase().contains(query) ||
            dest.location.city.toLowerCase().contains(query) ||
            dest.description.toLowerCase().contains(query) ||
            dest.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Sort
    filtered = _sortFavorites(filtered);

    return filtered;
  }

  List<Destination> _sortFavorites(List<Destination> favorites) {
    final sorted = List<Destination>.from(favorites);
    switch (_sortOption) {
      case SortOption.name:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.dateAdded:
        // Giữ nguyên thứ tự (đã được sort trong service theo addedAt)
        break;
      case SortOption.rating:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.price:
        sorted.sort((a, b) {
          final aPrice = a.entranceFee ?? 0;
          final bPrice = b.entranceFee ?? 0;
          return aPrice.compareTo(bPrice);
        });
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu thích'),
        centerTitle: true,
        actions: [
          // Nút sort
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sắp xếp',
            onPressed: () => _showSortDialog(context),
          ),
          // Nút add/folder (placeholder)
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: 'Thư mục',
            onPressed: () {
              // TODO: Implement add to folder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng thêm vào thư mục sẽ được thêm sau')),
              );
            },
          ),
        ],
      ),
      body: _buildBody(userProvider, favoritesProvider),
      bottomNavigationBar: buildMainBottomNavigationBar(context, 1),
    );
  }

  Widget _buildBody(UserProvider userProvider, FavoritesProvider favoritesProvider) {
    // Kiểm tra đăng nhập
    if (!userProvider.isLoggedIn) {
      return _buildNotLoggedInState();
    }

    // Loading state với shimmer
    if (favoritesProvider.isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => const FavoriteCardShimmer(),
      );
    }

    // Error state
    if (favoritesProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              favoritesProvider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (userProvider.user != null) {
                  favoritesProvider.refreshFavorites(userProvider.user!.uid);
                }
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final favorites = favoritesProvider.favorites;
    final filteredFavorites = _getFilteredFavorites(favorites);
    final filterChips = _getFilterChips(favorites);

    // Empty state
    if (favorites.isEmpty) {
      return _buildEmptyState();
    }

    // Có favorites
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm trong yêu thích...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ),
        // Filter chips
        if (filterChips.isNotEmpty)
          FilterChipsWidget(
            chips: filterChips,
            selectedChip: _selectedFilter,
            onChipSelected: (chip) {
              setState(() {
                _selectedFilter = _selectedFilter == chip ? null : chip;
              });
            },
            onFilterTap: () {
              // TODO: Show filter dialog
            },
          ),
        // Banner gợi ý
        if (_showRecommendationBanner && _recommendationCity != null)
          RecommendationBannerWidget(
            city: _recommendationCity!,
            onDismiss: () {
              setState(() {
                _showRecommendationBanner = false;
              });
            },
            onTap: () {
              // Navigate to home screen
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
        // Danh sách favorites với pull-to-refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (userProvider.user != null) {
                await favoritesProvider.refreshFavorites(userProvider.user!.uid);
              }
            },
          child: filteredFavorites.isEmpty
              ? _buildFilterEmptyState()
              : ListView.builder(
                  itemCount: filteredFavorites.length,
                  itemBuilder: (context, index) {
                    final destination = filteredFavorites[index];
                    return FavoriteDestinationCard(
                      destination: destination,
                        onRemove: () async {
                          if (userProvider.user != null) {
                            await favoritesProvider.toggleFavorite(
                              userId: userProvider.user!.uid,
                              destinationId: destination.id ?? '',
                            );
                          }
                        },
                      );
                    },
              ),
            ),
          ),
      ],
    );
  }

  /// UI khi chưa đăng nhập
  Widget _buildNotLoggedInState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Graphic: Trái tim màu cam lớn với ticket màu teal chèn vào
            Stack(
              alignment: Alignment.center,
              children: [
                // Trái tim màu cam
                Icon(
                  Icons.favorite,
                  size: 120,
                  color: Colors.orange,
                ),
                // Ticket màu teal chèn vào từ bên trái
                Positioned(
                  left: 20,
                  child: Transform.rotate(
                    angle: -0.1,
                    child: Container(
                      width: 80,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.confirmation_number,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Text
            const Text(
              'Hãy đăng nhập để xem danh sách yêu thích của mình',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            // Button "Đăng nhập"
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Đăng nhập',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state khi không có favorites
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có địa điểm yêu thích nào',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
                fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy khám phá và thêm các địa điểm bạn yêu thích',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              icon: const Icon(Icons.explore),
              label: const Text('Khám phá ngay'),
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
      ),
    );
  }

  /// Empty state khi filter không có kết quả
  Widget _buildFilterEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy địa điểm nào với bộ lọc "$_selectedFilter"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedFilter = null;
              });
            },
            child: const Text('Xóa bộ lọc'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sắp xếp theo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...SortOption.values.map((option) {
              final labels = {
                SortOption.name: 'Tên A-Z',
                SortOption.dateAdded: 'Mới thêm nhất',
                SortOption.rating: 'Đánh giá cao nhất',
                SortOption.price: 'Giá thấp nhất',
              };
              final isSelected = _sortOption == option;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.orange : Colors.grey,
                ),
                title: Text(labels[option]!),
                onTap: () {
                  setState(() {
                    _sortOption = option;
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    // Dừng watch favorites khi dispose
    final favoritesProvider = context.read<FavoritesProvider>();
    favoritesProvider.stopWatchingFavorites();
    super.dispose();
  }
}
