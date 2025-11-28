import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget hiển thị carousel ảnh với page indicator
class ImageCarouselWidget extends StatefulWidget {
  final List<String> images;
  final double height;
  final String? thumbnail; // Fallback nếu images rỗng

  const ImageCarouselWidget({
    super.key,
    required this.images,
    this.height = 300,
    this.thumbnail,
  });

  @override
  State<ImageCarouselWidget> createState() => _ImageCarouselWidgetState();
}

class _ImageCarouselWidgetState extends State<ImageCarouselWidget> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _displayImages {
    if (widget.images.isNotEmpty) {
      return widget.images;
    }
    if (widget.thumbnail != null) {
      return [widget.thumbnail!];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final images = _displayImages;

    if (images.isEmpty) {
      return Container(
        height: widget.height,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image, size: 64, color: Colors.grey),
        ),
      );
    }

    return Stack(
      children: [
        // PageView với images
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: images.length,
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        ),
        // Page indicator (dots)
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => _buildDot(index == _currentPage),
              ),
            ),
          ),
        // Nút "Thư viện ảnh" ở góc dưới phải
        if (images.length > 1)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.photo_library, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Thư viện ảnh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 8 : 6,
      height: isActive ? 8 : 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.white : Colors.white70,
      ),
    );
  }
}
