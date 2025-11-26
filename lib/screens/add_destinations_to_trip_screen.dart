import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/trip_provider.dart';
import '../providers/user_provider.dart';
import '../providers/destination_provider.dart';
import '../models/trip.dart';
import '../models/destination.dart';
import '../services/trip_validation_service.dart';
import '../widgets/distance_warning_dialog.dart';
import 'trip_detail_screen.dart';

class AddDestinationsToTripScreen extends StatefulWidget {
  final String tripId;
  final Trip? trip; // Thêm trip để lấy startDate và endDate

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
  final Map<String, DateTime?> _selectedDates = {}; // destinationId -> plannedDate
  final Map<String, TimeOfDay?> _selectedTimes = {}; // destinationId -> plannedTime
  final DestinationProvider _destinationProvider = DestinationProvider();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDestinations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _destinationProvider.dispose();
    super.dispose();
  }

  void _loadDestinations() {
    _destinationProvider.loadRecommendedDestinations(limit: 50);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _destinationProvider.searchDestinations(query);
    } else {
      _destinationProvider.clearSearch();
    }
  }

  Future<void> _selectDate(String destinationId) async {
    final trip = widget.trip ?? context.read<TripProvider>().currentTrip;
    if (trip == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDates[destinationId] ?? trip.startDate,
      firstDate: trip.startDate,
      lastDate: trip.endDate,
    );
    if (picked != null) {
      setState(() {
        _selectedDates[destinationId] = picked;
      });
    }
  }

  Future<void> _selectTime(String destinationId) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[destinationId] ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _selectedTimes[destinationId] = picked;
      });
    }
  }

  Future<void> _addDestinationsToTrip() async {
    // Kiểm tra tất cả destinations đã chọn đều có ngày
    final missingDates = <String>[];
    for (final destinationId in _selectedDates.keys) {
      if (_selectedDates[destinationId] == null) {
        missingDates.add(destinationId);
      }
    }

    if (missingDates.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày cho tất cả điểm đến đã chọn'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    final tripProvider = context.read<TripProvider>();

    if (!userProvider.isLoggedIn || userProvider.user == null) {
      return;
    }

    final trip = widget.trip ?? tripProvider.currentTrip;
    if (trip == null) return;

    // Validate từng destination trước khi thêm
    final validationService = TripValidationService.instance;
    final destinationsToAdd = <MapEntry<String, DateTime>>[];

    // Lấy thông tin destinations từ provider
    final allDestinations = _destinationProvider.searchResults.isNotEmpty
        ? _destinationProvider.searchResults
        : _destinationProvider.recommendedDestinations;

    // Show loading khi đang validate
    if (mounted && _selectedDates.length > 1) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      // Validate từng destination
      for (final entry in _selectedDates.entries) {
        final destinationId = entry.key;
        final plannedDate = entry.value;
      
      if (plannedDate == null) continue; // Skip nếu không có ngày

      // Tìm destination object
      final destination = allDestinations.firstWhere(
        (d) => d.id == destinationId,
        orElse: () => throw Exception('Destination not found: $destinationId'),
      );

      // Validate destination
      final validationResult = await validationService.validateDestination(
        destination,
        trip.items,
        trip.daysCount,
        plannedDate: plannedDate,
      );

      if (!validationResult.isValid) {
        // Hiển thị dialog cảnh báo
        final shouldContinue = await _showValidationDialog(
          destination,
          validationResult,
        );

        if (shouldContinue == true) {
          // User chọn "Vẫn tiếp tục"
          destinationsToAdd.add(MapEntry(destinationId, plannedDate));
        } else if (shouldContinue == false) {
          // User chọn "Hủy" hoặc đóng dialog
          return;
        }
        // shouldContinue == null: User chọn suggestion (đã được xử lý trong dialog)
      } else {
        // Validation pass, thêm vào danh sách
        destinationsToAdd.add(MapEntry(destinationId, plannedDate));
      }
      }

      // Close validation loading
      if (mounted && _selectedDates.length > 1) {
        Navigator.pop(context);
      }

      if (destinationsToAdd.isEmpty) {
        return; // Không có điểm nào để thêm
      }

      // Show loading khi đang thêm
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Thêm từng destination với ngày và giờ
      for (final entry in destinationsToAdd) {
        final destinationId = entry.key;
        final plannedDate = entry.value;
        final plannedTime = _selectedTimes[destinationId];

        // Thêm item với ngày và giờ
        await tripProvider.addDestinationToTripWithDetails(
          userProvider.user!.uid,
          widget.tripId,
          destinationId,
          plannedDate: plannedDate,
          plannedTime: plannedTime,
        );
      }

      if (mounted) {
        Navigator.pop(context); // Close loading
        
        // Reload weather forecasts để cập nhật ngày mới
        await tripProvider.loadWeatherForecasts(
          userProvider.user!.uid,
          widget.tripId,
        );
        
        // Navigate to trip detail
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TripDetailScreen(
              tripId: widget.tripId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Hiển thị dialog validation và trả về kết quả
  /// Returns: true nếu user chọn "Vẫn tiếp tục", false nếu "Hủy", null nếu chọn suggestion
  Future<bool?> _showValidationDialog(
    Destination destination,
    ValidationResult validationResult,
  ) async {
    bool? result;

    await DistanceWarningDialog.show(
      context,
      validationResult: validationResult,
      targetDestination: destination,
      onContinue: () {
        result = true;
      },
      onCancel: () {
        result = false;
      },
      onSelectSuggestion: (suggestedDestination) {
        // Thay thế destination hiện tại bằng suggestion
        final destinationId = destination.id ?? '';
        final suggestedId = suggestedDestination.id ?? '';

        if (destinationId.isNotEmpty && suggestedId.isNotEmpty) {
          setState(() {
            // Xóa destination cũ
            _selectedDates.remove(destinationId);
            _selectedTimes.remove(destinationId);

            // Thêm suggestion với cùng ngày (nếu có)
            final originalDate = _selectedDates[destinationId];
            if (originalDate != null) {
              _selectedDates[suggestedId] = originalDate;
              final originalTime = _selectedTimes[destinationId];
              if (originalTime != null) {
                _selectedTimes[suggestedId] = originalTime;
              }
            }
          });

          // Hiển thị thông báo
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thay thế "${destination.name}" bằng "${suggestedDestination.name}"'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        result = null; // Đã xử lý suggestion
      },
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm điểm đến'),
        actions: [
          if (_selectedDates.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  'Đã chọn: ${_selectedDates.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm điểm đến...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          // List destinations
          Expanded(
            child: ListenableBuilder(
              listenable: _destinationProvider,
              builder: (context, child) {
                if (_destinationProvider.isSearching) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final destinations = _destinationProvider.searchResults.isNotEmpty
                    ? _destinationProvider.searchResults
                    : _destinationProvider.recommendedDestinations;

                if (destinations.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy điểm đến nào'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: destinations.length,
                  itemBuilder: (context, index) {
                    final destination = destinations[index];
                    final destinationId = destination.id ?? '';
                    final isSelected = _selectedDates.containsKey(destinationId);
                    final selectedDate = _selectedDates[destinationId];
                    final selectedTime = _selectedTimes[destinationId];
                    final dateFormat = DateFormat('dd/MM/yyyy');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: Text(destination.name),
                            subtitle: Text(
                              '${destination.location.city} • ⭐ ${destination.rating.toStringAsFixed(1)}',
                            ),
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedDates[destinationId] = null; // Reset để user phải chọn
                                  _selectedTimes[destinationId] = null;
                                } else {
                                  _selectedDates.remove(destinationId);
                                  _selectedTimes.remove(destinationId);
                                }
                              });
                            },
                            secondary: destination.thumbnail.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      destination.thumbnail,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.image),
                                    ),
                                  )
                                : const Icon(Icons.place),
                          ),
                          // Date and time pickers (chỉ hiển thị khi đã chọn)
                          if (isSelected) ...[
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  // Date picker
                                  InkWell(
                                    onTap: () => _selectDate(destinationId),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: selectedDate != null
                                              ? Colors.orange
                                              : (Colors.grey[300] ?? Colors.grey),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 20,
                                            color: selectedDate != null
                                                ? Colors.orange
                                                : Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              selectedDate != null
                                                  ? dateFormat.format(selectedDate)
                                                  : 'Chọn ngày *',
                                              style: TextStyle(
                                                color: selectedDate != null
                                                    ? Colors.black87
                                                    : Colors.grey[600],
                                                fontWeight: selectedDate != null
                                                    ? FontWeight.w500
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Time picker (optional)
                                  InkWell(
                                    onTap: () => _selectTime(destinationId),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: selectedTime != null
                                              ? Colors.orange
                                              : (Colors.grey[300] ?? Colors.grey),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 20,
                                            color: selectedTime != null
                                                ? Colors.orange
                                                : Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              selectedTime != null
                                                  ? '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'
                                                  : 'Chọn giờ (tùy chọn)',
                                              style: TextStyle(
                                                color: selectedTime != null
                                                    ? Colors.black87
                                                    : Colors.grey[600],
                                                fontWeight: selectedTime != null
                                                    ? FontWeight.w500
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Bottom button
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addDestinationsToTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _selectedDates.isEmpty
                      ? 'Chọn điểm đến'
                      : 'Thêm ${_selectedDates.length} điểm đến',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
