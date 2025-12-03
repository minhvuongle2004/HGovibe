import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho một điểm du lịch
class Destination {
  final String? id; // Document ID từ Firestore
  final String name;
  final String nameLowercase;
  final String slug;
  final String category;
  final List<String> tags;
  final Location location;
  final String description;
  final String shortDescription;
  final List<String> images;
  final String thumbnail;
  final double rating;
  final int reviewCount;
  final int popularityScore;
  final OpeningHours? openingHours;
  final List<int> bestMonths;
  final String? bestSeason;
  final List<SeasonalEvent> seasonalEvents;
  final List<int>? avoidMonths;
  final List<Specialty> specialties;
  final List<Activity> activities;
  final List<String> tips;
  final List<NearbyPlace> nearbyPlaces;
  final EstimatedCost? estimatedCost;
  final int? entranceFee;
  final Parking? parking;
  final String suggestedDuration;
  final int suggestedDurationHours;
  final bool weatherDependent;
  final String? idealWeather;
  final List<String> suitableFor;
  final Accessibility? accessibility;
  final String status;
  final bool verified;
  final int visitCount;
  final int trendingScore;
  final List<String> userPreferenceTags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Destination({
    this.id,
    required this.name,
    required this.nameLowercase,
    required this.slug,
    required this.category,
    required this.tags,
    required this.location,
    required this.description,
    required this.shortDescription,
    required this.images,
    required this.thumbnail,
    required this.rating,
    required this.reviewCount,
    required this.popularityScore,
    this.openingHours,
    required this.bestMonths,
    this.bestSeason,
    required this.seasonalEvents,
    this.avoidMonths,
    required this.specialties,
    required this.activities,
    required this.tips,
    required this.nearbyPlaces,
    this.estimatedCost,
    this.entranceFee,
    this.parking,
    required this.suggestedDuration,
    required this.suggestedDurationHours,
    required this.weatherDependent,
    this.idealWeather,
    required this.suitableFor,
    this.accessibility,
    required this.status,
    required this.verified,
    required this.visitCount,
    required this.trendingScore,
    required this.userPreferenceTags,
    this.createdAt,
    this.updatedAt,
  });

  /// Convert Firestore DocumentSnapshot thành Destination object
  factory Destination.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Destination(
      id: doc.id,
      name: data['name'] ?? '',
      nameLowercase: data['name_lowercase'] ?? '',
      slug: data['slug'] ?? '',
      category: data['category'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      location: Location.fromMap(data['location'] as Map<String, dynamic>?),
      description: data['description'] ?? '',
      shortDescription: data['short_description'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      thumbnail: data['thumbnail'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: _toInt(data['review_count']),
      popularityScore: _toInt(data['popularity_score']),
      openingHours: data['opening_hours'] != null
          ? OpeningHours.fromMap(data['opening_hours'])
          : null,
      bestMonths: _toIntList(data['best_months']),
      bestSeason: data['best_season'],
      seasonalEvents: (data['seasonal_events'] as List<dynamic>?)
              ?.map((e) => SeasonalEvent.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      avoidMonths: data['avoid_months'] != null
          ? _toIntList(data['avoid_months'])
          : null,
      specialties: (data['specialties'] as List<dynamic>?)
              ?.map((e) => Specialty.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      activities: (data['activities'] as List<dynamic>?)
              ?.map((e) => Activity.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      tips: List<String>.from(data['tips'] ?? []),
      nearbyPlaces: (data['nearby_places'] as List<dynamic>?)
              ?.map((e) => NearbyPlace.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      estimatedCost: data['estimated_cost'] != null
          ? EstimatedCost.fromMap(data['estimated_cost'])
          : null,
      entranceFee: data['entrance_fee'] != null
          ? _toInt(data['entrance_fee'])
          : null,
      parking: data['parking'] != null
          ? Parking.fromMap(data['parking'])
          : null,
      suggestedDuration: data['suggested_duration'] ?? '',
      suggestedDurationHours: _toInt(data['suggested_duration_hours']),
      weatherDependent: data['weather_dependent'] ?? false,
      idealWeather: data['ideal_weather'],
      suitableFor: List<String>.from(data['suitable_for'] ?? []),
      accessibility: data['accessibility'] != null
          ? Accessibility.fromMap(data['accessibility'])
          : null,
      status: data['status'] ?? 'active',
      verified: data['verified'] ?? false,
      visitCount: _toInt(data['visit_count']),
      trendingScore: _toInt(data['trending_score']),
      userPreferenceTags: List<String>.from(data['user_preference_tags'] ?? []),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert Destination thành Map (để lưu vào Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'name_lowercase': nameLowercase,
      'slug': slug,
      'category': category,
      'tags': tags,
      'location': location.toMap(),
      'description': description,
      'short_description': shortDescription,
      'images': images,
      'thumbnail': thumbnail,
      'rating': rating,
      'review_count': reviewCount,
      'popularity_score': popularityScore,
      'opening_hours': openingHours?.toMap(),
      'best_months': bestMonths,
      'best_season': bestSeason,
      'seasonal_events': seasonalEvents.map((e) => e.toMap()).toList(),
      'avoid_months': avoidMonths,
      'specialties': specialties.map((e) => e.toMap()).toList(),
      'activities': activities.map((e) => e.toMap()).toList(),
      'tips': tips,
      'nearby_places': nearbyPlaces.map((e) => e.toMap()).toList(),
      'estimated_cost': estimatedCost?.toMap(),
      'entrance_fee': entranceFee,
      'parking': parking?.toMap(),
      'suggested_duration': suggestedDuration,
      'suggested_duration_hours': suggestedDurationHours,
      'weather_dependent': weatherDependent,
      'ideal_weather': idealWeather,
      'suitable_for': suitableFor,
      'accessibility': accessibility?.toMap(),
      'status': status,
      'verified': verified,
      'visit_count': visitCount,
      'trending_score': trendingScore,
      'user_preference_tags': userPreferenceTags,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  /// Helper: Convert value to int (handle both int and double)
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Helper: Convert list to List<int> (handle both int and double in list)
  static List<int> _toIntList(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    return value.map((e) {
      if (e is int) return e;
      if (e is double) return e.toInt();
      if (e is String) return int.tryParse(e) ?? 0;
      return 0;
    }).toList();
  }
}

/// Model cho thông tin vị trí
class Location {
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String district;
  final String country;

  Location({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    required this.district,
    required this.country,
  });

  factory Location.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return Location(
        latitude: 0.0,
        longitude: 0.0,
        address: '',
        city: '',
        district: '',
        country: 'Vietnam',
      );
    }
    return Location(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      country: map['country'] ?? 'Vietnam',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'district': district,
      'country': country,
    };
  }
}

/// Model cho giờ mở cửa
class OpeningHours {
  final Map<String, DayHours> days;
  final String? note;

  OpeningHours({required this.days, this.note});

  factory OpeningHours.fromMap(Map<String, dynamic> map) {
    final days = <String, DayHours>{};
    for (var entry in map.entries) {
      if (entry.key != 'note' && entry.value is Map) {
        days[entry.key] = DayHours.fromMap(entry.value as Map<String, dynamic>);
      }
    }
    return OpeningHours(days: days, note: map['note']);
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    days.forEach((key, value) {
      result[key] = value.toMap();
    });
    if (note != null) result['note'] = note;
    return result;
  }
}

class DayHours {
  final String open;
  final String close;
  final bool closed;

  DayHours({required this.open, required this.close, this.closed = false});

  factory DayHours.fromMap(Map<String, dynamic> map) {
    return DayHours(
      open: map['open'] ?? '',
      close: map['close'] ?? '',
      closed: map['closed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'open': open,
      'close': close,
      'closed': closed,
    };
  }
}

class SeasonalEvent {
  final String name;
  final String month;
  final String? description;

  SeasonalEvent({required this.name, required this.month, this.description});

  factory SeasonalEvent.fromMap(Map<String, dynamic> map) {
    return SeasonalEvent(
      name: map['name'] ?? '',
      month: map['month'] ?? '',
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'month': month,
      if (description != null) 'description': description,
    };
  }
}

class Specialty {
  final String name;
  final String? description;

  Specialty({required this.name, this.description});

  factory Specialty.fromMap(Map<String, dynamic> map) {
    return Specialty(
      name: map['name'] ?? '',
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (description != null) 'description': description,
    };
  }
}

class Activity {
  final String name;
  final String duration;
  final String bestTime;
  final String? description;

  Activity({
    required this.name,
    required this.duration,
    required this.bestTime,
    this.description,
  });

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      name: map['name'] ?? '',
      duration: map['duration'] ?? '',
      bestTime: map['best_time'] ?? '',
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'duration': duration,
      'best_time': bestTime,
      if (description != null) 'description': description,
    };
  }
}

class NearbyPlace {
  final String name;
  final double distanceKm;
  final String type;
  final String? destinationId;

  NearbyPlace({
    required this.name,
    required this.distanceKm,
    required this.type,
    this.destinationId,
  });

  factory NearbyPlace.fromMap(Map<String, dynamic> map) {
    return NearbyPlace(
      name: map['name'] ?? '',
      distanceKm: (map['distance_km'] ?? 0.0).toDouble(),
      type: map['type'] ?? '',
      destinationId: map['destination_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'distance_km': distanceKm,
      'type': type,
      'destination_id': destinationId,
    };
  }
}

class EstimatedCost {
  final int entranceFee;
  final int averageMeal;
  final int shoppingBudget;
  final int totalSuggested;
  final String currency;

  EstimatedCost({
    required this.entranceFee,
    required this.averageMeal,
    required this.shoppingBudget,
    required this.totalSuggested,
    required this.currency,
  });

  factory EstimatedCost.fromMap(Map<String, dynamic> map) {
    return EstimatedCost(
      entranceFee: Destination._toInt(map['entrance_fee']),
      averageMeal: Destination._toInt(map['average_meal']),
      shoppingBudget: Destination._toInt(map['shopping_budget']),
      totalSuggested: Destination._toInt(map['total_suggested']),
      currency: map['currency'] ?? 'VND',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'entrance_fee': entranceFee,
      'average_meal': averageMeal,
      'shopping_budget': shoppingBudget,
      'total_suggested': totalSuggested,
      'currency': currency,
    };
  }
}

class Parking {
  final bool available;
  final String fee;
  final String? note;

  Parking({required this.available, required this.fee, this.note});

  factory Parking.fromMap(Map<String, dynamic> map) {
    return Parking(
      available: map['available'] ?? false,
      fee: map['fee'] ?? '',
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'available': available,
      'fee': fee,
      if (note != null) 'note': note,
    };
  }
}

class Accessibility {
  final bool wheelchairAccessible;
  final bool elderlyFriendly;
  final bool kidFriendly;
  final String? notes;

  Accessibility({
    required this.wheelchairAccessible,
    required this.elderlyFriendly,
    required this.kidFriendly,
    this.notes,
  });

  factory Accessibility.fromMap(Map<String, dynamic> map) {
    return Accessibility(
      wheelchairAccessible: map['wheelchair_accessible'] ?? false,
      elderlyFriendly: map['elderly_friendly'] ?? false,
      kidFriendly: map['kid_friendly'] ?? false,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wheelchair_accessible': wheelchairAccessible,
      'elderly_friendly': elderlyFriendly,
      'kid_friendly': kidFriendly,
      if (notes != null) 'notes': notes,
    };
  }
}


