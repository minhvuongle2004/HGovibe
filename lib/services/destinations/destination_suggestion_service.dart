import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:smart_travel_app/models/destinations/destination.dart';
import 'package:smart_travel_app/services/destinations/destination_service.dart';
import 'package:smart_travel_app/services/maps/mapbox_service.dart';

/// Kết quả gợi ý điểm đến với khoảng cách
class SuggestedDestination {
  final Destination destination;
  final double distance; // Khoảng cách (km)
  final DistanceResult? distanceResult; // Kết quả chi tiết từ MapBox

  SuggestedDestination({
    required this.destination,
    required this.distance,
    this.distanceResult,
  });
}

/// Service để gợi ý các điểm đến gần hơn trong cùng khu vực
class DestinationSuggestionService {
  DestinationSuggestionService._();
  static final DestinationSuggestionService instance =
      DestinationSuggestionService._();

  final MapBoxService _mapboxService = MapBoxService.instance;

  // Cache để tránh tính toán lại
  final Map<String, List<SuggestedDestination>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTTL = Duration(hours: 1);

  /// Tìm các điểm đến gần hơn trong cùng khu vực
  ///
  /// [targetDestination]: Điểm đến mục tiêu (điểm người dùng muốn thêm)
  /// [allDestinations]: Danh sách tất cả destinations để tìm kiếm (nếu null, sẽ query từ Firestore)
  /// [maxDistance]: Khoảng cách tối đa (km). Mặc định: 100km
  /// [limit]: Số lượng kết quả tối đa. Mặc định: 10
  /// [excludeIds]: Danh sách ID cần loại trừ (ví dụ: các điểm đã chọn)
  ///
  /// Returns: Danh sách SuggestedDestination sắp xếp theo khoảng cách gần nhất
  Future<List<SuggestedDestination>> suggestNearbyDestinations(
    Destination targetDestination, {
    List<Destination>? allDestinations,
    double maxDistance = 100.0,
    int limit = 10,
    List<String>? excludeIds,
  }) async {
    // Kiểm tra cache trước
    final cacheKey = _getCacheKey(
      targetDestination,
      maxDistance,
      limit,
      excludeIds,
    );
    final cachedResult = _getCachedResult(cacheKey);
    if (cachedResult != null) {
      debugPrint('✅ Using cached suggestions');
      return cachedResult;
    }

    try {
      // Lấy danh sách destinations để tìm kiếm
      List<Destination> destinationsToSearch;

      if (allDestinations != null) {
        destinationsToSearch = allDestinations;
      } else {
        // Query từ Firestore: lấy destinations trong cùng thành phố
        destinationsToSearch = await DestinationService.getDestinationsByCity(
          targetDestination.location.city,
          limit: 100, // Lấy nhiều để filter
        );

        // Nếu không có kết quả trong cùng thành phố, thử lấy tất cả
        if (destinationsToSearch.isEmpty) {
          debugPrint(
            '⚠️ No destinations found in same city, trying all destinations',
          );
          destinationsToSearch = await DestinationService.getAllDestinations(
            limit: 200,
          );
        }
      }

      // Filter: loại bỏ chính target destination và các điểm trong excludeIds
      final filteredDestinations = destinationsToSearch.where((dest) {
        // Loại bỏ chính target destination
        if (dest.id == targetDestination.id) {
          return false;
        }

        // Loại bỏ các điểm trong excludeIds
        if (excludeIds != null &&
            dest.id != null &&
            excludeIds.contains(dest.id)) {
          return false;
        }

        // Chỉ lấy destinations trong cùng thành phố hoặc tỉnh
        final sameCity =
            dest.location.city.toLowerCase() ==
            targetDestination.location.city.toLowerCase();
        final sameProvince =
            dest.location.district.isNotEmpty &&
            targetDestination.location.district.isNotEmpty &&
            dest.location.district.toLowerCase() ==
                targetDestination.location.district.toLowerCase();

        return sameCity || sameProvince;
      }).toList();

      debugPrint(
        '🔍 Found ${filteredDestinations.length} destinations in same region',
      );

      // Tính khoảng cách đến từng điểm
      final suggestions = <SuggestedDestination>[];

      for (var dest in filteredDestinations) {
        try {
          final result = await _mapboxService.calculateDistance(
            targetDestination.location.latitude,
            targetDestination.location.longitude,
            dest.location.latitude,
            dest.location.longitude,
            mode: 'driving',
          );

          if (result != null &&
              result.distance > 0 &&
              result.distance <= maxDistance) {
            suggestions.add(
              SuggestedDestination(
                destination: dest,
                distance: result.distance,
                distanceResult: result,
              ),
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error calculating distance for ${dest.name}: $e');
          // Fallback: dùng Haversine nếu MapBox fail
          final haversineDistance = _calculateHaversineDistance(
            targetDestination.location.latitude,
            targetDestination.location.longitude,
            dest.location.latitude,
            dest.location.longitude,
          );

          if (haversineDistance > 0 && haversineDistance <= maxDistance) {
            suggestions.add(
              SuggestedDestination(
                destination: dest,
                distance: haversineDistance,
              ),
            );
          }
        }
      }

      // Sắp xếp theo khoảng cách (gần nhất trước)
      suggestions.sort((a, b) => a.distance.compareTo(b.distance));

      // Limit kết quả
      final finalSuggestions = suggestions.take(limit).toList();

      // Lưu vào cache
      _cache[cacheKey] = finalSuggestions;
      _cacheTimestamps[cacheKey] = DateTime.now();

      debugPrint('✅ Found ${finalSuggestions.length} nearby destinations');
      return finalSuggestions;
    } catch (e, stack) {
      debugPrint('❌ Error suggesting nearby destinations: $e');
      debugPrint('$stack');
      return [];
    }
  }

  /// Tính khoảng cách Haversine (fallback khi MapBox API fail)
  double _calculateHaversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Convert độ sang radian
  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Tạo cache key
  String _getCacheKey(
    Destination targetDestination,
    double maxDistance,
    int limit,
    List<String>? excludeIds,
  ) {
    final excludeStr = excludeIds?.join(',') ?? '';
    return '${targetDestination.id}_${targetDestination.location.city}_${maxDistance.toStringAsFixed(0)}_$limit$excludeStr';
  }

  /// Lấy kết quả từ cache nếu còn hợp lệ
  List<SuggestedDestination>? _getCachedResult(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) {
      return null;
    }

    // Kiểm tra TTL
    if (DateTime.now().difference(timestamp) > _cacheTTL) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }

    return _cache[key];
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    debugPrint('✅ Destination suggestion cache cleared');
  }

  /// Get cache size (for debugging)
  int get cacheSize => _cache.length;
}
