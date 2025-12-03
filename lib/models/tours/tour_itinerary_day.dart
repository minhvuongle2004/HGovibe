import 'package:smart_travel_app/models/tours/tour_activity.dart';

/// Model đại diện cho lịch trình một ngày trong tour
class TourItineraryDay {
  final int dayNumber; // Số ngày (1, 2, 3...)
  final String title; // Tiêu đề ngày
  final String description; // Mô tả ngày
  final List<TourActivity> activities; // Các hoạt động trong ngày
  final List<String> meals; // Các bữa ăn (optional)
  final String? accommodation; // Nơi nghỉ đêm (optional)

  TourItineraryDay({
    required this.dayNumber,
    required this.title,
    required this.description,
    required this.activities,
    this.meals = const [],
    this.accommodation,
  });

  /// Convert từ Map (Firestore hoặc JSON)
  factory TourItineraryDay.fromMap(Map<String, dynamic> map) {
    return TourItineraryDay(
      dayNumber: map['dayNumber'] ?? 0,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      activities: (map['activities'] as List<dynamic>?)
              ?.map((e) => TourActivity.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      meals: List<String>.from(map['meals'] ?? []),
      accommodation: map['accommodation'],
    );
  }

  /// Convert sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'dayNumber': dayNumber,
      'title': title,
      'description': description,
      'activities': activities.map((e) => e.toMap()).toList(),
      'meals': meals,
      if (accommodation != null) 'accommodation': accommodation,
    };
  }
}

