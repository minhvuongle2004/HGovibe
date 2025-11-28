import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smart_travel_app/models/weather/weather_forecast.dart';

/// Card hiển thị dự báo thời tiết
class WeatherForecastCard extends StatelessWidget {
  final WeatherForecast forecast;

  const WeatherForecastCard({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Format ngày tháng với locale tiếng Việt
    String dayName;
    try {
      final dayFormat = DateFormat('EEEE', 'vi');
      dayName = dayFormat.format(forecast.date);
    } catch (e) {
      // Fallback nếu locale chưa được khởi tạo
      final dayNames = [
        'Chủ nhật',
        'Thứ hai',
        'Thứ ba',
        'Thứ tư',
        'Thứ năm',
        'Thứ sáu',
        'Thứ bảy',
      ];
      dayName = dayNames[forecast.date.weekday % 7];
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Ngày và địa điểm
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(forecast.date),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Weather icon
                CachedNetworkImage(
                  imageUrl: forecast.iconUrl,
                  width: 64,
                  height: 64,
                  errorWidget: (context, url, error) => Icon(
                    _getWeatherIcon(forecast.condition),
                    size: 64,
                    color: _getWeatherColor(forecast.condition),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Nhiệt độ
            Row(
              children: [
                Text(
                  '${forecast.temperatureMax.toInt()}°',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '/ ${forecast.temperatureMin.toInt()}°',
                  style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                ),
                const Spacer(),
                // Condition description
                Expanded(
                  child: Text(
                    forecast.description,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Chi tiết: Độ ẩm, Gió
            Row(
              children: [
                _buildDetailItem(
                  Icons.water_drop,
                  'Độ ẩm',
                  '${forecast.humidity}%',
                ),
                const SizedBox(width: 24),
                _buildDetailItem(
                  Icons.air,
                  'Gió',
                  '${forecast.windSpeed.toInt()} km/h',
                ),
              ],
            ),
            // Khuyến nghị
            if (forecast.recommendation != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getRecommendationColor(
                    forecast.condition,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getRecommendationColor(
                      forecast.condition,
                    ).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getRecommendationIcon(forecast.condition),
                      color: _getRecommendationColor(forecast.condition),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        forecast.recommendation!,
                        style: TextStyle(
                          fontSize: 13,
                          color: _getRecommendationColor(forecast.condition),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return Icons.wb_sunny;
      case 'clouds':
      case 'cloudy':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
        return Icons.blur_on;
      default:
        return Icons.wb_cloudy;
    }
  }

  Color _getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return Colors.orange;
      case 'clouds':
      case 'cloudy':
        return Colors.grey;
      case 'rain':
      case 'drizzle':
      case 'thunderstorm':
        return Colors.blue;
      case 'snow':
        return Colors.lightBlue;
      default:
        return Colors.grey;
    }
  }

  IconData _getRecommendationIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'rain':
      case 'drizzle':
      case 'thunderstorm':
        return Icons.umbrella;
      case 'snow':
        return Icons.warning;
      case 'extreme':
        return Icons.error;
      case 'clear':
      case 'sunny':
        return Icons.wb_sunny;
      default:
        return Icons.info;
    }
  }

  Color _getRecommendationColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'rain':
      case 'drizzle':
      case 'thunderstorm':
        return Colors.blue;
      case 'snow':
      case 'extreme':
        return Colors.red;
      case 'clear':
      case 'sunny':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
