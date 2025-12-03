import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:smart_travel_app/models/tours/tour_package.dart';

/// Script để import tour packages từ JSON vào Firestore
class TourPackageImporter {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'tour_packages';

  /// Import từ file JSON
  static Future<void> importFromJson(String jsonPath) async {
    try {
      print('📦 Bắt đầu import tour packages từ $jsonPath...');

      // Đọc file JSON
      final jsonString = await rootBundle.loadString(jsonPath);
      final List<dynamic> jsonList = json.decode(jsonString);

      print('📊 Tìm thấy ${jsonList.length} tour packages');

      int successCount = 0;
      int errorCount = 0;

      for (final jsonData in jsonList) {
        try {
          // Parse tour package
          final tourPackage = TourPackage.fromMap(jsonData as Map<String, dynamic>);

          // Tạo document ID từ id trong JSON hoặc tự động
          final docId = tourPackage.id ?? _firestore.collection(_collection).doc().id;

          // Convert sang Map với computed fields
          final data = tourPackage.toMap();
          data['id'] = docId;

          // Thêm computed fields
          data['destination_lowercase'] = tourPackage.destination.toLowerCase();
          data['title_lowercase'] = tourPackage.title.toLowerCase();
          data['tags'] = [
            ...tourPackage.destinations.map((d) => d.toLowerCase()),
            ...tourPackage.title.toLowerCase().split(' '),
          ];

          // Tính priceRange
          double minPrice = tourPackage.basePrice;
          double maxPrice = tourPackage.basePrice;
          if (tourPackage.priceTiers.isNotEmpty) {
            final prices =
                tourPackage.priceTiers.map((t) => t.pricePerPerson).toList();
            minPrice = prices.reduce((a, b) => a < b ? a : b);
            maxPrice = prices.reduce((a, b) => a > b ? a : b);
          }
          data['priceRange'] = {'min': minPrice, 'max': maxPrice};

          // Lưu vào Firestore
          await _firestore.collection(_collection).doc(docId).set(data);

          successCount++;
          print('✅ Đã import: ${tourPackage.title} (ID: $docId)');
        } catch (e) {
          errorCount++;
          print('❌ Lỗi import tour: ${jsonData['title'] ?? 'Unknown'}: $e');
        }
      }

      print('✅ Hoàn thành!');
      print('   - Thành công: $successCount');
      print('   - Lỗi: $errorCount');
    } catch (e) {
      print('❌ Lỗi import: $e');
      rethrow;
    }
  }

  /// Import một tour package đơn lẻ (dùng cho testing)
  static Future<String> importSingleTour(Map<String, dynamic> jsonData) async {
    try {
      final tourPackage = TourPackage.fromMap(jsonData);
      final docId = tourPackage.id ?? _firestore.collection(_collection).doc().id;

      final data = tourPackage.toMap();
      data['id'] = docId;

      // Thêm computed fields
      data['destination_lowercase'] = tourPackage.destination.toLowerCase();
      data['title_lowercase'] = tourPackage.title.toLowerCase();
      data['tags'] = [
        ...tourPackage.destinations.map((d) => d.toLowerCase()),
        ...tourPackage.title.toLowerCase().split(' '),
      ];

      // Tính priceRange
      double minPrice = tourPackage.basePrice;
      double maxPrice = tourPackage.basePrice;
      if (tourPackage.priceTiers.isNotEmpty) {
        final prices =
            tourPackage.priceTiers.map((t) => t.pricePerPerson).toList();
        minPrice = prices.reduce((a, b) => a < b ? a : b);
        maxPrice = prices.reduce((a, b) => a > b ? a : b);
      }
      data['priceRange'] = {'min': minPrice, 'max': maxPrice};

      await _firestore.collection(_collection).doc(docId).set(data);
      return docId;
    } catch (e) {
      print('❌ Lỗi import single tour: $e');
      rethrow;
    }
  }
}

