import 'package:flutter/foundation.dart';
import 'package:smart_travel_app/models/tours/tour_package.dart';
import 'package:smart_travel_app/services/tours/tour_package_service.dart';

/// Provider quản lý state của tour packages
class TourPackageProvider with ChangeNotifier {
  final TourPackageService _service = TourPackageService.instance;

  List<TourPackage> _tours = [];
  List<TourPackage> _featuredTours = [];
  bool _isLoading = false;
  String? _error;

  List<TourPackage> get tours => _tours;
  List<TourPackage> get featuredTours => _featuredTours;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load tất cả tours
  Future<void> loadTours({
    TourStatus? status,
    bool? featured,
    int? limit,
    String? destination,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Loading tours: status=$status, featured=$featured, limit=$limit');
      _tours = await _service.getAllTourPackages(
        status: status,
        featured: featured,
        limit: limit,
        destination: destination,
      );
      print('✅ Loaded ${_tours.length} tours');
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading tours: $e');
      print('Stack trace: ${StackTrace.current}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load featured tours
  Future<void> loadFeaturedTours({int limit = 5}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Loading featured tours: limit=$limit');
      _featuredTours = await _service.getFeaturedTours(limit: limit);
      print('✅ Loaded ${_featuredTours.length} featured tours');
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading featured tours: $e');
      print('Stack trace: ${StackTrace.current}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tìm kiếm tours
  Future<void> searchTours(String query) async {
    if (query.trim().isEmpty) {
      await loadTours(status: TourStatus.active);
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tours = await _service.searchTours(query);
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error searching tours: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lấy tour theo ID
  Future<TourPackage?> getTourById(String tourId) async {
    try {
      return await _service.getTourPackageById(tourId);
    } catch (e) {
      print('Error getting tour by ID: $e');
      return null;
    }
  }

  /// Tăng viewCount
  Future<void> incrementViewCount(String tourId) async {
    await _service.incrementViewCount(tourId);
    // Cập nhật local state nếu tour đang trong list
    final index = _tours.indexWhere((t) => t.id == tourId);
    if (index != -1) {
      // Không cần notify vì viewCount không ảnh hưởng UI chính
    }
  }

  /// Refresh tours
  Future<void> refresh() async {
    await loadTours(status: TourStatus.active);
  }
}

