import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Model đại diện user lấy từ Firebase Auth + Firestore profile
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final String role;
  final UserProfile? profile;
  final List<String> providerIds;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.emailVerified = false,
    this.createdAt,
    this.lastLoginAt,
    this.role = 'traveler',
    this.profile,
    this.providerIds = const [],
  });

  factory AppUser.fromFirebaseUser(fb.User user, {UserProfile? profile}) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      phoneNumber: user.phoneNumber,
      emailVerified: user.emailVerified,
      createdAt: _toDateTime(user.metadata.creationTime),
      lastLoginAt: _toDateTime(user.metadata.lastSignInTime),
      profile: profile,
      providerIds: user.providerData
          .map((info) => info.providerId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(),
    );
  }

  static DateTime? _toDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is DateTime) return timestamp;
    if (timestamp is Timestamp) return timestamp.toDate();
    return null;
  }

  bool get isBanned => profile?.banned ?? false;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'emailVerified': emailVerified,
      'createdAt': createdAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'role': role,
      'providerIds': providerIds,
      'profile': profile?.toMap(),
    };
  }
}

/// User profile từ Firestore
class UserProfile {
  final String uid;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final bool banned;
  final DateTime? bannedAt;
  final String? banReason;
  final bool deleted;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.banned = false,
    this.bannedAt,
    this.banReason,
    this.deleted = false,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.empty(String uid, {String? fullName, String? email}) {
    return UserProfile(
      uid: uid,
      fullName: fullName,
      email: email,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String? ?? map['id'] as String? ?? '',
      fullName: map['fullName'] as String?,
      email: map['email'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      dateOfBirth: map['dateOfBirth'] != null
          ? (map['dateOfBirth'] is Timestamp
              ? (map['dateOfBirth'] as Timestamp).toDate()
              : DateTime.parse(map['dateOfBirth'] as String))
          : null,
      gender: map['gender'] as String?,
      address: map['address'] as String?,
      banned: map['banned'] as bool? ?? false,
      bannedAt: map['bannedAt'] != null
          ? (map['bannedAt'] is Timestamp
              ? (map['bannedAt'] as Timestamp).toDate()
              : DateTime.parse(map['bannedAt'] as String))
          : null,
      banReason: map['banReason'] as String?,
      deleted: map['deleted'] as bool? ?? false,
      deletedAt: map['deletedAt'] != null
          ? (map['deletedAt'] is Timestamp
              ? (map['deletedAt'] as Timestamp).toDate()
              : DateTime.parse(map['deletedAt'] as String))
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt'] as String))
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(map['updatedAt'] as String))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'address': address,
      'banned': banned,
      'bannedAt': bannedAt != null ? Timestamp.fromDate(bannedAt!) : null,
      if (banReason != null) 'banReason': banReason,
      'deleted': deleted,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    bool? banned,
    DateTime? bannedAt,
    String? banReason,
    bool? deleted,
    DateTime? deletedAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      banned: banned ?? this.banned,
      bannedAt: bannedAt ?? this.bannedAt,
      banReason: banReason ?? this.banReason,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

