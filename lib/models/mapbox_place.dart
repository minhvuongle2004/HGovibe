class MapboxPlace {
  final String id;
  final String name;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final String placeType;
  final String? category;
  final String? context;
  final double? distanceMeters; // Nếu API trả về khoảng cách ước tính
  final String? externalId; // Dùng khi Mapbox gắn external_id (ví dụ Google)

  const MapboxPlace({
    required this.id,
    required this.name,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    required this.placeType,
    this.category,
    this.context,
    this.distanceMeters,
    this.externalId,
  });

  MapboxPlace copyWith({
    String? id,
    String? name,
    String? fullAddress,
    double? latitude,
    double? longitude,
    String? placeType,
    String? category,
    String? context,
    double? distanceMeters,
    String? externalId,
  }) {
    return MapboxPlace(
      id: id ?? this.id,
      name: name ?? this.name,
      fullAddress: fullAddress ?? this.fullAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeType: placeType ?? this.placeType,
      category: category ?? this.category,
      context: context ?? this.context,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      externalId: externalId ?? this.externalId,
    );
  }
}

class MapboxBoundingBox {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const MapboxBoundingBox({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });
}