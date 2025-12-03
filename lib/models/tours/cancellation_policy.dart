/// Model đại diện cho chính sách hủy tour
class CancellationPolicy {
  final String type; // "flexible", "moderate", "strict"
  final List<CancellationRule> rules; // Các quy tắc hủy
  final String? notes; // Ghi chú

  CancellationPolicy({
    required this.type,
    required this.rules,
    this.notes,
  });

  /// Convert từ Map (Firestore hoặc JSON)
  factory CancellationPolicy.fromMap(Map<String, dynamic> map) {
    return CancellationPolicy(
      type: map['type'] ?? 'flexible',
      rules: (map['rules'] as List<dynamic>?)
              ?.map((e) => CancellationRule.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: map['notes'],
    );
  }

  /// Convert sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'rules': rules.map((e) => e.toMap()).toList(),
      if (notes != null) 'notes': notes,
    };
  }
}

/// Model đại diện cho một quy tắc hủy tour
class CancellationRule {
  final int daysBeforeDeparture; // Số ngày trước khi khởi hành
  final int refundPercentage; // % hoàn tiền (0-100)
  final String description; // Mô tả

  CancellationRule({
    required this.daysBeforeDeparture,
    required this.refundPercentage,
    required this.description,
  });

  /// Convert từ Map (Firestore hoặc JSON)
  factory CancellationRule.fromMap(Map<String, dynamic> map) {
    return CancellationRule(
      daysBeforeDeparture: map['daysBeforeDeparture'] ?? 0,
      refundPercentage: map['refundPercentage'] ?? 0,
      description: map['description'] ?? '',
    );
  }

  /// Convert sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'daysBeforeDeparture': daysBeforeDeparture,
      'refundPercentage': refundPercentage,
      'description': description,
    };
  }
}

