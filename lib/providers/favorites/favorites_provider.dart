import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:smart_travel_app/models/destinations/destination.dart';
import 'package:smart_travel_app/services/destinations/favorites_service.dart';

/// Provider để quản lý state của favorites
class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider({FavoritesService? favoritesService})
      : _favoritesService = favoritesService ?? FavoritesService.instance;

  final FavoritesService _favoritesService;

  // State variables
  List<Destination> _favorites = [];
  Set<String> _favoriteIds = {}; // Set để check nhanh
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<Destination>>? _subscription;
  bool _isDisposed = false;

  // Getters
  List<Destination> get favorites => _favorites;
  Set<String> get favoriteIds => _favoriteIds;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get favoritesCount => _favorites.length;

  /// Kiểm tra nhanh xem destination có trong favorites không
  bool isFavorite(String destinationId) {
    return _favoriteIds.contains(destinationId);
  }

  /// Load danh sách favorites
  Future<void> loadFavorites(String userId) async {
    if (userId.isEmpty) {
      _favorites = [];
      _favoriteIds = {};
      _error = null;
      _safeNotifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final destinations = await _favoritesService.getFavoriteDestinations(
        userId,
      );
      _favorites = destinations;
      _favoriteIds = destinations
          .map((d) => d.id ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      _error = null;
      debugPrint('✅ Loaded ${_favorites.length} favorites');
    } catch (e, stack) {
      _error = 'Không thể tải danh sách yêu thích: $e';
      _favorites = [];
      _favoriteIds = {};
      debugPrint('❌ Error loading favorites: $e');
      debugPrint('$stack');
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Bắt đầu lắng nghe thay đổi favorites real-time
  void startWatchingFavorites(String userId) {
    if (userId.isEmpty) {
      _favorites = [];
      _favoriteIds = {};
      notifyListeners();
      return;
    }

    // Hủy subscription cũ nếu có
    _subscription?.cancel();

    // Bắt đầu lắng nghe stream
    _subscription = _favoritesService
        .watchFavoriteDestinations(userId)
        .listen(
          (destinations) {
            _favorites = destinations;
            _favoriteIds = destinations
                .map((d) => d.id ?? '')
                .where((id) => id.isNotEmpty)
                .toSet();
            _error = null;
            debugPrint('✅ Favorites updated: ${_favorites.length} items');
            _safeNotifyListeners();
          },
          onError: (error) {
            _error = 'Lỗi khi cập nhật danh sách yêu thích: $error';
            debugPrint('❌ Error in favorites stream: $error');
            _safeNotifyListeners();
          },
        );
  }

  /// Dừng lắng nghe thay đổi favorites
  void stopWatchingFavorites() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Toggle favorite (thêm nếu chưa có, xóa nếu đã có)
  ///
  /// Returns `true` nếu đã thêm, `false` nếu đã xóa
  Future<bool> toggleFavorite({
    required String userId,
    required String destinationId,
  }) async {
    if (userId.isEmpty) {
      _error = 'Bạn cần đăng nhập để thêm vào yêu thích';
      _safeNotifyListeners();
      throw Exception(_error);
    }

    if (destinationId.isEmpty) {
      _error = 'ID địa điểm không hợp lệ';
      _safeNotifyListeners();
      throw Exception(_error);
    }

    try {
      final wasAdded = await _favoritesService.toggleFavorite(
        userId: userId,
        destinationId: destinationId,
      );

      // Cập nhật local state ngay lập tức để UI responsive
      if (wasAdded) {
        // Đã thêm: thêm vào set
        _favoriteIds.add(destinationId);
        debugPrint('✅ Favorite added locally: $destinationId');
      } else {
        // Đã xóa: xóa khỏi set và list
        _favoriteIds.remove(destinationId);
        _favorites.removeWhere((d) => d.id == destinationId);
        debugPrint('✅ Favorite removed locally: $destinationId');
      }

      _error = null;
      _safeNotifyListeners();

      // Nếu đang watch stream, stream sẽ tự động cập nhật
      // Nếu không, cần refresh thủ công
      if (_subscription == null) {
        await loadFavorites(userId);
      }

      return wasAdded;
    } catch (e, stack) {
      _error = 'Không thể cập nhật yêu thích: $e';
      debugPrint('❌ Error toggling favorite: $e');
      debugPrint('$stack');
      _safeNotifyListeners();
      rethrow;
    }
  }

  /// Refresh danh sách favorites
  Future<void> refreshFavorites(String userId) async {
    await loadFavorites(userId);
  }

  /// Clear tất cả favorites (dùng khi logout)
  void clearFavorites() {
    _favorites = [];
    _favoriteIds = {};
    _error = null;
    stopWatchingFavorites();
    _safeNotifyListeners();
  }

  /// Helper method để gọi notifyListeners() an toàn
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    stopWatchingFavorites();
    super.dispose();
  }
}
