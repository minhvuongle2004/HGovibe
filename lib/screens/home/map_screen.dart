import 'dart:async';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:smart_travel_app/config/api/api_config.dart';
import 'package:smart_travel_app/models/destinations/destination.dart';
import 'package:smart_travel_app/models/maps/mapbox_place.dart';
import 'package:smart_travel_app/providers/destinations/destination_provider.dart';
import 'package:smart_travel_app/services/maps/mapbox_service.dart';
import 'package:smart_travel_app/services/destinations/usage_log_service.dart';
import 'package:smart_travel_app/widgets/common/main_bottom_nav.dart';

class MapScreen extends StatelessWidget {
  final Destination? initialDestination;
  final bool showBackToDetail;

  const MapScreen({
    super.key,
    this.initialDestination,
    this.showBackToDetail = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          DestinationProvider()..loadRecommendedDestinations(limit: 50),
      child: _MapScreenContent(
        initialDestination: initialDestination,
        showBackToDetail: showBackToDetail,
      ),
    );
  }
}

class _MapScreenContent extends StatefulWidget {
  final Destination? initialDestination;
  final bool showBackToDetail;

  const _MapScreenContent({
    this.initialDestination,
    this.showBackToDetail = false,
  });

  @override
  State<_MapScreenContent> createState() => _MapScreenContentState();
}

class _MapScreenContentState extends State<_MapScreenContent> {
  static const CameraPosition _defaultCamera = CameraPosition(
    target: LatLng(16.047079, 108.20623), // Đà Nẵng làm trung tâm mặc định
    zoom: 5.2,
  );

  MapboxMapController? _mapController;
  bool _isStyleLoaded = false;
  bool _isRequestingLocation = false;
  CameraPosition _initialCamera = _defaultCamera;
  double _currentZoom = _defaultCamera.zoom;
  Position? _currentPosition;
  String? _locationError;
  final List<Symbol> _symbols = [];
  List<String> _lastMarkerKeys = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  Completer<void>? _locationCompleter;
  bool _isSearchingPlaces = false;
  String? _searchError;
  List<MapboxPlace> _searchResults = [];
  List<MapboxPlace> _recentPlaces = [];
  Destination? _selectedDestination;
  MapboxPlace? _selectedPlace;
  Symbol? _searchSymbol;
  final Map<String, Destination> _destinationLookup = {};
  DistanceResult? _selectionDistance;
  bool _isCalculatingDistance = false;
  String? _distanceError;
  Destination? _pendingInitialDestination;
  bool _shouldAutoCenterOnUser = true;
  RouteResult? _activeRoute;
  List<RouteStepInfo> _routeSteps = [];
  bool _isRequestingRoute = false;
  String? _routeError;
  Line? _routeLine;
  String _selectedProfile = _RoutingProfileOption.motorbike.id;
  bool _showSteps = false;
  int _routingVersion = 0;
  bool _isInfoSheetVisible = true;
  bool get _isRoutingActive => _activeRoute != null;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOffline = false;

  bool get _hasSelection =>
      _selectedDestination != null || _selectedPlace != null;
  bool get _shouldShowRecentSearches =>
      _searchController.text.trim().isEmpty && _recentPlaces.isNotEmpty;
  List<double>? get _selectionCoordinates {
    if (_selectedDestination != null) {
      final loc = _selectedDestination!.location;
      return [loc.latitude, loc.longitude];
    }
    if (_selectedPlace != null) {
      return [_selectedPlace!.latitude, _selectedPlace!.longitude];
    }
    return null;
  }

  _RoutingProfileOption get _activeProfileOption =>
      _RoutingProfileOption.values.firstWhere(
        (option) => option.id == _selectedProfile,
        orElse: () => _RoutingProfileOption.motorbike,
      );

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleSearchFocusChange);
    _initConnectivityMonitoring();
    _shouldAutoCenterOnUser = widget.initialDestination == null;
    _initialCamera = widget.initialDestination != null
        ? CameraPosition(
            target: LatLng(
              widget.initialDestination!.location.latitude,
              widget.initialDestination!.location.longitude,
            ),
            zoom: 12.5,
          )
        : _defaultCamera;
    _pendingInitialDestination = widget.initialDestination;
    if (_pendingInitialDestination != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đang dẫn tới ${_pendingInitialDestination!.name} trên bản đồ',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      });
    }
    _initUserLocation();
  }

  @override
  void dispose() {
    if (_mapController != null) {
      _mapController!.onSymbolTapped.remove(_handleSymbolTap);
      if (_searchSymbol != null) {
        _mapController!.removeSymbol(_searchSymbol!);
      }
      if (_routeLine != null) {
        try {
          _mapController!.removeLine(_routeLine!);
        } catch (_) {}
      }
    }
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode
      ..removeListener(_handleSearchFocusChange)
      ..dispose();
    _symbols.clear();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initUserLocation() async {
    if (_isRequestingLocation) {
      await _locationCompleter?.future;
      return;
    }
    _locationCompleter = Completer<void>();
    setState(() {
      _isRequestingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locationError =
              'Dịch vụ vị trí đang tắt. Vui lòng bật GPS để xem vị trí hiện tại.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _locationError =
              'Ứng dụng cần quyền truy cập vị trí để hiển thị vị trí của bạn.';
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationError =
              'Bạn đã từ chối quyền vị trí vĩnh viễn. Vui lòng mở cài đặt để cấp quyền.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });

      if (_shouldAutoCenterOnUser) {
        await _moveCameraToUser();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Không thể lấy vị trí hiện tại: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingLocation = false;
        });
      }
      if (!(_locationCompleter?.isCompleted ?? true)) {
        _locationCompleter?.complete();
      }
      _locationCompleter = null;
    }
  }

  Future<void> _moveCameraToUser() async {
    if (_mapController == null || _currentPosition == null) return;
    final position = _currentPosition!;
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 13.0,
        ),
      ),
    );
  }

  void _handleSearchFocusChange() {
    if (!mounted) return;
    setState(() {});
  }

  void _initConnectivityMonitoring() {
    final connectivity = Connectivity();
    connectivity.checkConnectivity().then((results) {
      if (!mounted) return;
      _updateOfflineState(_isOfflineFromResults(results), showBanner: false);
    });
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((
      results,
    ) {
      _updateOfflineState(_isOfflineFromResults(results));
    });
  }

  void _updateOfflineState(bool offline, {bool showBanner = true}) {
    if (!mounted || _isOffline == offline) return;
    setState(() {
      _isOffline = offline;
    });
    if (showBanner) {
      final message = offline
          ? 'Bạn đang offline, một số tính năng bản đồ sẽ tạm dừng.'
          : 'Đã online trở lại, bạn có thể tiếp tục thao tác.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  bool _isOfflineFromResults(List<ConnectivityResult> results) {
    if (results.isEmpty) return true;
    return results.every((result) => result == ConnectivityResult.none);
  }

  void _handleSymbolTap(Symbol symbol) {
    final data = symbol.data ?? {};
    final source = data['source'] as String? ?? 'destination';

    if (source == 'cluster') {
      final lat = (data['clusterLat'] as num?)?.toDouble();
      final lng = (data['clusterLng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        final targetZoom = math.min(_currentZoom + 1.5, 16.0);
        _focusCameraOnLatLng(lat, lng, zoom: targetZoom);
      }
      return;
    }

    if (source == 'search') {
      final place = MapboxPlace(
        id: (data['placeId'] as String?) ?? '',
        name: (data['name'] as String?) ?? '',
        fullAddress: (data['address'] as String?) ?? '',
        latitude:
            (data['lat'] as num?)?.toDouble() ??
            symbol.options.geometry!.latitude,
        longitude:
            (data['lng'] as num?)?.toDouble() ??
            symbol.options.geometry!.longitude,
        placeType: (data['placeType'] as String?) ?? 'poi',
        category: data['category'] as String?,
        context: data['context'] as String?,
      );

      setState(() {
        _selectedPlace = place;
        _selectedDestination = null;
        _isInfoSheetVisible = true;
      });
      _computeDistanceForSelection(place.latitude, place.longitude);
      return;
    }

    final destinationKey = data['destinationKey'] as String?;
    Destination? destination = _destinationLookup[destinationKey];

    destination ??= _findDestinationByData(data);
    if (destination == null) return;

    unawaited(_clearRoute());
    setState(() {
      _selectedDestination = destination;
      _selectedPlace = null;
      _isInfoSheetVisible = true;
    });
    _computeDistanceForSelection(
      destination.location.latitude,
      destination.location.longitude,
    );
  }

  Destination? _findDestinationByData(Map<dynamic, dynamic> data) {
    final provider = context.read<DestinationProvider>();
    final id = data['destinationId'] as String?;
    final slug = data['destinationSlug'] as String?;

    if (id != null) {
      try {
        return provider.recommendedDestinations.firstWhere(
          (dest) => dest.id == id,
        );
      } catch (_) {}
    }

    if (slug != null) {
      try {
        return provider.recommendedDestinations.firstWhere(
          (dest) => dest.slug == slug,
        );
      } catch (_) {}
    }
    return null;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = null;
        _isSearchingPlaces = false;
      });
      return;
    }

    setState(() {
      _isSearchingPlaces = true;
      _searchError = null;
    });

    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _performSearch(value.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (_isOffline) {
      if (!mounted) return;
      setState(() {
        _isSearchingPlaces = false;
        _searchResults = [];
        _searchError = 'Bạn đang offline, không thể tìm kiếm lúc này.';
      });
      _showSnack('Không thể tìm kiếm khi offline.');
      return;
    }
    try {
      final results = await MapBoxService.instance.searchPlaces(
        query,
        limit: 6,
        proximityLat: _currentPosition?.latitude,
        proximityLng: _currentPosition?.longitude,
      );
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searchError = results.isEmpty
            ? 'Không tìm thấy địa điểm phù hợp, thử từ khóa khác.'
            : null;
      });
      if (results.isNotEmpty) {
        unawaited(UsageLogService.instance.logSearch(query));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _searchError = 'Không thể tìm kiếm lúc này: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingPlaces = false;
        });
      }
    }
  }

  Future<void> _selectPlace(MapboxPlace place) async {
    await _clearRoute();
    setState(() {
      _isInfoSheetVisible = true;
    });
    _searchController.text = place.name;
    _searchFocusNode.unfocus();
    setState(() {
      _selectedPlace = place;
      _selectedDestination = null;
      _searchResults = [];
    });
    _shouldAutoCenterOnUser = false;
    _addRecentPlace(place);
    await _focusCameraOnLatLng(place.latitude, place.longitude, zoom: 14);
    await _highlightSearchPlace(place);
    await _computeDistanceForSelection(place.latitude, place.longitude);
  }

  void _addRecentPlace(MapboxPlace place) {
    setState(() {
      _recentPlaces.removeWhere((item) => item.id == place.id);
      _recentPlaces.insert(0, place);
      if (_recentPlaces.length > 6) {
        _recentPlaces = _recentPlaces.sublist(0, 6);
      }
    });
  }

  Future<void> _focusCameraOnLatLng(
    double latitude,
    double longitude, {
    double zoom = 13,
  }) async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(latitude, longitude), zoom: zoom),
      ),
    );
  }

  Future<void> _highlightSearchPlace(MapboxPlace place) async {
    if (_mapController == null || !_isStyleLoaded) return;
    if (_searchSymbol != null) {
      await _mapController!.removeSymbol(_searchSymbol!);
      _searchSymbol = null;
    }
    try {
      _searchSymbol = await _mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(place.latitude, place.longitude),
          iconImage: 'marker-15',
          iconColor: '#2F80ED',
          iconSize: 1.3,
          textField: place.name,
          textOffset: const Offset(0, 1.4),
          textSize: 11,
        ),
        {
          'source': 'search',
          'placeId': place.id,
          'name': place.name,
          'address': place.fullAddress,
          'lat': place.latitude,
          'lng': place.longitude,
          'placeType': place.placeType,
          'context': place.context,
          'category': place.category,
        },
      );
    } catch (e) {
      debugPrint('❌ Không thể thêm marker tìm kiếm: $e');
    }
  }

  void _clearSelection({bool hideSheetOnly = false}) {
    if (!_hasSelection) return;
    if (hideSheetOnly) {
      setState(() {
        _isInfoSheetVisible = false;
      });
      return;
    }
    setState(() {
      _selectedDestination = null;
      _selectedPlace = null;
      _selectionDistance = null;
      _distanceError = null;
      _isInfoSheetVisible = false;
    });
    unawaited(_clearRoute());
  }

  Future<void> _clearRoute({bool keepProfile = true}) async {
    _routingVersion++;
    if (_routeLine != null && _mapController != null) {
      try {
        await _mapController!.removeLine(_routeLine!);
      } catch (e) {
        debugPrint('⚠️ Không thể xóa polyline: $e');
      } finally {
        _routeLine = null;
      }
    }
    if (!mounted) return;
    setState(() {
      _activeRoute = null;
      _routeSteps = [];
      _routeError = null;
      _isRequestingRoute = false;
      _showSteps = false;
      if (!keepProfile) {
        _selectedProfile = _RoutingProfileOption.motorbike.id;
      }
    });
  }

  void _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
    controller.onSymbolTapped.add(_handleSymbolTap);
    final position = controller.cameraPosition;
    if (position != null) {
      _currentZoom = position.zoom;
    }
  }

  void _onCameraIdle() {
    if (_mapController == null) return;
    final position = _mapController!.cameraPosition;
    if (position == null) return;
    final newZoom = position.zoom;
    if ((newZoom - _currentZoom).abs() > 0.25) {
      _currentZoom = newZoom;
      final provider = context.read<DestinationProvider>();
      _syncDestinationMarkers(provider.recommendedDestinations, force: true);
    } else {
      _currentZoom = newZoom;
    }
  }

  Future<void> _onStyleLoaded() async {
    setState(() {
      _isStyleLoaded = true;
    });
    if (_shouldAutoCenterOnUser) {
      await _moveCameraToUser();
    }
    if (mounted) {
      final provider = context.read<DestinationProvider>();
      await _syncDestinationMarkers(provider.recommendedDestinations);
      await _applyInitialDestinationFocus();
      await _restoreRouteIfNeeded();
    }
  }

  Future<void> _syncDestinationMarkers(
    List<Destination> destinations, {
    bool force = false,
  }) async {
    if (!_isStyleLoaded || _mapController == null) return;
    final effectiveList = List<Destination>.from(destinations);
    if (_selectedDestination != null &&
        !effectiveList.any(
          (dest) =>
              _destinationKey(dest) == _destinationKey(_selectedDestination!),
        )) {
      effectiveList.add(_selectedDestination!);
    }
    _refreshDestinationLookup(effectiveList);
    final entries = _buildMarkerEntries(effectiveList);
    final markerKeys = entries.map((entry) => entry.key).toList();

    if (!force && listEquals(markerKeys, _lastMarkerKeys)) return;

    _lastMarkerKeys = markerKeys;
    if (_symbols.isNotEmpty) {
      for (final symbol in List<Symbol>.from(_symbols)) {
        await _mapController!.removeSymbol(symbol);
      }
      _symbols.clear();
    }

    for (final entry in entries) {
      try {
        if (entry.isCluster) {
          final symbol = await _mapController!.addSymbol(
            SymbolOptions(
              geometry: LatLng(entry.latitude, entry.longitude),
              iconImage: 'marker-15',
              iconColor: '#F59E0B',
              iconSize: 1.5,
              textField: entry.count.toString(),
              textOffset: const Offset(0, 1.4),
              textSize: 12,
              textColor: '#FFFFFF',
              textHaloColor: '#000000',
              textHaloWidth: 0.8,
            ),
            {
              'source': 'cluster',
              'clusterLat': entry.latitude,
              'clusterLng': entry.longitude,
              'clusterCount': entry.count,
            },
          );
          _symbols.add(symbol);
        } else {
          final destination = entry.destination!;
          final loc = destination.location;
          final destinationKey = _destinationKey(destination);
          final symbol = await _mapController!.addSymbol(
            SymbolOptions(
              geometry: LatLng(loc.latitude, loc.longitude),
              iconImage: 'marker-15',
              iconColor: '#FF7A00',
              iconSize: 1.2,
              textField: destination.name,
              textOffset: const Offset(0, 1.3),
              textSize: 10,
            ),
            {
              'source': 'destination',
              'destinationId': destination.id ?? destination.slug,
              'destinationSlug': destination.slug,
              'destinationKey': destinationKey,
              'name': destination.name,
              'address': destination.location.address,
              'shortDescription': destination.shortDescription,
              'rating': destination.rating,
            },
          );
          _symbols.add(symbol);
        }
      } catch (e) {
        debugPrint('❌ Không thể thêm marker: $e');
      }
    }
  }

  void _refreshDestinationLookup(List<Destination> destinations) {
    _destinationLookup
      ..clear()
      ..addEntries(
        destinations.map((dest) => MapEntry(_destinationKey(dest), dest)),
      );
  }

  String _destinationKey(Destination destination) {
    final id = destination.id;
    if (id != null && id.isNotEmpty) {
      return id;
    }
    if (destination.slug.isNotEmpty) {
      return destination.slug;
    }
    return '${destination.name}-${destination.location.latitude}-${destination.location.longitude}';
  }

  List<_MarkerEntry> _buildMarkerEntries(List<Destination> destinations) {
    final effective = destinations
        .where(
          (dest) => dest.location.latitude != 0 && dest.location.longitude != 0,
        )
        .toList();
    if (effective.isEmpty) {
      return <_MarkerEntry>[];
    }
    if (_currentZoom >= 11 || effective.length <= 30) {
      return effective
          .map(
            (dest) => _MarkerEntry.single(
              destination: dest,
              key: _destinationKey(dest),
            ),
          )
          .toList();
    }

    final cellSize = _currentZoom < 7 ? 1.0 : 0.5;
    final Map<String, _ClusterAccumulator> clusters = {};

    for (final destination in effective) {
      final loc = destination.location;
      final bucketLat = (loc.latitude / cellSize).floor();
      final bucketLng = (loc.longitude / cellSize).floor();
      final bucketKey = '$bucketLat-$bucketLng';
      clusters
          .putIfAbsent(bucketKey, () => _ClusterAccumulator())
          .add(destination);
    }

    final entries = <_MarkerEntry>[];
    clusters.forEach((bucketKey, cluster) {
      if (cluster.count == 1) {
        final destination = cluster.members.first;
        entries.add(
          _MarkerEntry.single(
            destination: destination,
            key: _destinationKey(destination),
          ),
        );
      } else {
        entries.add(
          _MarkerEntry.cluster(
            key: 'cluster-$bucketKey',
            latitude: cluster.latitude,
            longitude: cluster.longitude,
            memberIds: cluster.members
                .map((dest) => _destinationKey(dest))
                .toList(),
          ),
        );
      }
    });
    return entries;
  }

  Future<void> _applyInitialDestinationFocus() async {
    if (_pendingInitialDestination == null ||
        !_isStyleLoaded ||
        _mapController == null) {
      return;
    }
    final destination = _pendingInitialDestination!;
    await _ensureDestinationMarker(destination);
    setState(() {
      _selectedDestination = destination;
      _selectedPlace = null;
    });
    _shouldAutoCenterOnUser = false;
    await _focusCameraOnLatLng(
      destination.location.latitude,
      destination.location.longitude,
      zoom: 14.5,
    );
    await _computeDistanceForSelection(
      destination.location.latitude,
      destination.location.longitude,
    );
    _shouldAutoCenterOnUser = false;
    _pendingInitialDestination = null;
  }

  Future<void> _restoreRouteIfNeeded() async {
    if (_activeRoute == null || !_isStyleLoaded) return;
    await _drawRouteOnMap(_activeRoute!);
  }

  Future<void> _ensureDestinationMarker(Destination destination) async {
    if (_mapController == null || !_isStyleLoaded) return;
    final key = _destinationKey(destination);
    if (_destinationLookup.containsKey(key)) {
      return;
    }
    try {
      final symbol = await _mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(
            destination.location.latitude,
            destination.location.longitude,
          ),
          iconImage: 'marker-15',
          iconColor: '#FF7A00',
          iconSize: 1.2,
          textField: destination.name,
          textOffset: const Offset(0, 1.3),
          textSize: 10,
        ),
        {
          'source': 'destination',
          'destinationId': destination.id ?? destination.slug,
          'destinationSlug': destination.slug,
          'destinationKey': key,
          'name': destination.name,
          'address': destination.location.address,
          'shortDescription': destination.shortDescription,
          'rating': destination.rating,
        },
      );
      _symbols.add(symbol);
      _destinationLookup[key] = destination;
    } catch (e) {
      debugPrint('❌ Không thể thêm marker cho ${destination.name}: $e');
    }
  }

  Future<void> _computeDistanceForSelection(double lat, double lng) async {
    if (_currentPosition == null) {
      await _initUserLocation();
      if (_currentPosition == null) {
        if (!mounted) return;
        setState(() {
          _selectionDistance = null;
          _distanceError =
              'Không thể xác định vị trí của bạn. Vui lòng bật GPS.';
        });
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _isCalculatingDistance = true;
      _distanceError = null;
    });

    try {
      final result = await MapBoxService.instance.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        lat,
        lng,
      );
      if (!mounted) return;
      if (result != null) {
        setState(() {
          _selectionDistance = result;
        });
      } else {
        setState(() {
          _selectionDistance = null;
          _distanceError = 'Không thể tính khoảng cách cho vị trí này.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selectionDistance = null;
        _distanceError = 'Không thể tính khoảng cách: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCalculatingDistance = false;
        });
      }
    }
  }

  Widget _buildSearchBar() {
    if (_isRoutingActive) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          children: [
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(32),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm địa điểm, thành phố, quận huyện...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            _buildSearchOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchOverlay() {
    final hasFocus = _searchFocusNode.hasFocus;
    final showRecent = hasFocus && _shouldShowRecentSearches;
    final hasQuery = _searchController.text.trim().isNotEmpty;
    final showResults = hasFocus && hasQuery;

    if (!showRecent && !showResults) {
      return const SizedBox.shrink();
    }

    final items = showRecent ? _recentPlaces : _searchResults;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(top: 8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 250),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isSearchingPlaces) const LinearProgressIndicator(minHeight: 2),
            if (showRecent)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Tìm kiếm gần đây',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            if (showResults && hasQuery)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Kết quả cho “${_searchController.text.trim()}”',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            if (_searchError != null && !_isSearchingPlaces)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _searchError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            if (items.isEmpty && !_isSearchingPlaces && _searchError == null)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Không có dữ liệu để hiển thị.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
            if (items.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final place = items[index];
                    return _buildSuggestionTile(place, isRecent: showRecent);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(MapboxPlace place, {bool isRecent = false}) {
    return ListTile(
      onTap: () => _selectPlace(place),
      leading: Icon(
        isRecent ? Icons.history : Icons.place_outlined,
        color: isRecent ? Colors.amber[700] : Colors.blueAccent,
      ),
      title: Text(
        place.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        place.fullAddress,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: place.category != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                place.category!,
                style: const TextStyle(fontSize: 11),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoSheet(BuildContext context) {
    if (!_hasSelection) return const SizedBox.shrink();

    final destination = _selectedDestination;
    final place = _selectedPlace;

    final title = destination?.name ?? place?.name ?? '';
    final address =
        destination?.location.address ??
        place?.fullAddress ??
        'Chưa rõ địa chỉ';
    final subtitle =
        destination?.shortDescription ??
        place?.context ??
        place?.category ??
        '';
    final rating = destination?.rating;
    final secondaryLabel = widget.showBackToDetail
        ? 'Quay lại chi tiết'
        : 'Đóng';
    final secondaryAction = widget.showBackToDetail
        ? () {
            Navigator.of(context).pop();
          }
        : () => _clearSelection();
    final mediaQuery = MediaQuery.of(context);
    final sheetMaxHeight = mediaQuery.size.height * 0.55;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16 + mediaQuery.padding.bottom,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: sheetMaxHeight,
            minHeight: 220,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            address,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _clearSelection(hideSheetOnly: true),
                      icon: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ],
                ),
                if (rating != null && rating > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 18),
                      const SizedBox(width: 4),
                      Text('${rating.toStringAsFixed(1)} / 5'),
                      const SizedBox(width: 12),
                      Text(
                        destination?.category ?? '',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ],
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
                const SizedBox(height: 12),
                if (_isCalculatingDistance)
                  Row(
                    children: const [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Đang tính khoảng cách...'),
                    ],
                  )
                else if (_selectionDistance != null)
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.route, size: 18, color: Colors.teal),
                          const SizedBox(width: 4),
                          Text(_selectionDistance!.distanceFormatted),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 18,
                            color: Colors.indigo,
                          ),
                          const SizedBox(width: 4),
                          Text(_selectionDistance!.durationFormatted),
                        ],
                      ),
                    ],
                  )
                else if (_distanceError != null)
                  Text(
                    _distanceError!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                const SizedBox(height: 16),
                _buildProfileSelector(),
                if (_routeError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _routeError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (_activeRoute != null) ...[
                  const SizedBox(height: 12),
                  _buildRouteDetails(),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isRequestingRoute ? null : _startNavigation,
                        icon: _isRequestingRoute
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.navigation_rounded),
                        label: Text(
                          _isRequestingRoute
                              ? 'Đang lấy tuyến đường...'
                              : 'Bắt đầu dẫn đường',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: secondaryAction,
                      child: Text(secondaryLabel),
                    ),
                  ],
                ),
                if (_activeRoute != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _clearRoute(),
                        icon: const Icon(Icons.clear),
                        label: const Text('Xóa tuyến đường'),
                      ),
                    ),
                  ),
                if (_hasSelection)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () async => await _openExternalNavigation(
                            _ExternalNavTarget.google,
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Mở Google Maps'),
                        ),
                        TextButton.icon(
                          onPressed: () async => await _openExternalNavigation(
                            _ExternalNavTarget.mapbox,
                          ),
                          icon: const Icon(Icons.explore_outlined),
                          label: const Text('Mở Mapbox'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn phương tiện',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _RoutingProfileOption.values.map((option) {
            final isSelected = option.id == _selectedProfile;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    option.icon,
                    size: 16,
                    color: isSelected ? option.color : Colors.black54,
                  ),
                  const SizedBox(width: 6),
                  Text(option.label),
                ],
              ),
              selected: isSelected,
              labelStyle: TextStyle(
                color: isSelected ? option.color : Colors.black87,
              ),
              selectedColor: _colorWithOpacity(option.color, 0.18),
              backgroundColor: Colors.grey.shade100,
              onSelected: (value) {
                if (!value) return;
                setState(() {
                  _selectedProfile = option.id;
                });
                if (_activeRoute != null && !_isRequestingRoute) {
                  _startNavigation();
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNextStepBanner() {
    if (_routeSteps.isEmpty) {
      return const SizedBox.shrink();
    }
    final step = _routeSteps.first;
    final profile = _activeProfileOption;
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _colorWithOpacity(profile.color, 0.15),
                child: Icon(Icons.turn_right, color: profile.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      step.instruction,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${step.distanceFormatted} • ${step.durationFormatted}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteDetails() {
    final route = _activeRoute;
    if (route == null) {
      return const SizedBox.shrink();
    }
    final profile = _activeProfileOption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _colorWithOpacity(profile.color, 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tuyến đường cho ${profile.label.toLowerCase()}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.route, size: 18, color: Colors.black87),
                      const SizedBox(width: 4),
                      Text(route.distanceFormatted),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, size: 18, color: Colors.black87),
                      const SizedBox(width: 4),
                      Text(route.durationFormatted),
                    ],
                  ),
                ],
              ),
              if (route.fromCache)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Đọc từ cache gần đây',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
            ],
          ),
        ),
        if (_routeSteps.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildRouteSteps(),
        ],
      ],
    );
  }

  Widget _buildRouteSteps() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: Text(
              'Các chặng di chuyển (${_routeSteps.length})',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: IconButton(
              icon: Icon(_showSteps ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _showSteps = !_showSteps;
                });
              },
            ),
          ),
          if (_showSteps)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _routeSteps.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final step = _routeSteps[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: _colorWithOpacity(
                      _activeProfileOption.color,
                      0.15,
                    ),
                    child: Icon(
                      Icons.navigation,
                      size: 16,
                      color: _activeProfileOption.color,
                    ),
                  ),
                  title: Text(
                    step.instruction,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                  subtitle: Text(
                    '${step.distanceFormatted} • ${step.durationFormatted}',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _startNavigation() async {
    if (_isOffline) {
      _showSnack('Không thể dẫn đường khi đang offline.');
      return;
    }
    final coords = _selectionCoordinates;
    if (coords == null) {
      _showSnack('Hãy chọn một địa điểm trước khi dẫn đường.');
      return;
    }

    if (_currentPosition == null) {
      await _initUserLocation();
    }

    if (_currentPosition == null) {
      _showSnack('Không thể lấy vị trí hiện tại để dẫn đường.');
      return;
    }

    final origin = _currentPosition!;
    final requestId = ++_routingVersion;

    unawaited(
      UsageLogService.instance.logNavigation(
        destination: _selectedDestination,
        place: _selectedPlace,
        profile: _selectedProfile,
        distanceKm: _selectionDistance?.distance,
      ),
    );

    setState(() {
      _isRequestingRoute = true;
      _routeError = null;
    });

    try {
      final route = await MapBoxService.instance.getRoute(
        originLat: origin.latitude,
        originLng: origin.longitude,
        destinationLat: coords[0],
        destinationLng: coords[1],
        profile: _selectedProfile,
      );

      if (!mounted || requestId != _routingVersion) return;

      if (route == null) {
        setState(() {
          _routeError = 'Không tìm thấy tuyến đường phù hợp.';
        });
        return;
      }

      setState(() {
        _activeRoute = route;
        _routeSteps = route.steps;
        _showSteps = false;
        _isInfoSheetVisible = true;
      });

      await _drawRouteOnMap(route);
      await _fitCameraToRoute(route);
      await _focusOnUserForNavigation();
    } catch (e) {
      unawaited(UsageLogService.instance.logError('navigation', e));
      if (!mounted || requestId != _routingVersion) return;
      setState(() {
        _routeError = 'Không thể lấy tuyến đường: $e';
      });
    } finally {
      if (mounted && requestId == _routingVersion) {
        setState(() {
          _isRequestingRoute = false;
        });
      }
    }
  }

  Future<void> _drawRouteOnMap(RouteResult route) async {
    if (_mapController == null || !_isStyleLoaded) return;
    final coordinates = route.coordinates;
    if (coordinates.isEmpty) return;

    if (_routeLine != null) {
      try {
        await _mapController!.removeLine(_routeLine!);
      } catch (e) {
        debugPrint('⚠️ Không thể xóa polyline cũ: $e');
      } finally {
        _routeLine = null;
      }
    }

    try {
      _routeLine = await _mapController!.addLine(
        LineOptions(
          geometry: coordinates
              .map((coord) => LatLng(coord.latitude, coord.longitude))
              .toList(),
          lineColor: _colorToHex(_profileColor(route.profile)),
          lineWidth: 5.2,
          lineOpacity: 0.9,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Không thể vẽ tuyến đường: $e');
    }
  }

  Future<void> _fitCameraToRoute(RouteResult route) async {
    if (_mapController == null || route.coordinates.isEmpty) return;
    double minLat = route.coordinates.first.latitude;
    double maxLat = route.coordinates.first.latitude;
    double minLng = route.coordinates.first.longitude;
    double maxLng = route.coordinates.first.longitude;

    for (final coord in route.coordinates) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          left: 40,
          right: 40,
          top: 80,
          bottom: _hasSelection ? 320 : 140,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Không thể fit bounds: $e');
    }
  }

  Future<void> _focusOnUserForNavigation() async {
    if (_mapController == null || _currentPosition == null) return;
    final origin = _currentPosition!;
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(origin.latitude, origin.longitude),
            zoom: 15.5,
            tilt: 45,
          ),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Không thể focus người dùng: $e');
    }
  }

  Future<void> _openExternalNavigation(_ExternalNavTarget target) async {
    final coords = _selectionCoordinates;
    if (coords == null) {
      _showSnack('Hãy chọn một địa điểm trước.');
      return;
    }
    if (_currentPosition == null) {
      await _initUserLocation();
    }
    final origin = _currentPosition;
    if (origin == null) {
      _showSnack('Không thể lấy vị trí hiện tại để mở dẫn đường.');
      return;
    }

    final destinationLat = coords[0];
    final destinationLng = coords[1];

    Uri uri;
    if (target == _ExternalNavTarget.google) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${origin.latitude},${origin.longitude}'
        '&destination=$destinationLat,$destinationLng'
        '&travelmode=driving',
      );
    } else {
      uri = Uri.parse(
        'https://www.mapbox.com/directions/?origin=${origin.longitude},${origin.latitude}'
        '&destination=$destinationLng,$destinationLat'
        '&profile=$_selectedProfile',
      );
    }

    final launchMode = kIsWeb
        ? LaunchMode.platformDefault
        : LaunchMode.externalApplication;
    final success = await launchUrl(uri, mode: launchMode);
    if (!success) {
      _showSnack('Không thể mở ứng dụng dẫn đường bên ngoài.');
    }
  }

  Color _profileColor(String profileId) {
    return _RoutingProfileOption.values
        .firstWhere(
          (option) => option.id == profileId,
          orElse: () => _RoutingProfileOption.motorbike,
        )
        .color;
  }

  String _colorToHex(Color color) {
    final value = color.toARGB32() & 0x00FFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Color _colorWithOpacity(Color color, double opacity) {
    final clamped = opacity.clamp(0.0, 1.0);
    final alpha = (clamped * 255).round();
    return color.withAlpha(alpha);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _zoomMap(double delta) async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(CameraUpdate.zoomBy(delta));
  }

  Future<void> _recenterCamera() async {
    _shouldAutoCenterOnUser = true;
    if (_currentPosition != null) {
      await _moveCameraToUser();
    } else {
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(_defaultCamera),
      );
    }
  }

  @override
  void didUpdateWidget(covariant _MapScreenContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDestination != oldWidget.initialDestination) {
      if (widget.initialDestination != null) {
        _shouldAutoCenterOnUser = false;
        _initialCamera = CameraPosition(
          target: LatLng(
            widget.initialDestination!.location.latitude,
            widget.initialDestination!.location.longitude,
          ),
          zoom: 12.5,
        );
        _pendingInitialDestination = widget.initialDestination;
        if (_isStyleLoaded) {
          _applyInitialDestinationFocus();
        }
      } else {
        _shouldAutoCenterOnUser = true;
        _initialCamera = _defaultCamera;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinationProvider = context.watch<DestinationProvider>();
    final destinations = destinationProvider.recommendedDestinations;
    final media = MediaQuery.of(context);
    final offlineIndicatorTop = _isRoutingActive
        ? media.padding.top + 12
        : media.padding.top + 90;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncDestinationMarkers(destinations);
    });

    return Scaffold(
      body: Stack(
        children: [
          MapboxMap(
            accessToken: ApiConfig.mapboxApiKey,
            styleString: MapboxStyles.MAPBOX_STREETS,
            initialCameraPosition: _initialCamera,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onCameraIdle: _onCameraIdle,
            onMapClick: (point, coordinates) {
              if (_searchFocusNode.hasFocus) {
                _searchFocusNode.unfocus();
              }
              if (_hasSelection) {
                setState(() {
                  _isInfoSheetVisible = false;
                });
              } else {
                _clearSelection();
              }
            },
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.TrackingCompass,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            logoViewMargins: const math.Point(16, 16),
            attributionButtonMargins: const math.Point(16, 56),
          ),
          if (!_isRoutingActive)
            Positioned(left: 0, right: 0, child: _buildSearchBar()),
          if (_activeRoute != null && _routeSteps.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: _buildNextStepBanner(),
            ),
          if (_isOffline)
            Positioned(
              top: offlineIndicatorTop,
              left: 16,
              child: Chip(
                avatar: const Icon(
                  Icons.signal_wifi_connected_no_internet_4,
                  size: 18,
                ),
                label: const Text(
                  'Đang offline',
                  style: TextStyle(fontSize: 12.5),
                ),
                backgroundColor: Colors.orange.shade100,
              ),
            ),
          if (_isRequestingLocation)
            const Positioned(
              top: 110,
              left: 16,
              child: Chip(
                avatar: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                label: Text('Đang xác định vị trí...'),
              ),
            ),
          if (_locationError != null)
            Positioned(
              top: 120,
              right: 16,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Card(
                  color: Colors.black87,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _locationError!,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: _hasSelection ? 220 : 24,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () => _zoomMap(1),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () => _zoomMap(-1),
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'recenter',
                  onPressed: _recenterCamera,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
          if (destinationProvider.isLoading)
            const Positioned(
              bottom: 24,
              left: 16,
              child: Chip(
                avatar: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                label: Text('Đang tải địa điểm...'),
              ),
            ),
          if (_hasSelection && _isInfoSheetVisible) _buildInfoSheet(context),
          if (_hasSelection && !_isInfoSheetVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24 + MediaQuery.of(context).padding.bottom,
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _isInfoSheetVisible = true;
                    });
                  },
                  child: const Text('Hiển thị thông tin điểm đến'),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: buildMainBottomNavigationBar(context, 2),
    );
  }
}

enum _ExternalNavTarget { google, mapbox }

class _RoutingProfileOption {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const _RoutingProfileOption({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });

  static const _RoutingProfileOption motorbike = _RoutingProfileOption(
    id: 'driving',
    label: 'Xe máy',
    description: 'Linh hoạt, ưu tiên đường nhỏ',
    icon: Icons.two_wheeler,
    color: Color(0xFFF57C00),
  );

  static const _RoutingProfileOption car = _RoutingProfileOption(
    id: 'driving-traffic',
    label: 'Ô tô',
    description: 'Tối ưu đường lớn, tránh kẹt xe',
    icon: Icons.directions_car,
    color: Color(0xFF1565C0),
  );

  static List<_RoutingProfileOption> get values => [motorbike, car];
}

class _MarkerEntry {
  final String key;
  final double latitude;
  final double longitude;
  final Destination? destination;
  final List<String> memberIds;

  const _MarkerEntry._({
    required this.key,
    required this.latitude,
    required this.longitude,
    required this.destination,
    required this.memberIds,
  });

  factory _MarkerEntry.single({
    required Destination destination,
    required String key,
  }) {
    final loc = destination.location;
    return _MarkerEntry._(
      key: key,
      latitude: loc.latitude,
      longitude: loc.longitude,
      destination: destination,
      memberIds: [key],
    );
  }

  factory _MarkerEntry.cluster({
    required String key,
    required double latitude,
    required double longitude,
    required List<String> memberIds,
  }) {
    return _MarkerEntry._(
      key: key,
      latitude: latitude,
      longitude: longitude,
      destination: null,
      memberIds: memberIds,
    );
  }

  bool get isCluster => destination == null;
  int get count => destination == null ? memberIds.length : 1;
}

class _ClusterAccumulator {
  final List<Destination> members = [];
  double _latSum = 0;
  double _lngSum = 0;

  void add(Destination destination) {
    members.add(destination);
    _latSum += destination.location.latitude;
    _lngSum += destination.location.longitude;
  }

  int get count => members.length;
  double get latitude => _latSum / count;
  double get longitude => _lngSum / count;
}
