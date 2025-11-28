import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_travel_app/models/destinations/destination.dart';
import 'package:smart_travel_app/models/trips/trip.dart';
import 'package:smart_travel_app/providers/auth/user_provider.dart';
import 'package:smart_travel_app/providers/trips/trip_provider.dart';
import 'package:smart_travel_app/services/destinations/destination_service.dart';

class AddDestinationsToTripScreen extends StatefulWidget {
  final String tripId;
  final Trip? trip;

  const AddDestinationsToTripScreen({
    super.key,
    required this.tripId,
    this.trip,
  });

  @override
  State<AddDestinationsToTripScreen> createState() =>
      _AddDestinationsToTripScreenState();
}

class _AddDestinationsToTripScreenState
    extends State<AddDestinationsToTripScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Destination> _destinations = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    setState(() => _isLoading = true);
    try {
      final results = await DestinationService.getAllDestinations(limit: 40);
      setState(() => _destinations = results);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchDestinations(String query) async {
    if (query.trim().isEmpty) {
      _loadDestinations();
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await DestinationService.searchDestinations(query);
      setState(() => _destinations = results);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _addDestination(Destination destination) async {
    if (destination.id == null || destination.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Điểm đến này chưa có ID hợp lệ')),
      );
      return;
    }
    final user = context.read<UserProvider>().user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để thêm điểm đến')),
      );
      return;
    }

    final tripProvider = context.read<TripProvider>();
    try {
      await tripProvider.addDestinationToTrip(
        user.uid,
        widget.tripId,
        destination.id!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm ${destination.name} vào kế hoạch')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể thêm điểm đến: $error')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm điểm đến')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm địa điểm, ví dụ: Hội An',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadDestinations();
                        },
                      ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _searchDestinations,
            ),
          ),
          if (_isSearching) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _destinations.isEmpty
                    ? const Center(child: Text('Không tìm thấy địa điểm phù hợp'))
                    : ListView.builder(
                        itemCount: _destinations.length,
                        itemBuilder: (context, index) {
                          final destination = _destinations[index];
                          return ListTile(
                            leading: const Icon(Icons.place),
                            title: Text(destination.name),
                            subtitle: Text(
                              destination.location.city.isNotEmpty
                                  ? '${destination.location.city}, ${destination.location.country}'
                                  : destination.location.country,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => _addDestination(destination),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
