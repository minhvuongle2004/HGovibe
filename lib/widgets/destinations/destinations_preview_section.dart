import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smart_travel_app/models/destinations/destination.dart';

/// Widget hiển thị preview destinations (thu gọn)
class DestinationsPreviewSection extends StatefulWidget {
  final List<Destination> destinations;
  final Function(Destination) onDestinationTap;
  final VoidCallback? onViewAll;

  const DestinationsPreviewSection({
    super.key,
    required this.destinations,
    required this.onDestinationTap,
    this.onViewAll,
  });

  @override
  State<DestinationsPreviewSection> createState() =>
      _DestinationsPreviewSectionState();
}

class _DestinationsPreviewSectionState
    extends State<DestinationsPreviewSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.destinations.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayDestinations = _isExpanded
        ? widget.destinations
        : widget.destinations.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.explore, size: 20, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Khám phá địa điểm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (widget.destinations.length > 6)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Text(
                    _isExpanded ? 'Thu gọn' : 'Xem thêm',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: displayDestinations.length,
            itemBuilder: (context, index) {
              final destination = displayDestinations[index];
              return _buildDestinationCard(destination);
            },
          ),
        ),
        if (widget.onViewAll != null && !_isExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: TextButton(
                onPressed: widget.onViewAll,
                child: const Text(
                  'Xem tất cả địa điểm →',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDestinationCard(Destination destination) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => widget.onDestinationTap(destination),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image
            CachedNetworkImage(
              imageUrl: destination.thumbnail,
              width: double.infinity,
              height: 90,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: double.infinity,
                height: 90,
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: double.infinity,
                height: 90,
                color: Colors.grey[300],
                child: const Icon(
                  Icons.image_not_supported,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        destination.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 10,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          destination.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

