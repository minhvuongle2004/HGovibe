import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel_app/models/tours/tour_booking.dart';
import 'package:smart_travel_app/models/tours/tour_package.dart';
import 'package:smart_travel_app/services/payments/payment_service.dart';
import 'package:smart_travel_app/services/tours/tour_booking_service.dart';
import 'package:smart_travel_app/screens/bookings/my_bookings_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.bookingNumber,
    required this.amount,
    required this.currency,
    this.tour,
    this.autoLaunchPayment = false,
  });

  final String bookingId;
  final String bookingNumber;
  final double amount;
  final String currency;
  final TourPackage? tour;
  final bool autoLaunchPayment;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  final PaymentService _paymentService = PaymentService.instance;
  final TourBookingService _bookingService = TourBookingService.instance;
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  TourBooking? _booking;
  bool _isLoadingBooking = true;
  bool _isCreatingPayment = false;
  String? _errorMessage;
  bool _autoLaunchTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBooking();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Khi người dùng quay lại app từ trình duyệt, tự động reload booking
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !_isLoadingBooking) {
      _loadBooking();
    }
  }

  Future<void> _loadBooking() async {
    setState(() {
      _isLoadingBooking = true;
      _errorMessage = null;
    });
    try {
      final previousStatus = _booking?.paymentStatus;
      final booking = await _bookingService.getBookingById(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _isLoadingBooking = false;
      });

      // Nếu trạng thái thanh toán vừa chuyển sang "paid", hiển thị thông báo
      if (booking != null &&
          previousStatus != PaymentStatus.paid &&
          booking.paymentStatus == PaymentStatus.paid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanh toán VNPay thành công!'),
          ),
        );
      }

      if (booking != null &&
          widget.autoLaunchPayment &&
          !_autoLaunchTriggered &&
          _canStartPayment(booking)) {
        _autoLaunchTriggered = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startPayment();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoadingBooking = false;
      });
    }
  }


  bool _canStartPayment(TourBooking booking) {
    if (booking.status == BookingStatus.cancelled) return false;
    return booking.paymentStatus == PaymentStatus.unpaid ||
        booking.paymentStatus == PaymentStatus.failed;
  }

  Future<void> _startPayment() async {
    final booking = _booking;
    if (booking == null) return;
    if (_isCreatingPayment) return;
    if (!_canStartPayment(booking)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking này không thể thanh toán online.')),
      );
      return;
    }

    setState(() {
      _isCreatingPayment = true;
      _errorMessage = null;
    });

    try {
      final request = await _paymentService.createVnPayPayment(booking: booking);
      await _paymentService.redirectToGateway(request);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tạo thanh toán: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingPayment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán VNPay'),
        actions: [
          IconButton(
            onPressed: _isLoadingBooking ? null : _loadBooking,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại trạng thái',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingBooking) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_booking == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Không tìm thấy thông tin booking.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadBooking,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final booking = _booking!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.tour?.title ?? 'Mã booking: ${booking.bookingNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.tour != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.tour!.destination,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _infoRow('Mã booking', booking.bookingNumber),
                  _infoRow('Trạng thái booking', _bookingStatusLabel(booking.status)),
                  _infoRow('Trạng thái thanh toán', _paymentStatusLabel(booking.paymentStatus)),
                  if (booking.paymentRequestId != null)
                    _infoRow('Request ID', booking.paymentRequestId!),
                  if (booking.paymentTransactionId != null)
                    _infoRow('Mã giao dịch', booking.paymentTransactionId!),
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
                children: [
                  const Text(
                    'Số tiền cần thanh toán',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatAmount(widget.amount, widget.currency),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lưu ý:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• VNPay sẽ mở trong trình duyệt. Sau khi thanh toán xong, bạn có thể quay lại app.\n'
                    '• Trạng thái cuối cùng sẽ được xác nhận thông qua webhook, vui lòng kiểm tra lại trang "Đặt tour của tôi".',
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final booking = _booking;
    final canPay = booking != null && _canStartPayment(booking);
    final isPaid = booking?.paymentStatus == PaymentStatus.paid;

    if (isPaid) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                  (route) => route.isFirst,
                );
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text(
                'Xem tour của tôi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canPay && !_isCreatingPayment ? _startPayment : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.pink,
                ),
                child: _isCreatingPayment
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Thanh toán qua VNPay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
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

  String _paymentStatusLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.unpaid:
        return 'Chưa thanh toán';
      case PaymentStatus.pending:
        return 'Đang xử lý';
      case PaymentStatus.paid:
        return 'Đã thanh toán';
      case PaymentStatus.refunded:
        return 'Đã hoàn tiền';
      case PaymentStatus.failed:
        return 'Thất bại';
    }
  }

  String _bookingStatusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Chờ xác nhận';
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.cancelled:
        return 'Đã hủy';
      case BookingStatus.completed:
        return 'Hoàn thành';
    }
  }

  String _formatAmount(double amount, String currency) {
    if (currency.toUpperCase() == 'VND' || currency == '₫') {
      return _currencyFormat.format(amount);
    }
    final formatter = NumberFormat('#,###.##');
    return '${formatter.format(amount)} $currency';
  }
}

