import 'package:flutter/material.dart';
import 'package:smart_travel_app/models/trips/trip_item.dart';

/// Item trong timeline view
class TripTimelineItem extends StatelessWidget {
  final TripItem item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TripTimelineItem({
    super.key,
    required this.item,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final destination = item.destination;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Icon(Icons.drag_handle, color: Colors.grey[400], size: 20),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.1),
              child: Icon(Icons.place, color: Colors.orange[700], size: 20),
            ),
          ],
        ),
        title: Text(
          destination?.name ?? 'Điểm đến',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.plannedTime != null)
              Text(
                '${item.plannedTime!.hour.toString().padLeft(2, '0')}:${item.plannedTime!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (item.durationHours != null)
              Text(
                'Thời gian: ${item.durationHours} giờ',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (item.notes != null && item.notes!.isNotEmpty)
              Text(
                item.notes!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
