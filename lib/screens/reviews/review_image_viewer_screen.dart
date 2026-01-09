import 'package:flutter/material.dart';

class ReviewImageViewerScreen extends StatefulWidget {
  const ReviewImageViewerScreen({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  final List<String> photos;
  final int initialIndex;

  @override
  State<ReviewImageViewerScreen> createState() => _ReviewImageViewerScreenState();
}

class _ReviewImageViewerScreenState extends State<ReviewImageViewerScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1}/${widget.photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemCount: widget.photos.length,
        itemBuilder: (context, index) {
          final url = widget.photos[index];
          return Center(
            child: InteractiveViewer(
              maxScale: 4,
              minScale: 0.8,
              child: Hero(
                tag: 'review_photo_${url}_$index',
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}




