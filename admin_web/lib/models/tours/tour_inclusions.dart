/// Model đại diện cho những gì tour bao gồm
class TourInclusions {
  final List<String> transportation; // Phương tiện
  final List<String> accommodation; // Chỗ ở
  final List<String> meals; // Bữa ăn
  final List<String> activities; // Hoạt động
  final List<String> other; // Khác

  TourInclusions({
    this.transportation = const [],
    this.accommodation = const [],
    this.meals = const [],
    this.activities = const [],
    this.other = const [],
  });

  /// Convert từ Map (Firestore hoặc JSON)
  factory TourInclusions.fromMap(Map<String, dynamic> map) {
    return TourInclusions(
      transportation: List<String>.from(map['transportation'] ?? []),
      accommodation: List<String>.from(map['accommodation'] ?? []),
      meals: List<String>.from(map['meals'] ?? []),
      activities: List<String>.from(map['activities'] ?? []),
      other: List<String>.from(map['other'] ?? []),
    );
  }

  /// Convert sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'transportation': transportation,
      'accommodation': accommodation,
      'meals': meals,
      'activities': activities,
      'other': other,
    };
  }
}

