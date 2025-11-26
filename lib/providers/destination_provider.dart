import 'package:flutter/foundation.dart';
import '../models/destination.dart';
import '../services/destination_service.dart';

/// Provider để quản lý state của destinations
/// Sử dụng ChangeNotifier (có sẵn trong Flutter SDK)
class DestinationProvider extends ChangeNotifier {
  // State variables
  List<Destination> _destinations = [];
  List<Destination> _recommendedDestinations = [];
  List<Destination> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  String _searchQuery = '';

  // Getters
  List<Destination> get destinations => _destinations;
  List<Destination> get recommendedDestinations => _recommendedDestinations;
  List<Destination> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  /// Load tất cả destinations
  Future<void> loadDestinations({int limit = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _destinations = await DestinationService.getAllDestinations(limit: limit);
      _error = null;
    } catch (e) {
      _error = 'Không thể tải danh sách địa điểm: $e';
      _destinations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load recommended destinations
  Future<void> loadRecommendedDestinations({int limit = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recommendedDestinations =
          await DestinationService.getRecommendedDestinations(limit: limit);
      
      if (_recommendedDestinations.isEmpty) {
        _error = 'Chưa có dữ liệu. Vui lòng import data vào Firestore trước.';
      } else {
        _error = null;
      }
    } catch (e) {
      _error = 'Không thể tải gợi ý: $e';
      _recommendedDestinations = [];
      print('❌ Provider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tìm kiếm destinations
  Future<void> searchDestinations(String query) async {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await DestinationService.searchDestinations(query);
      _error = null;
    } catch (e) {
      _error = 'Không thể tìm kiếm: $e';
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Load destinations theo thành phố
  Future<void> loadDestinationsByCity(String city, {int limit = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _destinations =
          await DestinationService.getDestinationsByCity(city, limit: limit);
      _error = null;
    } catch (e) {
      _error = 'Không thể tải địa điểm theo thành phố: $e';
      _destinations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load destinations theo vùng miền
  Future<void> loadDestinationsByRegion(String region, {int limit = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _destinations =
          await DestinationService.getDestinationsByRegion(region, limit: limit);
      _error = null;
    } catch (e) {
      _error = 'Không thể tải địa điểm theo vùng: $e';
      _destinations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load destinations theo tags
  Future<void> loadDestinationsByTags(List<String> tags, {int limit = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _destinations =
          await DestinationService.getDestinationsByTags(tags, limit: limit);
      _error = null;
    } catch (e) {
      _error = 'Không thể tải địa điểm theo tags: $e';
      _destinations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load destinations theo tháng
  Future<void> loadDestinationsByMonth(int month, {int limit = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _destinations =
          await DestinationService.getDestinationsByMonth(month, limit: limit);
      _error = null;
    } catch (e) {
      _error = 'Không thể tải địa điểm theo tháng: $e';
      _destinations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadDestinations();
    await loadRecommendedDestinations();
  }

  // State cho seasonal recommendations
  List<Destination> _seasonalDestinations = [];
  bool _isLoadingSeasonal = false;

  List<Destination> get seasonalDestinations => _seasonalDestinations;
  bool get isLoadingSeasonal => _isLoadingSeasonal;

  /// Load destinations theo tháng hiện tại
  Future<void> loadSeasonalDestinations({int limit = 10}) async {
    _isLoadingSeasonal = true;
    notifyListeners();

    try {
      final currentMonth = DateTime.now().month;
      _seasonalDestinations =
          await DestinationService.getDestinationsByMonth(currentMonth, limit: limit);
    } catch (e) {
      print('❌ Lỗi loadSeasonalDestinations: $e');
      _seasonalDestinations = [];
    } finally {
      _isLoadingSeasonal = false;
      notifyListeners();
    }
  }

  // State cho tag recommendations
  List<Destination> _tagDestinations = [];
  bool _isLoadingTags = false;
  String? _selectedTag;

  List<Destination> get tagDestinations => _tagDestinations;
  bool get isLoadingTags => _isLoadingTags;
  String? get selectedTag => _selectedTag;

  /// Load destinations theo tag
  Future<void> loadDestinationsByTag(String tag, {int limit = 10}) async {
    _selectedTag = tag;
    _isLoadingTags = true;
    notifyListeners();

    try {
      _tagDestinations =
          await DestinationService.getDestinationsByTags([tag], limit: limit);
    } catch (e) {
      print('❌ Lỗi loadDestinationsByTag: $e');
      _tagDestinations = [];
    } finally {
      _isLoadingTags = false;
      notifyListeners();
    }
  }

  /// Clear tag filter
  void clearTagFilter() {
    _selectedTag = null;
    _tagDestinations = [];
    notifyListeners();
  }
}

