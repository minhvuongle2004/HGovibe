import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel_app/models/payments/payment_return_data.dart';
import 'package:smart_travel_app/models/tours/tour_package.dart';

class PaymentResultScreen extends StatelessWidget {
  const PaymentResultScreen({
    super.key,
    required this.bookingId,
    required this.bookingNumber,
    required this.amount,
    required this.currency,
    required this.returnData,
    this.tour,
  });

  final String bookingId;
  final String bookingNumber;
  final double amount;
  final String currency;
  final PaymentReturnData returnData;
  final TourPackage? tour;

  @override
  Widget build(BuildContext context) {
    final success = returnData.isSuccess;
    final color = success ? Colors.green : Colors.red;
    final icon = success ? Icons.check_circle : Icons.error;
    final title = success ? 'Thanh toán đang được xử lý' : 'Thanh toán chưa thành công';
    final NumberFormat currencyFormat =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Kết quả thanh toán'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Icon(icon, size: 80, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                returnData.message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin booking',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      _infoRow('Mã booking', bookingNumber),
                      if (tour != null) ...[
                        _infoRow('Tour', tour!.title),
                        _infoRow('Điểm đến', tour!.destination),
                      ],
                      _infoRow('Số tiền', currencyFormat.format(amount)),
                      _infoRow('Mã giao dịch', returnData.gatewayTransactionId ?? 'Đang cập nhật'),
                      _infoRow('Result code', (returnData.resultCode ?? '-').toString()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Bước tiếp theo',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      Text('• Đợi thông báo xác nhận từ hệ thống trong vài phút.'),
                      SizedBox(height: 4),
                      Text('• Bạn có thể mở mục "Đặt tour của tôi" để kiểm tra trạng thái.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/account',
                      (route) => route.isFirst,
                    );
                  },
                  child: const Text('Xem đặt tour của tôi'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/home',
                      (route) => route.isFirst,
                    );
                  },
                  child: const Text('Về trang chủ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

