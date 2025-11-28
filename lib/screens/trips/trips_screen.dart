import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_travel_app/models/trips/trip.dart';
import 'package:smart_travel_app/providers/auth/user_provider.dart';
import 'package:smart_travel_app/providers/trips/trip_provider.dart';
import 'package:smart_travel_app/screens/trips/create_trip_screen.dart';
import 'package:smart_travel_app/screens/trips/trip_detail/trip_detail_screen.dart';
import 'package:smart_travel_app/widgets/trips/trip_card.dart';
import 'package:smart_travel_app/widgets/common/main_bottom_nav.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      final tripProvider = context.read<TripProvider>();
      final user = userProvider.user;
      if (user != null) {
        tripProvider.loadTrips(user.uid);
        tripProvider.startWatchingTrips(user.uid);
      }
    });
  }

  @override
  void dispose() {
    context.read<TripProvider>().stopWatchingTrips();
    super.dispose();
  }

  Future<void> _refreshTrips() async {
    final user = context.read<UserProvider>().user;
    if (user != null) {
      await context.read<TripProvider>().loadTrips(user.uid);
    }
  }

  void _openCreateTrip() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTripScreen()),
    );
  }

  void _openTripDetail(String tripId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripDetailScreen(tripId: tripId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final tripProvider = context.watch<TripProvider>();

    final user = userProvider.user;
    final isLoading = tripProvider.isLoading;
    final trips = tripProvider.trips;

    Widget body;
    if (user == null) {
      body = const Center(
        child: Text('Vui lòng đăng nhập để xem các kế hoạch của bạn.'),
      );
    } else if (isLoading && trips.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (trips.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.travel_explore, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Bạn chưa có kế hoạch nào. Hãy tạo kế hoạch đầu tiên ngay!',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _openCreateTrip,
                icon: const Icon(Icons.add),
                label: const Text('Tạo kế hoạch'),
              ),
            ],
          ),
        ),
      );
    } else {
      final groupedTrips = _groupTrips(trips);
      body = RefreshIndicator(
        onRefresh: _refreshTrips,
        child: ListView(
          children: [
            if (groupedTrips.upcoming.isNotEmpty) ...[
              _TripSectionHeader(title: 'Sắp tới'),
              ...groupedTrips.upcoming.map(
                (trip) => TripCard(
                  trip: trip,
                  onTap: () => _openTripDetail(trip.id!),
                ),
              ),
            ],
            if (groupedTrips.ongoing.isNotEmpty) ...[
              _TripSectionHeader(title: 'Đang diễn ra'),
              ...groupedTrips.ongoing.map(
                (trip) => TripCard(
                  trip: trip,
                  onTap: () => _openTripDetail(trip.id!),
                ),
              ),
            ],
            if (groupedTrips.completed.isNotEmpty) ...[
              _TripSectionHeader(title: 'Đã hoàn thành'),
              ...groupedTrips.completed.map(
                (trip) => TripCard(
                  trip: trip,
                  onTap: () => _openTripDetail(trip.id!),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kế hoạch của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTrips,
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: buildMainBottomNavigationBar(context, 3),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton(
              onPressed: _openCreateTrip,
              child: const Icon(Icons.add),
            ),
    );
  }

  _TripGrouping _groupTrips(List<Trip> trips) {
    final upcoming = <Trip>[];
    final ongoing = <Trip>[];
    final completed = <Trip>[];
    for (final trip in trips) {
      switch (trip.status) {
        case TripStatus.upcoming:
          upcoming.add(trip);
          break;
        case TripStatus.ongoing:
          ongoing.add(trip);
          break;
        case TripStatus.completed:
          completed.add(trip);
          break;
      }
    }
    return _TripGrouping(upcoming, ongoing, completed);
  }
}

class _TripGrouping {
  final List<Trip> upcoming;
  final List<Trip> ongoing;
  final List<Trip> completed;

  const _TripGrouping(this.upcoming, this.ongoing, this.completed);
}

class _TripSectionHeader extends StatelessWidget {
  final String title;

  const _TripSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

