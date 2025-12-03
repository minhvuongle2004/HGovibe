import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// Service để upload images lên Firebase Storage
class ImageUploadService {
  static final ImageUploadService instance = ImageUploadService._();
  ImageUploadService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;
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
      // Tạo path: destinations/{folder}/{fileName}
      final path = folder != null 
          ? 'destinations/$folder/$fileName'
          : 'destinations/$fileName';

      // Tạo reference
      final ref = _storage.ref().child(path);

      // Upload với metadata
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=31536000',
        ),
      );

      // Listen to progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // Wait for upload to complete
      await uploadTask;

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
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
      final fileName = '${baseFileName}_${i + 1}_${_uuid.v4()}.jpg';
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

  /// Delete image từ Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract path from URL
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('❌ Error deleting image: $e');
      // Không throw để không block nếu image không tồn tại
    }
  }

  /// Delete multiple images
  Future<void> deleteImages(List<String> imageUrls) async {
    await Future.wait(
      imageUrls.map((url) => deleteImage(url)),
      eagerError: false, // Continue even if some fail
    );
  }
}


