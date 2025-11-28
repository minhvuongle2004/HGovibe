import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImportData {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Import tất cả data
  static Future<void> importAllDestinations() async {
    try {
      print('🚀 Bắt đầu import data...');

      // Import từng file
      await _importFile('assets/data/destinations_mien_nam.json', 'Miền Nam');
      await _importFile(
        'assets/data/destinations_mien_trung.json',
        'Miền Trung',
      );
      await _importFile('assets/data/destinations_mien_bac.json', 'Miền Bắc');

      print('✅ Import hoàn tất!');
    } catch (e) {
      print('❌ Lỗi import: $e');
    }
  }

  // Import 1 file
  static Future<void> _importFile(String filePath, String region) async {
    try {
      // Đọc file JSON
      final String jsonString = await rootBundle.loadString(filePath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> destinations = jsonData['destinations'];

      print('📁 Import $region: ${destinations.length} địa điểm');

      // Thêm từng địa điểm vào Firestore
      int count = 0;
      for (var dest in destinations) {
        // Thêm timestamp
        dest['created_at'] = FieldValue.serverTimestamp();
        dest['updated_at'] = FieldValue.serverTimestamp();

        // Thêm vào Firestore
        await _db.collection('destinations').add(dest);
        count++;
        print('  ✓ Đã thêm: ${dest['name']} ($count/${destinations.length})');
      }

      print('✅ Hoàn tất $region: $count địa điểm');
    } catch (e) {
      print('❌ Lỗi import $region: $e');
    }
  }

  // Xóa tất cả data (nếu cần reset)
  static Future<void> clearAllDestinations() async {
    try {
      print('🗑️ Đang xóa tất cả destinations...');

      final snapshot = await _db.collection('destinations').get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ Đã xóa ${snapshot.docs.length} destinations');
    } catch (e) {
      print('❌ Lỗi xóa: $e');
    }
  }

  /// Xóa các destinations trùng lặp
  /// Duplicates được xác định dựa trên: name + location (latitude, longitude)
  /// Giữ lại document cũ nhất (created_at nhỏ nhất) trong mỗi nhóm duplicate
  static Future<void> removeDuplicateDestinations() async {
    try {
      print('🔍 Đang tìm duplicates...');

      // Lấy tất cả documents
      final snapshot = await _db.collection('destinations').get();
      print('📊 Tổng số documents: ${snapshot.docs.length}');

      // Nhóm documents theo key: name + lat + lng
      final Map<String, List<DocumentSnapshot>> groups = {};

      for (var doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        final name = (data['name'] ?? '').toString().trim().toLowerCase();
        final location = data['location'] as Map<String, dynamic>?;
        final lat = location?['latitude']?.toString() ?? '';
        final lng = location?['longitude']?.toString() ?? '';

        // Tạo key unique dựa trên name + tọa độ (làm tròn 6 chữ số thập phân)
        final key = '$name|${lat}|${lng}';

        if (!groups.containsKey(key)) {
          groups[key] = [];
        }
        groups[key]!.add(doc);
      }

      print('📊 Số nhóm unique: ${groups.length}');

      // Tìm các nhóm có > 1 document (duplicates)
      int duplicateCount = 0;
      int deletedCount = 0;

      for (var entry in groups.entries) {
        if (entry.value.length > 1) {
          duplicateCount++;
          final firstData = entry.value.first.data() as Map<String, dynamic>?;
          final name = firstData?['name'] ?? 'Unknown';
          print('⚠️ Tìm thấy ${entry.value.length} duplicates cho: $name');

          // Sắp xếp theo created_at (giữ lại document cũ nhất)
          entry.value.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aCreated = aData['created_at'] as Timestamp?;
            final bCreated = bData['created_at'] as Timestamp?;

            if (aCreated == null && bCreated == null) return 0;
            if (aCreated == null) return 1; // a không có timestamp -> mới hơn
            if (bCreated == null) return -1; // b không có timestamp -> mới hơn

            return aCreated.compareTo(bCreated); // Cũ nhất trước
          });

          // Giữ lại document đầu tiên (cũ nhất), xóa các document còn lại
          final toKeep = entry.value.first;
          final toDelete = entry.value.skip(1).toList();

          final toKeepData = toKeep.data() as Map<String, dynamic>?;
          print(
            '  ✓ Giữ lại: ${toKeep.id} (created: ${toKeepData?['created_at']})',
          );

          for (var doc in toDelete) {
            await doc.reference.delete();
            deletedCount++;
            final docData = doc.data() as Map<String, dynamic>?;
            print('  ✗ Đã xóa: ${doc.id} (created: ${docData?['created_at']})');
          }
        }
      }

      print('✅ Hoàn tất!');
      print('📊 Tổng số nhóm duplicates: $duplicateCount');
      print('📊 Số documents đã xóa: $deletedCount');
      print('📊 Số documents còn lại: ${snapshot.docs.length - deletedCount}');
    } catch (e) {
      print('❌ Lỗi xóa duplicates: $e');
      rethrow;
    }
  }
}
