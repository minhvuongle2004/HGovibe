import 'package:flutter/material.dart';

/// Banner gợi ý "Thêm ý tưởng khám phá"
class RecommendationBannerWidget extends StatelessWidget {
  final String city;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const RecommendationBannerWidget({
    super.key,
    required this.city,
    this.onDismiss,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          // Icon khinh khí cầu
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.air, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Thêm ý tưởng khám phá $city',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.orange),
                ],
              ),
            ),
          ),
          // Nút X để dismiss
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
