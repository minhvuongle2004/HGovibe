import 'package:flutter/material.dart';
import 'package:smart_travel_app/models/tours/tour_inclusions.dart';
import 'package:smart_travel_app/models/tours/tour_exclusions.dart';

/// Widget hiển thị những gì tour bao gồm và không bao gồm
class TourInclusionsWidget extends StatelessWidget {
  final TourInclusions inclusions;
  final TourExclusions exclusions;

  const TourInclusionsWidget({
    super.key,
    required this.inclusions,
    required this.exclusions,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inclusions
          _buildSection(
            context,
            title: 'Bao gồm',
            icon: Icons.check_circle,
            color: Colors.green,
            items: [
              if (inclusions.transportation.isNotEmpty)
                _buildCategory('Phương tiện', inclusions.transportation),
              if (inclusions.accommodation.isNotEmpty)
                _buildCategory('Chỗ ở', inclusions.accommodation),
              if (inclusions.meals.isNotEmpty)
                _buildCategory('Bữa ăn', inclusions.meals),
              if (inclusions.activities.isNotEmpty)
                _buildCategory('Hoạt động', inclusions.activities),
              if (inclusions.other.isNotEmpty)
                _buildCategory('Khác', inclusions.other),
            ],
          ),
          const SizedBox(height: 24),
          // Exclusions
          _buildSection(
            context,
            title: 'Không bao gồm',
            icon: Icons.cancel,
            color: Colors.red,
            items: [
              if (exclusions.meals.isNotEmpty)
                _buildCategory('Bữa ăn', exclusions.meals),
              if (exclusions.activities.isNotEmpty)
                _buildCategory('Hoạt động', exclusions.activities),
              if (exclusions.other.isNotEmpty)
                _buildCategory('Khác', exclusions.other),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> items,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get darker shade of color
    final colorValue = color.value;
    final darkerColor = Color.fromRGBO(
      ((colorValue >> 16 & 0xFF) * 0.7).toInt(),
      ((colorValue >> 8 & 0xFF) * 0.7).toInt(),
      ((colorValue & 0xFF) * 0.7).toInt(),
      1.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkerColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildCategory(String category, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_right, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

