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

  factory AppUser.fromFirebaseUser(
    fb.User user, {
    UserProfile? profile,
  }) {
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

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'],
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      phoneNumber: map['phoneNumber'],
      emailVerified: map['emailVerified'] ?? false,
      createdAt: _fromTimestamp(map['createdAt']),
      lastLoginAt: _fromTimestamp(map['lastLoginAt']),
      role: map['role'] ?? 'traveler',
      profile: map['profile'] != null
          ? UserProfile.fromMap(Map<String, dynamic>.from(map['profile']))
          : null,
      providerIds:
          (map['providerIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'emailVerified': emailVerified,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
      'role': role,
      'providerIds': providerIds,
      if (profile != null) 'profile': profile!.toMap(),
    };
  }

  AppUser copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? role,
    UserProfile? profile,
    List<String>? providerIds,
  }) {
    return AppUser(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      role: role ?? this.role,
      profile: profile ?? this.profile,
      providerIds: providerIds ?? this.providerIds,
    );
  }

  static DateTime? _toDateTime(DateTime? date) => date;

  static DateTime? _fromTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

/// Profile mở rộng lưu ở Firestore collection `users`
class UserProfile {
  final String uid;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final String? city;
  final String? country;
  final int favoritesCount;
  final int savedTripsCount;
  final List<String> favoriteCategories;
  final List<String> savedDestinations;
  final Map<String, dynamic> preferences;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.city,
    this.country,
    this.favoritesCount = 0,
    this.savedTripsCount = 0,
    this.favoriteCategories = const [],
    this.savedDestinations = const [],
    this.preferences = const {},
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.empty(String uid, {String? fullName, String? email}) {
    return UserProfile(
      uid: uid,
      fullName: fullName ?? email,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      fullName: map['fullName'],
      avatarUrl: map['avatarUrl'],
      bio: map['bio'],
      city: map['city'],
      country: map['country'],
      favoritesCount: map['favoritesCount'] ?? 0,
      savedTripsCount: map['savedTripsCount'] ?? 0,
      favoriteCategories:
          (map['favoriteCategories'] as List?)?.cast<String>() ?? const [],
      savedDestinations:
          (map['savedDestinations'] as List?)?.cast<String>() ?? const [],
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
      createdAt: AppUser._fromTimestamp(map['createdAt']),
      updatedAt: AppUser._fromTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'city': city,
      'country': country,
      'favoritesCount': favoritesCount,
      'savedTripsCount': savedTripsCount,
      'favoriteCategories': favoriteCategories,
      'savedDestinations': savedDestinations,
      'preferences': preferences,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? DateTime.now(),
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? city,
    String? country,
    int? favoritesCount,
    int? savedTripsCount,
    List<String>? favoriteCategories,
    List<String>? savedDestinations,
    Map<String, dynamic>? preferences,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      country: country ?? this.country,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      savedTripsCount: savedTripsCount ?? this.savedTripsCount,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      savedDestinations: savedDestinations ?? this.savedDestinations,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt ?? DateTime.now(),
    );
  }
}


