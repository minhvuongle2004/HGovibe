import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_travel_app/models/destinations/destination.dart';
import 'package:smart_travel_app/utils/constants.dart';

/// Service để truy vấn dữ liệu destinations từ Firestore
class DestinationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final CollectionReference _destinationsRef = _db.collection(
    AppConstants.destinationsCollection,
  );

  /// Lấy tất cả destinations với phân trang
  ///
  /// [limit] - Số lượng documents mỗi lần query (mặc định: 20)
  /// [startAfter] - DocumentSnapshot của item cuối cùng để phân trang tiếp
  /// [status] - Lọc theo status (mặc định: 'active')
  static Future<List<Destination>> getAllDestinations({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String status = 'active',
  }) async {
    try {
      // Query không dùng orderBy với where để tránh cần index
      // Sẽ sort thủ công sau
      Query query = _destinationsRef
          .where('status', isEqualTo: status)
          .limit(limit * 2); // Lấy nhiều hơn để sort

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final results = snapshot.docs
          .map((doc) {
            try {
              return Destination.fromFirestore(doc);
            } catch (e) {
              print('⚠️ Lỗi parse document ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Destination>()
          .toList();

      // Loại bỏ duplicates dựa trên id
      final seenIds = <String>{};
      final uniqueResults = <Destination>[];
      for (var dest in results) {
        final destId = dest.id ?? '';
        if (destId.isNotEmpty && !seenIds.contains(destId)) {
          seenIds.add(destId);
          uniqueResults.add(dest);
        }
      }

      // Sắp xếp thủ công
      uniqueResults.sort(
        (a, b) => b.popularityScore.compareTo(a.popularityScore),
      );
      return uniqueResults.take(limit).toList();
    } catch (e) {
      print('❌ Lỗi getAllDestinations: $e');
      return [];
    }
  }

  /// Tìm kiếm destinations theo tên
  ///
  /// [query] - Từ khóa tìm kiếm
  /// [limit] - Số lượng kết quả tối đa (mặc định: 50)
  static Future<List<Destination>> searchDestinations(
    String query, {
    int limit = 50,
  }) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      print('🔍 Đang tìm kiếm: "$query"');
      final queryLower = query.toLowerCase().trim();

      // Lấy tất cả destinations active và filter thủ công
      // (Tránh cần index cho range query)
      final allSnapshot = await _destinationsRef
          .where('status', isEqualTo: 'active')
          .limit(limit * 3) // Lấy nhiều hơn để filter
          .get();

      print('📊 Tìm thấy ${allSnapshot.docs.length} documents để filter');

      final results = <Destination>[];
      for (var doc in allSnapshot.docs) {
        try {
          final dest = Destination.fromFirestore(doc);

          // Tìm kiếm trong name, description, tags, city
          final matchName = dest.nameLowercase.contains(queryLower);
          final matchDescription = dest.description.toLowerCase().contains(
            queryLower,
          );
          final matchTags = dest.tags.any(
            (tag) => tag.toLowerCase().contains(queryLower),
          );
          final matchCity = dest.location.city.toLowerCase().contains(
            queryLower,
          );

          if (matchName || matchDescription || matchTags || matchCity) {
            results.add(dest);
            if (results.length >= limit) break;
          }
        } catch (e) {
          print('⚠️ Lỗi parse document ${doc.id}: $e');
          continue;
        }
      }

      // Loại bỏ duplicates dựa trên id
      final seenIds = <String>{};
      final uniqueResults = <Destination>[];
      for (var dest in results) {
        final destId = dest.id ?? '';
        if (destId.isNotEmpty && !seenIds.contains(destId)) {
          seenIds.add(destId);
          uniqueResults.add(dest);
        }
      }

      // Sắp xếp: ưu tiên match trong name
      uniqueResults.sort((a, b) {
        final aNameMatch = a.nameLowercase.contains(queryLower);
        final bNameMatch = b.nameLowercase.contains(queryLower);
        if (aNameMatch && !bNameMatch) return -1;
        if (!aNameMatch && bNameMatch) return 1;
        return b.popularityScore.compareTo(a.popularityScore);
      });

      print(
        '✅ Tìm thấy ${uniqueResults.length} kết quả (${results.length - uniqueResults.length} duplicates đã loại bỏ) cho "$query"',
      );
      return uniqueResults;
    } catch (e) {
      print('❌ Lỗi searchDestinations: $e');
      return [];
    }
  }

  /// Lấy destinations theo thành phố
  ///
  /// [city] - Tên thành phố (ví dụ: "Hà Nội", "Hồ Chí Minh")
  /// [limit] - Số lượng kết quả (mặc định: 20)
  static Future<List<Destination>> getDestinationsByCity(
    String city, {
    int limit = 20,
  }) async {
    try {
      print('🔍 Đang load destinations cho thành phố: $city');

      // Query không dùng orderBy để tránh cần index
      // Sẽ sort thủ công sau
      final snapshot = await _destinationsRef
          .where('status', isEqualTo: 'active')
          .where('location.city', isEqualTo: city)
          .limit(limit * 2) // Lấy nhiều hơn để sort
          .get();

      print('📊 Tìm thấy ${snapshot.docs.length} documents cho $city');

      final results = snapshot.docs
          .map((doc) {
            try {
              return Destination.fromFirestore(doc);
            } catch (e) {
              print('⚠️ Lỗi parse document ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Destination>()
          .toList();

      // Loại bỏ duplicates dựa trên id
      final seenIds = <String>{};
      final uniqueResults = <Destination>[];
      for (var dest in results) {
        final destId = dest.id ?? '';
        if (destId.isNotEmpty && !seenIds.contains(destId)) {
          seenIds.add(destId);
          uniqueResults.add(dest);
        }
      }

      // Sắp xếp thủ công theo popularity_score
      uniqueResults.sort(
        (a, b) => b.popularityScore.compareTo(a.popularityScore),
      );

      final finalResults = uniqueResults.take(limit).toList();
      print(
        '✅ Load được ${finalResults.length} destinations cho $city (${results.length - uniqueResults.length} duplicates đã loại bỏ)',
      );
      return finalResults;
    } catch (e) {
      print('❌ Lỗi getDestinationsByCity: $e');
      return [];
    }
  }

  /// Lấy destinations theo vùng miền (dựa vào city)
  ///
  /// [region] - Vùng miền: "Miền Bắc", "Miền Trung", "Miền Nam"
  /// [limit] - Số lượng kết quả (mặc định: 20)
  static Future<List<Destination>> getDestinationsByRegion(
    String region, {
    int limit = 20,
  }) async {
    try {
      // Map vùng miền với các thành phố chính
      final regionCities = <String, List<String>>{
        'Miền Bắc': ['Hà Nội', 'Hải Phòng', 'Quảng Ninh', 'Ninh Bình'],
        'Miền Trung': [
          'Đà Nẵng',
          'Huế',
          'Hội An',
          'Quảng Nam',
          'Quảng Bình',
          'Nghệ An',
        ],
        'Miền Nam': [
          'Hồ Chí Minh',
          'Cần Thơ',
          'Đà Lạt',
          'Phú Quốc',
          'Vũng Tàu',
          'Nha Trang',
        ],
      };

      final cities = regionCities[region] ?? [];
      if (cities.isEmpty) return [];

      // Query với whereIn (tối đa 10 items trong whereIn)
      // Không dùng orderBy để tránh cần index, sẽ sort thủ công sau
      final results = <Destination>[];
      for (var i = 0; i < cities.length; i += 10) {
        final batch = cities.skip(i).take(10).toList();
        final snapshot = await _destinationsRef
            .where('status', isEqualTo: 'active')
            .where('location.city', whereIn: batch)
            .limit(limit * 2) // Lấy nhiều hơn để sort
            .get();

        results.addAll(
          snapshot.docs.map((doc) {
            try {
              return Destination.fromFirestore(doc);
            } catch (e) {
              print('⚠️ Lỗi parse document ${doc.id}: $e');
              return null;
            }
          }).whereType<Destination>(),
        );
      }

      // Sắp xếp lại và giới hạn số lượng
      results.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));
      return results.take(limit).toList();
    } catch (e) {
      print('❌ Lỗi getDestinationsByRegion: $e');
      return [];
    }
  }

  /// Lấy destinations được gợi ý (Recommended)
  ///
  /// Ưu tiên: trending_score → popularity_score → rating
  /// [limit] - Số lượng kết quả (mặc định: 20)
  static Future<List<Destination>> getRecommendedDestinations({
    int limit = 20,
  }) async {
    try {
      print('🔍 Đang load recommended destinations...');

      // Kiểm tra tổng số documents trong Firestore (không filter)
      final totalSnapshot = await _destinationsRef.limit(1000).get();
      print(
        '📊 Tổng số documents trong Firestore: ${totalSnapshot.docs.length}',
      );

      // Kiểm tra số documents với status = 'active'
      final activeSnapshot = await _destinationsRef
          .where('status', isEqualTo: 'active')
          .limit(1000)
          .get();
      print(
        '📊 Số documents với status = active: ${activeSnapshot.docs.length}',
      );

      // Tính toán limit hợp lý: lấy tối đa 2x limit hoặc tất cả nếu ít hơn
      final maxLimit = (limit * 2 < activeSnapshot.docs.length)
          ? limit * 2
          : activeSnapshot.docs.length;

      // Không dùng orderBy với where để tránh cần index
      // Sẽ sort thủ công sau
      final snapshot = await _destinationsRef
          .where('status', isEqualTo: 'active')
          .limit(maxLimit)
          .get();

      print(
        '📊 Query lấy ${snapshot.docs.length} documents (limit: $maxLimit)',
      );

      final results = snapshot.docs
          .map((doc) {
            try {
              return Destination.fromFirestore(doc);
            } catch (e) {
              print('⚠️ Lỗi parse document ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Destination>()
          .toList();

      // Loại bỏ duplicates dựa trên id
      final seenIds = <String>{};
      final uniqueResults = <Destination>[];
      for (var dest in results) {
        final destId = dest.id ?? '';
        if (destId.isNotEmpty && !seenIds.contains(destId)) {
          seenIds.add(destId);
          uniqueResults.add(dest);
        } else if (destId.isNotEmpty && seenIds.contains(destId)) {
          print('⚠️ Phát hiện duplicate ID: $destId');
        }
      }

      if (results.length != uniqueResults.length) {
        print(
          '⚠️ Phát hiện ${results.length - uniqueResults.length} duplicates trong kết quả query',
        );
      }

      // Sắp xếp thủ công theo priority
      uniqueResults.sort((a, b) {
        if (b.trendingScore != a.trendingScore) {
          return b.trendingScore.compareTo(a.trendingScore);
        }
        if (b.popularityScore != a.popularityScore) {
          return b.popularityScore.compareTo(a.popularityScore);
        }
        return b.rating.compareTo(a.rating);
      });

      final finalResults = uniqueResults.take(limit).toList();
      print(
        '✅ Load được ${finalResults.length} recommended destinations (${results.length - uniqueResults.length} duplicates đã loại bỏ)',
      );
      return finalResults;
    } catch (e) {
      print('❌ Lỗi getRecommendedDestinations: $e');
      print(
        '💡 Có thể cần tạo index trong Firestore hoặc data chưa được import',
      );

      // Fallback: Lấy tất cả active destinations không cần orderBy
      try {
        print('🔄 Thử fallback query...');
        final snapshot = await _destinationsRef
            .where('status', isEqualTo: 'active')
            .limit(limit)
            .get();

        final results = snapshot.docs
            .map((doc) {
              try {
                return Destination.fromFirestore(doc);
              } catch (e) {
                return null;
              }
            })
            .whereType<Destination>()
            .toList();

        print('✅ Fallback load được ${results.length} destinations');
        return results;
      } catch (e2) {
        print('❌ Lỗi fallback: $e2');
        return [];
      }
    }
  }

  /// Lấy destinations theo tags
  ///
  /// [tags] - Danh sách tags để filter
  /// [limit] - Số lượng kết quả (mặc định: 20)
  static Future<List<Destination>> getDestinationsByTags(
    List<String> tags, {
    int limit = 20,
  }) async {
    try {
      if (tags.isEmpty) return [];

      // Firestore chỉ hỗ trợ whereIn với 1 tag, nên ta sẽ query và filter
      // Không dùng orderBy để tránh cần index, sẽ sort thủ công sau
      final snapshot = await _destinationsRef
          .where('status', isEqualTo: 'active')
          .where('tags', arrayContainsAny: tags)
          .limit(limit * 3) // Lấy nhiều hơn để filter và sort
          .get();

      final results = snapshot.docs
          .map((doc) {
            try {
              return Destination.fromFirestore(doc);
            } catch (e) {
              print('⚠️ Lỗi parse document ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Destination>()
          .where(
            (dest) => tags.any(
              (tag) =>
                  dest.tags.any((t) => t.toLowerCase() == tag.toLowerCase()),
            ),
          )
          .toList();

      // Sắp xếp thủ công
      results.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));
      return results.take(limit).toList();
    } catch (e) {
      print('❌ Lỗi getDestinationsByTags: $e');
      return [];
    }
  }

  /// Lấy destinations phù hợp với tháng hiện tại
  ///
  /// [currentMonth] - Tháng hiện tại (1-12)
  /// [limit] - Số lượng kết quả (mặc định: 20)
  static Future<List<Destination>> getDestinationsByMonth(
    int currentMonth, {
    int limit = 20,
  }) async {
    try {
      // Lấy tất cả destinations active
      // Không dùng orderBy với where để tránh cần index, sẽ sort thủ công sau
      final snapshot = await _destinationsRef
          .where('status', isEqualTo: 'active')
          .limit(limit * 3) // Lấy nhiều hơn để filter và sort
          .get();

      // Filter destinations có currentMonth trong best_months
      final results = snapshot.docs
          .map((doc) {
            try {
              return Destination.fromFirestore(doc);
            } catch (e) {
              print('⚠️ Lỗi parse document ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Destination>()
          .where((dest) => dest.bestMonths.contains(currentMonth))
          .toList();

      // Sắp xếp thủ công
      results.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));
      return results.take(limit).toList();
    } catch (e) {
      print('❌ Lỗi getDestinationsByMonth: $e');
      return [];
    }
  }

  /// Lấy destination theo ID
  ///
  /// [id] - Document ID của destination
  static Future<Destination?> getDestinationById(String id) async {
    try {
      final doc = await _destinationsRef.doc(id).get();
      if (doc.exists) {
        return Destination.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Lỗi getDestinationById: $e');
      return null;
    }
  }

  /// Lấy top destinations theo rating
  ///
  /// [limit] - Số lượng kết quả (mặc định: 10)
  static Future<List<Destination>> getTopRatedDestinations({
    int limit = 10,
  }) async {
    try {
      final snapshot = await _destinationsRef
          .where('status', isEqualTo: 'active')
          .orderBy('rating', descending: true)
          .orderBy('review_count', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Destination.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Lỗi getTopRatedDestinations: $e');
      return [];
    }
  }

  /// Lấy trending destinations
  ///
  /// [limit] - Số lượng kết quả (mặc định: 10)
  static Future<List<Destination>> getTrendingDestinations({
    int limit = 10,
  }) async {
    try {
      final snapshot = await _destinationsRef
          .where('status', isEqualTo: 'active')
          .orderBy('trending_score', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Destination.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Lỗi getTrendingDestinations: $e');
      return [];
    }
  }
}
