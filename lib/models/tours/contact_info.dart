/// Model đại diện cho thông tin liên hệ (người đặt tour)
class ContactInfo {
  final String fullName; // Họ tên người đặt
  final String email; // Email
  final String phoneNumber; // Số điện thoại
  final String? address; // Địa chỉ (optional)

  ContactInfo({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.address,
  });

  /// Convert từ Map (Firestore hoặc JSON)
  factory ContactInfo.fromMap(Map<String, dynamic> map) {
    return ContactInfo(
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'],
    );
  }

  /// Convert sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      if (address != null) 'address': address,
    };
  }
}

