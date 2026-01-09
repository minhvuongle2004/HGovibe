import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_travel_app/models/reviews/tour_review.dart';
import 'package:smart_travel_app/services/reviews/review_media_service.dart';
import 'package:smart_travel_app/services/reviews/tour_review_service.dart';

class ReviewFormScreen extends StatefulWidget {
  const ReviewFormScreen({
    super.key,
    required this.tourId,
    required this.bookingId,
    required this.userId,
    this.tourTitle,
    this.onSubmitted,
    this.existingReview,
  });

  final String tourId;
  final String bookingId;
  final String userId;
  final String? tourTitle;
  final VoidCallback? onSubmitted;
  final TourReview? existingReview;

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final _commentController = TextEditingController();
  double _rating = 5;
  bool _isSubmitting = false;
  final List<XFile> _images = [];
  List<String> _existingPhotos = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existingReview;
    if (existing != null) {
      _rating = existing.rating;
      if (existing.comment != null) {
        _commentController.text = existing.comment!;
      }
      _existingPhotos = List<String>.from(existing.photos);
    }
  }

  Future<void> _pickGallery() async {
    final picked = await ReviewMediaService.instance.pickImages(maxImages: 5);
    if (!mounted) return;
    setState(() {
      _images
        ..clear()
        ..addAll(picked.take(5));
    });
  }

  Future<void> _pickCamera() async {
    final picked = await ReviewMediaService.instance.pickCamera();
    if (picked == null) return;
    if (!mounted) return;
    setState(() {
      if (_images.length < 5) {
        _images.add(picked);
      }
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_rating <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn số sao')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Upload ảnh mới (nếu có)
      List<String> newPhotoUrls = [];
      if (_images.isNotEmpty) {
        newPhotoUrls = await ReviewMediaService.instance.uploadImages(_images);
      }

      // Gộp ảnh cũ + mới
      final allPhotos = [..._existingPhotos, ...newPhotoUrls];

      final review = TourReview(
        tourId: widget.tourId,
        bookingId: widget.bookingId,
        userId: widget.userId,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        photos: allPhotos,
      );

      // Nếu đang tạo mới: chặn trùng booking
      if (widget.existingReview == null) {
        final existed = await TourReviewService.instance
            .hasReviewForBooking(widget.bookingId);
        if (existed) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn đã gửi đánh giá cho booking này')),
          );
          setState(() => _isSubmitting = false);
          return;
        }
        await TourReviewService.instance.createReview(review);
      } else {
        // Update
        await TourReviewService.instance.updateReview(
          widget.existingReview!.id!,
          rating: review.rating,
          comment: review.comment,
          photos: review.photos,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.existingReview == null
                ? 'Đã gửi đánh giá'
                : 'Đã cập nhật đánh giá')),
      );
      widget.onSubmitted?.call();
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi đánh giá: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tourTitle != null
            ? 'Đánh giá ${widget.tourTitle}'
            : (widget.existingReview != null ? 'Chỉnh sửa đánh giá' : 'Viết đánh giá')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn số sao',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildStars(),
            const SizedBox(height: 16),
            const Text(
              'Nội dung',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Chia sẻ trải nghiệm của bạn...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _images.length >= 5 ? null : _pickGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Chọn ảnh'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _images.length >= 5 ? null : _pickCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Chụp ảnh'),
                ),
                const Spacer(),
                Text(
                  '${_images.length}/5 ảnh',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildExistingPhotos(),
            const SizedBox(height: 8),
            _buildPreviewGrid(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Gửi đánh giá',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStars() {
    return Row(
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final filled = _rating >= starIndex;
        return IconButton(
          icon: Icon(
            filled ? Icons.star : Icons.star_border,
            color: Colors.orange,
            size: 32,
          ),
          onPressed: () {
            setState(() {
              _rating = starIndex.toDouble();
            });
          },
        );
      }),
    );
  }

  Widget _buildPreviewGrid() {
    if (_images.isEmpty) {
      return const SizedBox.shrink();
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final file = _images[index];
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(file.path),
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _images.removeAt(index);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExistingPhotos() {
    if (_existingPhotos.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _existingPhotos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final url = _existingPhotos[index];
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _existingPhotos.removeAt(index);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

