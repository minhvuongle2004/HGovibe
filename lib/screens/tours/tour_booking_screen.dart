import 'package:flutter/material.dart';
import 'package:smart_travel_app/models/tours/tour_package.dart';

/// Screen đặt tour (tạm thời - sẽ implement đầy đủ trong Phase 3)
class TourBookingScreen extends StatelessWidget {
  final TourPackage tour;

  const TourBookingScreen({
    super.key,
    required this.tour,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt tour'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.luggage, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              tour.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tour Booking Screen',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming soon...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



