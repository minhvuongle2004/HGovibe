import 'package:flutter/material.dart';
import 'package:smart_travel_app/models/reviews/tour_review.dart';
import 'package:smart_travel_app/screens/reviews/review_image_viewer_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_travel_app/screens/reviews/review_form_screen.dart';
import 'package:smart_travel_app/services/reviews/tour_review_service.dart';

class ReviewListSection extends StatelessWidget {
  const ReviewListSection({
    super.key,
    required this.reviews,
    this.onWriteReview,
    this.onReload,
    this.tourId,
  });

  final List<TourReview> reviews;
  final VoidCallback? onWriteReview;
  final VoidCallback? onReload;
  final String? tourId;

  double get _avgRating {
    if (reviews.isEmpty) return 0;
    final sum = reviews.fold<double>(0, (p, e) => p + e.rating);
    return sum / reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Đánh giá (${reviews.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            if (reviews.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 18),
                  Text(
                    _avgRating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              )
            else
              const Text(
                'Chưa có đánh giá',
                style: TextStyle(color: Colors.grey),
              ),
            const Spacer(),
            if (onWriteReview != null)
              TextButton.icon(
                onPressed: onWriteReview,
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Viết đánh giá'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (reviews.isEmpty)
          const Text(
            'Hãy là người đầu tiên đánh giá tour này!',
            style: TextStyle(color: Colors.grey),
          )
        else
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _ReviewItem(
                review: review,
                tourId: tourId,
                onWriteReview: onWriteReview,
                onReload: onReload,
              );
            },
          ),
      ],
    );
  }
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({
    required this.review,
    this.tourId,
    this.onWriteReview,
    this.onReload,
  });

  final TourReview review;
  final String? tourId;
  final VoidCallback? onWriteReview;
  final VoidCallback? onReload;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Row(
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return Icon(
                      star <= review.rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 18,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                if (review.createdAt != null)
                  Text(
                    _formatDate(review.createdAt!),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment!),
            ],
            if (review.photos.isNotEmpty) ...[
              const SizedBox(height: 8),
              _PhotoGrid(
                photos: review.photos,
              ),
            ],
            // Action row
            _ReviewActions(
              review: review,
              tourId: tourId,
              onUpdated: onReload ?? onWriteReview,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _ReviewActions extends StatelessWidget {
  const _ReviewActions({
    required this.review,
    this.tourId,
    this.onUpdated,
  });

  final TourReview review;
  final String? tourId;
  final VoidCallback? onUpdated;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser != null && currentUser.uid == review.userId;

    if (!isOwner) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: () => _edit(context),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Sửa'),
        ),
        TextButton.icon(
          onPressed: () => _delete(context),
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          label: const Text('Xóa'),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
        ),
      ],
    );
  }

  void _edit(BuildContext context) {
    if (tourId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewFormScreen(
          tourId: tourId!,
          bookingId: review.bookingId,
          userId: review.userId,
          tourTitle: null,
          existingReview: review,
          onSubmitted: onUpdated,
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa đánh giá?'),
        content: const Text('Bạn có chắc muốn xóa đánh giá này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await TourReviewService.instance.deleteReview(review.id!);
      onUpdated?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa đánh giá')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa đánh giá: $e')),
        );
      }
    }
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.photos,
  });

  final List<String> photos;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final url = photos[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReviewImageViewerScreen(
                  photos: photos,
                  initialIndex: index,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Hero(
              tag: 'review_photo_${url}_$index',
              child: Image.network(
                url,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}

