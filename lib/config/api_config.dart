/// Configuration cho API keys
/// 
/// LƯU Ý: Trong production, nên lưu API keys trong environment variables
/// hoặc sử dụng Firebase Functions để proxy API calls
class ApiConfig {
  // OpenWeatherMap API Key
  static const String weatherApiKey = '9f9512aa836b9eadc3cc60bd59da8e27';
  static const String weatherBaseUrl = 'https://api.openweathermap.org/data/2.5';
  
  // Google Gemini API Key
  static const String geminiApiKey = 'AIzaSyDw7DJhigvDTrxR4nJuDp5i1hf8cZXLlEQ';
  // Thử với v1 thay vì v1beta
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1';
  
  // MapBox API
  static const String mapboxApiKey = 'pk.eyJ1IjoidnVvbmdkaDEyYzEiLCJhIjoiY21pOXM2cDV3MHB4NTJpcGo2cTNxNjBxZSJ9.erxF_ABIH1oJYeyAABK-Kg';
  static const String mapboxBaseUrl = 'https://api.mapbox.com';
  
  // OpenAI API (nếu cần dùng thay vì Gemini)
  // static const String openAiApiKey = 'your_key_here';
  // static const String openAiBaseUrl = 'https://api.openai.com/v1';
}

