import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel_app/models/tours/tour_package.dart';
import 'package:smart_travel_app/models/tours/tour_booking.dart';
import 'package:smart_travel_app/models/tours/participant_info.dart';
import 'package:smart_travel_app/models/tours/contact_info.dart';
import 'package:smart_travel_app/providers/tours/tour_booking_provider.dart';
import 'package:smart_travel_app/services/tours/tour_booking_service.dart';
import 'package:smart_travel_app/screens/tours/tour_booking_success_screen.dart';

/// Screen xác nhận & thanh toán booking
class TourBookingConfirmScreen extends StatefulWidget {
  final TourPackage tour;
  final DateTime departureDate;
  final int numberOfAdults;
  final int numberOfChildren;
  final int numberOfInfants;
  final List<ParticipantInfo> participants;
  final ContactInfo contactInfo;
  final String? specialRequests;
  final double subtotal;
  final double totalAmount;

  const TourBookingConfirmScreen({
    super.key,
    required this.tour,
    required this.departureDate,
    required this.numberOfAdults,
    required this.numberOfChildren,
    required this.numberOfInfants,
    required this.participants,
    required this.contactInfo,
    this.specialRequests,
    required this.subtotal,
    required this.totalAmount,
  });

  @override
  State<TourBookingConfirmScreen> createState() => _TourBookingConfirmScreenState();
}

class _TourBookingConfirmScreenState extends State<TourBookingConfirmScreen> {
  final _bookingService = TourBookingService.instance;
  PaymentMethod? _selectedPaymentMethod;
  bool _isCreatingBooking = false;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    // Mặc định: không thanh toán online
    _selectedPaymentMethod = null;
  }

  /// Tạo booking
  Future<void> _createBooking() async {
    if (_isCreatingBooking) return;

    setState(() {
      _isCreatingBooking = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để đặt tour')),
        );
        Navigator.pop(context);
        return;
      }

      // Generate booking number
      final bookingNumber = await _bookingService.generateBookingNumber();

      // Tạo booking
      final booking = TourBooking(
        userId: user.uid,
        tourPackageId: widget.tour.id!,
        bookingNumber: bookingNumber,
        bookingDate: DateTime.now(),
        departureDate: widget.departureDate,
        numberOfAdults: widget.numberOfAdults,
        numberOfChildren: widget.numberOfChildren,
        numberOfInfants: widget.numberOfInfants,
        participants: widget.participants,
        contactInfo: widget.contactInfo,
        subtotal: widget.subtotal,
        totalAmount: widget.totalAmount,
        currency: widget.tour.currency,
        paymentStatus: PaymentStatus.unpaid,
        paymentMethod: _selectedPaymentMethod,
        status: BookingStatus.pending,
        specialRequests: widget.specialRequests,
      );

      // Lưu vào Firestore
      final bookingProvider = context.read<TourBookingProvider>();
      final bookingId = await bookingProvider.createBooking(booking);

      if (bookingId != null) {
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => TourBookingSuccessScreen(
              bookingNumber: bookingNumber,
              tour: widget.tour,
            ),
          ),
          (route) => route.isFirst,
        );
      } else {
        throw Exception('Không thể tạo booking');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingBooking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận đặt tour'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tóm tắt booking
            _buildSectionTitle('Tóm tắt đặt tour'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tour.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.tour.destination,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Ngày khởi hành', _dateFormat.format(widget.departureDate)),
                    _buildInfoRow(
                      'Số người',
                      '${widget.numberOfAdults + widget.numberOfChildren + widget.numberOfInfants} người',
                    ),
                    if (widget.numberOfAdults > 0)
                      _buildInfoRow('  - Người lớn', '${widget.numberOfAdults}'),
                    if (widget.numberOfChildren > 0)
                      _buildInfoRow('  - Trẻ em', '${widget.numberOfChildren}'),
                    if (widget.numberOfInfants > 0)
                      _buildInfoRow('  - Em bé', '${widget.numberOfInfants}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Thông tin liên hệ
            _buildSectionTitle('Thông tin liên hệ'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Họ tên', widget.contactInfo.fullName),
                    _buildInfoRow('Email', widget.contactInfo.email),
                    _buildInfoRow('Số điện thoại', widget.contactInfo.phoneNumber),
                    if (widget.contactInfo.address != null)
                      _buildInfoRow('Địa chỉ', widget.contactInfo.address!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Giá
            _buildSectionTitle('Chi tiết giá'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildPriceRow('Tổng tiền', widget.totalAmount, widget.tour.currency),
                    if (widget.specialRequests != null) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Yêu cầu đặc biệt: ${widget.specialRequests}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Phương thức thanh toán
            _buildSectionTitle('Phương thức thanh toán'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  RadioListTile<PaymentMethod?>(
                    title: const Text('Chuyển khoản ngân hàng'),
                    subtitle: const Text('Thanh toán qua chuyển khoản'),
                    value: PaymentMethod.bankTransfer,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<PaymentMethod?>(
                    title: const Text('Tiền mặt'),
                    subtitle: const Text('Thanh toán khi nhận tour'),
                    value: PaymentMethod.cash,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Chính sách hủy
            if (widget.tour.cancellationPolicy.rules.isNotEmpty) ...[
              _buildSectionTitle('Chính sách hủy'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tour.cancellationPolicy.type,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.tour.cancellationPolicy.rules.map((rule) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${rule.description}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Lưu ý
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sau khi đặt tour, bạn sẽ nhận được email xác nhận. Vui lòng kiểm tra email và liên hệ với chúng tôi nếu có thắc mắc.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100), // Space cho bottom button
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng tiền:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,###').format(widget.totalAmount)} ${widget.tour.currency}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _isCreatingBooking ? null : _createBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: _isCreatingBooking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Xác nhận đặt tour',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, String currency) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${NumberFormat('#,###').format(amount)} $currency',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}

