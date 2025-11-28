import 'package:flutter/material.dart';
import 'package:smart_travel_app/models/destinations/destination.dart';
import 'activity_card.dart';

/// Section hiển thị danh sách hoạt động
class ActivitiesSection extends StatelessWidget {
  final List<Activity> activities;
  final Function(Activity)? onActivityTap;

  const ActivitiesSection({
    super.key,
    required this.activities,
    this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.local_activity, size: 20, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text(
              'Hoạt động & Trải nghiệm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // List of activities
        ...activities.asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value;
          return AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(milliseconds: 300 + (index * 50)),
            child: ActivityCard(
              activity: activity,
              onTap: onActivityTap != null
                  ? () => onActivityTap!(activity)
                  : null,
            ),
          );
        }).toList(),
      ],
    );
  }
}
