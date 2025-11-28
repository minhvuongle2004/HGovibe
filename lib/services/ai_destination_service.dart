import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:smart_travel_app/models/ai/ai_activity_suggestion.dart';
import 'package:smart_travel_app/models/destinations/destination.dart';
import 'ai_destination_builder.dart';
import 'ai_destination_validator.dart';

/// Service để tạo và quản lý destinations từ AI suggestions
class AIDestinationService {
  AIDestinationService._({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static final AIDestinationService instance = AIDestinationService._();

  final FirebaseFirestore _firestore;

  @visibleForTesting
  factory AIDestinationService.testing(FirebaseFirestore firestore) {
    return AIDestinationService._(firestore: firestore);
  }

  /// Collection reference cho destinations
  CollectionReference<Map<String, dynamic>> get _destinationsRef =>
      _firestore.collection('destinations');

  /// Tạo destination từ AI suggestion với validation
  Future<Destination> createDestinationFromSuggestion(
    AIActivitySuggestion suggestion,
  ) async {
    debugPrint('🔍 Validating AI suggestion: ${suggestion.activityName}');
    debugPrint('  - Category: ${suggestion.category}');
    debugPrint('  - Coordinates: ${suggestion.latitude}, ${suggestion.longitude}');
    debugPrint('  - Address: ${suggestion.address ?? "N/A"}');
    
    // 1. Validate suggestion trước
    final validation = AIDestinationValidator.validateSuggestion(suggestion);
    AIDestinationValidator.logValidationResult(validation, suggestion.activityName);
    
    if (!validation.isValid) {
      debugPrint('❌ Validation failed: ${validation.errors.join('; ')}');
      throw ValidationException(
        'AI suggestion không hợp lệ: ${validation.errors.join(', ')}',
        validation.errors,
        validation.warnings,
      );
    }
    
    if (validation.warnings.isNotEmpty) {
      debugPrint('⚠️ Validation warnings (non-blocking): ${validation.warnings.join('; ')}');
    }

      // 2. Kiểm tra duplicate location (chỉ nếu có tọa độ)
      if (suggestion.latitude != null && suggestion.longitude != null) {
        final existingDestinations = await _getNearbyDestinations(
          suggestion.latitude!,
          suggestion.longitude!,
          radiusKm: 0.1, // 100m
        );

        if (existingDestinations.isNotEmpty) {
          final duplicateCheck = await AIDestinationValidator.checkDuplicateLocation(
            suggestion.latitude!,
            suggestion.longitude!,
            existingDestinations,
          );

          if (!duplicateCheck.isValid) {
            debugPrint('⚠️ Duplicate location detected: ${duplicateCheck.errors.join('; ')}');
            throw DuplicateLocationException(
              'Địa điểm đã tồn tại: ${duplicateCheck.errors.join(', ')}',
              existingDestinations.first,
            );
          }
        }
      } else {
        debugPrint('⚠️ No coordinates provided, skipping duplicate check');
      }

    // 3. Build destination từ template
    final destination = AIDestinationBuilder.buildFromSuggestion(suggestion);
    
    debugPrint('✅ Created destination from AI suggestion: ${destination.name}');
    return destination;
  }

  /// Lưu destination với status pending review
  Future<String> saveAIDestination(Destination destination) async {
    try {
      final data = destination.toMap();
      
      // Thêm metadata cho AI destinations
      data['createdBy'] = 'ai';
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      data['needsReview'] = true; // Flag cho moderation
      
      final docRef = await _destinationsRef.add(data);
      
      debugPrint('✅ AI destination saved to Firestore: ${docRef.id}');
      return docRef.id;
    } catch (e, stack) {
      debugPrint('❌ Error saving AI destination: $e');
      debugPrint('$stack');
      rethrow;
    }
  }

  /// Kiểm tra destination đã tồn tại chưa (theo tọa độ + tên)
  Future<Destination?> findExistingDestination(
    AIActivitySuggestion suggestion,
  ) async {
    try {
      if (suggestion.latitude == null || suggestion.longitude == null) {
        return null;
      }

      // Tìm destinations gần đó (trong bán kính 500m)
      final nearbyDestinations = await _getNearbyDestinations(
        suggestion.latitude!,
        suggestion.longitude!,
        radiusKm: 0.5,
      );

      // Kiểm tra tên tương tự
      for (final destData in nearbyDestinations) {
        final existingName = destData['name']?.toString().toLowerCase() ?? '';
        final suggestionName = suggestion.activityName.toLowerCase();
        
        // Kiểm tra similarity đơn giản
        if (_calculateNameSimilarity(existingName, suggestionName) > 0.8) {
          debugPrint('🔍 Found similar destination: $existingName vs $suggestionName');
          return Destination.fromFirestore(
            _firestore.doc('destinations/${destData['id']}') as DocumentSnapshot<Map<String, dynamic>>,
          );
        }
      }

      return null;
    } catch (e, stack) {
      debugPrint('❌ Error finding existing destination: $e');
      debugPrint('$stack');
      return null;
    }
  }

  /// Lấy destinations gần một tọa độ
  Future<List<Map<String, dynamic>>> _getNearbyDestinations(
    double lat,
    double lng,
    {double radiusKm = 1.0}
  ) async {
    try {
      // Tính bounding box để query hiệu quả
      final boundingBox = _calculateBoundingBox(lat, lng, radiusKm);
      
      final query = await _destinationsRef
          .where('location.latitude', isGreaterThanOrEqualTo: boundingBox['minLat'])
          .where('location.latitude', isLessThanOrEqualTo: boundingBox['maxLat'])
          .limit(50) // Giới hạn để tránh quá nhiều results
          .get();

      final results = <Map<String, dynamic>>[];
      
      for (final doc in query.docs) {
        final data = doc.data();
        final destLat = data['location']?['latitude'] as double?;
        final destLng = data['location']?['longitude'] as double?;
        
        if (destLat != null && destLng != null) {
          final distance = _calculateDistance(lat, lng, destLat, destLng);
          
          if (distance <= radiusKm) {
            data['id'] = doc.id;
            data['distance'] = distance;
            results.add(data);
          }
        }
      }
      
      // Sort by distance
      results.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      
      debugPrint('🔍 Found ${results.length} destinations within ${radiusKm}km');
      return results;
    } catch (e, stack) {
      debugPrint('❌ Error getting nearby destinations: $e');
      debugPrint('$stack');
      return [];
    }
  }

  /// Tính bounding box cho query hiệu quả
  Map<String, double> _calculateBoundingBox(double lat, double lng, double radiusKm) {
    // Approximation: 1 degree ≈ 111km
    final latDelta = radiusKm / 111.0;
    final lngDelta = radiusKm / (111.0 * math.cos(lat));
    
    return {
      'minLat': lat - latDelta,
      'maxLat': lat + latDelta,
      'minLng': lng - lngDelta,
      'maxLng': lng + lngDelta,
    };
  }

  /// Tính khoảng cách Haversine giữa 2 điểm (km)
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // km
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    
    final a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * 
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    final c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  /// Tính độ tương tự giữa 2 tên (simple Levenshtein-based)
  double _calculateNameSimilarity(String name1, String name2) {
    if (name1 == name2) return 1.0;
    if (name1.isEmpty || name2.isEmpty) return 0.0;
    
    // Simple similarity check
    final longer = name1.length > name2.length ? name1 : name2;
    final shorter = name1.length > name2.length ? name2 : name1;
    
    if (longer.length == 0) return 1.0;
    
    final editDistance = _levenshteinDistance(longer, shorter);
    return (longer.length - editDistance) / longer.length;
  }

  /// Tính Levenshtein distance
  int _levenshteinDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;
    
    final matrix = List.generate(len1 + 1, (i) => List.filled(len2 + 1, 0));
    
    for (int i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    
    for (int j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }
    
    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[len1][len2];
  }

  /// Get destination by ID
  Future<Destination?> getDestination(String destinationId) async {
    try {
      final doc = await _destinationsRef.doc(destinationId).get();
      if (doc.exists) {
        return Destination.fromFirestore(doc);
      }
      return null;
    } catch (e, stack) {
      debugPrint('❌ Error getting destination: $e');
      debugPrint('$stack');
      return null;
    }
  }

  /// Approve AI destination (chuyển từ pending sang active)
  Future<void> approveDestination(String destinationId) async {
    try {
      await _destinationsRef.doc(destinationId).update({
        'status': 'active',
        'verified': true,
        'needsReview': false,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ AI destination approved: $destinationId');
    } catch (e, stack) {
      debugPrint('❌ Error approving destination: $e');
      debugPrint('$stack');
      rethrow;
    }
  }

  /// Reject AI destination
  Future<void> rejectDestination(String destinationId, String reason) async {
    try {
      await _destinationsRef.doc(destinationId).update({
        'status': 'rejected',
        'needsReview': false,
        'rejectionReason': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ AI destination rejected: $destinationId - $reason');
    } catch (e, stack) {
      debugPrint('❌ Error rejecting destination: $e');
      debugPrint('$stack');
      rethrow;
    }
  }
}

// No need for extension - using math directly

/// Custom exceptions
class ValidationException implements Exception {
  final String message;
  final List<String> errors;
  final List<String> warnings;
  
  ValidationException(this.message, this.errors, this.warnings);
  
  @override
  String toString() => 'ValidationException: $message';
}

class DuplicateLocationException implements Exception {
  final String message;
  final Map<String, dynamic> existingDestination;
  
  DuplicateLocationException(this.message, this.existingDestination);
  
  @override
  String toString() => 'DuplicateLocationException: $message';
}
