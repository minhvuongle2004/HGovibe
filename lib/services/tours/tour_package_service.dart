import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_travel_app/models/tours/tour_package.dart';

/// Service để quản lý tour packages trong Firestore
class TourPackageService {
  static final TourPackageService instance = TourPackageService._();
  TourPackageService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tour_packages';

  /// Lấy tất cả tour packages (với filter và limit)
  Future<List<TourPackage>> getAllTourPackages({
    TourStatus? status,
    bool? featured,
    int? limit,
    String? destination,
  }) async {
    try {
      print('🔄 getAllTourPackages: status=$status, featured=$featured, limit=$limit');
      Query query = _firestore.collection(_collection);

      // Filter theo status
      if (status != null) {
        query = query.where(
          'status',
          isEqualTo: _statusToString(status),
        );
      }

      // Filter theo featured
      if (featured != null) {
        query = query.where('featured', isEqualTo: featured);
      }

      // Filter theo destination (nếu có field destination_lowercase)
      if (destination != null && destination.isNotEmpty) {
        query = query.where(
          'destination_lowercase',
          isGreaterThanOrEqualTo: destination.toLowerCase(),
        ).where(
          'destination_lowercase',
          isLessThanOrEqualTo: '${destination.toLowerCase()}\uf8ff',
        );
      }

      // Sort và limit - chỉ orderBy một field để tránh cần composite index
      // Nếu có featured filter, sort theo rating
      // Nếu không, không orderBy (sẽ sort thủ công sau)
      if (featured != null) {
        try {
          query = query.orderBy('rating', descending: true);
        } catch (e) {
          print('⚠️ Cannot orderBy rating, will sort manually: $e');
        }
      }
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      print('📊 Firestore returned ${snapshot.docs.length} documents');
      
      final tours = snapshot.docs
          .map((doc) {
            try {
              final tour = TourPackage.fromFirestore(doc);
              print('✅ Parsed tour: ${tour.title} (featured: ${tour.featured})');
              return tour;
            } catch (e) {
              print('❌ Error parsing tour ${doc.id}: $e');
              print('   Document data: ${doc.data()}');
              return null;
            }
          })
          .whereType<TourPackage>()
          .toList();
      
      // Sort thủ công nếu cần
      if (featured == null) {
        tours.sort((a, b) {
          if (a.featured != b.featured) {
            return b.featured ? 1 : -1;
          }
          return b.rating.compareTo(a.rating);
        });
      }
      
      // Apply limit sau khi sort
      if (limit != null && tours.length > limit) {
        tours.removeRange(limit, tours.length);
      }
      
      print('✅ Loaded ${tours.length} tours');
      return tours;
    } catch (e, stackTrace) {
      print('❌ Error getting tour packages: $e');
      print('Stack trace: $stackTrace');
      // Nếu lỗi do index, thử query đơn giản hơn
      if (e.toString().contains('index') || e.toString().contains('FAILED_PRECONDITION')) {
        print('⚠️ Index error, trying simple query...');
        try {
          // Query đơn giản: chỉ filter theo status nếu có
          Query simpleQuery = _firestore.collection(_collection);
          if (status != null) {
            simpleQuery = simpleQuery.where('status', isEqualTo: _statusToString(status));
          }
          
          // Lấy nhiều hơn để filter thủ công
          final snapshot = await simpleQuery.limit((limit ?? 50) * 2).get();
          final tours = snapshot.docs
              .map((doc) {
                try {
                  return TourPackage.fromFirestore(doc);
                } catch (e) {
                  print('❌ Error parsing tour ${doc.id} in fallback: $e');
                  return null;
                }
              })
              .whereType<TourPackage>()
              .toList();
          
          // Filter thủ công
          var filtered = tours;
          if (status != null) {
            filtered = filtered.where((t) => t.status == status).toList();
          }
          if (featured != null) {
            filtered = filtered.where((t) => t.featured == featured).toList();
          }
          
          // Sort
          filtered.sort((a, b) {
            if (featured == null && a.featured != b.featured) {
              return b.featured ? 1 : -1;
            }
            return b.rating.compareTo(a.rating);
          });
          
          if (limit != null && filtered.length > limit) {
            filtered.removeRange(limit, filtered.length);
          }
          
          print('✅ Loaded ${filtered.length} tours (fallback query)');
          return filtered;
        } catch (e2) {
          print('❌ Fallback query also failed: $e2');
          rethrow;
        }
      }
      rethrow;
    }
  }

  /// Lấy tour package theo ID
  Future<TourPackage?> getTourPackageById(String tourId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(tourId).get();
      if (!doc.exists) return null;
      return TourPackage.fromFirestore(doc);
    } catch (e) {
      print('Error getting tour package by ID: $e');
      rethrow;
    }
  }

  /// Lấy featured tours
  Future<List<TourPackage>> getFeaturedTours({int limit = 5}) async {
    return getAllTourPackages(
      status: TourStatus.active,
      featured: true,
      limit: limit,
    );
  }

  /// Tìm kiếm tours
  Future<List<TourPackage>> searchTours(String query) async {
    try {
      if (query.trim().isEmpty) {
        return getAllTourPackages(status: TourStatus.active);
      }

      final lowerQuery = query.toLowerCase();
      
      // Search trong title_lowercase
      final titleQuery = _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'active')
          .where('title_lowercase',
              isGreaterThanOrEqualTo: lowerQuery)
          .where('title_lowercase',
              isLessThanOrEqualTo: '$lowerQuery\uf8ff')
          .limit(20);

      // Search trong destination_lowercase
      final destinationQuery = _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'active')
          .where('destination_lowercase',
              isGreaterThanOrEqualTo: lowerQuery)
          .where('destination_lowercase',
              isLessThanOrEqualTo: '$lowerQuery\uf8ff')
          .limit(20);

      final titleSnapshot = await titleQuery.get();
      final destinationSnapshot = await destinationQuery.get();

      final tours = <String, TourPackage>{};
      
      for (final doc in titleSnapshot.docs) {
        tours[doc.id] = TourPackage.fromFirestore(doc);
      }
      for (final doc in destinationSnapshot.docs) {
        tours[doc.id] = TourPackage.fromFirestore(doc);
      }

      return tours.values.toList();
    } catch (e) {
      print('Error searching tours: $e');
      rethrow;
    }
  }

  /// Tạo tour package mới
  Future<String> createTourPackage(TourPackage tourPackage) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final data = tourPackage.toMap();
      data['id'] = docRef.id;
      
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
        final prices = tourPackage.priceTiers.map((t) => t.pricePerPerson).toList();
        minPrice = prices.reduce((a, b) => a < b ? a : b);
        maxPrice = prices.reduce((a, b) => a > b ? a : b);
      }
      data['priceRange'] = {'min': minPrice, 'max': maxPrice};

      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      print('Error creating tour package: $e');
      rethrow;
    }
  }

  /// Cập nhật tour package
  Future<void> updateTourPackage(TourPackage tourPackage) async {
    try {
      if (tourPackage.id == null) {
        throw Exception('Tour package ID is required for update');
      }

      final data = tourPackage.toMap();
      
      // Cập nhật computed fields
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
        final prices = tourPackage.priceTiers.map((t) => t.pricePerPerson).toList();
        minPrice = prices.reduce((a, b) => a < b ? a : b);
        maxPrice = prices.reduce((a, b) => a > b ? a : b);
      }
      data['priceRange'] = {'min': minPrice, 'max': maxPrice};
      data['updatedAt'] = Timestamp.now();

      await _firestore.collection(_collection).doc(tourPackage.id).update(data);
    } catch (e) {
      print('Error updating tour package: $e');
      rethrow;
    }
  }

  /// Tăng viewCount
  Future<void> incrementViewCount(String tourId) async {
    try {
      await _firestore.collection(_collection).doc(tourId).update({
        'viewCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error incrementing view count: $e');
      // Không throw để không ảnh hưởng đến UX
    }
  }

  String _statusToString(TourStatus status) {
    switch (status) {
      case TourStatus.active:
        return 'active';
      case TourStatus.inactive:
        return 'inactive';
      case TourStatus.soldOut:
        return 'sold_out';
    }
  }
}

