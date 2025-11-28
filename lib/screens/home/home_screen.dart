import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_app/models/destinations/destination.dart';
import 'package:smart_travel_app/providers/destinations/destination_provider.dart';
import 'package:smart_travel_app/providers/favorites/favorites_provider.dart';
import 'package:smart_travel_app/providers/auth/user_provider.dart';
import 'package:smart_travel_app/widgets/destinations/destination_card.dart';
import 'package:smart_travel_app/widgets/destinations/category_chip.dart';
import 'package:smart_travel_app/widgets/common/search_bar_widget.dart';
import 'package:smart_travel_app/widgets/destinations/destination_card_shimmer.dart';
import 'package:smart_travel_app/screens/destinations/destination_detail_screen.dart';
import 'package:smart_travel_app/widgets/common/main_bottom_nav.dart';
import 'package:smart_travel_app/services/destinations/recent_views_service.dart';
import 'package:smart_travel_app/utils/import_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final DestinationProvider _provider = DestinationProvider();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  int _selectedTabIndex = 0; // 0: Đề xuất, 1: Gần đây
  String? _selectedCategory;
  List<Destination> _recentDestinations = [];
  bool _isLoadingRecent = false;

  // Categories data
  final List<CategoryItem> _categories = [
    CategoryItem(
      id: 'ha_noi',
      label: 'Hà Nội',
      imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64',
    ),
    CategoryItem(
      id: 'phu_quoc',
      label: 'Phú Quốc',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e',
    ),
    CategoryItem(
      id: 'ha_long',
      label: 'Hạ Long',
      imageUrl: 'https://images.unsplash.com/photo-1559827260-dc66d52bef19',
    ),
    CategoryItem(
      id: 'da_lat',
      label: 'Đà Lạt',
      imageUrl: 'https://images.unsplash.com/photo-1583417319070-4a69db38a482',
    ),
    CategoryItem(
      id: 'hoi_an',
      label: 'Hội An',
      imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
    // Load favorites nếu user đã đăng nhập
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userProvider = context.read<UserProvider>();
      final favoritesProvider = context.read<FavoritesProvider>();
      if (userProvider.isLoggedIn && userProvider.user != null) {
        favoritesProvider.loadFavorites(userProvider.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    _provider.dispose();
    super.dispose();
  }

  void _loadData() {
    _provider.loadRecommendedDestinations(limit: 20);
    _provider.loadSeasonalDestinations(limit: 10);
    _loadRecentDestinations();
  }

  Future<void> _loadRecentDestinations() async {
    setState(() {
      _isLoadingRecent = true;
    });

    final recent = await RecentViewsService.getRecentDestinations(limit: 20);

    setState(() {
      _recentDestinations = recent;
      _isLoadingRecent = false;
    });
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _provider.searchDestinations(query);
      } else {
        _provider.clearSearch();
      }
    });
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      // Nếu tap lại category đang chọn, clear filter
      if (_selectedCategory == categoryId) {
        _selectedCategory = null;
        // Reload recommended destinations
        _provider.loadRecommendedDestinations(limit: 20);
      } else {
        _selectedCategory = categoryId;
        // Map category ID to city name
        final categoryMap = {
          'ha_noi': 'Hà Nội',
          'phu_quoc': 'Phú Quốc',
          'ha_long': 'Hạ Long',
          'da_lat': 'Đà Lạt',
          'hoi_an': 'Hội An',
        };

        final city = categoryMap[categoryId];
        if (city != null) {
          _provider.loadDestinationsByCity(city, limit: 20);
        }
      }
    });
  }

  void _onDestinationTap(Destination destination) async {
    // Lưu vào recent views
    await RecentViewsService.addRecentView(destination);

    // Reload recent nếu đang ở tab "Gần đây"
    if (_selectedTabIndex == 1) {
      _loadRecentDestinations();
    }

    // Navigate đến màn chi tiết địa điểm với smooth transition
    if (!mounted) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DestinationDetailScreen(destination: destination),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            SearchBarWidget(
              hintText: 'tràng an',
              controller: _searchController,
              onChanged: (value) {
                // Search được handle trong _onSearchChanged
              },
              onShoppingCartTap: () {
                // TODO: Navigate to shopping cart
              },
              onNotificationTap: () {
                // TODO: Navigate to notifications
              },
            ),

            // Main Content với Pull-to-Refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _provider.refresh();
                  await _provider.loadSeasonalDestinations();
                  await _loadRecentDestinations();
                },
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: buildMainBottomNavigationBar(context, 0),
    );
  }

  Widget _buildContent() {
    // Nếu đang search, hiển thị kết quả search
    // Sử dụng ValueListenableBuilder để rebuild khi search text thay đổi
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _searchController,
      builder: (context, value, child) {
        if (value.text.trim().isNotEmpty) {
          return _buildSearchResults();
        }

        // Nếu không search, hiển thị content bình thường
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section: "Bạn muốn đi đâu chơi?"
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bạn muốn đi đâu chơi?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to all categories
                      },
                      child: const Text(
                        'Xem thêm',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Category Chips
              CategoryChipList(
                categories: _categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: _onCategorySelected,
              ),

              const SizedBox(height: 24),

              // Section: Gợi ý theo mùa
              _buildSeasonalSection(),

              const SizedBox(height: 24),

              // Section: Gợi ý theo tags
              _buildTagsSection(),

              const SizedBox(height: 16),

              // Tabs: Đề xuất | Gần đây
              _buildTabs(),

              const SizedBox(height: 8),

              // Content theo tab
              _buildTabContent(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: 'Đề xuất',
              index: 0,
              isSelected: _selectedTabIndex == 0,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: 'Gần đây',
              index: 1,
              isSelected: _selectedTabIndex == 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
        if (index == 1) {
          _loadRecentDestinations();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_selectedTabIndex == 0) {
      // Tab "Đề xuất"
      return _buildRecommendedList();
    } else {
      // Tab "Gần đây"
      return _buildRecentList();
    }
  }

  Widget _buildRecommendedList() {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, child) {
        if (_provider.isLoading) {
          // Shimmer skeleton loaders
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3, // Hiển thị 3 skeleton cards
            itemBuilder: (context, index) {
              return const DestinationCardShimmer();
            },
          );
        }

        if (_provider.error != null) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    _provider.error!,
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_selectedCategory != null) {
                        // Reload theo category nếu đang filter
                        final categoryMap = {
                          'ha_noi': 'Hà Nội',
                          'phu_quoc': 'Phú Quốc',
                          'ha_long': 'Hạ Long',
                          'da_lat': 'Đà Lạt',
                          'hoi_an': 'Hội An',
                        };
                        final city = categoryMap[_selectedCategory];
                        if (city != null) {
                          _provider.loadDestinationsByCity(city);
                        }
                      } else {
                        _provider.loadRecommendedDestinations();
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        // Nếu có category được chọn, hiển thị filtered destinations
        // Ngược lại, hiển thị recommended destinations
        final destinations = _selectedCategory != null
            ? _provider.destinations
            : _provider.recommendedDestinations;

        if (destinations.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.explore_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có địa điểm nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vui lòng import data vào Firestore',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Show loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        await ImportData.importAllDestinations();
                        if (mounted) {
                          Navigator.pop(context); // Close loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Import data thành công!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Reload data
                          _provider.loadRecommendedDestinations();
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.pop(context); // Close loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Lỗi import: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Import Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Confirm dialog
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xóa Duplicates'),
                          content: const Text(
                            'Bạn có chắc muốn xóa các destinations trùng lặp?\n\n'
                            'Script sẽ giữ lại document cũ nhất trong mỗi nhóm duplicates.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hủy'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Xóa'),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      // Show loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        await ImportData.removeDuplicateDestinations();
                        if (mounted) {
                          Navigator.pop(context); // Close loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Đã xóa duplicates thành công!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Reload data
                          _provider.loadRecommendedDestinations();
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.pop(context); // Close loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Lỗi xóa duplicates: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Xóa Duplicates'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: destinations.length,
          itemBuilder: (context, index) {
            final destination = destinations[index];
            return DestinationCard(
              destination: destination,
              onTap: () => _onDestinationTap(destination),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentList() {
    if (_isLoadingRecent) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recentDestinations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Chưa có địa điểm nào được xem gần đây',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _recentDestinations.length,
      itemBuilder: (context, index) {
        final destination = _recentDestinations[index];
        return DestinationCard(
          destination: destination,
          onTap: () => _onDestinationTap(destination),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, child) {
        if (_provider.isSearching) {
          // Shimmer skeleton khi đang search
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: 3,
            itemBuilder: (context, index) {
              return const DestinationCardShimmer();
            },
          );
        }

        final results = _provider.searchResults;
        if (results.isEmpty && _searchController.text.trim().isNotEmpty) {
          // Empty state khi không có kết quả
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy kết quả cho "${_searchController.text}"',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Thử tìm kiếm với từ khóa khác',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final destination = results[index];
            return DestinationCard(
              destination: destination,
              onTap: () => _onDestinationTap(destination),
            );
          },
        );
      },
    );
  }

  Widget _buildSeasonalSection() {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, child) {
        final currentMonth = DateTime.now().month;
        final monthNames = [
          'Tháng 1',
          'Tháng 2',
          'Tháng 3',
          'Tháng 4',
          'Tháng 5',
          'Tháng 6',
          'Tháng 7',
          'Tháng 8',
          'Tháng 9',
          'Tháng 10',
          'Tháng 11',
          'Tháng 12',
        ];

        if (_provider.isLoadingSeasonal) {
          // Shimmer skeleton cho seasonal section
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Gợi ý ${monthNames[currentMonth - 1]}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      child: const DestinationCardShimmer(isCompact: true),
                    );
                  },
                ),
              ),
            ],
          );
        }

        final seasonalDestinations = _provider.seasonalDestinations;
        if (seasonalDestinations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Gợi ý ${monthNames[currentMonth - 1]}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.2, // Giảm line height
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ), // Khoảng cách hợp lý giữa heading và cards
            SizedBox(
              height: 210, // Giảm từ 320 xuống 210 để loại bỏ khoảng trống
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  8,
                ), // Thêm bottom padding 8px để không bị che
                itemCount: seasonalDestinations.length,
                itemBuilder: (context, index) {
                  final destination = seasonalDestinations[index];
                  return Container(
                    width: 200,
                    margin: EdgeInsets.only(
                      right: index == seasonalDestinations.length - 1
                          ? 0
                          : 12, // Không margin cho item cuối
                    ),
                    child: _buildCompactDestinationCard(destination),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTagsSection() {
    // Popular tags
    final popularTags = [
      {'tag': 'lịch sử', 'icon': Icons.history, 'label': 'Lịch sử'},
      {'tag': 'văn hóa', 'icon': Icons.museum, 'label': 'Văn hóa'},
      {'tag': 'thiên nhiên', 'icon': Icons.nature, 'label': 'Thiên nhiên'},
      {'tag': 'check-in', 'icon': Icons.camera_alt, 'label': 'Check-in'},
      {'tag': 'ẩm thực', 'icon': Icons.restaurant, 'label': 'Ẩm thực'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.local_offer, size: 20, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Khám phá theo chủ đề',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Tag chips
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: popularTags.length,
            itemBuilder: (context, index) {
              final tagData = popularTags[index];
              final isSelected = _provider.selectedTag == tagData['tag'];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(tagData['label'] as String),
                  avatar: Icon(tagData['icon'] as IconData, size: 18),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _provider.loadDestinationsByTag(
                        tagData['tag'] as String,
                        limit: 10,
                      );
                    } else {
                      _provider.clearTagFilter();
                    }
                  },
                  selectedColor: Colors.orange[100],
                  checkmarkColor: Colors.orange[700],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.orange[700] : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
        // Tag destinations list - Luôn hiển thị khi có tag được chọn
        ListenableBuilder(
          listenable: _provider,
          builder: (context, child) {
            // Chỉ hiển thị khi có tag được chọn
            if (_provider.selectedTag == null) {
              return const SizedBox.shrink();
            }

            if (_provider.isLoadingTags) {
              // Shimmer skeleton cho tag destinations
              return SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      child: const DestinationCardShimmer(isCompact: true),
                    );
                  },
                ),
              );
            }

            if (_provider.tagDestinations.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'Không tìm thấy địa điểm nào với tag "${_provider.selectedTag}"',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 210, // Giống với seasonal section
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  8,
                ), // Thêm bottom padding
                itemCount: _provider.tagDestinations.length,
                itemBuilder: (context, index) {
                  final destination = _provider.tagDestinations[index];
                  return Container(
                    width: 200,
                    margin: EdgeInsets.only(
                      right: index == _provider.tagDestinations.length - 1
                          ? 0
                          : 12,
                    ),
                    child: _buildCompactDestinationCard(destination),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  /// Build compact destination card cho horizontal lists
  Widget _buildCompactDestinationCard(Destination destination) {
    return Card(
      margin: EdgeInsets.zero, // Không có margin để tránh khoảng trống
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Clip để tránh overflow
      child: InkWell(
        onTap: () => _onDestinationTap(destination),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hình ảnh thumbnail (nhỏ hơn)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: destination.thumbnail,
                    width: double.infinity,
                    height: 130, // Giảm từ 140 xuống 130
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: double.infinity,
                      height: 130,
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: double.infinity,
                      height: 130,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  // Location tag overlay
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[700]?.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              destination.location.city,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Thông tin destination (compact)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                10,
                8,
                10,
                8,
              ), // Giảm top padding từ 10 xuống 8
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title (1 dòng thôi)
                  Text(
                    destination.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.1, // Giảm line height xuống 1.1
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4), // Giảm từ 6 xuống 4
                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14, // Giảm từ 16 xuống 14
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 3), // Giảm từ 4 xuống 3
                      Flexible(
                        child: Text(
                          '${destination.rating.toStringAsFixed(1)}(${_formatReviewCount(destination.reviewCount)})',
                          style: TextStyle(
                            fontSize: 11, // Giảm từ 12 xuống 11
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                            height: 1.0, // Giảm line height
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
