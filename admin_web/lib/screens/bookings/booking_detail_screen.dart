import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/tours/tour_booking.dart';
import '../../services/bookings/admin_booking_service.dart';
import '../../services/tours/admin_tour_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _bookingService = AdminBookingService.instance;
  final _tourService = AdminTourService.instance;
  final _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  TourBooking? _booking;
  String? _tourTitle;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      final booking = await _bookingService.getBookingById(widget.bookingId);
      if (booking == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy booking')),
          );
          Navigator.of(context).pop();
        }
        return;
      }
      String? tourTitle = booking.tourPackage?.title;
      if (tourTitle == null && booking.tourPackageId.isNotEmpty) {
        final tour = await _tourService.getTourById(booking.tourPackageId);
        tourTitle = tour?.title ?? booking.tourPackageId;
      }
      if (mounted) {
        setState(() {
          _booking = booking;
          _tourTitle = tourTitle;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải booking: $e')),
      );
    }
  }

  Future<void> _confirmBooking() async {
    if (_booking == null) return;
    bool markPaid = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận booking'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bạn có chắc muốn xác nhận booking này?'),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Đồng thời đánh dấu đã thanh toán'),
                  value: markPaid,
                  onChanged: (value) {
                    setState(() => markPaid = value ?? false);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _runAction(() async {
      await _bookingService.confirmBooking(
        widget.bookingId,
        markAsPaid: markPaid,
      );
      await _loadBooking();
    }, successMessage: 'Đã xác nhận booking');
  }

  Future<void> _cancelBooking() async {
    final reasonController = TextEditingController();
    bool markRefunded = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy booking'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Lý do hủy *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    hintText: 'Nhập lý do hủy...',
                  ),
                  maxLines: 3,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Đánh dấu đã hoàn tiền'),
                  value: markRefunded,
                  onChanged: (value) {
                    setState(() => markRefunded = value ?? false);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do hủy')),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _runAction(() async {
      await _bookingService.cancelBooking(
        widget.bookingId,
        reason: reasonController.text.trim(),
        markRefunded: markRefunded,
      );
      await _loadBooking();
    }, successMessage: 'Đã hủy booking');
  }

  Future<void> _completeBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn thành booking'),
        content: const Text('Đánh dấu booking này là đã hoàn thành?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _runAction(() async {
      await _bookingService.completeBooking(widget.bookingId);
      await _loadBooking();
    }, successMessage: 'Đã cập nhật booking');
  }

  Future<void> _addAdminNote() async {
    final noteController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm ghi chú'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Nhập ghi chú nội bộ...',
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              if (noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập nội dung')),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('Lưu ghi chú'),
          ),
        ],
      ),
    );
    if (saved != true) return;

    await _runAction(() async {
      await _bookingService.addAdminNote(
        widget.bookingId,
        note: BookingAdminNote(content: noteController.text.trim()),
      );
      await _loadBooking();
    }, successMessage: 'Đã thêm ghi chú');
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    setState(() => _isProcessing = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thao tác thất bại: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết booking'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
              ? const Center(child: Text('Không tìm thấy booking'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final booking = _booking!;
    final totalPeople = booking.numberOfAdults +
        booking.numberOfChildren +
        booking.numberOfInfants;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummary(booking),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildInfoCard(
                title: 'Thông tin tour',
                children: [
                  _infoRow('Mã booking', booking.bookingNumber),
                  _infoRow('Tour', _tourTitle ?? booking.tourPackageId),
                  _infoRow(
                    'Ngày đặt',
                    DateFormat('dd/MM/yyyy HH:mm').format(booking.bookingDate),
                  ),
                  _infoRow(
                    'Ngày khởi hành',
                    DateFormat('dd/MM/yyyy').format(booking.departureDate),
                  ),
                  _infoRow('Số khách', '$totalPeople người'),
                ],
              ),
              _buildInfoCard(
                title: 'Thông tin liên hệ',
                children: [
                  _infoRow('Họ tên', booking.contactInfo.fullName),
                  _infoRow('Email', booking.contactInfo.email),
                  _infoRow('SĐT', booking.contactInfo.phoneNumber),
                  if (booking.contactInfo.address != null)
                    _infoRow('Địa chỉ', booking.contactInfo.address!),
                  if (booking.specialRequests != null &&
                      booking.specialRequests!.isNotEmpty)
                    _infoRow('Yêu cầu đặc biệt', booking.specialRequests!),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildParticipants(booking),
          const SizedBox(height: 16),
          _buildPricing(booking),
          const SizedBox(height: 16),
          _buildTimeline(booking),
          const SizedBox(height: 16),
          _buildAdminNotes(booking),
          const SizedBox(height: 24),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildSummary(TourBooking booking) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trạng thái hiện tại',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatusChip(booking.status),
                      const SizedBox(width: 12),
                      _buildPaymentChip(booking.paymentStatus),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Tổng tiền', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  _currencyFormat.format(booking.totalAmount),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return SizedBox(
      width: 360,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipants(TourBooking booking) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danh sách khách tham gia',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (booking.participants.isEmpty)
              const Text('Chưa có thông tin người tham gia')
            else
              Column(
                children: List.generate(
                  booking.participants.length,
                  (index) {
                    final participant = booking.participants[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  participant.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      'Sinh: ${participant.dateOfBirth != null ? DateFormat('dd/MM/yyyy').format(participant.dateOfBirth!) : '-'}',
                                    ),
                                    if (participant.gender != null &&
                                        participant.gender!.isNotEmpty)
                                      Text('Giới tính: ${participant.gender}'),
                                    if (participant.nationality != null &&
                                        participant.nationality!.isNotEmpty)
                                      Text('Quốc tịch: ${participant.nationality}'),
                                    if (participant.passportNumber != null &&
                                        participant.passportNumber!.isNotEmpty)
                                      Text('Hộ chiếu: ${participant.passportNumber}'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricing(TourBooking booking) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thanh toán',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _infoRow('Tạm tính', _currencyFormat.format(booking.subtotal)),
            if (booking.discountAmount != null)
              _infoRow(
                'Giảm giá',
                '-${_currencyFormat.format(booking.discountAmount)}',
              ),
            _infoRow(
              'Tổng cộng',
              _currencyFormat.format(booking.totalAmount),
              valueStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Divider(height: 24),
            _infoRow('Trạng thái thanh toán', _paymentLabel(booking.paymentStatus)),
            if (booking.paymentMethod != null)
              _infoRow('Phương thức', _paymentMethodLabel(booking.paymentMethod!)),
            if (booking.paymentAt != null)
              _infoRow(
                'Thanh toán lúc',
                DateFormat('dd/MM/yyyy HH:mm').format(booking.paymentAt!),
              ),
            if (booking.paymentTransactionId != null)
              _infoRow('Mã giao dịch', booking.paymentTransactionId!),
            if (booking.paymentRequestId != null)
              _infoRow('Request ID', booking.paymentRequestId!),
            if (booking.paymentGatewayRawData != null &&
                booking.paymentGatewayRawData!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildGatewayPayload(
                  booking.paymentGatewayRawData!,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(TourBooking booking) {
    final steps = <_TimelineStep>[
      _TimelineStep(
        label: 'Tạo booking',
        time: booking.bookingDate,
        description: 'Booking được tạo bởi người dùng',
        completed: true,
      ),
      _TimelineStep(
        label: 'Xác nhận',
        time: booking.confirmedAt,
        description: 'Admin xác nhận booking',
        completed: booking.confirmedAt != null,
      ),
      _TimelineStep(
        label: 'Thanh toán',
        time: booking.paymentAt,
        description: 'Khách hàng thanh toán',
        completed: booking.paymentStatus == PaymentStatus.paid ||
            booking.paymentStatus == PaymentStatus.refunded,
      ),
      _TimelineStep(
        label: 'Hoàn thành / Hủy',
        time: booking.status == BookingStatus.cancelled
            ? booking.cancelledAt
            : (booking.status == BookingStatus.completed
                ? booking.confirmedAt
                : null),
        description: booking.status == BookingStatus.cancelled
            ? 'Booking đã bị hủy'
            : (booking.status == BookingStatus.completed
                ? 'Tour đã hoàn thành'
                : 'Đang xử lý'),
        completed: booking.status == BookingStatus.cancelled ||
            booking.status == BookingStatus.completed,
      ),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timeline',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Column(
              children: steps.map((step) => _TimelineTile(step: step)).toList(),
            ),
            if (booking.cancellationReason != null &&
                booking.cancellationReason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _infoRow('Lý do hủy', booking.cancellationReason!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminNotes(TourBooking booking) {
    final notes = booking.adminNotes;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ghi chú nội bộ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: _isProcessing ? null : _addAdminNote,
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('Thêm ghi chú'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (notes.isEmpty)
              const Text('Chưa có ghi chú nào')
            else
              Column(
                children: notes
                    .map(
                      (note) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.sticky_note_2_outlined),
                        title: Text(note.content),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(note.createdAt),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    final booking = _booking!;
    final canConfirm = booking.status == BookingStatus.pending;
    final canCancel = booking.status == BookingStatus.pending ||
        booking.status == BookingStatus.confirmed;
    final canComplete = booking.status == BookingStatus.confirmed;

    return Wrap(
      spacing: 12,
      children: [
        if (canConfirm)
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _confirmBooking,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Xác nhận booking'),
          ),
        if (canCancel)
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _cancelBooking,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Hủy booking'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        if (canComplete)
          TextButton.icon(
            onPressed: _isProcessing ? null : _completeBooking,
            icon: const Icon(Icons.flag_circle_outlined),
            label: const Text('Đánh dấu hoàn thành'),
          ),
      ],
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    Color color;
    String label;
    switch (status) {
      case BookingStatus.pending:
        color = Colors.orange;
        label = 'Chờ xác nhận';
        break;
      case BookingStatus.confirmed:
        color = Colors.green;
        label = 'Đã xác nhận';
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        label = 'Đã hủy';
        break;
      case BookingStatus.completed:
        color = Colors.blue;
        label = 'Hoàn thành';
        break;
    }
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildPaymentChip(PaymentStatus status) {
    Color color;
    String label;
    switch (status) {
      case PaymentStatus.unpaid:
        color = Colors.grey;
        label = 'Chưa thanh toán';
        break;
      case PaymentStatus.pending:
        color = Colors.orange;
        label = 'Chờ thanh toán';
        break;
      case PaymentStatus.paid:
        color = Colors.green;
        label = 'Đã thanh toán';
        break;
      case PaymentStatus.refunded:
        color = Colors.blueGrey;
        label = 'Đã hoàn tiền';
        break;
      case PaymentStatus.failed:
        color = Colors.red;
        label = 'Lỗi thanh toán';
        break;
    }
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }

  String _paymentLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.unpaid:
        return 'Chưa thanh toán';
      case PaymentStatus.pending:
        return 'Chờ thanh toán';
      case PaymentStatus.paid:
        return 'Đã thanh toán';
      case PaymentStatus.refunded:
        return 'Đã hoàn tiền';
      case PaymentStatus.failed:
        return 'Thanh toán thất bại';
    }
  }

  String _paymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Tiền mặt';
      case PaymentMethod.bankTransfer:
        return 'Chuyển khoản';
      case PaymentMethod.creditCard:
        return 'Thẻ tín dụng';
      case PaymentMethod.vnpay:
        return 'VNPay';
      case PaymentMethod.momo:
        return 'MoMo';
    }
  }

  Widget _buildGatewayPayload(Map<String, dynamic> payload) {
    final encoder = const JsonEncoder.withIndent('  ');
    final formatted = encoder.convert(payload);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      padding: const EdgeInsets.all(12),
      child: SelectableText(
        formatted,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _TimelineStep {
  final String label;
  final DateTime? time;
  final String description;
  final bool completed;

  const _TimelineStep({
    required this.label,
    required this.time,
    required this.description,
    required this.completed,
  });
}

class _TimelineTile extends StatelessWidget {
  final _TimelineStep step;

  const _TimelineTile({required this.step});

  @override
  Widget build(BuildContext context) {
    final color = step.completed ? Colors.green : Colors.grey;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 40,
              color: Colors.grey.shade300,
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              if (step.time != null)
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(step.time!),
                  style: const TextStyle(color: Colors.grey),
                ),
              Text(step.description),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

