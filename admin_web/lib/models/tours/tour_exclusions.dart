/// Model đại diện cho những gì tour không bao gồm
class TourExclusions {
  final List<String> meals; // Bữa ăn
  final List<String> activities; // Hoạt động
  final List<String> other; // Khác

  TourExclusions({
    this.meals = const [],
    this.activities = const [],
    this.other = const [],
  });

  /// Convert từ Map (Firestore hoặc JSON)
  factory TourExclusions.fromMap(Map<String, dynamic> map) {
    return TourExclusions(
      meals: List<String>.from(map['meals'] ?? []),
      activities: List<String>.from(map['activities'] ?? []),
      other: List<String>.from(map['other'] ?? []),
    );
  }

  /// Convert sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'meals': meals,
      'activities': activities,
      'other': other,
    };
  }
}

