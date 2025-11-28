import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smart_travel_app/models/destinations/destination.dart';

/// Card hiển thị đặc sản (đồ ăn/đồ uống)
class SpecialtyCard extends StatefulWidget {
  final Specialty specialty;
  final VoidCallback? onTap;

  const SpecialtyCard({super.key, required this.specialty, this.onTap});

  @override
  State<SpecialtyCard> createState() => _SpecialtyCardState();
}

class _SpecialtyCardState extends State<SpecialtyCard> {
  bool _isDescriptionExpanded = false;

  /// Map type sang label, icon và color
  Map<String, dynamic> _getTypeInfo(String type) {
    final typeLower = type.toLowerCase();

    switch (typeLower) {
      case 'food':
        return {
          'label': 'Đồ ăn',
          'icon': Icons.restaurant,
          'color': Colors.orange,
        };
      case 'drink':
        return {
          'label': 'Đồ uống',
          'icon': Icons.local_drink,
          'color': Colors.blue,
        };
      case 'souvenir':
        return {
          'label': 'Quà lưu niệm',
          'icon': Icons.card_giftcard,
          'color': Colors.purple,
        };
      case 'activity':
        return {
          'label': 'Hoạt động',
          'icon': Icons.local_activity,
          'color': Colors.green,
        };
      case 'attraction':
        return {
          'label': 'Điểm tham quan',
          'icon': Icons.place,
          'color': Colors.red,
        };
      case 'exhibition':
      case 'exhibit':
        return {
          'label': 'Triển lãm',
          'icon': Icons.museum,
          'color': Colors.teal,
        };
      case 'nature':
        return {
          'label': 'Thiên nhiên',
          'icon': Icons.nature,
          'color': Colors.green,
        };
      case 'offering':
        return {
          'label': 'Lễ vật',
          'icon': Icons.celebration,
          'color': Colors.amber,
        };
      case 'show':
        return {
          'label': 'Biểu diễn',
          'icon': Icons.theater_comedy,
          'color': Colors.pink,
        };
      case 'park':
        return {
          'label': 'Công viên',
          'icon': Icons.park,
          'color': Colors.green,
        };
      case 'shopping_mall':
        return {
          'label': 'Trung tâm mua sắm',
          'icon': Icons.store_mall_directory,
          'color': Colors.indigo,
        };
      default:
        return {
          'label': type, // Hiển thị type gốc nếu không biết
          'icon': Icons.category,
          'color': Colors.grey,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeInfo = _getTypeInfo(widget.specialty.type);
    final typeColor = typeInfo['color'] as Color;
    final typeIcon = typeInfo['icon'] as IconData;
    final typeLabel = typeInfo['label'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              // Ảnh hoặc placeholder icon
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    widget.specialty.image != null &&
                        widget.specialty.image!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.specialty.image!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: Icon(
                            typeIcon,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: Icon(
                          typeIcon,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Thông tin bên phải
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên và type badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.specialty.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: typeColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(typeIcon, size: 14, color: typeColor),
                              const SizedBox(width: 4),
                              Text(
                                typeLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: typeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Rating và Price
                    Row(
                      children: [
                        // Rating
                        if (widget.specialty.rating != null) ...[
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            widget.specialty.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        // Price
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.specialty.priceRange,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Location (nếu có)
                    if (widget.specialty.location != null &&
                        widget.specialty.location!.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.specialty.location!,
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
                      const SizedBox(height: 6),
                    ],
                    // Description
                    Text(
                      widget.specialty.description,
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
                    if (widget.specialty.description.length > 100)
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
