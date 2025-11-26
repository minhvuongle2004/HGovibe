import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../models/trip_item.dart';
import '../models/trip_cost_estimate.dart';
import '../models/weather_forecast.dart';
import '../models/ai_activity_suggestion.dart';
import '../services/trip_service.dart';
import '../services/weather_service.dart';
import '../services/ai_cost_estimation_service.dart';
import '../services/ai_plan_service.dart';
import '../models/ai_plan.dart';

/// Provider để quản lý state của trips
class TripProvider extends ChangeNotifier {
  final TripService _tripService = TripService.instance;

  // State variables
  List<Trip> _trips = [];
  Trip? _currentTrip;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<Trip>>? _tripsSubscription;
  StreamSubscription<List<TripItem>>? _itemsSubscription;
  bool _isDisposed = false;

  // Cost estimation state
  TripCostEstimate? _costEstimate;
  bool _isEstimatingCost = false;
  double _costMultiplier = 1.0; // Multiplier để điều chỉnh nhu cầu

  // Weather forecasts state
  List<WeatherForecast>? _weatherForecasts;
  bool _isLoadingWeather = false;

  // AI suggestions state
  List<AIActivitySuggestion>? _aiSuggestions;
  bool _isLoadingSuggestions = false;

  // Getters
  List<Trip> get trips => _trips;
  Trip? get currentTrip => _currentTrip;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TripCostEstimate? get costEstimate => _costEstimate;
  bool get isEstimatingCost => _isEstimatingCost;
  double get costMultiplier => _costMultiplier;
  List<WeatherForecast>? get weatherForecasts => _weatherForecasts;
  bool get isLoadingWeather => _isLoadingWeather;
  List<AIActivitySuggestion>? get aiSuggestions => _aiSuggestions;
  bool get isLoadingSuggestions => _isLoadingSuggestions;

  /// Load danh sách trips
  Future<void> loadTrips(String userId) async {
    if (userId.isEmpty) {
      _trips = [];
      _error = null;
      _safeNotifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final trips = await _tripService.getTrips(userId);
      _trips = trips;
      _error = null;
      debugPrint('✅ Loaded ${_trips.length} trips');
    } catch (e, stack) {
      _error = 'Không thể tải danh sách kế hoạch: $e';
      _trips = [];
      debugPrint('❌ Error loading trips: $e');
      debugPrint('$stack');
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Bắt đầu lắng nghe thay đổi trips real-time
  void startWatchingTrips(String userId) {
    if (userId.isEmpty) {
      _trips = [];
      _safeNotifyListeners();
      return;
    }

    // Hủy subscription cũ nếu có
    _tripsSubscription?.cancel();

    // Bắt đầu lắng nghe stream
    _tripsSubscription = _tripService
        .watchTrips(userId)
        .listen(
          (trips) {
            _trips = trips;
            _error = null;
            debugPrint('✅ Trips updated: ${_trips.length} items');
            _safeNotifyListeners();
          },
          onError: (error) {
            _error = 'Lỗi khi cập nhật danh sách kế hoạch: $error';
            debugPrint('❌ Error in trips stream: $error');
            _safeNotifyListeners();
          },
        );
  }

  /// Dừng lắng nghe thay đổi trips
  void stopWatchingTrips() {
    _tripsSubscription?.cancel();
    _tripsSubscription = null;
  }

  /// Tạo trip mới
  Future<String?> createTrip(Trip trip) async {
    if (trip.userId.isEmpty) {
      _error = 'User ID không hợp lệ';
      _safeNotifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final tripId = await _tripService.createTrip(trip);
      // Reload trips
      await loadTrips(trip.userId);
      debugPrint('✅ Trip created: $tripId');
      return tripId;
    } catch (e, stack) {
      _error = 'Không thể tạo kế hoạch: $e';
      debugPrint('❌ Error creating trip: $e');
      debugPrint('$stack');
      _safeNotifyListeners();
      return null;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Cập nhật trip
  Future<void> updateTrip(
    String userId,
    String tripId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _tripService.updateTrip(userId, tripId, updates);
      // Reload trips
      await loadTrips(userId);
      // Reload current trip nếu đang xem
      if (_currentTrip?.id == tripId) {
        final updatedTrip = await _tripService.getTrip(userId, tripId);
        if (updatedTrip != null) {
          _currentTrip = updatedTrip;
        }
      }
      _error = null;
      _safeNotifyListeners();
    } catch (e, stack) {
      _error = 'Không thể cập nhật kế hoạch: $e';
      debugPrint('❌ Error updating trip: $e');
      debugPrint('$stack');
      _safeNotifyListeners();
      rethrow;
    }
  }

  /// Xóa trip
  Future<void> deleteTrip(String userId, String tripId) async {
    try {
      await _tripService.deleteTrip(userId, tripId);
      // Reload trips
      await loadTrips(userId);
      // Clear current trip nếu đang xem trip bị xóa
      if (_currentTrip?.id == tripId) {
        _currentTrip = null;
      }
      _error = null;
      _safeNotifyListeners();
    } catch (e, stack) {
      _error = 'Không thể xóa kế hoạch: $e';
      debugPrint('❌ Error deleting trip: $e');
      debugPrint('$stack');
      _safeNotifyListeners();
      rethrow;
    }
  }

  /// Set trip hiện tại
  Future<void> setCurrentTrip(String userId, String tripId) async {
    try {
      // Reset các state của trip cũ trước khi load trip mới
      _costEstimate = null;
      _weatherForecasts = null;
      _aiSuggestions = null;
      _costMultiplier = 1.0;
      _isEstimatingCost = false;
      _isLoadingWeather = false;
      _isLoadingSuggestions = false;
      _safeNotifyListeners(); // Notify ngay để UI clear state cũ
      
      debugPrint('🔄 Loading trip: $tripId');
      final trip = await _tripService.getTrip(userId, tripId);
      if (trip != null) {
        _currentTrip = trip;
        // Load costEstimate từ trip (đã được load từ Firestore)
        _costEstimate = trip.costEstimate;
        if (_costEstimate != null) {
          debugPrint('✅ Loaded costEstimate from Firestore for trip $tripId (total: ${_costEstimate!.total} VND)');
        } else {
          debugPrint('ℹ️ No costEstimate found in Firestore for trip $tripId');
        }
        // Bắt đầu watch items
        _startWatchingItems(userId, tripId);
        _safeNotifyListeners();
      } else {
        debugPrint('⚠️ Trip $tripId not found');
      }
    } catch (e, stack) {
      debugPrint('❌ Error setting current trip: $e');
      debugPrint('$stack');
    }
  }

  /// Clear current trip
  void clearCurrentTrip() {
    _currentTrip = null;
    _itemsSubscription?.cancel();
    _itemsSubscription = null;
    _costEstimate = null;
    _weatherForecasts = null;
    _aiSuggestions = null;
    _safeNotifyListeners();
  }

  /// Bắt đầu watch items của trip hiện tại
  void _startWatchingItems(String userId, String tripId) {
    _itemsSubscription?.cancel();
    _itemsSubscription = _tripService
        .watchTripItems(userId, tripId)
        .listen(
          (items) {
            if (_currentTrip != null) {
              // Giữ nguyên costEstimate khi update items
              final currentCostEstimate = _currentTrip!.costEstimate ?? _costEstimate;
              _currentTrip = _currentTrip!.copyWith(items: items, costEstimate: currentCostEstimate);
              // Đảm bảo _costEstimate trong provider cũng được giữ nguyên
              if (currentCostEstimate != null) {
                _costEstimate = currentCostEstimate;
              }
              _safeNotifyListeners();
            }
          },
          onError: (error) {
            debugPrint('❌ Error in items stream: $error');
          },
        );
  }

  /// Thêm destination vào trip
  Future<void> addDestinationToTrip(
    String userId,
    String tripId,
    String destinationId,
  ) async {
    try {
      // Lấy số items hiện tại để set order
      final currentItems = _currentTrip?.items ?? [];
      final order = currentItems.length;

      final item = TripItem(
        tripId: tripId,
        destinationId: destinationId,
        order: order,
      );

      await _tripService.addTripItem(userId, tripId, item);
      // Reload current trip
      await setCurrentTrip(userId, tripId);
      _error = null;
      _safeNotifyListeners();
    } catch (e, stack) {
      _error = 'Không thể thêm điểm đến: $e';
      debugPrint('❌ Error adding destination: $e');
      debugPrint('$stack');
      _safeNotifyListeners();
      rethrow;
    }
  }

  /// Thêm destination vào trip với chi tiết (ngày, giờ)
  Future<void> addDestinationToTripWithDetails(
    String userId,
    String tripId,
    String destinationId, {
    required DateTime plannedDate,
    TimeOfDay? plannedTime,
    int? order,
  }) async {
    try {
      // Lấy số items hiện tại để set order nếu không có
      final currentItems = _currentTrip?.items ?? [];
      final itemOrder = order ?? currentItems.length;

      final item = TripItem(
        tripId: tripId,
        destinationId: destinationId,
        order: itemOrder,
        plannedDate: plannedDate,
        plannedTime: plannedTime,
      );

      await _tripService.addTripItem(userId, tripId, item);
      // Reload current trip
      await setCurrentTrip(userId, tripId);
      _error = null;
      _safeNotifyListeners();
    } catch (e, stack) {
      _error = 'Không thể thêm điểm đến: $e';
      debugPrint('❌ Error adding destination: $e');
      debugPrint('$stack');
      _safeNotifyListeners();
      rethrow;
    }
  }

  /// Cập nhật trip item
  Future<void> updateTripItem(
    String userId,
    String tripId,
    String itemId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _tripService.updateTripItem(userId, tripId, itemId, updates);
      // Reload current trip
      await setCurrentTrip(userId, tripId);
      _error = null;
      _safeNotifyListeners();
    } catch (e, stack) {
      _error = 'Không thể cập nhật điểm đến: $e';
      debugPrint('❌ Error updating trip item: $e');
      debugPrint('$stack');
      _safeNotifyListeners();
      rethrow;
    }
  }

  /// Xóa destination khỏi trip
  Future<void> removeDestinationFromTrip(
    String userId,
    String tripId,
    String itemId,
  ) async {
    try {
      await _tripService.removeTripItem(userId, tripId, itemId);
      // Reload current trip
      await setCurrentTrip(userId, tripId);
      _error = null;
      _safeNotifyListeners();
    } catch (e, stack) {
      _error = 'Không thể xóa điểm đến: $e';
      debugPrint('❌ Error removing destination: $e');
      debugPrint('$stack');
      _safeNotifyListeners();
      rethrow;
    }
  }

  /// Sắp xếp lại items
  Future<void> reorderTripItems(
    String userId,
    String tripId,
    List<String> itemIds,
  ) async {
    try {
      await _tripService.reorderTripItems(userId, tripId, itemIds);
      // Reload current trip
      await setCurrentTrip(userId, tripId);
      _error = null;
      _safeNotifyListeners();
    } catch (e, stack) {
      _error = 'Không thể sắp xếp lại: $e';
      debugPrint('❌ Error reordering items: $e');
      debugPrint('$stack');
      _safeNotifyListeners();
      rethrow;
    }
  }

  /// Tính toán chi phí bằng AI
  /// [multiplierChange] để điều chỉnh: 0.2 = cao hơn 20%, -0.2 = thấp hơn 20%
  Future<void> estimateCost(
    String userId,
    String tripId, {
    double? multiplierChange,
  }) async {
    if (_currentTrip == null) {
      return;
    }

    // Cập nhật multiplier nếu có
    if (multiplierChange != null) {
      _costMultiplier = (_costMultiplier + multiplierChange).clamp(0.5, 2.0);
    }

    _isEstimatingCost = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final trip = _currentTrip!;
      final estimate = await AICostEstimationService.instance.estimateTripCost(
        trip,
        multiplier: _costMultiplier,
      );
      
      if (estimate != null) {
        _costEstimate = estimate;
        _error = null;
        debugPrint('✅ Cost estimation completed (multiplier: $_costMultiplier)');
        
        // Lưu costEstimate vào Firestore
        await _saveCostEstimateToFirestore(userId, tripId, estimate);
        
        // Lưu description vào Firestore nếu có
        if (estimate.detailedDescription != null && 
            estimate.detailedDescription!.isNotEmpty) {
          debugPrint('💾 Saving AIPlan to Firestore (${estimate.detailedDescription!.length} chars)');
          await _saveAIPlanToFirestore(
            tripId,
            userId,
            estimate.detailedDescription!,
            estimate.aiModel ?? 'unknown',
            _costMultiplier,
          );
        } else {
          debugPrint('⚠️ No detailedDescription to save');
        }
      } else {
        _error = 'Không thể tính toán chi phí';
      }
    } catch (e, stack) {
      _error = 'Lỗi khi tính toán chi phí: $e';
      debugPrint('❌ Error estimating cost: $e');
      debugPrint('$stack');
    } finally {
      _isEstimatingCost = false;
      _safeNotifyListeners();
    }
  }
  
  /// Reset multiplier về 1.0
  void resetCostMultiplier() {
    _costMultiplier = 1.0;
    _safeNotifyListeners();
  }

  /// Lưu costEstimate vào Firestore
  Future<void> _saveCostEstimateToFirestore(
    String userId,
    String tripId,
    TripCostEstimate estimate,
  ) async {
    try {
      final costEstimateMap = estimate.toMap();
      await _tripService.updateTrip(userId, tripId, {
        'costEstimate': costEstimateMap,
      });
      debugPrint('✅ CostEstimate saved to Firestore for trip $tripId (total: ${estimate.total} VND)');
    } catch (e, stack) {
      debugPrint('❌ Error saving CostEstimate to Firestore: $e');
      debugPrint('$stack');
      // Không throw error để không ảnh hưởng đến flow chính
    }
  }

  /// Lưu kế hoạch AI vào Firestore
  Future<void> _saveAIPlanToFirestore(
    String tripId,
    String userId,
    String description,
    String aiModel,
    double multiplier,
  ) async {
    try {
      final plan = AIPlan(
        tripId: tripId,
        userId: userId,
        description: description,
        aiModel: aiModel,
        multiplier: multiplier,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await AIPlanService.instance.saveAIPlan(plan);
      debugPrint('✅ AIPlan saved to Firestore (description length: ${description.length} chars)');
    } catch (e, stack) {
      debugPrint('❌ Error saving AIPlan to Firestore: $e');
      debugPrint('$stack');
      // Không throw error để không ảnh hưởng đến flow chính
    }
  }

  /// Load dự báo thời tiết
  Future<void> loadWeatherForecasts(String userId, String tripId) async {
    if (_currentTrip == null) {
      return;
    }

    _isLoadingWeather = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final trip = _currentTrip!;
      
      // Lấy thành phố từ location hoặc từ destination đầu tiên
      String? city;
      if (trip.location != null && trip.location!.isNotEmpty) {
        city = trip.location;
      } else if (trip.items.isNotEmpty && trip.items.first.destination != null) {
        city = trip.items.first.destination!.location.city;
      }

      if (city == null || city.isEmpty) {
        _weatherForecasts = [];
        _isLoadingWeather = false;
        _safeNotifyListeners();
        return;
      }

      // Lấy dự báo thời tiết cho tất cả các ngày trong trip
      final forecasts = await WeatherService.instance.getWeatherForecastsForTrip(
        city,
        trip.startDate,
        trip.endDate,
      );

      _weatherForecasts = forecasts;
      _error = null;
      debugPrint('✅ Loaded ${forecasts.length} weather forecasts');
    } catch (e, stack) {
      _error = 'Không thể tải dự báo thời tiết: $e';
      _weatherForecasts = [];
      debugPrint('❌ Error loading weather forecasts: $e');
      debugPrint('$stack');
    } finally {
      _isLoadingWeather = false;
      _safeNotifyListeners();
    }
  }

  /// Load gợi ý AI (placeholder - sẽ implement sau)
  Future<void> loadAISuggestions(
    String userId,
    String tripId, {
    String? destinationId,
  }) async {
    _isLoadingSuggestions = true;
    _safeNotifyListeners();

    // TODO: Implement AI suggestions in Phase 5
    await Future.delayed(const Duration(seconds: 1));
    
    _isLoadingSuggestions = false;
    _safeNotifyListeners();
  }

  /// Clear tất cả trips (dùng khi logout)
  void clearTrips() {
    _trips = [];
    _currentTrip = null;
    _error = null;
    _costEstimate = null;
    _weatherForecasts = null;
    _aiSuggestions = null;
    stopWatchingTrips();
    _itemsSubscription?.cancel();
    _itemsSubscription = null;
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
    stopWatchingTrips();
    _itemsSubscription?.cancel();
    super.dispose();
  }
}

