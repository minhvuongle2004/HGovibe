import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_app/models/destinations/destination.dart';
import 'package:smart_travel_app/models/tours/tour_package.dart';
import 'package:smart_travel_app/providers/destinations/destination_provider.dart';
import 'package:smart_travel_app/providers/tours/tour_package_provider.dart';
import 'package:smart_travel_app/providers/favorites/favorites_provider.dart';
import 'package:smart_travel_app/providers/auth/user_provider.dart';
import 'package:smart_travel_app/widgets/common/search_bar_widget.dart';
import 'package:smart_travel_app/widgets/tours/featured_tours_carousel.dart';
import 'package:smart_travel_app/widgets/tours/tours_horizontal_list.dart';
import 'package:smart_travel_app/widgets/common/quick_actions_section.dart';
import 'package:smart_travel_app/widgets/destinations/destinations_preview_section.dart';
import 'package:smart_travel_app/screens/destinations/destination_detail_screen.dart';
import 'package:smart_travel_app/screens/tours/tour_detail_screen.dart';
import 'package:smart_travel_app/screens/tours/tours_screen.dart';
import 'package:smart_travel_app/screens/trips/create_trip_screen.dart';
import 'package:smart_travel_app/widgets/common/main_bottom_nav.dart';
import 'package:smart_travel_app/services/destinations/recent_views_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DestinationProvider _destinationProvider = DestinationProvider();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

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
    _destinationProvider.dispose();
    super.dispose();
  }

  void _loadData() {
    // Load tours
    final tourProvider = context.read<TourPackageProvider>();
    tourProvider.loadFeaturedTours(limit: 5);
    tourProvider.loadTours(status: TourStatus.active, limit: 10);

    // Load destinations
    _destinationProvider.loadRecommendedDestinations(limit: 6);
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _destinationProvider.searchDestinations(query);
      } else {
        _destinationProvider.clearSearch();
      }
    });
  }

  void _onTourTap(TourPackage tour) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TourDetailScreen(tour: tour),
      ),
    );
  }

  void _onDestinationTap(Destination destination) async {
    // Lưu vào recent views
    await RecentViewsService.addRecentView(destination);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DestinationDetailScreen(destination: destination),
      ),
    );
  }

  void _onBookTour() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ToursScreen()),
    );
  }

  void _onCreatePlan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTripScreen()),
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
              hintText: 'Tìm kiếm tours hoặc địa điểm...',
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

            // Main Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _destinationProvider.refresh();
                  final tourProvider = context.read<TourPackageProvider>();
                  await tourProvider.loadFeaturedTours(limit: 5);
                  await tourProvider.refresh();
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
              // Section 1: Featured Tours Carousel
              Consumer<TourPackageProvider>(
                builder: (context, tourProvider, child) {
                  if (tourProvider.isLoading && tourProvider.featuredTours.isEmpty) {
                    return const SizedBox(
                      height: 280,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (tourProvider.error != null) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Lỗi: ${tourProvider.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (tourProvider.featuredTours.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return FeaturedToursCarousel(
                    tours: tourProvider.featuredTours,
                    onTourTap: _onTourTap,
                  );
                },
              ),

              const SizedBox(height: 16),

              // Section 2: Quick Actions
              QuickActionsSection(
                onBookTour: _onBookTour,
                onCreatePlan: _onCreatePlan,
              ),

              const SizedBox(height: 16),

              // Section 3: Tours mới nhất
              Consumer<TourPackageProvider>(
                builder: (context, tourProvider, child) {
                  if (tourProvider.isLoading && tourProvider.tours.isEmpty) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (tourProvider.error != null) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Lỗi: ${tourProvider.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (tourProvider.tours.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return ToursHorizontalList(
                    tours: tourProvider.tours,
                    onTourTap: _onTourTap,
                  );
                },
              ),

              const SizedBox(height: 24),

              // Section 4: Destinations Preview (Thu gọn)
              ListenableBuilder(
                listenable: _destinationProvider,
                builder: (context, child) {
                  if (_destinationProvider.isLoading &&
                      _destinationProvider.recommendedDestinations.isEmpty) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return DestinationsPreviewSection(
                    destinations: _destinationProvider.recommendedDestinations,
                    onDestinationTap: _onDestinationTap,
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return ListenableBuilder(
      listenable: _destinationProvider,
      builder: (context, child) {
        if (_destinationProvider.isSearching) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = _destinationProvider.searchResults;
        if (results.isEmpty && _searchController.text.trim().isNotEmpty) {
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
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final destination = results[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    destination.thumbnail,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported),
                  ),
                ),
                title: Text(destination.name),
                subtitle: Text(destination.location.city),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _onDestinationTap(destination),
              ),
            );
          },
        );
      },
    );
  }
}

