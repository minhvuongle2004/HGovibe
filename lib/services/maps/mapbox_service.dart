import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:smart_travel_app/models/maps/mapbox_place.dart';
import 'package:smart_travel_app/config/api/api_config.dart';

/// Kết quả tính khoảng cách và thời gian di chuyển
class DistanceResult {
  final double distance; // Khoảng cách (km)
  final int duration; // Thời gian di chuyển (giây)
  final String mode; // Phương tiện (driving, walking, cycling)
  final bool fromCache; // Có phải từ cache không

  DistanceResult({
    required this.distance,
    required this.duration,
    required this.mode,
    this.fromCache = false,
  });

  /// Thời gian di chuyển dạng string (VD: "2 giờ 30 phút")
  String get durationFormatted {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;

    if (hours > 0 && minutes > 0) {
      return '$hours giờ $minutes phút';
    } else if (hours > 0) {
      return '$hours giờ';
    } else if (minutes > 0) {
      return '$minutes phút';
    } else {
      return '$duration giây';
    }
  }

  /// Khoảng cách dạng string (VD: "1,700 km")
  /// Lưu ý: distance đã là km, không phải meters
  String get distanceFormatted {
    if (distance >= 1.0) {
      // >= 1 km: hiển thị km với 1 chữ số thập phân
      return '${distance.toStringAsFixed(1)} km';
    } else {
      // < 1 km: convert sang meters và hiển thị
      final meters = (distance * 1000).round();
      return '$meters m';
    }
  }
}

/// Tọa độ cho tuyến đường
class RouteCoordinate {
  final double latitude;
  final double longitude;

  const RouteCoordinate({required this.latitude, required this.longitude});
}

/// Thông tin từng bước rẽ
class RouteStepInfo {
  final String instruction;
  final double distance; // km
  final int duration; // giây
  final String? maneuverType;
  final String? maneuverModifier;
  final String? name;

  const RouteStepInfo({
    required this.instruction,
    required this.distance,
    required this.duration,
    this.maneuverType,
    this.maneuverModifier,
    this.name,
  });

  String get distanceFormatted {
    if (distance >= 1) {
      return '${distance.toStringAsFixed(1)} km';
    }
    return '${(distance * 1000).round()} m';
  }

  String get durationFormatted {
    final minutes = (duration / 60).round();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remain = minutes % 60;
      if (remain > 0) {
        return '$hours giờ $remain phút';
      }
      return '$hours giờ';
    }
    return '$minutes phút';
  }
}

/// Kết quả tuyến đường
class RouteResult {
  final List<RouteCoordinate> coordinates;
  final double distance; // km
  final int duration; // giây
  final String profile;
  final List<RouteStepInfo> steps;
  final bool fromCache;

  const RouteResult({
    required this.coordinates,
    required this.distance,
    required this.duration,
    required this.profile,
    required this.steps,
    this.fromCache = false,
  });

  String get distanceFormatted {
    if (distance >= 1) {
      return '${distance.toStringAsFixed(1)} km';
    }
    return '${(distance * 1000).round()} m';
  }

  String get durationFormatted {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    if (hours > 0 && minutes > 0) {
      return '$hours giờ $minutes phút';
    } else if (hours > 0) {
      return '$hours giờ';
    } else if (minutes > 0) {
      return '$minutes phút';
    }
    return '$duration giây';
  }
}

/// Service để tính khoảng cách và thời gian di chuyển sử dụng MapBox API
class MapBoxService {
  MapBoxService._();
  static final MapBoxService instance = MapBoxService._();
  static const Set<String> _supportedCategories = {
    'restaurant',
    'restaurants',
    'cafe',
    'coffee-shop',
    'tea-house',
    'bakery',
    'bar',
    'pub',
    'wine-bar',
    'fast-food',
    'food',
    'food-truck',
    'bbq',
    'seafood',
    'sushi',
    'steakhouse',
    'pizza',
    'dessert',
    'ice-cream',
    'juice-bar',
    'vegan',
    'vegetarian',
  };

  // Cache để tránh gọi API nhiều lần
  final Map<String, DistanceResult> _cache = {};
  static const Duration _cacheTTL = Duration(hours: 1);
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, RouteResult> _routeCache = {};
  final Map<String, DateTime> _routeCacheTimestamps = {};
  static const Duration _routeCacheTTL = Duration(minutes: 30);
  final Map<String, _SearchCacheEntry> _searchCache = {};
  static const Duration _searchCacheTTL = Duration(minutes: 30);
  http.Client? _clientOverride;
  http.Client? _sharedClient;

  /// Tính khoảng cách và thời gian di chuyển giữa 2 điểm
  void setHttpClient(http.Client? client) {
    _clientOverride = client;
  }

  http.Client get _httpClient {
    if (_clientOverride != null) return _clientOverride!;
    _sharedClient ??= http.Client();
    return _sharedClient!;
  }

  /// [lat1, lng1]: Tọa độ điểm xuất phát
  /// [lat2, lng2]: Tọa độ điểm đích
  /// [mode]: Phương tiện (driving, walking, cycling). Mặc định: driving
  ///
  /// Returns DistanceResult hoặc null nếu có lỗi
  Future<DistanceResult?> calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2, {
    String mode = 'driving',
  }) async {
    // Kiểm tra cache trước
    final cacheKey = _getCacheKey(lat1, lng1, lat2, lng2, mode);
    final cachedResult = _getCachedResult(cacheKey);
    if (cachedResult != null) {
      debugPrint('✅ Using cached distance result');
      return cachedResult;
    }

    try {
      // Thử dùng MapBox API trước
      final result = await _calculateDistanceWithMapBox(
        lat1,
        lng1,
        lat2,
        lng2,
        mode,
      );

      if (result != null) {
        // Lưu vào cache
        _cache[cacheKey] = result;
        _cacheTimestamps[cacheKey] = DateTime.now();
        debugPrint(
          '✅ Distance calculated with MapBox API: ${result.distanceFormatted}, ${result.durationFormatted}',
        );
        return result;
      }
    } catch (e) {
      debugPrint('⚠️ MapBox API error: $e');
    }

    // Fallback: Dùng Haversine formula
    debugPrint('⚠️ Falling back to Haversine formula');
    final haversineResult = _calculateDistanceWithHaversine(
      lat1,
      lng1,
      lat2,
      lng2,
      mode,
    );

    // Lưu vào cache
    _cache[cacheKey] = haversineResult;
    _cacheTimestamps[cacheKey] = DateTime.now();

    return haversineResult;
  }

  /// Tính khoảng cách với MapBox Distance Matrix API
  Future<DistanceResult?> _calculateDistanceWithMapBox(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
    String mode,
  ) async {
    // MapBox API format: lng,lat (lưu ý: longitude trước, latitude sau)
    final coordinates = '$lng1,$lat1;$lng2,$lat2';
    final url = Uri.parse(
      '${ApiConfig.mapboxBaseUrl}/directions-matrix/v1/mapbox/$mode/$coordinates'
      '?access_token=${ApiConfig.mapboxApiKey}'
      '&annotations=distance,duration',
    );

    final response = await _requestWithRetry(
      url,
      timeout: const Duration(seconds: 10),
      label: 'distance-matrix',
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;

      final distances = data['distances'] as List?;
      final durations = data['durations'] as List?;

      debugPrint('📍 MapBox API Response Debug:');
      debugPrint('   Request URL: $url');
      debugPrint('   From: ($lat1, $lng1)');
      debugPrint('   To: ($lat2, $lng2)');
      debugPrint('   Coordinates string: $coordinates');
      debugPrint('   Distances array: $distances');
      debugPrint('   Durations array: $durations');

      if (distances != null &&
          durations != null &&
          distances.isNotEmpty &&
          durations.isNotEmpty) {
        // Lấy khoảng cách và thời gian từ điểm 0 đến điểm 1
        // distances[0] là array các khoảng cách từ điểm 0 đến tất cả các điểm
        // distances[0][1] là khoảng cách từ điểm 0 đến điểm 1
        final distanceMeters = (distances[0] as List)[1] as num?;
        final durationSeconds = (durations[0] as List)[1] as num?;

        debugPrint('   Distance [0][1] (meters): $distanceMeters');
        debugPrint('   Duration [0][1] (seconds): $durationSeconds');

        if (distanceMeters != null && durationSeconds != null) {
          // MapBox API trả về distance trong meters
          final distanceKm =
              distanceMeters.toDouble() / 1000.0; // Convert m to km

          // Kiểm tra nếu khoảng cách quá nhỏ (< 1km) nhưng thời gian lại rất lớn (> 1 giờ)
          // Có thể là lỗi parse hoặc API trả về sai
          if (distanceKm < 1.0 && durationSeconds > 3600) {
            debugPrint(
              '   ⚠️ WARNING: Distance too small ($distanceKm km) but duration too large (${durationSeconds / 3600} hours)',
            );
            debugPrint(
              '   ⚠️ This might be a parsing error. Using Haversine fallback...',
            );
            // Fallback về Haversine
            return _calculateDistanceWithHaversine(
              lat1,
              lng1,
              lat2,
              lng2,
              mode,
            );
          }

          debugPrint('   ✅ Final distance: $distanceKm km');
          debugPrint(
            '   ✅ Final duration: ${durationSeconds.toInt()} seconds (${(durationSeconds.toInt() / 3600).toStringAsFixed(2)} hours)',
          );

          return DistanceResult(
            distance: distanceKm,
            duration: durationSeconds.toInt(),
            mode: mode,
            fromCache: false,
          );
        } else {
          debugPrint(
            '   ⚠️ Distance or duration is null, using Haversine fallback',
          );
          return _calculateDistanceWithHaversine(lat1, lng1, lat2, lng2, mode);
        }
      } else {
        debugPrint(
          '   ⚠️ Distances or durations array is empty, using Haversine fallback',
        );
        return _calculateDistanceWithHaversine(lat1, lng1, lat2, lng2, mode);
      }
    } else {
      debugPrint(
        '⚠️ MapBox API error: ${response.statusCode} - ${response.body}',
      );
      debugPrint('   Using Haversine fallback...');
      return _calculateDistanceWithHaversine(lat1, lng1, lat2, lng2, mode);
    }
  }

  /// Tính khoảng cách với Haversine formula (fallback)
  DistanceResult _calculateDistanceWithHaversine(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
    String mode,
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
    final distance = earthRadius * c;

    // Ước tính thời gian di chuyển dựa trên phương tiện
    // Giả sử tốc độ trung bình:
    // - driving: 60 km/h
    // - walking: 5 km/h
    // - cycling: 15 km/h
    int estimatedDuration;
    switch (mode) {
      case 'walking':
        estimatedDuration = (distance / 5 * 3600).round(); // 5 km/h
        break;
      case 'cycling':
        estimatedDuration = (distance / 15 * 3600).round(); // 15 km/h
        break;
      case 'driving':
      default:
        // Ước tính tốc độ dựa trên khoảng cách
        // < 50km: 40 km/h (nội thành)
        // 50-200km: 60 km/h (quốc lộ)
        // > 200km: 80 km/h (cao tốc)
        double avgSpeed;
        if (distance < 50) {
          avgSpeed = 40;
        } else if (distance < 200) {
          avgSpeed = 60;
        } else {
          avgSpeed = 80;
        }
        estimatedDuration = (distance / avgSpeed * 3600).round();
        break;
    }

    return DistanceResult(
      distance: distance,
      duration: estimatedDuration,
      mode: mode,
      fromCache: false,
    );
  }

  /// Tính khoảng cách cho nhiều điểm (batch)
  /// [coordinates]: List of [lat, lng] pairs
  /// Returns Map với key là "lat1,lng1,lat2,lng2" và value là DistanceResult
  Future<Map<String, DistanceResult>> calculateDistanceMatrix(
    List<List<double>> coordinates, {
    String mode = 'driving',
  }) async {
    if (coordinates.length < 2) {
      return {};
    }

    final results = <String, DistanceResult>{};

    try {
      // Build coordinates string cho MapBox API
      final coordsString = coordinates
          .map((coord) => '${coord[1]},${coord[0]}') // lng,lat
          .join(';');

      final url = Uri.parse(
        '${ApiConfig.mapboxBaseUrl}/directions-matrix/v1/mapbox/$mode/$coordsString'
        '?access_token=${ApiConfig.mapboxApiKey}'
        '&annotations=distance,duration',
      );

      final response = await _requestWithRetry(
        url,
        timeout: const Duration(seconds: 15),
        label: 'distance-matrix-batch',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        final distances = data['distances'] as List?;
        final durations = data['durations'] as List?;

        if (distances != null && durations != null) {
          // Parse kết quả cho tất cả các cặp điểm
          for (var i = 0; i < coordinates.length; i++) {
            for (var j = 0; j < coordinates.length; j++) {
              if (i != j) {
                final distanceMeters = (distances[i] as List)[j] as num?;
                final durationSeconds = (durations[i] as List)[j] as num?;

                if (distanceMeters != null && durationSeconds != null) {
                  final key = _getCacheKey(
                    coordinates[i][0],
                    coordinates[i][1],
                    coordinates[j][0],
                    coordinates[j][1],
                    mode,
                  );

                  results[key] = DistanceResult(
                    distance: distanceMeters.toDouble() / 1000,
                    duration: durationSeconds.toInt(),
                    mode: mode,
                    fromCache: false,
                  );
                }
              }
            }
          }

          debugPrint(
            '✅ Calculated ${results.length} distances with MapBox API',
          );
          return results;
        }
      } else {
        debugPrint(
          '⚠️ MapBox API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('⚠️ MapBox API error: $e');
    }

    // Fallback: Tính từng cặp với Haversine
    debugPrint('⚠️ Falling back to Haversine formula for batch calculation');
    for (var i = 0; i < coordinates.length; i++) {
      for (var j = i + 1; j < coordinates.length; j++) {
        final result = _calculateDistanceWithHaversine(
          coordinates[i][0],
          coordinates[i][1],
          coordinates[j][0],
          coordinates[j][1],
          mode,
        );

        final key = _getCacheKey(
          coordinates[i][0],
          coordinates[i][1],
          coordinates[j][0],
          coordinates[j][1],
          mode,
        );

        results[key] = result;
      }
    }

    return results;
  }

  /// Tính khoảng cách từ một điểm mốc đến tất cả các điểm còn lại
  /// Trả về danh sách DistanceResult theo đúng thứ tự tọa độ truyền vào.
  /// Phần tử tại [originIndex] sẽ luôn là null.
  Future<List<DistanceResult?>> calculateDistancesFromOrigin(
    List<List<double>> coordinates,
    int originIndex, {
    String mode = 'driving',
  }) async {
    if (coordinates.length < 2) {
      return const [];
    }

    if (originIndex < 0 || originIndex >= coordinates.length) {
      throw RangeError(
        'originIndex must be between 0 and ${coordinates.length - 1}',
      );
    }

    final coordsString = coordinates
        .map((coord) => '${coord[1]},${coord[0]}') // lng,lat
        .join(';');

    final url = Uri.parse(
      '${ApiConfig.mapboxBaseUrl}/directions-matrix/v1/mapbox/$mode/$coordsString'
      '?access_token=${ApiConfig.mapboxApiKey}'
      '&annotations=distance,duration',
    );

    try {
      final response = await _requestWithRetry(
        url,
        timeout: const Duration(seconds: 12),
        label: 'distance-matrix-single-source',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final distances = data['distances'] as List?;
        final durations = data['durations'] as List?;

        if (distances != null &&
            durations != null &&
            distances.length > originIndex &&
            durations.length > originIndex) {
          final originDistances = distances[originIndex] as List?;
          final originDurations = durations[originIndex] as List?;
          if (originDistances == null || originDurations == null) {
            return _calculateDistancesWithHaversineFallback(
              coordinates,
              originIndex,
              mode,
            );
          }

          final results = <DistanceResult?>[];
          for (var i = 0; i < coordinates.length; i++) {
            if (i == originIndex) {
              results.add(null);
              continue;
            }

            final distanceMeters = originDistances[i] as num?;
            final durationSeconds = originDurations[i] as num?;
            if (distanceMeters == null || durationSeconds == null) {
              results.add(null);
              continue;
            }

            final distanceResult = DistanceResult(
              distance: distanceMeters.toDouble() / 1000,
              duration: durationSeconds.toInt(),
              mode: mode,
              fromCache: false,
            );

            results.add(distanceResult);

            // Lưu cache cho từng cặp điểm
            final key = _getCacheKey(
              coordinates[originIndex][0],
              coordinates[originIndex][1],
              coordinates[i][0],
              coordinates[i][1],
              mode,
            );
            _cache[key] = distanceResult;
            _cacheTimestamps[key] = DateTime.now();
          }

          debugPrint(
            '✅ Calculated ${results.whereType<DistanceResult>().length} distances with single-source matrix',
          );
          return results;
        }
      } else {
        debugPrint(
          '⚠️ MapBox API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('⚠️ MapBox API error: $e');
    }

    return _calculateDistancesWithHaversineFallback(
      coordinates,
      originIndex,
      mode,
    );
  }

  List<DistanceResult?> _calculateDistancesWithHaversineFallback(
    List<List<double>> coordinates,
    int originIndex,
    String mode,
  ) {
    debugPrint('⚠️ Falling back to Haversine for single-source matrix');
    final results = <DistanceResult?>[];

    for (var i = 0; i < coordinates.length; i++) {
      if (i == originIndex) {
        results.add(null);
        continue;
      }

      final fallbackResult = _calculateDistanceWithHaversine(
        coordinates[originIndex][0],
        coordinates[originIndex][1],
        coordinates[i][0],
        coordinates[i][1],
        mode,
      );

      results.add(fallbackResult);

      final key = _getCacheKey(
        coordinates[originIndex][0],
        coordinates[originIndex][1],
        coordinates[i][0],
        coordinates[i][1],
        mode,
      );
      _cache[key] = fallbackResult;
      _cacheTimestamps[key] = DateTime.now();
    }

    return results;
  }

  /// Tạo cache key từ tọa độ
  String _getCacheKey(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
    String mode,
  ) {
    // Làm tròn tọa độ để cache hiệu quả hơn (0.01 độ ≈ 1km)
    final roundedLat1 = (lat1 * 100).round() / 100;
    final roundedLng1 = (lng1 * 100).round() / 100;
    final roundedLat2 = (lat2 * 100).round() / 100;
    final roundedLng2 = (lng2 * 100).round() / 100;

    // Sắp xếp để đảm bảo key giống nhau cho cả 2 chiều
    final coords = [
      [roundedLat1, roundedLng1],
      [roundedLat2, roundedLng2],
    ];
    coords.sort((a, b) {
      if (a[0] != b[0]) return a[0].compareTo(b[0]);
      return a[1].compareTo(b[1]);
    });

    return '${coords[0][0]},${coords[0][1]},${coords[1][0]},${coords[1][1]},$mode';
  }

  String _getRouteCacheKey(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
    String profile,
  ) {
    final roundedOriginLat = (originLat * 1000).round() / 1000;
    final roundedOriginLng = (originLng * 1000).round() / 1000;
    final roundedDestLat = (destLat * 1000).round() / 1000;
    final roundedDestLng = (destLng * 1000).round() / 1000;
    return '$roundedOriginLat,$roundedOriginLng,$roundedDestLat,$roundedDestLng,$profile';
  }

  /// Lấy kết quả từ cache nếu còn hợp lệ
  DistanceResult? _getCachedResult(String key) {
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

    final result = _cache[key];
    if (result != null) {
      return result.copyWith(fromCache: true);
    }

    return null;
  }

  RouteResult? _getCachedRoute(String key) {
    final timestamp = _routeCacheTimestamps[key];
    if (timestamp == null) return null;
    if (DateTime.now().difference(timestamp) > _routeCacheTTL) {
      _routeCache.remove(key);
      _routeCacheTimestamps.remove(key);
      return null;
    }
    final route = _routeCache[key];
    if (route != null) {
      return route.copyWith(fromCache: true);
    }
    return null;
  }

  /// Convert độ sang radian
  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    _searchCache.clear();
    _routeCache.clear();
    _routeCacheTimestamps.clear();
    debugPrint('✅ MapBox cache cleared');
  }

  /// Get cache size (for debugging)
  int get cacheSize => _cache.length;

  /// Tìm kiếm địa điểm bằng Mapbox Geocoding API
  Future<List<MapboxPlace>> searchPlaces(
    String query, {
    int limit = 6,
    double? proximityLat,
    double? proximityLng,
    MapboxBoundingBox? boundingBox,
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return [];

    final cached = _searchCache[normalized];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) <= _searchCacheTTL) {
      debugPrint('✅ Using cached geocoding result for "$normalized"');
      return cached.results;
    }

    final encodedQuery = Uri.encodeComponent(query.trim());
    final buffer = StringBuffer(
      '${ApiConfig.mapboxBaseUrl}/geocoding/v5/mapbox.places/$encodedQuery.json'
      '?access_token=${ApiConfig.mapboxApiKey}'
      '&autocomplete=true'
      '&language=vi'
      '&limit=$limit'
      '&types=poi,address,place',
    );

    if (proximityLat != null && proximityLng != null) {
      buffer.write('&proximity=$proximityLng,$proximityLat');
    }

    if (boundingBox != null) {
      buffer.write(
        '&bbox=${boundingBox.minLng},${boundingBox.minLat},${boundingBox.maxLng},${boundingBox.maxLat}',
      );
    }

    final url = Uri.parse(buffer.toString());
    debugPrint('🔍 Mapbox Geocoding request: $url');

    final response = await _requestWithRetry(
      url,
      timeout: const Duration(seconds: 8),
      label: 'geocoding',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Mapbox geocoding error: ${response.statusCode} - ${response.body}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final features = List<Map<String, dynamic>>.from(data['features'] ?? []);

    final results = <MapboxPlace>[];
    for (final feature in features) {
      final id = feature['id'] as String? ?? '';
      final text =
          feature['text'] as String? ?? feature['place_name'] as String? ?? '';
      final placeName = feature['place_name'] as String? ?? text;
      final placeTypeList = feature['place_type'] is List
          ? feature['place_type'] as List
          : null;
      final placeType = placeTypeList != null && placeTypeList.isNotEmpty
          ? placeTypeList.first as String
          : 'poi';

      final geometry = feature['geometry'] as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'] as List?;
      if (coordinates == null || coordinates.length < 2) continue;

      final longitude = (coordinates[0] as num).toDouble();
      final latitude = (coordinates[1] as num).toDouble();

      final properties = feature['properties'] is Map<String, dynamic>
          ? feature['properties'] as Map<String, dynamic>
          : <String, dynamic>{};
      final category = properties['category'] as String?;
      final distanceMeters = properties['distance'] is num
          ? (properties['distance'] as num).toDouble()
          : null;
      final externalId = properties['external_id'] as String?;
      final contextRaw = feature['context'];
      final contextList = contextRaw is List
          ? contextRaw
                .whereType<Map<String, dynamic>>()
                .map((ctx) => Map<String, dynamic>.from(ctx))
                .toList()
          : <Map<String, dynamic>>[];
      final contextNames = contextList
          .map((ctx) => ctx['text'] as String?)
          .where((value) => value != null && value.trim().isNotEmpty)
          .cast<String>()
          .toList();
      final contextString = contextNames.isNotEmpty
          ? contextNames.join(' • ')
          : null;

      results.add(
        MapboxPlace(
          id: id,
          name: text,
          fullAddress: placeName,
          latitude: latitude,
          longitude: longitude,
          placeType: placeType,
          category: category,
          context: contextString,
          distanceMeters: distanceMeters,
          externalId: externalId,
        ),
      );
    }

    _searchCache[normalized] = _SearchCacheEntry(
      results: results,
      timestamp: DateTime.now(),
    );

    return results;
  }

  MapboxBoundingBox createBoundingBox({
    required double latitude,
    required double longitude,
    double delta = 0.1,
  }) {
    final minLat = (latitude - delta).clamp(-90.0, 90.0);
    final maxLat = (latitude + delta).clamp(-90.0, 90.0);
    final minLng = (longitude - delta).clamp(-180.0, 180.0);
    final maxLng = (longitude + delta).clamp(-180.0, 180.0);
    return MapboxBoundingBox(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    );
  }

  /// Tìm kiếm các địa điểm ăn uống gần một tọa độ cụ thể
  Future<List<MapboxPlace>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    int limit = 8,
    double radiusMeters =
        800, // Mapbox chưa hỗ trợ radius trực tiếp (chỉ dùng proximity)
    String? query,
    List<String>? categories,
  }) async {
    final normalizedQuery = (query != null && query.trim().isNotEmpty)
        ? query.trim().toLowerCase()
        : 'food';
    final normalizedCategories = categories != null && categories.isNotEmpty
        ? categories
              .map((cat) => cat.trim().toLowerCase())
              .where((cat) => cat.isNotEmpty)
              .join(',')
        : 'all';
    final cacheKey =
        'nearby:$latitude,$longitude:$limit:$radiusMeters:$normalizedQuery:$normalizedCategories';

    final cached = _searchCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) <= _searchCacheTTL) {
      debugPrint('✅ Using cached nearby search result ($cacheKey)');
      return cached.results;
    }

    final queryKeyword = (query != null && query.trim().isNotEmpty)
        ? query.trim()
        : 'restaurant';
    final encodedQuery = Uri.encodeComponent(queryKeyword);

    final buffer = StringBuffer(
      '${ApiConfig.mapboxBaseUrl}/geocoding/v5/mapbox.places/$encodedQuery.json'
      '?access_token=${ApiConfig.mapboxApiKey}'
      '&types=poi'
      '&language=vi'
      '&autocomplete=false'
      '&limit=$limit'
      '&proximity=$longitude,$latitude',
    );

    if (categories != null && categories.isNotEmpty) {
      final cleaned = categories
          .map((cat) => cat.trim().toLowerCase())
          .where((cat) => cat.isNotEmpty && _supportedCategories.contains(cat))
          .toList();
      if (cleaned.isNotEmpty) {
        buffer.write('&categories=${Uri.encodeComponent(cleaned.join(','))}');
      }
    }

    final url = Uri.parse(buffer.toString());
    debugPrint(
      '🍽️ Mapbox nearby search request: $url (radius≈${radiusMeters.toStringAsFixed(0)}m)',
    );

    final response = await _requestWithRetry(
      url,
      timeout: const Duration(seconds: 8),
      label: 'nearby-poi',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Mapbox nearby search error: ${response.statusCode} - ${response.body}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final features = List<Map<String, dynamic>>.from(data['features'] ?? []);

    final results = <MapboxPlace>[];
    for (final feature in features) {
      final id = feature['id'] as String? ?? '';
      final text =
          feature['text'] as String? ?? feature['place_name'] as String? ?? '';
      final placeName = feature['place_name'] as String? ?? text;
      final placeTypeList = feature['place_type'] is List
          ? feature['place_type'] as List
          : null;
      final placeType = placeTypeList != null && placeTypeList.isNotEmpty
          ? placeTypeList.first as String
          : 'poi';

      final geometry = feature['geometry'] as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'] as List?;
      if (coordinates == null || coordinates.length < 2) continue;

      final longitudeResult = (coordinates[0] as num).toDouble();
      final latitudeResult = (coordinates[1] as num).toDouble();

      final properties = feature['properties'] is Map<String, dynamic>
          ? feature['properties'] as Map<String, dynamic>
          : <String, dynamic>{};
      final category = properties['category'] as String?;
      final distanceMeters = properties['distance'] is num
          ? (properties['distance'] as num).toDouble()
          : null;
      final externalId = properties['external_id'] as String?;
      final contextRaw = feature['context'];
      final contextList = contextRaw is List
          ? contextRaw
                .whereType<Map<String, dynamic>>()
                .map((ctx) => Map<String, dynamic>.from(ctx))
                .toList()
          : <Map<String, dynamic>>[];
      final contextNames = contextList
          .map((ctx) => ctx['text'] as String?)
          .where((value) => value != null && value.trim().isNotEmpty)
          .cast<String>()
          .toList();
      final contextString = contextNames.isNotEmpty
          ? contextNames.join(' • ')
          : null;

      results.add(
        MapboxPlace(
          id: id,
          name: text,
          fullAddress: placeName,
          latitude: latitudeResult,
          longitude: longitudeResult,
          placeType: placeType,
          category: category,
          context: contextString,
          distanceMeters: distanceMeters,
          externalId: externalId,
        ),
      );
    }

    _searchCache[cacheKey] = _SearchCacheEntry(
      results: results,
      timestamp: DateTime.now(),
    );

    return results;
  }

  /// Lấy tuyến đường giữa 2 điểm
  Future<RouteResult?> getRoute({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String profile = 'driving',
  }) async {
    final cacheKey = _getRouteCacheKey(
      originLat,
      originLng,
      destinationLat,
      destinationLng,
      profile,
    );
    final cached = _getCachedRoute(cacheKey);
    if (cached != null) {
      debugPrint('✅ Using cached route result');
      return cached;
    }

    final coordinates = '$originLng,$originLat;$destinationLng,$destinationLat';
    final url = Uri.parse(
      '${ApiConfig.mapboxBaseUrl}/directions/v5/mapbox/$profile/$coordinates'
      '?access_token=${ApiConfig.mapboxApiKey}'
      '&alternatives=false'
      '&geometries=geojson'
      '&overview=full'
      '&language=vi'
      '&steps=true',
    );

    try {
      final response = await _requestWithRetry(
        url,
        timeout: const Duration(seconds: 15),
        label: 'directions',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Mapbox directions error: ${response.statusCode} - ${response.body}',
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final routes = List<Map<String, dynamic>>.from(data['routes'] ?? []);
      if (routes.isEmpty) {
        throw Exception('Không tìm thấy tuyến đường phù hợp.');
      }

      final route = routes.first;
      final geometry = Map<String, dynamic>.from(route['geometry'] ?? {});
      final coordinatesList = List<List>.from(
        geometry['coordinates'] as List? ?? [],
      );

      final steps = <RouteStepInfo>[];
      final legs = List<Map<String, dynamic>>.from(route['legs'] ?? []);
      if (legs.isNotEmpty) {
        final legSteps = List<Map<String, dynamic>>.from(
          legs.first['steps'] ?? [],
        );
        for (final step in legSteps) {
          final maneuverRaw = step['maneuver'];
          final maneuver = maneuverRaw is Map<String, dynamic>
              ? Map<String, dynamic>.from(maneuverRaw)
              : null;
          final nameValue = step['name'];
          final fallbackName = nameValue is String ? nameValue : '';
          final instruction =
              (maneuver?['instruction'] as String?) ?? fallbackName;
          steps.add(
            RouteStepInfo(
              instruction: instruction.trim().isEmpty
                  ? 'Tiếp tục đi thẳng'
                  : instruction.trim(),
              distance: ((step['distance'] as num?) ?? 0) / 1000,
              duration: ((step['duration'] as num?) ?? 0).toInt(),
              maneuverType: maneuver?['type'] as String?,
              maneuverModifier: maneuver?['modifier'] as String?,
              name: step['name'] as String?,
            ),
          );
        }
      }

      final mappedCoordinates = coordinatesList
          .map(
            (coord) => RouteCoordinate(
              latitude: (coord[1] as num).toDouble(),
              longitude: (coord[0] as num).toDouble(),
            ),
          )
          .toList();

      final result = RouteResult(
        coordinates: mappedCoordinates,
        distance: ((route['distance'] as num?) ?? 0) / 1000,
        duration: ((route['duration'] as num?) ?? 0).toInt(),
        profile: profile,
        steps: steps,
        fromCache: false,
      );

      _routeCache[cacheKey] = result;
      _routeCacheTimestamps[cacheKey] = DateTime.now();
      return result;
    } catch (e) {
      debugPrint('⚠️ Directions error: $e');
      rethrow;
    }
  }

  Future<http.Response> _requestWithRetry(
    Uri url, {
    required Duration timeout,
    int maxAttempts = 3,
    String label = 'request',
  }) async {
    int attempt = 0;
    while (attempt < maxAttempts) {
      attempt++;
      try {
        final response = await _httpClient
            .get(url)
            .timeout(
              timeout,
              onTimeout: () {
                throw TimeoutException('Request timeout');
              },
            );
        return response;
      } catch (e) {
        if (attempt >= maxAttempts) rethrow;
        final backoff = Duration(milliseconds: 300 * attempt * attempt);
        debugPrint(
          '⚠️ $label attempt $attempt failed ($e). Retrying in ${backoff.inMilliseconds}ms',
        );
        await Future<void>.delayed(backoff);
      }
    }
    throw Exception('Unknown error when calling $label');
  }
}

/// Extension để thêm copyWith cho DistanceResult
extension DistanceResultCopyWith on DistanceResult {
  DistanceResult copyWith({
    double? distance,
    int? duration,
    String? mode,
    bool? fromCache,
  }) {
    return DistanceResult(
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      mode: mode ?? this.mode,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}

extension RouteResultCopyWith on RouteResult {
  RouteResult copyWith({
    List<RouteCoordinate>? coordinates,
    double? distance,
    int? duration,
    String? profile,
    List<RouteStepInfo>? steps,
    bool? fromCache,
  }) {
    return RouteResult(
      coordinates: coordinates ?? this.coordinates,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      profile: profile ?? this.profile,
      steps: steps ?? this.steps,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}

class _SearchCacheEntry {
  final List<MapboxPlace> results;
  final DateTime timestamp;

  _SearchCacheEntry({required this.results, required this.timestamp});
}
