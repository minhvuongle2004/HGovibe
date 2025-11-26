import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/destination.dart';
import 'destination_service.dart';

/// Service để quản lý recent views (lưu local)
class RecentViewsService {
  static const String _key = 'recent_views';
  static const int _maxRecentViews = 20; // Giới hạn số lượng recent views

  /// Lưu destination vào recent views
  static Future<void> addRecentView(Destination destination) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentViewsJson = prefs.getStringList(_key) ?? [];
      
      // Loại bỏ destination đã tồn tại (nếu có)
      recentViewsJson.removeWhere((json) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return map['id'] == destination.id;
      });
      
      // Thêm destination mới vào đầu danh sách
      recentViewsJson.insert(0, jsonEncode({
        'id': destination.id,
        'name': destination.name,
        'thumbnail': destination.thumbnail,
        'city': destination.location.city,
        'rating': destination.rating,
        'review_count': destination.reviewCount,
        'timestamp': DateTime.now().toIso8601String(),
      }));
      
      // Giới hạn số lượng
      if (recentViewsJson.length > _maxRecentViews) {
        recentViewsJson.removeRange(_maxRecentViews, recentViewsJson.length);
      }
      
      await prefs.setStringList(_key, recentViewsJson);
    } catch (e) {
      print('❌ Lỗi addRecentView: $e');
    }
  }

  /// Lấy danh sách recent views (chỉ IDs)
  static Future<List<String>> getRecentViewIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentViewsJson = prefs.getStringList(_key) ?? [];
      
      return recentViewsJson.map((json) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return map['id'] as String;
      }).toList();
    } catch (e) {
      print('❌ Lỗi getRecentViewIds: $e');
      return [];
    }
  }

  /// Lấy danh sách destinations từ recent views
  static Future<List<Destination>> getRecentDestinations({int limit = 20}) async {
    try {
      final ids = await getRecentViewIds();
      if (ids.isEmpty) return [];
      
      final destinations = <Destination>[];
      for (var id in ids.take(limit)) {
        final dest = await DestinationService.getDestinationById(id);
        if (dest != null) {
          destinations.add(dest);
        }
      }
      
      return destinations;
    } catch (e) {
      print('❌ Lỗi getRecentDestinations: $e');
      return [];
    }
  }

  /// Xóa tất cả recent views
  static Future<void> clearRecentViews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      print('❌ Lỗi clearRecentViews: $e');
    }
  }
}

