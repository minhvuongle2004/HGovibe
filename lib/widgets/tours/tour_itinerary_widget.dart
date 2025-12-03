import 'package:flutter/material.dart';
import 'package:smart_travel_app/models/tours/tour_itinerary_day.dart';

/// Widget hiển thị lịch trình tour
class TourItineraryWidget extends StatelessWidget {
  final List<TourItineraryDay> itinerary;

  const TourItineraryWidget({
    super.key,
    required this.itinerary,
  });

  @override
  Widget build(BuildContext context) {
    if (itinerary.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Chưa có thông tin lịch trình',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itinerary.length,
      itemBuilder: (context, index) {
        final day = itinerary[index];
        return _buildDayCard(day, index == itinerary.length - 1);
      },
    );
  }

  Widget _buildDayCard(TourItineraryDay day, bool isLast) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Timeline line - chỉ hiển thị nếu không phải ngày cuối
                if (!isLast)
                  Positioned(
                    top: 28,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: Colors.grey[300],
                    ),
                  ),
                // Day number circle
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.orange[700],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.dayNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      day.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (day.activities.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Hoạt động:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...day.activities.map((activity) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  activity.time,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange[900],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (activity.description != null &&
                                        activity.description!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        activity.description!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    if (day.meals.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: day.meals.map((meal) {
                          return Chip(
                            label: Text(meal),
                            backgroundColor: Colors.green[50],
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.green[900],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    if (day.accommodation != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.hotel, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              day.accommodation!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

