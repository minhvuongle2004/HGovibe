import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Sidebar navigation cho admin panel
class AdminSidebar extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;

  const AdminSidebar({
    super.key,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Lấy current route từ GoRouter
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final width = expanded ? 250.0 : 70.0;

    return Container(
      width: width,
      color: Colors.grey[900],
      child: Column(
        children: [
          // Logo/Title
          Container(
            height: 64,
            padding: const EdgeInsets.all(16),
            child: expanded
                ? Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: Colors.orange[700],
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.orange[700],
                      size: 32,
                    ),
                  ),
          ),
          const Divider(color: Colors.grey, height: 1),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  context,
                  currentRoute: currentRoute,
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  route: '/dashboard',
                ),
                _buildNavItem(
                  context,
                  currentRoute: currentRoute,
                  icon: Icons.people,
                  label: 'Người dùng',
                  route: '/users',
                ),
                _buildNavItem(
                  context,
                  currentRoute: currentRoute,
                  icon: Icons.location_on,
                  label: 'Điểm đến',
                  route: '/destinations',
                ),
                _buildNavItem(
                  context,
                  currentRoute: currentRoute,
                  icon: Icons.luggage,
                  label: 'Tours',
                  route: '/tours',
                ),
                _buildNavItem(
                  context,
                  currentRoute: currentRoute,
                  icon: Icons.book_online,
                  label: 'Bookings',
                  route: '/bookings',
                ),
              ],
            ),
          ),
          // Toggle button
          Container(
            padding: const EdgeInsets.all(8),
            child: IconButton(
              icon: Icon(
                expanded ? Icons.chevron_left : Icons.chevron_right,
                color: Colors.white,
              ),
              onPressed: onToggle,
              tooltip: expanded ? 'Thu gọn' : 'Mở rộng',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String currentRoute,
    required IconData icon,
    required String label,
    required String route,
  }) {
    final isActive = currentRoute == route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: isActive ? Colors.orange[700] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            context.go(route);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
                if (expanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

