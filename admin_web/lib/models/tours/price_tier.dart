/// Model đại diện cho giá theo số người (price tier)
class PriceTier {
  final int minPeople; // Số người tối thiểu
  final int? maxPeople; // Số người tối đa (null = không giới hạn)
  final double pricePerPerson; // Giá mỗi người

  PriceTier({
    required this.minPeople,
    this.maxPeople,
    required this.pricePerPerson,
  });

  /// Convert từ Map (Firestore hoặc JSON)
  factory PriceTier.fromMap(Map<String, dynamic> map) {
    return PriceTier(
      minPeople: map['minPeople'] ?? 1,
      maxPeople: map['maxPeople'],
      pricePerPerson: (map['pricePerPerson'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convert sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'minPeople': minPeople,
      if (maxPeople != null) 'maxPeople': maxPeople,
      'pricePerPerson': pricePerPerson,
    };
  }

  /// Kiểm tra xem số người có nằm trong tier này không
  bool matches(int numberOfPeople) {
    if (numberOfPeople < minPeople) return false;
    if (maxPeople != null && numberOfPeople > maxPeople!) return false;
    return true;
  }
}

