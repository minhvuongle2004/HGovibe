import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/destination.dart';
import '../models/mapbox_place.dart';

class UsageLogService {
  UsageLogService._();

  static final UsageLogService instance = UsageLogService._();

  File? _logFile;
  bool _isInitializing = false;
  final List<String> _buffer = [];

  Future<void> _ensureInitialized() async {
    if (_logFile != null) return;
    if (kIsWeb) {
      // Web không hỗ trợ filesystem, giữ log ở memory buffer.
      return;
    }
    if (_isInitializing) {
      // Avoid race when multiple callers wait for initialization.
      while (_isInitializing) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _isInitializing = true;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/usage_logs.txt');
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
      _logFile = file;
      if (_buffer.isNotEmpty) {
        await file.writeAsString(_buffer.join(), mode: FileMode.append);
        _buffer.clear();
      }
    } catch (e) {
      debugPrint('⚠️ Không thể khởi tạo UsageLogService: $e');
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> logSearch(String query) async {
    final timestamp = DateTime.now().toIso8601String();
    final line = '[$timestamp] SEARCH: "$query"\n';
    await _append(line);
  }

  Future<void> logNavigation({
    Destination? destination,
    MapboxPlace? place,
    required String profile,
    double? distanceKm,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    final targetName = destination?.name ?? place?.name ?? 'unknown';
    final line = '[$timestamp] NAVIGATION: $targetName | profile=$profile | '
        'distance=${distanceKm?.toStringAsFixed(1) ?? 'unknown'} km\n';
    await _append(line);
  }

  Future<void> logError(String context, Object error) async {
    final timestamp = DateTime.now().toIso8601String();
    final line = '[$timestamp] ERROR: $context => $error\n';
    await _append(line);
  }

  Future<void> _append(String line) async {
    try {
      await _ensureInitialized();
      final file = _logFile;
      if (file != null) {
        await file.writeAsString(line, mode: FileMode.append);
      } else {
        _buffer.add(line);
      }
    } catch (e) {
      debugPrint('⚠️ Không thể ghi log usage: $e');
    }
    debugPrint(line.trim());
  }

  Future<List<String>> readRecent({int limit = 50}) async {
    await _ensureInitialized();
    final file = _logFile;
    if (file == null) return _buffer.take(limit).toList();
    final content = await file.readAsLines();
    return content.reversed.take(limit).toList();
  }
}

