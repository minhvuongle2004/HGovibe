import 'package:flutter_test/flutter_test.dart';
import 'package:smart_travel_app/services/mapbox_service.dart';

void main() {
  group('MapBoxService', () {
    test('calculateDistance should return DistanceResult for valid coordinates', () async {
      // Test với tọa độ Hà Nội và TP.HCM
      final result = await MapBoxService.instance.calculateDistance(
        21.0285, // Hà Nội lat
        105.8542, // Hà Nội lng
        10.8231, // TP.HCM lat
        106.6297, // TP.HCM lng
      );

      expect(result, isNotNull);
      expect(result!.distance, greaterThan(0));
      expect(result.duration, greaterThan(0));
      expect(result.mode, equals('driving'));
    });

    test('calculateDistance should use cache for same coordinates', () async {
      final service = MapBoxService.instance;
      service.clearCache();

      // First call
      final result1 = await service.calculateDistance(21.0285, 105.8542, 10.8231, 106.6297);
      
      // Second call (should use cache)
      final result2 = await service.calculateDistance(21.0285, 105.8542, 10.8231, 106.6297);

      expect(result1, isNotNull);
      expect(result2, isNotNull);
      expect(result1!.distance, equals(result2!.distance));
      expect(result1.duration, equals(result2.duration));
      expect(result2.fromCache, isTrue);
    });

    test('calculateDistance should handle invalid coordinates gracefully', () async {
      // Test với tọa độ không hợp lệ (sẽ fallback về Haversine)
      final result = await MapBoxService.instance.calculateDistance(
        0, 0, 0, 0,
      );

      // Should return result (even if distance is 0)
      expect(result, isNotNull);
    });

    test('DistanceResult should format distance correctly', () {
      final result = DistanceResult(
        distance: 1500, // 1.5 km
        duration: 3600, // 1 hour
        mode: 'driving',
      );

      expect(result.distanceFormatted, equals('1.5 km'));
      expect(result.durationFormatted, equals('1 giờ'));
    });

    test('DistanceResult should format small distances in meters', () {
      final result = DistanceResult(
        distance: 0.5, // 500m
        duration: 300, // 5 minutes
        mode: 'driving',
      );

      expect(result.distanceFormatted, equals('500 m'));
      expect(result.durationFormatted, equals('5 phút'));
    });

    test('clearCache should clear all cached results', () {
      final service = MapBoxService.instance;
      service.clearCache();
      
      expect(service.cacheSize, equals(0));
    });
  });
}

