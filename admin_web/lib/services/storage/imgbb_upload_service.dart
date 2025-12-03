import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// Service để upload images lên ImgBB (miễn phí, không cần đăng ký phức tạp)
/// 
/// Setup:
/// 1. Lấy API key từ https://api.imgbb.com/
/// 2. Thêm vào .env hoặc config
class ImgBBUploadService {
  static final ImgBBUploadService instance = ImgBBUploadService._();
  ImgBBUploadService._();

  // ImgBB API endpoint
  static const String _apiUrl = 'https://api.imgbb.com/1/upload';
  
  // API key - có thể dùng public key hoặc lấy từ https://api.imgbb.com/
  // Lưu ý: Nên lưu trong .env hoặc config file, không hardcode
  // Tạm thời dùng public key (có thể bị rate limit)
  // Để lấy API key: https://api.imgbb.com/ → Register → Get API key
  String _apiKey = 'a280cd0f548abc2ab941f2793d4d6d13'; // TODO: Thay bằng API key thật
  
  /// Set API key (nên gọi từ config hoặc .env)
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  final _uuid = const Uuid();

  /// Upload image từ bytes
  /// Returns: Download URL của image
  Future<String> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
    String? folder,
    Function(double)? onProgress,
  }) async {
    try {
      // Tạo unique file name
      final uniqueFileName = '${_uuid.v4()}_$fileName';

      // Tạo multipart request
      final request = http.MultipartRequest('POST', Uri.parse('$_apiUrl?key=$_apiKey'));
      
      // Convert bytes to base64
      final base64Image = base64Encode(imageBytes);
      
      // Add image data
      request.fields['image'] = base64Image;
      request.fields['name'] = uniqueFileName;

      // Simulate progress (ImgBB API không hỗ trợ progress callback)
      if (onProgress != null) {
        onProgress(0.5); // Simulate 50%
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          final imageUrl = jsonResponse['data']['url'] as String;
          
          if (onProgress != null) {
            onProgress(1.0); // Complete
          }
          
          return imageUrl;
        } else {
          throw Exception('Upload failed: ${jsonResponse['error']?['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error uploading image to ImgBB: $e');
      rethrow;
    }
  }

  /// Upload multiple images
  /// Returns: List of download URLs
  Future<List<String>> uploadImages({
    required List<Uint8List> imageBytesList,
    required String baseFileName,
    String? folder,
    Function(int index, double progress)? onProgress,
  }) async {
    final urls = <String>[];
    
    for (int i = 0; i < imageBytesList.length; i++) {
      final fileName = '${baseFileName}_${i + 1}.jpg';
      final url = await uploadImage(
        imageBytes: imageBytesList[i],
        fileName: fileName,
        folder: folder,
        onProgress: onProgress != null 
            ? (progress) => onProgress(i, progress)
            : null,
      );
      urls.add(url);
    }
    
    return urls;
  }

  /// Delete image từ ImgBB
  /// Lưu ý: ImgBB không hỗ trợ delete qua API công khai
  /// Cần đăng nhập vào ImgBB để delete thủ công
  /// Hoặc có thể bỏ qua nếu không quan trọng
  Future<void> deleteImage(String imageUrl) async {
    try {
      // ImgBB không có public API để delete
      // Có thể bỏ qua hoặc log để admin delete thủ công
      print('⚠️ ImgBB không hỗ trợ delete qua API. URL: $imageUrl');
      print('💡 Có thể delete thủ công tại: https://imgbb.com/');
    } catch (e) {
      print('❌ Error deleting image: $e');
    }
  }

  /// Delete multiple images
  Future<void> deleteImages(List<String> imageUrls) async {
    await Future.wait(
      imageUrls.map((url) => deleteImage(url)),
      eagerError: false,
    );
  }

}

