import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/destinations/destination.dart';

/// Service để quản lý destinations trong admin panel
class AdminDestinationService {
  static final AdminDestinationService instance = AdminDestinationService._();
  AdminDestinationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'destinations';

  /// Lấy tất cả destinations với pagination
  /// Note: Mặc định loại bỏ destinations đã xóa (status != 'deleted')
  Future<List<Destination>> getAllDestinations({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? searchQuery,
    String? category,
    String? city,
    String? status, // Optional: filter theo status
    bool includeDeleted = false, // Include deleted destinations
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      // Mặc định loại bỏ deleted destinations (trừ khi includeDeleted = true)
      if (!includeDeleted && (status == null || status.isEmpty)) {
        // Không filter deleted nếu đang filter theo status cụ thể
        // Sẽ filter ở client-side để tránh cần index
      }

      // Filter theo status (nếu có)
      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      // Filter theo category
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      // Filter theo city - không dùng nested field để tránh index issues
      // Sẽ filter ở client-side

      // Không orderBy để tránh cần index, sẽ sort ở client-side
      // Tăng limit để lấy nhiều destinations hơn
      query = query.limit(limit * 5); // Lấy nhiều hơn để đảm bảo có đủ data

      if (startAfter != null) {
        try {
          query = query.startAfterDocument(startAfter);
        } catch (e) {
          print('⚠️ Cannot use startAfter: $e');
        }
      }

      final snapshot = await query.get();
      print('📊 Query returned ${snapshot.docs.length} documents');
      var destinations = <Destination>[];

      for (var doc in snapshot.docs) {
        try {
          final docData = doc.data();
          if (docData == null) continue;

          final data = Map<String, dynamic>.from(docData as Map);
          data['id'] = doc.id;

          final destination = Destination.fromFirestore(doc);

          // Filter by search query (client-side)
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final queryLower = searchQuery.toLowerCase();
            final matches = 
                destination.name.toLowerCase().contains(queryLower) ||
                destination.location.city.toLowerCase().contains(queryLower) ||
                destination.description.toLowerCase().contains(queryLower);
            if (!matches) continue;
          }

          // Filter by category (client-side nếu cần)
          if (category != null && destination.category != category) {
            continue;
          }

          // Filter by city (client-side)
          if (city != null && city.isNotEmpty) {
            if (destination.location.city.toLowerCase() != city.toLowerCase()) {
              continue;
            }
          }

          // Filter by status (client-side nếu cần)
          if (status != null && status.isNotEmpty) {
            if (destination.status != status) {
              continue;
            }
          }

          // Loại bỏ deleted destinations (trừ khi includeDeleted = true)
          if (!includeDeleted && destination.status == 'deleted') {
            continue;
          }

          destinations.add(destination);
          
          // Dừng khi đủ limit
          if (destinations.length >= limit) break;
        } catch (e) {
          print('Error parsing destination ${doc.id}: $e');
        }
      }

      // Sort ở client-side (luôn sort để đảm bảo thứ tự)
      destinations.sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate); // Descending
      });

      return destinations;
    } catch (e) {
      print('Error getting all destinations: $e');
      rethrow;
    }
  }

  /// Lấy destination theo ID
  Future<Destination?> getDestinationById(String destinationId) async {
    try {
      print('🔍 Fetching destination: $destinationId');
      final doc = await _firestore.collection(_collection).doc(destinationId).get();
      if (!doc.exists) {
        print('❌ Document does not exist: $destinationId');
        return null;
      }
      print('✅ Document exists, parsing...');
      final destination = Destination.fromFirestore(doc);
      print('✅ Destination parsed: ${destination.name}');
      return destination;
    } catch (e, stackTrace) {
      print('❌ Error getting destination by ID: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Tạo destination mới
  Future<String> createDestination(Map<String, dynamic> data) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      data['id'] = docRef.id;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      data['status'] = data['status'] ?? 'active';

      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      print('Error creating destination: $e');
      rethrow;
    }
  }

  /// Cập nhật destination
  Future<void> updateDestination(String destinationId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      data.remove('id'); // Không update id
      data.remove('createdAt'); // Không update createdAt

      await _firestore.collection(_collection).doc(destinationId).update(data);
    } catch (e) {
      print('Error updating destination: $e');
      rethrow;
    }
  }

  /// Xóa destination (soft delete)
  Future<void> deleteDestination(String destinationId) async {
    try {
      print('🗑️ Deleting destination: $destinationId');
      await _firestore.collection(_collection).doc(destinationId).update({
        'status': 'deleted',
        'deleted_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      print('✅ Destination deleted successfully: $destinationId');
    } catch (e, stackTrace) {
      print('❌ Error deleting destination: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Lấy danh sách categories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final categories = <String>{};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }
      
      return categories.toList()..sort();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  /// Lấy danh sách cities
  Future<List<String>> getCities() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final cities = <String>{};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final location = data['location'] as Map<String, dynamic>?;
        final city = location?['city'] as String?;
        if (city != null && city.isNotEmpty) {
          cities.add(city);
        }
      }
      
      return cities.toList()..sort();
    } catch (e) {
      print('Error getting cities: $e');
      return [];
    }
  }
}

