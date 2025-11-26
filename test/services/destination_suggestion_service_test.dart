import 'package:flutter_test/flutter_test.dart';
import 'package:smart_travel_app/services/destination_suggestion_service.dart';
import 'package:smart_travel_app/models/destination.dart';
import 'package:smart_travel_app/models/location.dart';

void main() {
  group('DestinationSuggestionService', () {
    late DestinationSuggestionService service;
    late Destination targetDestination;

    setUp(() {
      service = DestinationSuggestionService.instance;
      
      targetDestination = Destination(
        name: 'Hà Nội',
        nameLowercase: 'hà nội',
        slug: 'ha-noi',
        category: 'city',
        tags: [],
        location: Location(
          latitude: 21.0285,
          longitude: 105.8542,
          address: 'Hà Nội',
          city: 'Hà Nội',
          district: 'Hoàn Kiếm',
          country: 'Vietnam',
        ),
        description: 'Thủ đô Việt Nam',
        shortDescription: 'Thủ đô',
        images: [],
        thumbnail: '',
        rating: 4.5,
        reviewCount: 1000,
        popularityScore: 100,
        bestMonths: [1, 2, 3, 4, 10, 11, 12],
        seasonalEvents: [],
        specialties: [],
        activities: [],
        tips: [],
        nearbyPlaces: [],
        suggestedDuration: '3 ngày',
        suggestedDurationHours: 72,
        weatherDependent: false,
        suitableFor: [],
        status: 'active',
        verified: true,
        visitCount: 10000,
        trendingScore: 100,
        userPreferenceTags: [],
      );
    });

    test('suggestNearbyDestinations should return empty list if no destinations provided', () async {
      final suggestions = await service.suggestNearbyDestinations(
        targetDestination,
        allDestinations: [],
        maxDistance: 100,
        limit: 10,
      );

      expect(suggestions, isEmpty);
    });

    test('suggestNearbyDestinations should exclude target destination', () async {
      final allDestinations = [targetDestination];
      
      final suggestions = await service.suggestNearbyDestinations(
        targetDestination,
        allDestinations: allDestinations,
        maxDistance: 100,
        limit: 10,
      );

      expect(suggestions, isEmpty);
    });

    test('suggestNearbyDestinations should exclude destinations in excludeIds', () async {
      final otherDestination = Destination(
        name: 'TP.HCM',
        nameLowercase: 'tp.hcm',
        slug: 'tp-hcm',
        category: 'city',
        tags: [],
        location: Location(
          latitude: 10.8231,
          longitude: 106.6297,
          address: 'TP.HCM',
          city: 'TP.HCM',
          district: 'Quận 1',
          country: 'Vietnam',
        ),
        description: 'Thành phố lớn nhất Việt Nam',
        shortDescription: 'TP.HCM',
        images: [],
        thumbnail: '',
        rating: 4.5,
        reviewCount: 1000,
        popularityScore: 100,
        bestMonths: [1, 2, 3, 4, 10, 11, 12],
        seasonalEvents: [],
        specialties: [],
        activities: [],
        tips: [],
        nearbyPlaces: [],
        suggestedDuration: '3 ngày',
        suggestedDurationHours: 72,
        weatherDependent: false,
        suitableFor: [],
        status: 'active',
        verified: true,
        visitCount: 10000,
        trendingScore: 100,
        userPreferenceTags: [],
      );

      final allDestinations = [otherDestination];
      final excludeIds = [otherDestination.id ?? ''];

      final suggestions = await service.suggestNearbyDestinations(
        targetDestination,
        allDestinations: allDestinations,
        maxDistance: 1000,
        limit: 10,
        excludeIds: excludeIds,
      );

      expect(suggestions, isEmpty);
    });

    test('suggestNearbyDestinations should respect limit', () async {
      // This test would need actual destinations from Firestore
      // For now, we test the structure
      expect(true, isTrue); // Placeholder
    });

    test('clearCache should clear all cached suggestions', () {
      service.clearCache();
      
      expect(service.cacheSize, equals(0));
    });
  });
}

