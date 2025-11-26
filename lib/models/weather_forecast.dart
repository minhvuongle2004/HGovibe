/// Model dự báo thời tiết
class WeatherForecast {
  final DateTime date; // Ngày dự báo
  final String location; // Vị trí
  final double temperatureMin; // Nhiệt độ thấp nhất
  final double temperatureMax; // Nhiệt độ cao nhất
  final String condition; // Điều kiện (sunny, rainy, cloudy...)
  final String description; // Mô tả
  final int humidity; // Độ ẩm (%)
  final double windSpeed; // Tốc độ gió (km/h)
  final String? recommendation; // Khuyến nghị
  final String iconCode; // Icon code từ API

  WeatherForecast({
    required this.date,
    required this.location,
    required this.temperatureMin,
    required this.temperatureMax,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    this.recommendation,
    required this.iconCode,
  });

  /// Convert từ Map (từ API response)
  factory WeatherForecast.fromMap(Map<String, dynamic> map) {
    return WeatherForecast(
      date: map['date'] is DateTime
          ? map['date'] as DateTime
          : DateTime.parse(map['date'] as String),
      location: map['location'] ?? '',
      temperatureMin: (map['temperatureMin'] ?? 0).toDouble(),
      temperatureMax: (map['temperatureMax'] ?? 0).toDouble(),
      condition: map['condition'] ?? 'unknown',
      description: map['description'] ?? '',
      humidity: map['humidity'] ?? 0,
      windSpeed: (map['windSpeed'] ?? 0).toDouble(),
      recommendation: map['recommendation'],
      iconCode: map['iconCode'] ?? '01d',
    );
  }

  /// Convert sang Map
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'location': location,
      'temperatureMin': temperatureMin,
      'temperatureMax': temperatureMax,
      'condition': condition,
      'description': description,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'recommendation': recommendation,
      'iconCode': iconCode,
    };
  }

  /// Lấy icon phù hợp với condition
  String get iconUrl {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  /// Kiểm tra thời tiết có tốt không
  bool get isGoodWeather {
    return condition == 'clear' || condition == 'sunny' || condition == 'partly_cloudy';
  }

  /// Kiểm tra có mưa không
  bool get isRainy {
    return condition.contains('rain') || condition.contains('drizzle');
  }
}

