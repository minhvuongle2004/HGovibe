import 'package:flutter/material.dart';

/// Widget hiển thị các hành động nhanh (Đặt tour / Tạo kế hoạch)
class QuickActionsSection extends StatelessWidget {
  final VoidCallback onBookTour;
  final VoidCallback onCreatePlan;

  const QuickActionsSection({
    super.key,
    required this.onBookTour,
    required this.onCreatePlan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              context,
              icon: Icons.luggage,
              label: 'Đặt tour ngay',
              color: Colors.orange,
              onTap: onBookTour,
              isPrimary: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              context,
              icon: Icons.edit_calendar,
              label: 'Tạo kế hoạch mới',
              color: Colors.blue,
              onTap: onCreatePlan,
              isPrimary: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary ? color : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: isPrimary ? 2 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isPrimary
                ? null
                : Border.all(
                    color: color.withOpacity(0.3),
                    width: 1.5,
                  ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: isPrimary ? Colors.white : color,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

