import 'package:flutter/material.dart';

import '../widgets/main_bottom_nav.dart';

class SaleScreen extends StatelessWidget {
  const SaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SALE'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Ưu đãi du lịch\nTính năng đang được phát triển...',
          textAlign: TextAlign.center,
        ),
      ),
      bottomNavigationBar: buildMainBottomNavigationBar(context, 2),
    );
  }
}


