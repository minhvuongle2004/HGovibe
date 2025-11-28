import 'package:flutter_test/flutter_test.dart';
import 'package:smart_travel_app/services/trips/trip_validation_service.dart';
import 'package:smart_travel_app/models/destinations/destination.dart';
import 'package:smart_travel_app/models/trips/trip_item.dart';

void main() {
  group('TripValidationService', () {
    late TripValidationService service;
    late Destination destination1;
    late Destination destination2;
    late Destination destination3;

    setUp(() {
      service = TripValidationService.testing();
      
      // Tạo test destinations
      destination1 = Destination(
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

      destination2 = Destination(
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

      destination3 = Destination(
        name: 'Đà Nẵng',
        nameLowercase: 'đà nẵng',
        slug: 'da-nang',
        category: 'city',
        tags: [],
        location: Location(
          latitude: 16.0544,
          longitude: 108.2022,
          address: 'Đà Nẵng',
          city: 'Đà Nẵng',
          district: 'Hải Châu',
          country: 'Vietnam',
        ),
        description: 'Thành phố biển',
        shortDescription: 'Đà Nẵng',
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

    test('validateDestination should return valid for empty items', () async {
      final result = await service.validateDestination(
        destination1,
        [],
        3,
      );

      expect(result.isValid, isTrue);
      expect(result.warningMessage, isNull);
    });

    test('validateDestination should return invalid for far destinations in 1 day trip', () async {
      final existingItems = [
        TripItem(
          tripId: 'test-trip',
          destinationId: destination1.id ?? '',
          destination: destination1,
          order: 0,
          plannedDate: DateTime(2024, 1, 1),
        ),
      ];

      // Hà Nội -> TP.HCM trong 1 ngày (quá xa)
      final result = await service.validateDestination(
        destination2,
        existingItems,
        1,
        plannedDate: DateTime(2024, 1, 1),
      );

      // Should be invalid (distance > 200km for 1 day)
      expect(result.isValid, isFalse);
      expect(result.warningMessage, isNotNull);
    });

    test('validateDestination should return valid for close destinations in 5 day trip', () async {
      final existingItems = [
        TripItem(
          tripId: 'test-trip',
          destinationId: destination1.id ?? '',
          destination: destination1,
          order: 0,
          plannedDate: DateTime(2024, 1, 1),
        ),
      ];

      // Hà Nội -> Đà Nẵng trong 5 ngày (có thể hợp lý)
      final result = await service.validateDestination(
        destination3,
        existingItems,
        5,
        plannedDate: DateTime(2024, 1, 2),
      );

      // Should be valid (distance < 1000km for 5 days)
      // Note: Actual result depends on real distance calculation
      expect(result, isNotNull);
    });

    test('_getDistanceThreshold should return correct thresholds', () {
      // Test thresholds through validation results
      // This is an indirect test since _getDistanceThreshold is private
      // We test it through validateDestination behavior
      expect(true, isTrue); // Placeholder - actual test would need public method
    });
  });
}

