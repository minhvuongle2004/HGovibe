import 'package:flutter/material.dart';
import '../models/ai_activity_suggestion.dart';

class AISuggestionCard extends StatelessWidget {
  final AIActivitySuggestion suggestion;
  final VoidCallback? onViewMap;
  final VoidCallback? onNavigate;
  final VoidCallback? onAddToTrip;
  final VoidCallback? onSaveFavorite;

  const AISuggestionCard({
    super.key,
    required this.suggestion,
    this.onViewMap,
    this.onNavigate,
    this.onAddToTrip,
    this.onSaveFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    suggestion.activityName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (suggestion.isAdded)
                  _buildChip(
                    'Đã trong lịch trình',
                    Icons.check_circle,
                    Colors.green.withOpacity(0.1),
                    Colors.green,
                  )
                else if (suggestion.mealType != null)
                  _buildChip(
                    suggestion.mealType!,
                    Icons.schedule,
                    theme.colorScheme.primary.withOpacity(0.1),
                    theme.colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.reason,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (suggestion.category != null)
                  _buildChip(
                    suggestion.category!,
                    Icons.restaurant,
                    Colors.orange.withOpacity(0.12),
                    Colors.orange[800]!,
                  ),
                if (suggestion.estimatedCost != null)
                  _buildChip(
                    '${suggestion.estimatedCost!.toStringAsFixed(0)} đ',
                    Icons.payments,
                    Colors.green.withOpacity(0.12),
                    Colors.green[700]!,
                  ),
                if (suggestion.estimatedDuration != null)
                  _buildChip(
                    '${suggestion.estimatedDuration} phút',
                    Icons.timelapse,
                    Colors.blueGrey.withOpacity(0.12),
                    Colors.blueGrey[700]!,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewMap,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Xem bản đồ'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.navigation_outlined),
                    label: const Text('Dẫn đường'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: suggestion.isAdded ? null : onAddToTrip,
                    icon: Icon(
                      suggestion.isAdded ? Icons.check_circle : Icons.add,
                    ),
                    label: Text(
                      suggestion.isAdded ? 'Đã thêm' : 'Thêm vào lịch trình',
                    ),
                    style: suggestion.isAdded
                        ? ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.withOpacity(0.1),
                            foregroundColor: Colors.green,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onSaveFavorite,
                  tooltip: 'Lưu yêu thích',
                  icon: const Icon(Icons.favorite_border),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    String label,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: iconColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}




