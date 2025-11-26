import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/main_bottom_nav.dart';
import '../providers/trip_provider.dart';
import '../providers/user_provider.dart';
import '../models/trip.dart';
import '../widgets/trip_card.dart';
import 'create_trip_screen.dart';
import 'trip_detail_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  String? _selectedFilter; // 'all', 'upcoming', 'ongoing', 'completed'

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips() {
    final userProvider = context.read<UserProvider>();
    final tripProvider = context.read<TripProvider>();
    
    if (userProvider.isLoggedIn && userProvider.user != null) {
      tripProvider.loadTrips(userProvider.user!.uid);
      tripProvider.startWatchingTrips(userProvider.user!.uid);
    }
  }

  List<Trip> _getFilteredTrips(List<Trip> trips) {
    if (_selectedFilter == null || _selectedFilter == 'all') {
      return trips;
    }

    return trips.where((trip) {
      switch (_selectedFilter) {
        case 'upcoming':
          return trip.isUpcoming;
        case 'ongoing':
          return trip.isOngoing;
        case 'completed':
          return trip.isPast;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final tripProvider = context.watch<TripProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuyến đi'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateTripScreen(),
                ),
              );
            },
            tooltip: 'Tạo kế hoạch mới',
          ),
        ],
      ),
      body: _buildBody(userProvider, tripProvider),
      bottomNavigationBar: buildMainBottomNavigationBar(context, 3),
    );
  }

  Widget _buildBody(UserProvider userProvider, TripProvider tripProvider) {
    // Kiểm tra đăng nhập
    if (!userProvider.isLoggedIn) {
      return _buildNotLoggedInState();
    }

    // Loading state
    if (tripProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state
    if (tripProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              tripProvider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (userProvider.user != null) {
                  tripProvider.loadTrips(userProvider.user!.uid);
                }
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final trips = tripProvider.trips;
    final filteredTrips = _getFilteredTrips(trips);

    // Empty state
    if (trips.isEmpty) {
      return _buildEmptyState();
    }

    // Có trips
    return Column(
      children: [
        // Filter chips
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildFilterChip('Tất cả', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Sắp tới', 'upcoming'),
              const SizedBox(width: 8),
              _buildFilterChip('Đang diễn ra', 'ongoing'),
              const SizedBox(width: 8),
              _buildFilterChip('Đã hoàn thành', 'completed'),
            ],
          ),
        ),
        // Danh sách trips
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (userProvider.user != null) {
                await tripProvider.loadTrips(userProvider.user!.uid);
              }
            },
            child: filteredTrips.isEmpty
                ? _buildFilterEmptyState()
                : ListView.builder(
                    itemCount: filteredTrips.length,
                    itemBuilder: (context, index) {
                      final trip = filteredTrips[index];
                      return TripCard(
                        trip: trip,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TripDetailScreen(
                                tripId: trip.id!,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : null;
        });
      },
      selectedColor: Colors.orange.withOpacity(0.2),
      checkmarkColor: Colors.orange,
      labelStyle: TextStyle(
        color: isSelected ? Colors.orange : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildNotLoggedInState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.luggage,
              size: 120,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 32),
            const Text(
              'Hãy đăng nhập để tạo và quản lý kế hoạch chuyến đi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.luggage_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có kế hoạch chuyến đi nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy tạo kế hoạch mới để bắt đầu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateTripScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo kế hoạch mới'),
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
            'Không tìm thấy kế hoạch nào với bộ lọc này',
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

  @override
  void dispose() {
    final tripProvider = context.read<TripProvider>();
    tripProvider.stopWatchingTrips();
    super.dispose();
  }
}


