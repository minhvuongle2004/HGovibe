import 'package:flutter/material.dart';

/// Widget nút trái tim có animation khi toggle
class AnimatedFavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback? onTap;
  final bool isLoading;
  final double size;

  const AnimatedFavoriteButton({
    super.key,
    required this.isFavorite,
    this.onTap,
    this.isLoading = false,
    this.size = 18,
  });

  @override
  State<AnimatedFavoriteButton> createState() => _AnimatedFavoriteButtonState();
}

class _AnimatedFavoriteButtonState extends State<AnimatedFavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void didUpdateWidget(AnimatedFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Khi trạng thái favorite thay đổi, chạy animation
    if (oldWidget.isFavorite != widget.isFavorite && !widget.isLoading) {
      _controller.forward().then((_) {
        _controller.reverse();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tooltip = widget.isFavorite ? 'Bỏ yêu thích' : 'Thêm vào yêu thích';
    
    return Semantics(
      label: tooltip,
      button: true,
      enabled: !widget.isLoading && widget.onTap != null,
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Tooltip(
          message: tooltip,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: widget.isLoading
                      ? SizedBox(
                          width: widget.size,
                          height: widget.size,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                          ),
                        )
                      : Icon(
                          widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: widget.size,
                          color: widget.isFavorite ? Colors.orange : Colors.grey[600],
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

