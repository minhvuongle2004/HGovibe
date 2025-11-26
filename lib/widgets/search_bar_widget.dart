import 'package:flutter/material.dart';

/// Widget search bar với style giống thiết kế mẫu
class SearchBarWidget extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onShoppingCartTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onTap;
  final bool enabled;

  const SearchBarWidget({
    super.key,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onShoppingCartTap,
    this.onNotificationTap,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onTap: onTap,
                enabled: enabled,
                decoration: InputDecoration(
                  hintText: hintText ?? 'Tìm kiếm điểm đến...',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Shopping cart icon
          IconButton(
            onPressed: onShoppingCartTap,
            icon: Icon(
              Icons.shopping_cart_outlined,
              color: Colors.grey[700],
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          // Notification bell icon
          IconButton(
            onPressed: onNotificationTap,
            icon: Icon(
              Icons.notifications_outlined,
              color: Colors.grey[700],
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

