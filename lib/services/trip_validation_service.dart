import 'package:flutter/foundation.dart';
import '../models/destination.dart';
import '../models/trip_item.dart';
import 'mapbox_service.dart';
import 'destination_suggestion_service.dart';

/// Kết quả validation điểm đến
class ValidationResult {
  final bool isValid; // Có hợp lệ không
  final String? warningMessage; // Thông báo cảnh báo (nếu có)
  final double? distance; // Khoảng cách đến điểm gần nhất (km)
  final int? estimatedDuration; // Thời gian di chuyển ước tính (giây)
  final DistanceResult? distanceResult; // Kết quả chi tiết từ MapBox
  final List<Destination>? suggestedDestinations; // Điểm đến gần hơn (sẽ được thêm ở Phase 3)
  final Destination? comparedDestination; // Điểm đã chọn được dùng để so sánh

  ValidationResult({
    required this.isValid,
    this.warningMessage,
    this.distance,
    this.estimatedDuration,
    this.distanceResult,
    this.suggestedDestinations,
    this.comparedDestination,
  });

  /// Validation hợp lệ (không có cảnh báo)
  factory ValidationResult.valid() {
    return ValidationResult(isValid: true);
  }

  /// Validation không hợp lệ (có cảnh báo)
  factory ValidationResult.invalid({
    required String warningMessage,
    double? distance,
    int? estimatedDuration,
    DistanceResult? distanceResult,
    List<Destination>? suggestedDestinations,
    Destination? comparedDestination,
  }) {
    return ValidationResult(
      isValid: false,
      warningMessage: warningMessage,
      distance: distance,
      estimatedDuration: estimatedDuration,
      distanceResult: distanceResult,
      suggestedDestinations: suggestedDestinations,
      comparedDestination: comparedDestination,
    );
  }
}

/// Service để validate điểm đến mới với các điểm đã chọn trong trip
class TripValidationService {
  TripValidationService._();
  static final TripValidationService instance = TripValidationService._();

  final MapBoxService _mapboxService = MapBoxService.instance;
  final DestinationSuggestionService _suggestionService = DestinationSuggestionService.instance;

  /// Validate điểm đến mới với các điểm đã chọn
  /// 
  /// [newDestination]: Điểm đến mới muốn thêm
  /// [existingItems]: Danh sách các điểm đã chọn trong trip
  /// [tripDays]: Số ngày du lịch
  /// [plannedDate]: Ngày dự kiến thăm điểm mới (nếu null, sẽ so với tất cả các điểm)
  /// 
  /// Returns ValidationResult
  Future<ValidationResult> validateDestination(
    Destination newDestination,
    List<TripItem> existingItems,
    int tripDays, {
    DateTime? plannedDate,
  }) async {
    // Nếu chưa có điểm nào, luôn hợp lệ
    if (existingItems.isEmpty) {
      debugPrint('✅ No existing items, destination is valid');
      return ValidationResult.valid();
    }

    // Lấy các điểm đến trong cùng ngày hoặc ngày gần nhất
    final relevantItems = _getRelevantItems(existingItems, plannedDate);
    
    if (relevantItems.isEmpty) {
      debugPrint('✅ No relevant items for comparison, destination is valid');
      return ValidationResult.valid();
    }

    // Tính khoảng cách đến điểm gần nhất và xa nhất
    double? maxDistance;
    DistanceResult? maxDistanceResult;
    double? nearestDistance;
    Destination? comparedDestination; // Điểm đã chọn được dùng để so sánh (điểm xa nhất)

    for (var item in relevantItems) {
      if (item.destination == null) continue;

      try {
        debugPrint('🔍 Calculating distance:');
        debugPrint('   From: ${item.destination!.name} (${item.destination!.location.latitude}, ${item.destination!.location.longitude})');
        debugPrint('   To: ${newDestination.name} (${newDestination.location.latitude}, ${newDestination.location.longitude})');
        
        final result = await _mapboxService.calculateDistance(
          item.destination!.location.latitude,
          item.destination!.location.longitude,
          newDestination.location.latitude,
          newDestination.location.longitude,
          mode: 'driving',
        );

        if (result != null) {
          debugPrint('✅ Distance calculated: ${result.distance.toStringAsFixed(2)} km');
          
          if (maxDistance == null || result.distance > maxDistance) {
            maxDistance = result.distance;
            maxDistanceResult = result;
            comparedDestination = item.destination; // Lưu điểm đã chọn xa nhất
            debugPrint('   📍 This is the maximum distance so far');
          }
          if (nearestDistance == null || result.distance < nearestDistance) {
            nearestDistance = result.distance;
          }
        } else {
          debugPrint('⚠️ MapBox API returned null, using Haversine fallback');
        }
      } catch (e, stack) {
        debugPrint('⚠️ Error calculating distance: $e');
        debugPrint('$stack');
      }
    }

    // Nếu không tính được khoảng cách, coi như hợp lệ (fallback)
    if (maxDistance == null || maxDistanceResult == null) {
      debugPrint('⚠️ Could not calculate distance, assuming valid');
      return ValidationResult.valid();
    }

    // Kiểm tra ngưỡng dựa trên số ngày
    final threshold = _getDistanceThreshold(tripDays);
    final warningLevel = _getWarningLevel(tripDays, maxDistance);

    if (maxDistance > threshold) {
      // Tạo thông báo cảnh báo
      final warningMessage = _buildWarningMessage(
        newDestination,
        maxDistance,
        maxDistanceResult,
        tripDays,
        warningLevel,
        comparedDestination,
      );

      // Lấy danh sách điểm đến gợi ý (gần điểm đã chọn, không phải điểm mới)
      List<Destination>? suggestedDestinations;
      try {
        // Lấy danh sách ID các điểm đã chọn để loại trừ
        final excludeIds = relevantItems
            .where((item) => item.destination?.id != null)
            .map((item) => item.destination!.id!)
            .toList();
        
        // Thêm chính target destination vào excludeIds
        if (newDestination.id != null) {
          excludeIds.add(newDestination.id!);
        }

        // Gợi ý các điểm gần điểm đã chọn (comparedDestination), không phải điểm mới
        // Nếu không có comparedDestination, dùng điểm đầu tiên trong relevantItems
        final suggestionTarget = comparedDestination ?? 
            (relevantItems.isNotEmpty && relevantItems.first.destination != null
                ? relevantItems.first.destination!
                : null);

        if (suggestionTarget != null) {
          final suggestions = await _suggestionService.suggestNearbyDestinations(
            suggestionTarget, // Gợi ý gần điểm đã chọn
            maxDistance: maxDistance * 0.5, // Chỉ gợi ý các điểm gần hơn 50% khoảng cách hiện tại
            limit: 5,
            excludeIds: excludeIds,
          );

          // Lưu cả destination và distance info (sẽ được dùng trong UI)
          suggestedDestinations = suggestions
              .map((s) => s.destination)
              .toList();
          
          // Lưu thông tin khoảng cách vào cache tạm thời (sẽ được dùng trong UI)
          // Note: Có thể cải thiện bằng cách thêm Map<Destination, double> vào ValidationResult
          // Nhưng để đơn giản, UI sẽ tính lại khoảng cách nếu cần

          debugPrint('💡 Found ${suggestedDestinations.length} suggested destinations near ${suggestionTarget.name}');
        }
      } catch (e) {
        debugPrint('⚠️ Error getting suggestions: $e');
        // Không fail validation nếu không lấy được suggestions
      }

      debugPrint('⚠️ Destination validation failed: $warningMessage');

      return ValidationResult.invalid(
        warningMessage: warningMessage,
        distance: maxDistance,
        estimatedDuration: maxDistanceResult.duration,
        distanceResult: maxDistanceResult,
        suggestedDestinations: suggestedDestinations,
        comparedDestination: comparedDestination,
      );
    }

    debugPrint('✅ Destination validation passed (distance: ${maxDistance.toStringAsFixed(1)} km)');
    return ValidationResult.valid();
  }

  /// Lấy các điểm đến liên quan để so sánh
  /// - Nếu có plannedDate: lấy các điểm trong cùng ngày
  /// - Nếu không có plannedDate: lấy tất cả các điểm
  List<TripItem> _getRelevantItems(
    List<TripItem> existingItems,
    DateTime? plannedDate,
  ) {
    if (plannedDate == null) {
      return existingItems.where((item) => item.destination != null).toList();
    }

    // Lấy các điểm trong cùng ngày
    final sameDayItems = existingItems.where((item) {
      if (item.destination == null || item.plannedDate == null) {
        return false;
      }
      final itemDate = DateTime(
        item.plannedDate!.year,
        item.plannedDate!.month,
        item.plannedDate!.day,
      );
      final targetDate = DateTime(
        plannedDate.year,
        plannedDate.month,
        plannedDate.day,
      );
      return itemDate.isAtSameMomentAs(targetDate);
    }).toList();

    // Nếu không có điểm trong cùng ngày, lấy điểm gần nhất
    if (sameDayItems.isEmpty) {
      TripItem? nearestItem;
      Duration? nearestDuration;

      for (var item in existingItems) {
        if (item.destination == null || item.plannedDate == null) continue;

        final itemDate = DateTime(
          item.plannedDate!.year,
          item.plannedDate!.month,
          item.plannedDate!.day,
        );
        final targetDate = DateTime(
          plannedDate.year,
          plannedDate.month,
          plannedDate.day,
        );

        final duration = (itemDate.difference(targetDate)).abs();
        if (nearestDuration == null || duration < nearestDuration) {
          nearestDuration = duration;
          nearestItem = item;
        }
      }

      if (nearestItem != null) {
        return [nearestItem];
      }
    }

    return sameDayItems;
  }

  /// Lấy ngưỡng khoảng cách dựa trên số ngày du lịch
  double _getDistanceThreshold(int tripDays) {
    if (tripDays <= 1) {
      return 200; // 200km cho 1 ngày
    } else if (tripDays <= 2) {
      return 500; // 500km cho 2 ngày
    } else if (tripDays <= 4) {
      return 800; // 800km cho 3-4 ngày
    } else {
      return 1000; // 1000km cho 5+ ngày (không cảnh báo)
    }
  }

  /// Lấy mức độ cảnh báo
  /// Returns: 'strong', 'medium', 'light', hoặc null (không cảnh báo)
  String? _getWarningLevel(int tripDays, double distance) {
    final threshold = _getDistanceThreshold(tripDays);
    
    if (distance <= threshold) {
      return null; // Không cảnh báo
    }

    if (tripDays <= 1) {
      return 'strong'; // Cảnh báo mạnh
    } else if (tripDays <= 2) {
      return 'medium'; // Cảnh báo
    } else if (tripDays <= 4) {
      return 'light'; // Cảnh báo nhẹ
    } else {
      return null; // Không cảnh báo
    }
  }

  /// Tạo thông báo cảnh báo
  String _buildWarningMessage(
    Destination newDestination,
    double distance,
    DistanceResult distanceResult,
    int tripDays,
    String? warningLevel,
    Destination? comparedDestination,
  ) {
    final buffer = StringBuffer();
    
    // Phần đầu: Mô tả vấn đề
    buffer.writeln('Điểm đến bạn chọn có khoảng cách khá xa so với các điểm đã chọn:');
    buffer.writeln('');
    if (comparedDestination != null) {
      buffer.writeln('📍 ${comparedDestination.name} → ${newDestination.name}');
    } else {
      buffer.writeln('📍 ${newDestination.name}');
    }
    buffer.writeln('📏 Khoảng cách: ${distanceResult.distanceFormatted}');
    buffer.writeln('⏱️ Thời gian di chuyển: ${distanceResult.durationFormatted}');
    buffer.writeln('');

    // Phần cảnh báo dựa trên mức độ
    if (warningLevel == 'strong') {
      buffer.writeln('⚠️ Với $tripDays ngày du lịch, việc di chuyển này có thể không hợp lý.');
      buffer.writeln('Bạn có thể không có đủ thời gian để tham quan đầy đủ các điểm đến.');
    } else if (warningLevel == 'medium') {
      buffer.writeln('⚠️ Với $tripDays ngày du lịch, việc di chuyển này có thể không hợp lý.');
      buffer.writeln('Bạn nên cân nhắc thời gian di chuyển và thời gian tham quan.');
    } else if (warningLevel == 'light') {
      buffer.writeln('💡 Với $tripDays ngày du lịch, bạn có thể cân nhắc các điểm đến gần hơn');
      buffer.writeln('để tối ưu thời gian và trải nghiệm.');
    }

    // Gợi ý (sẽ được thêm ở Phase 3)
    buffer.writeln('');
    buffer.writeln('💡 Gợi ý: Bạn có thể xem các điểm đến gần hơn trong cùng khu vực.');

    return buffer.toString();
  }

  /// Validate nhiều điểm đến cùng lúc (batch validation)
  /// Returns Map với key là destination ID và value là ValidationResult
  Future<Map<String, ValidationResult>> validateDestinations(
    List<Destination> newDestinations,
    List<TripItem> existingItems,
    int tripDays,
  ) async {
    final results = <String, ValidationResult>{};

    for (var destination in newDestinations) {
      final result = await validateDestination(
        destination,
        existingItems,
        tripDays,
      );
      // Chỉ thêm vào results nếu có ID
      if (destination.id != null) {
        results[destination.id!] = result;
      }
    }

    return results;
  }
}

