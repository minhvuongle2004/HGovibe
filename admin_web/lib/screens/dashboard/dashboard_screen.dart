import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/dashboard_stats_service.dart';
import '../../widgets/stats_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final statsService = DashboardStatsService.instance;

    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Text(
              'Chào mừng, ${user?.email ?? 'Admin'}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đây là trang quản trị của Smart Travel App',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            // Stats cards
            _buildStatsSection(context, statsService),
            const SizedBox(height: 32),
            // Quick actions
            _buildQuickActionsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, DashboardStatsService statsService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thống kê',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            // Total Users
            StreamBuilder<int>(
              stream: statsService.watchTotalUsers(),
              builder: (context, snapshot) {
                final value = snapshot.data ?? 0;
                return StatsCard(
                  title: 'Tổng người dùng',
                  value: value,
                  icon: Icons.people,
                  color: Colors.blue,
                  onTap: () => context.go('/users'),
                );
              },
            ),
            // Total Tours
            StreamBuilder<int>(
              stream: statsService.watchTotalTours(),
              builder: (context, snapshot) {
                final value = snapshot.data ?? 0;
                return StatsCard(
                  title: 'Tổng tours',
                  value: value,
                  icon: Icons.luggage,
                  color: Colors.orange,
                  onTap: () => context.go('/tours'),
                );
              },
            ),
            // Total Bookings
            StreamBuilder<int>(
              stream: statsService.watchTotalBookings(),
              builder: (context, snapshot) {
                final value = snapshot.data ?? 0;
                return StatsCard(
                  title: 'Tổng bookings',
                  value: value,
                  icon: Icons.book_online,
                  color: Colors.green,
                  onTap: () => context.go('/bookings'),
                );
              },
            ),
            // Pending Bookings
            StreamBuilder<int>(
              stream: statsService.watchPendingBookings(),
              builder: (context, snapshot) {
                final value = snapshot.data ?? 0;
                return StatsCard(
                  title: 'Bookings chờ xác nhận',
                  value: value,
                  icon: Icons.pending_actions,
                  color: Colors.amber,
                  onTap: () => context.go('/bookings?tab=pending'),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hành động nhanh',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                title: 'Xem bookings mới',
                icon: Icons.book_online,
                color: Colors.amber,
                onTap: () => context.go('/bookings?tab=pending'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                context,
                title: 'Tạo tour mới',
                icon: Icons.add_circle_outline,
                color: Colors.orange,
                onTap: () => context.go('/tours/new'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                context,
                title: 'Thêm điểm đến',
                icon: Icons.add_location,
                color: Colors.blue,
                onTap: () => context.go('/destinations/new'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

