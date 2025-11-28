import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:smart_travel_app/models/ai/ai_activity_suggestion.dart';

/// Validation result cho AI suggestions
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  ValidationResult.valid() : this(isValid: true);
  
  ValidationResult.invalid(List<String> errors, [List<String>? warnings]) 
    : this(isValid: false, errors: errors, warnings: warnings ?? []);
}

/// Validator cho AI destination với rules cụ thể cho Việt Nam
class AIDestinationValidator {
  // Phạm vi tọa độ Việt Nam
  static const double _minLatitude = 8.5;   // Cà Mau
  static const double _maxLatitude = 23.5;  // Lào Cai
  static const double _minLongitude = 102.0; // Điện Biên
  static const double _maxLongitude = 110.0; // Cà Mau

  // Danh sách thành phố lớn
  static const List<String> _majorCities = [
    'Hà Nội', 'TP.HCM', 'Đà Nẵng', 'Hội An', 'Huế', 'Nha Trang', 
    'Cần Thơ', 'Vũng Tàu', 'Đà Lạt', 'Phú Quốc', 'Hạ Long',
    'Sapa', 'Ninh Bình', 'Hải Phòng', 'Quy Nhon', 'Phan Thiết'
  ];

  // Categories được phép
  static const List<String> _allowedCategories = [
    'restaurant', 'cafe', 'street-food', 'local-food', 'food',
    'attraction', 'culture', 'temple', 'museum',
    'shopping', 'nature', 'entertainment', 'hotel'
  ];

  // Từ cấm trong tên
  static const List<String> _bannedWords = [
    'unknown', 'n/a', 'test', 'restaurant', 'cafe', 'shop', 'place',
    'location', 'venue', 'establishment', 'business', 'store'
  ];

  /// Validate toàn bộ AI suggestion
  static ValidationResult validateSuggestion(AIActivitySuggestion suggestion) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate coordinates
    final coordResult = validateCoordinates(suggestion.latitude, suggestion.longitude);
    if (!coordResult.isValid) {
      errors.addAll(coordResult.errors);
    }
    warnings.addAll(coordResult.warnings);

    // Validate name
    final nameResult = validateName(suggestion.activityName);
    if (!nameResult.isValid) {
      errors.addAll(nameResult.errors);
    }
    warnings.addAll(nameResult.warnings);

    // Validate description
    final descResult = validateDescription(suggestion.description);
    if (!descResult.isValid) {
      errors.addAll(descResult.errors);
    }
    warnings.addAll(descResult.warnings);

    // Validate category
    final categoryResult = validateCategory(suggestion.category);
    if (!categoryResult.isValid) {
      errors.addAll(categoryResult.errors);
    }
    warnings.addAll(categoryResult.warnings);

    // Validate address
    if (suggestion.address != null) {
      final addressResult = validateAddress(suggestion.address!);
      if (!addressResult.isValid) {
        errors.addAll(addressResult.errors);
      }
      warnings.addAll(addressResult.warnings);
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Kiểm tra tọa độ hợp lệ (trong phạm vi Việt Nam)
  static ValidationResult validateCoordinates(double? lat, double? lng) {
    final errors = <String>[];
    final warnings = <String>[];

    if (lat == null || lng == null) {
      errors.add('Thiếu tọa độ latitude hoặc longitude');
      return ValidationResult.invalid(errors);
    }

    // Kiểm tra phạm vi Việt Nam
    if (lat < _minLatitude || lat > _maxLatitude) {
      errors.add('Latitude $lat nằm ngoài phạm vi Việt Nam ($_minLatitude - $_maxLatitude)');
    }

    if (lng < _minLongitude || lng > _maxLongitude) {
      errors.add('Longitude $lng nằm ngoài phạm vi Việt Nam ($_minLongitude - $_maxLongitude)');
    }

    // Kiểm tra precision (ít nhất 4 chữ số thập phân) - chỉ warn nếu thực sự thấp
    final latPrecision = lat.toString().split('.').length > 1 ? lat.toString().split('.')[1].length : 0;
    final lngPrecision = lng.toString().split('.').length > 1 ? lng.toString().split('.')[1].length : 0;
    
    if (latPrecision < 3) { // Chỉ warn nếu < 3 chữ số (quá thấp)
      warnings.add('Latitude precision thấp ($latPrecision chữ số, nên có ít nhất 4 chữ số thập phân)');
    }
    
    if (lngPrecision < 3) { // Chỉ warn nếu < 3 chữ số (quá thấp)
      warnings.add('Longitude precision thấp ($lngPrecision chữ số, nên có ít nhất 4 chữ số thập phân)');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Kiểm tra tên địa điểm (theo pattern @data)
  static ValidationResult validateName(String name) {
    final errors = <String>[];
    final warnings = <String>[];

    // Kiểm tra độ dài
    if (name.trim().length < 5) {
      errors.add('Tên địa điểm quá ngắn (tối thiểu 5 ký tự)');
    }

    if (name.trim().length > 100) {
      errors.add('Tên địa điểm quá dài (tối đa 100 ký tự)');
    }

    // Kiểm tra từ cấm
    final nameLower = name.toLowerCase();
    for (final bannedWord in _bannedWords) {
      if (nameLower.contains(bannedWord)) {
        errors.add('Tên chứa từ không được phép: "$bannedWord"');
      }
    }

    // Kiểm tra pattern generic
    if (RegExp(r'^(restaurant|cafe|shop|place)\s*\d*$', caseSensitive: false).hasMatch(name)) {
      errors.add('Tên quá generic, cần cụ thể hơn');
    }

    // Kiểm tra có ít nhất 1 từ có nghĩa
    if (name.trim().split(' ').length < 2) {
      warnings.add('Tên nên có ít nhất 2 từ để cụ thể hơn');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Kiểm tra mô tả (theo style @data)
  static ValidationResult validateDescription(String description) {
    final errors = <String>[];
    final warnings = <String>[];

    // Kiểm tra độ dài
    if (description.trim().length < 50) {
      errors.add('Mô tả quá ngắn (tối thiểu 50 ký tự)');
    }

    if (description.trim().length > 1000) {
      errors.add('Mô tả quá dài (tối đa 1000 ký tự)');
    }

    // Kiểm tra có nội dung cụ thể
    if (description.toLowerCase().contains('lorem ipsum') ||
        description.toLowerCase().contains('placeholder') ||
        description.toLowerCase().contains('sample text')) {
      errors.add('Mô tả chứa placeholder text');
    }

    // Kiểm tra style tiếng Việt
    if (!RegExp(r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]').hasMatch(description)) {
      warnings.add('Mô tả không chứa ký tự tiếng Việt, có thể không phù hợp');
    }

    // Kiểm tra độ dài câu
    final sentences = description.split(RegExp(r'[.!?]'));
    if (sentences.length < 2) {
      warnings.add('Mô tả nên có ít nhất 2 câu để chi tiết hơn');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Kiểm tra category hợp lệ
  static ValidationResult validateCategory(String? category) {
    final errors = <String>[];
    final warnings = <String>[];

    if (category == null || category.trim().isEmpty) {
      errors.add('Category không được để trống');
      return ValidationResult.invalid(errors);
    }

    if (!_allowedCategories.contains(category.toLowerCase())) {
      errors.add('Category "$category" không được hỗ trợ. Allowed: ${_allowedCategories.join(', ')}');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Kiểm tra địa chỉ có format chuẩn
  static ValidationResult validateAddress(String address) {
    final errors = <String>[];
    final warnings = <String>[];

    // Kiểm tra độ dài
    if (address.trim().length < 10) {
      errors.add('Địa chỉ quá ngắn (tối thiểu 10 ký tự)');
    }

    // Kiểm tra có chứa thành phố Việt Nam
    bool hasVietnameseCity = false;
    for (final city in _majorCities) {
      if (address.contains(city)) {
        hasVietnameseCity = true;
        break;
      }
    }

    if (!hasVietnameseCity) {
      warnings.add('Địa chỉ không chứa tên thành phố Việt Nam nổi tiếng');
    }

    // Kiểm tra format cơ bản (có số nhà, tên đường)
    if (!RegExp(r'\d+').hasMatch(address)) {
      warnings.add('Địa chỉ nên có số nhà');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Kiểm tra không trùng lặp (trong bán kính 100m)
  static Future<ValidationResult> checkDuplicateLocation(
    double lat, 
    double lng, 
    List<Map<String, dynamic>> existingDestinations
  ) async {
    final errors = <String>[];
    final warnings = <String>[];

    const double duplicateThresholdKm = 0.1; // 100m

    for (final existing in existingDestinations) {
      final existingLat = existing['location']?['latitude'] as double?;
      final existingLng = existing['location']?['longitude'] as double?;
      
      if (existingLat != null && existingLng != null) {
        final distance = _calculateDistance(lat, lng, existingLat, existingLng);
        
        if (distance < duplicateThresholdKm) {
          errors.add('Địa điểm trùng lặp với "${existing['name']}" (cách ${(distance * 1000).toInt()}m)');
        } else if (distance < 0.5) { // 500m warning
          warnings.add('Gần địa điểm "${existing['name']}" (cách ${(distance * 1000).toInt()}m)');
        }
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Tính khoảng cách Haversine giữa 2 điểm (km)
  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // km
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    
    final a = 
        (dLat / 2).sin() * (dLat / 2).sin() +
        lat1.cos() * lat2.cos() * 
        (dLng / 2).sin() * (dLng / 2).sin();
    
    final c = 2 * a.sqrt().asin();
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  /// Log validation result cho debugging
  static void logValidationResult(ValidationResult result, String suggestionName) {
    if (!result.isValid) {
      debugPrint('❌ Validation failed for "$suggestionName":');
      for (final error in result.errors) {
        debugPrint('  - $error');
      }
    }
    
    if (result.warnings.isNotEmpty) {
      debugPrint('⚠️ Validation warnings for "$suggestionName":');
      for (final warning in result.warnings) {
        debugPrint('  - $warning');
      }
    }
    
    if (result.isValid && result.warnings.isEmpty) {
      debugPrint('✅ Validation passed for "$suggestionName"');
    }
  }
}

// Extension để dễ sử dụng
extension DoubleExtension on double {
  double sin() => math.sin(this);
  double cos() => math.cos(this);
  double asin() => math.asin(this);
  double sqrt() => math.sqrt(this);
}
