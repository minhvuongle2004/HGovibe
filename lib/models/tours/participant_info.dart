import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho thông tin người tham gia tour
class ParticipantInfo {
  final String fullName; // Họ tên đầy đủ
  final DateTime? dateOfBirth; // Ngày sinh
  final String? gender; // Giới tính
  final String? nationality; // Quốc tịch
  final String? passportNumber; // Số passport (nếu cần)
  final String? phoneNumber; // Số điện thoại
  final String? email; // Email

  ParticipantInfo({
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.nationality,
    this.passportNumber,
    this.phoneNumber,
    this.email,
  });

  /// Convert từ Map (Firestore hoặc JSON)
  factory ParticipantInfo.fromMap(Map<String, dynamic> map) {
    return ParticipantInfo(
      fullName: map['fullName'] ?? '',
      dateOfBirth: map['dateOfBirth'] is String
          ? DateTime.parse(map['dateOfBirth'])
          : (map['dateOfBirth'] as Timestamp?)?.toDate(),
      gender: map['gender'],
      nationality: map['nationality'],
      passportNumber: map['passportNumber'],
      phoneNumber: map['phoneNumber'],
      email: map['email'],
    );
  }

  /// Convert sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      if (dateOfBirth != null)
        'dateOfBirth': Timestamp.fromDate(dateOfBirth!),
      if (gender != null) 'gender': gender,
      if (nationality != null) 'nationality': nationality,
      if (passportNumber != null) 'passportNumber': passportNumber,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
    };
  }
}

