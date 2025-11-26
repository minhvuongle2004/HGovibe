import 'package:flutter/material.dart';
import '../models/destination.dart';

/// Card hiển thị hoạt động
class ActivityCard extends StatefulWidget {
  final Activity activity;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.activity,
    this.onTap,
  });

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  bool _isDescriptionExpanded = false;

  /// Lấy icon phù hợp với tên hoạt động
  IconData _getActivityIcon(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('dạo') || nameLower.contains('đi bộ') || nameLower.contains('walk')) {
      return Icons.directions_walk;
    } else if (nameLower.contains('tham quan') || nameLower.contains('explore')) {
      return Icons.explore;
    } else if (nameLower.contains('chụp') || nameLower.contains('ảnh') || nameLower.contains('photo')) {
      return Icons.camera_alt;
    } else if (nameLower.contains('xem') || nameLower.contains('biểu diễn') || nameLower.contains('show')) {
      return Icons.theater_comedy;
    } else if (nameLower.contains('bơi') || nameLower.contains('swim')) {
      return Icons.pool;
    } else if (nameLower.contains('leo') || nameLower.contains('climb')) {
      return Icons.landscape;
    } else if (nameLower.contains('ăn') || nameLower.contains('food')) {
      return Icons.restaurant;
    } else if (nameLower.contains('mua') || nameLower.contains('shop')) {
      return Icons.shopping_bag;
    }
    return Icons.local_activity;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getActivityIcon(widget.activity.name);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.orange.withOpacity(0.1),
        highlightColor: Colors.orange.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Thông tin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên hoạt động
                    Text(
                      widget.activity.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Duration và Best time
                    Row(
                      children: [
                        // Duration badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer,
                                size: 14,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.activity.duration,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Best time
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  widget.activity.bestTime,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Description
                    Text(
                      widget.activity.description,
                      maxLines: _isDescriptionExpanded ? null : 2,
                      overflow: _isDescriptionExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    // Xem thêm/Thu gọn
                    if (widget.activity.description.length > 100)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _isDescriptionExpanded ? 'Thu gọn' : 'Xem thêm',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

