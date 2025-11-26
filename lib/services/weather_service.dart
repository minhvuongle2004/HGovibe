import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/weather_forecast.dart';

/// Service để lấy dự báo thời tiết từ OpenWeatherMap API
class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  // Cache để tránh gọi API nhiều lần
  final Map<String, WeatherForecast> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(hours: 1);

  /// Lấy dự báo thời tiết cho một thành phố và ngày cụ thể
  Future<WeatherForecast?> getWeatherForecast(
    String city,
    DateTime date,
  ) async {
    try {
      // Tạo cache key
      final cacheKey = '${city}_${date.toIso8601String().split('T')[0]}';
      
      // Kiểm tra cache
      if (_cache.containsKey(cacheKey)) {
        final cachedTime = _cacheTimestamps[cacheKey];
        if (cachedTime != null &&
            DateTime.now().difference(cachedTime) < _cacheDuration) {
          debugPrint('✅ Using cached weather for $city on ${date.toIso8601String().split('T')[0]}');
          return _cache[cacheKey];
        }
      }

      // Gọi API
      final url = Uri.parse(
        '${ApiConfig.weatherBaseUrl}/forecast?q=$city&appid=${ApiConfig.weatherApiKey}&units=metric&lang=vi',
      );

      debugPrint('🌤️ Fetching weather for $city on ${date.toIso8601String().split('T')[0]}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Tìm forecast gần nhất với ngày yêu cầu
        final forecasts = data['list'] as List;
        WeatherForecast? closestForecast;
        DateTime? closestDate;
        final targetDate = DateTime(date.year, date.month, date.day);

        for (var forecast in forecasts) {
          final forecastTime = DateTime.fromMillisecondsSinceEpoch(
            forecast['dt'] * 1000,
          );
          final forecastDate = DateTime(
            forecastTime.year,
            forecastTime.month,
            forecastTime.day,
          );

          // Tìm forecast trong cùng ngày hoặc gần nhất
          if (forecastDate.isAtSameMomentAs(targetDate) ||
              (forecastDate.isAfter(targetDate) &&
                  (closestDate == null || forecastDate.isBefore(closestDate)))) {
            final main = forecast['main'];
            final weather = forecast['weather'][0];
            final wind = forecast['wind'];

            closestForecast = WeatherForecast(
              date: targetDate,
              location: city,
              temperatureMin: (main['temp_min'] as num).toDouble(),
              temperatureMax: (main['temp_max'] as num).toDouble(),
              condition: weather['main'].toString().toLowerCase(),
              description: weather['description'].toString(),
              humidity: main['humidity'] as int,
              windSpeed: (wind['speed'] as num).toDouble() * 3.6, // m/s to km/h
              recommendation: _getRecommendation(
                weather['main'].toString().toLowerCase(),
                (main['temp_max'] as num).toDouble(),
              ),
              iconCode: weather['icon'].toString(),
            );
            closestDate = forecastDate;
          }
        }

        if (closestForecast != null) {
          // Lưu vào cache
          _cache[cacheKey] = closestForecast;
          _cacheTimestamps[cacheKey] = DateTime.now();
          debugPrint('✅ Weather forecast loaded for $city');
          return closestForecast;
        } else {
          debugPrint('⚠️ No forecast found for $city on ${date.toIso8601String().split('T')[0]}');
          return null;
        }
      } else {
        debugPrint('❌ Weather API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stack) {
      debugPrint('❌ Error fetching weather: $e');
      debugPrint('$stack');
      return null;
    }
  }

  /// Lấy dự báo thời tiết cho nhiều ngày trong trip
  Future<List<WeatherForecast>> getWeatherForecastsForTrip(
    String city,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final forecasts = <WeatherForecast>[];
    final currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    var date = currentDate;
    while (!date.isAfter(end)) {
      final forecast = await getWeatherForecast(city, date);
      if (forecast != null) {
        forecasts.add(forecast);
      }
      date = date.add(const Duration(days: 1));
    }

    return forecasts;
  }

  /// Lấy khuyến nghị dựa trên điều kiện thời tiết
  String? _getRecommendation(String condition, double maxTemp) {
    switch (condition.toLowerCase()) {
      case 'rain':
      case 'drizzle':
      case 'thunderstorm':
        return 'Nên mang theo ô/dù và áo mưa';
      case 'snow':
        return 'Trời có tuyết, cần mặc ấm và cẩn thận khi di chuyển';
      case 'extreme':
        return 'Thời tiết cực đoan, nên cân nhắc hoãn chuyến đi';
      case 'clear':
      case 'sunny':
        if (maxTemp > 35) {
          return 'Trời nắng nóng, nên mang theo nước và kem chống nắng';
        } else if (maxTemp > 30) {
          return 'Trời nắng đẹp, phù hợp cho du lịch';
        } else {
          return 'Thời tiết đẹp, lý tưởng cho du lịch';
        }
      case 'clouds':
      case 'cloudy':
        return 'Trời nhiều mây, thời tiết mát mẻ';
      case 'mist':
      case 'fog':
        return 'Có sương mù, cẩn thận khi di chuyển';
      default:
        return null;
    }
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}

