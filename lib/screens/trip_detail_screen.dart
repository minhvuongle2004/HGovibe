import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/trip_provider.dart';
import '../providers/user_provider.dart';
import '../models/trip.dart';
import '../models/trip_item.dart';
import '../widgets/trip_timeline_item.dart';
import '../widgets/weather_forecast_card.dart';
import '../widgets/cost_breakdown_widget.dart';
import 'add_destinations_to_trip_screen.dart';
import 'edit_trip_item_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;

  const TripDetailScreen({
    super.key,
    required this.tripId,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  int _selectedTabIndex = 0; // 0: Lịch trình, 1: Chi phí, 2: Thời tiết, 3: Gợi ý AI

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  void _loadTrip() async {
    final userProvider = context.read<UserProvider>();
    final tripProvider = context.read<TripProvider>();

    if (userProvider.isLoggedIn && userProvider.user != null) {
      // Đợi setCurrentTrip hoàn thành để load costEstimate từ Firestore
      await tripProvider.setCurrentTrip(userProvider.user!.uid, widget.tripId);
      // Load weather forecasts
      tripProvider.loadWeatherForecasts(userProvider.user!.uid, widget.tripId);
      // KHÔNG tự động estimate cost nữa - chỉ estimate khi user click nút
      // costEstimate đã được load từ Firestore trong setCurrentTrip
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final tripProvider = context.watch<TripProvider>();
    final trip = tripProvider.currentTrip;

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết kế hoạch'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.name),
        actions: [
          // Nút tính toán lại chi phí (chỉ hiển thị ở tab Chi phí)
          if (_selectedTabIndex == 1)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Tính toán lại chi phí',
              onPressed: () {
                final userProvider = context.read<UserProvider>();
                final tripProvider = context.read<TripProvider>();
                if (userProvider.user != null) {
                  // Reset costEstimate trước khi tính lại
                  tripProvider.resetCostMultiplier();
                  tripProvider.estimateCost(userProvider.user!.uid, widget.tripId);
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng chỉnh sửa sẽ được thêm sau')),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa kế hoạch', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xóa kế hoạch?'),
                    content: Text('Bạn có chắc muốn xóa "${trip.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && userProvider.user != null) {
                  await tripProvider.deleteTrip(userProvider.user!.uid, widget.tripId);
                  if (mounted) {
                    Navigator.pop(context);
                  }
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header info
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${trip.numberOfTravelers} người',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.place, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${trip.items.length} điểm đến',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        trip.status.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('Lịch trình', 0),
                ),
                Expanded(
                  child: _buildTabButton('Chi phí', 1),
                ),
                Expanded(
                  child: _buildTabButton('Thời tiết', 2),
                ),
                Expanded(
                  child: _buildTabButton('Gợi ý AI', 3),
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: _buildTabContent(trip, userProvider, tripProvider),
          ),
        ],
      ),
      floatingActionButton: _selectedTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddDestinationsToTripScreen(
                      tripId: widget.tripId,
                      trip: trip,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm điểm đến'),
              backgroundColor: Colors.orange,
            )
          : null,
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.orange : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.orange : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    Trip trip,
    UserProvider userProvider,
    TripProvider tripProvider,
  ) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildTimelineTab(trip, userProvider, tripProvider);
      case 1:
        return _buildCostTab(trip);
      case 2:
        return _buildWeatherTab(trip);
      case 3:
        return _buildAISuggestionsTab(trip);
      default:
        return _buildTimelineTab(trip, userProvider, tripProvider);
    }
  }

  Widget _buildTimelineTab(
    Trip trip,
    UserProvider userProvider,
    TripProvider tripProvider,
  ) {
    if (trip.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.place_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Chưa có điểm đến nào',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddDestinationsToTripScreen(
                      tripId: widget.tripId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm điểm đến'),
            ),
          ],
        ),
      );
    }

    // Group items by date
    final itemsByDate = <DateTime, List<TripItem>>{};
    for (var item in trip.items) {
      final date = item.plannedDate ?? trip.startDate;
      final dateOnly = DateTime(date.year, date.month, date.day);
      itemsByDate.putIfAbsent(dateOnly, () => []).add(item);
    }

    final sortedDates = itemsByDate.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final items = itemsByDate[date]!;
        final dateFormat = DateFormat('dd/MM/yyyy');
        
        // Format ngày tháng với locale tiếng Việt
        String dayName;
        try {
          final dayFormat = DateFormat('EEEE', 'vi');
          dayName = dayFormat.format(date);
        } catch (e) {
          // Fallback nếu locale chưa được khởi tạo
          final dayNames = ['Chủ nhật', 'Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy'];
          dayName = dayNames[date.weekday % 7];
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '$dayName, ${dateFormat.format(date)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Items for this date - ReorderableListView
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) async {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                
                // Reorder items trong cùng một ngày
                final reorderedItems = List<TripItem>.from(items);
                final item = reorderedItems.removeAt(oldIndex);
                reorderedItems.insert(newIndex, item);
                
                // Update order trong Firestore
                if (userProvider.user != null) {
                  // Lấy tất cả items của trip để update order
                  final allItems = List<TripItem>.from(trip.items);
                  
                  // Tìm và update order cho items trong ngày này
                  int globalOrder = 0;
                  for (final dateKey in sortedDates) {
                    final dateItems = itemsByDate[dateKey]!;
                    if (dateKey == date) {
                      // Items của ngày hiện tại - dùng order mới
                      for (var i = 0; i < reorderedItems.length; i++) {
                        final reorderedItem = reorderedItems[i];
                        if (reorderedItem.id != null) {
                          final itemIndex = allItems.indexWhere((it) => it.id == reorderedItem.id);
                          if (itemIndex != -1) {
                            allItems[itemIndex] = reorderedItem.copyWith(order: globalOrder);
                          }
                        }
                        globalOrder++;
                      }
                    } else {
                      // Items của ngày khác - giữ nguyên order
                      for (var i = 0; i < dateItems.length; i++) {
                        final dateItem = dateItems[i];
                        if (dateItem.id != null) {
                          final itemIndex = allItems.indexWhere((it) => it.id == dateItem.id);
                          if (itemIndex != -1) {
                            allItems[itemIndex] = dateItem.copyWith(order: globalOrder);
                          }
                        }
                        globalOrder++;
                      }
                    }
                  }
                  
                  // Update order trong Firestore
                  final allItemIds = allItems
                      .where((it) => it.id != null)
                      .map((item) => item.id!)
                      .toList();
                  
                  if (allItemIds.isNotEmpty) {
                    await tripProvider.reorderTripItems(
                      userProvider.user!.uid,
                      widget.tripId,
                      allItemIds,
                    );
                  }
                }
              },
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return TripTimelineItem(
                  key: ValueKey(item.id ?? 'item_$index'),
                  item: item,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditTripItemScreen(
                          tripId: widget.tripId,
                          item: item,
                        ),
                      ),
                    );
                  },
                  onDelete: () async {
                    // Hiển thị dialog xác nhận
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xóa điểm đến?'),
                        content: Text(
                          'Bạn có chắc muốn xóa "${item.destination?.name ?? 'điểm đến này'}" khỏi kế hoạch?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && userProvider.user != null) {
                      if (item.id != null) {
                        await tripProvider.removeDestinationFromTrip(
                          userProvider.user!.uid,
                          widget.tripId,
                          item.id!,
                        );
                      }
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildCostTab(Trip trip) {
    final tripProvider = context.watch<TripProvider>();
    final costEstimate = tripProvider.costEstimate;
    final isEstimatingCost = tripProvider.isEstimatingCost;

    if (isEstimatingCost) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Đang tính toán chi phí bằng AI...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (costEstimate == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.attach_money, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Chưa có ước tính chi phí',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                final userProvider = context.read<UserProvider>();
                if (userProvider.user != null) {
                  tripProvider.resetCostMultiplier();
                  tripProvider.estimateCost(userProvider.user!.uid, widget.tripId);
                }
              },
              icon: const Icon(Icons.calculate),
              label: const Text('Tính toán chi phí'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final userProvider = context.read<UserProvider>();
        if (userProvider.user != null) {
          await tripProvider.estimateCost(userProvider.user!.uid, widget.tripId);
        }
      },
      child: CostBreakdownWidget(
        costEstimate: costEstimate,
        trip: trip,
        tripId: widget.tripId,
      ),
    );
  }

  Widget _buildWeatherTab(Trip trip) {
    final tripProvider = context.watch<TripProvider>();
    final weatherForecasts = tripProvider.weatherForecasts;
    final isLoadingWeather = tripProvider.isLoadingWeather;

    if (isLoadingWeather) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (weatherForecasts == null || weatherForecasts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wb_sunny, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Chưa có dự báo thời tiết',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                final userProvider = context.read<UserProvider>();
                if (userProvider.user != null) {
                  tripProvider.loadWeatherForecasts(
                    userProvider.user!.uid,
                    widget.tripId,
                  );
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Làm mới'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final userProvider = context.read<UserProvider>();
        if (userProvider.user != null) {
          await tripProvider.loadWeatherForecasts(
            userProvider.user!.uid,
            widget.tripId,
          );
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: weatherForecasts.length,
        itemBuilder: (context, index) {
          final forecast = weatherForecasts[index];
          return WeatherForecastCard(forecast: forecast);
        },
      ),
    );
  }

  Widget _buildAISuggestionsTab(Trip trip) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Tính năng gợi ý AI sẽ được thêm sau',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

