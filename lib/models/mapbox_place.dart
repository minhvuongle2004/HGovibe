class MapboxPlace {
  final String id;
  final String name;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final String placeType;
  final String? category;
  final String? context;

  const MapboxPlace({
    required this.id,
    required this.name,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    required this.placeType,
    this.category,
    this.context,
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
    );
  }
}



