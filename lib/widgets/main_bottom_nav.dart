import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';

/// Bottom navigation bar dùng chung cho toàn app
/// [currentIndex] là tab đang được chọn (0-4)
Widget buildMainBottomNavigationBar(
  BuildContext context,
  int currentIndex,
) {
  final favoritesProvider = context.watch<FavoritesProvider>();
  final favoritesCount = favoritesProvider.favoritesCount;
  void handleTap(int index) {
    if (index == currentIndex) return;

    String routeName;
    switch (index) {
      case 0:
        routeName = '/home';
        break;
      case 1:
        routeName = '/favorites';
        break;
      case 2:
        routeName = '/map';
        break;
      case 3:
        routeName = '/trips';
        break;
      case 4:
      default:
        routeName = '/account';
        break;
    }

    Navigator.pushReplacementNamed(context, routeName);
  }

  return BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    currentIndex: currentIndex,
    selectedItemColor: Colors.orange,
    unselectedItemColor: Colors.grey,
    items: [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Trang chủ',
      ),
      BottomNavigationBarItem(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.favorite_border),
            if (favoritesCount > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    favoritesCount > 99 ? '99+' : favoritesCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        label: 'Yêu thích',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.map_outlined),
        label: 'Bản đồ',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.luggage),
        label: 'Chuyến đi',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: 'Tài khoản',
      ),
    ],
    onTap: handleTap,
  );
}


