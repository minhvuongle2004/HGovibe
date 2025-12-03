/// Model đại diện cho một hoạt động trong lịch trình tour
class TourActivity {
  final String time; // Giờ (HH:mm)
  final String name; // Tên hoạt động
  final String? description; // Mô tả (optional)

  TourActivity({
    required this.time,
    required this.name,
    this.description,
  });

  /// Convert từ Map (Firestore hoặc JSON)
  factory TourActivity.fromMap(Map<String, dynamic> map) {
    return TourActivity(
      time: map['time'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
    );
  }

  /// Convert sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'name': name,
      if (description != null) 'description': description,
    };
  }
}

