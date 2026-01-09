import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:smart_travel_app/config/reviews/review_config.dart';

class ReviewMediaService {
  ReviewMediaService._();
  static final ReviewMediaService instance = ReviewMediaService._();

  final ImagePicker _picker = ImagePicker();

  Future<List<XFile>> pickImages({int maxImages = 5}) async {
    final images = await _picker.pickMultiImage(
      imageQuality: 85,
    );
    if (images.length > maxImages) {
      return images.take(maxImages).toList();
    }
    return images;
  }

  Future<XFile?> pickCamera() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    return image;
  }

  Future<List<String>> uploadImages(List<XFile> files) async {
    if (files.isEmpty) return [];

    final uri = Uri.parse(ReviewConfig.uploadImageEndpoint);
    final request = http.MultipartRequest('POST', uri);

    for (final file in files) {
      final bytes = await file.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'files',
          bytes,
          filename: file.name,
          contentType: _contentTypeFromPath(file.path),
        ),
      );
    }

    final streamedResponse = await request.send();
    final httpResponse = await http.Response.fromStream(streamedResponse);
    final body = httpResponse.body;
    if (httpResponse.statusCode != 200) {
      throw Exception('Upload thất bại (${httpResponse.statusCode}): $body');
    }

    final urls = <String>[];
    final data = body;

    try {
      final Map<String, dynamic> parsed = jsonDecode(data) as Map<String, dynamic>;
      final files = parsed['files'] as List<dynamic>? ?? [];
      for (final f in files) {
        final url = (f as Map<String, dynamic>)['url'] as String?;
        if (url != null && url.isNotEmpty) {
          urls.add(url);
        }
      }
    } catch (_) {
      // fallback: simple regex if parsing fails
      final regex = RegExp(r'https?:\/\/[^\s"\\]+');
      for (final match in regex.allMatches(data)) {
        urls.add(match.group(0)!);
      }
    }
    return urls;
  }

  MediaType? _contentTypeFromPath(String path) {
    final ext = path.toLowerCase();
    if (ext.endsWith('.png')) return MediaType('image', 'png');
    if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (ext.endsWith('.gif')) return MediaType('image', 'gif');
    return MediaType('application', 'octet-stream');
  }
}

