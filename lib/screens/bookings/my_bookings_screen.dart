import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel_app/models/tours/tour_booking.dart';
import 'package:smart_travel_app/providers/tours/tour_booking_provider.dart';
import 'package:smart_travel_app/screens/tours/tour_detail_screen.dart';
import 'package:smart_travel_app/models/tours/tour_package.dart';
import 'package:smart_travel_app/services/tours/tour_package_service.dart';
import 'package:smart_travel_app/screens/reviews/review_form_screen.dart';

/// Screen hiển thị danh sách bookings của user
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TourPackageService _tourService = TourPackageService.instance;
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  BookingStatus? _selectedStatus;
  final Map<String, TourPackage?> _tourCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _updateSelectedStatus();
    // Delay load để tránh setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _updateSelectedStatus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadBookings();
      });
    }
  }

  void _updateSelectedStatus() {
    switch (_tabController.index) {
      case 0:
        _selectedStatus = null; // Sắp tới - sẽ lọc ở client-side
        break;
      case 1:
        _selectedStatus = BookingStatus.completed;
        break;
      case 2:
        _selectedStatus = BookingStatus.cancelled;
        break;
    }
  }

  List<TourBooking> _getFilteredBookings(List<TourBooking> allBookings) {
    if (_tabController.index == 0) {
      // Tab "Sắp tới": Lọc các booking chưa hoàn thành và chưa bị hủy
      // và ngày khởi hành chưa qua (hoặc trong hôm nay)
      final now = DateTime.now();
      // Convert to local date (không có giờ)
      final today = DateTime(now.year, now.month, now.day);
      
      print('🔍 Filtering bookings for "Sắp tới" tab');
      print('📅 Today: $today');
      print('📊 Total bookings: ${allBookings.length}');
      
      final filtered = allBookings.where((booking) {
        // Debug log
        print('  - Booking ${booking.bookingNumber}:');
        print('    Status: ${booking.status}');
        print('    DepartureDate (raw): ${booking.departureDate}');
        print('    DepartureDate (local): ${booking.departureDate.toLocal()}');
        
        // Chỉ lấy pending và confirmed
        if (booking.status != BookingStatus.pending && 
            booking.status != BookingStatus.confirmed) {
          print('    ❌ Filtered out: wrong status');
          return false;
        }
        
        // Convert departureDate to local time và chỉ lấy ngày
        final departureLocal = booking.departureDate.toLocal();
        final departureDay = DateTime(
          departureLocal.year,
          departureLocal.month,
          departureLocal.day,
        );
        
        print('    DepartureDay: $departureDay');
        print('    Today: $today');
        
        final isAfterOrToday = departureDay.isAfter(today) || 
                                departureDay.isAtSameMomentAs(today);
        
        print('    ✅ Included: $isAfterOrToday');
        
        return isAfterOrToday;
      }).toList();
      
      print('✅ Filtered bookings: ${filtered.length}');
      return filtered;
    }
    return allBookings;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ No user logged in');
      return;
    }

    print('📥 Loading bookings for user: ${user.uid}');
    print('📑 Current tab index: ${_tabController.index}');
    print('🔖 Selected status: $_selectedStatus');

    final bookingProvider = context.read<TourBookingProvider>();
    
    // Tab "Sắp tới" cần load tất cả bookings (không filter status)
    // để có thể filter ở client-side theo departureDate
    if (_tabController.index == 0) {
      // Load tất cả bookings không filter status
      print('📥 Loading all bookings (no status filter)');
      await bookingProvider.loadUserBookings(user.uid, status: null);
    } else {
      // Các tab khác filter theo status
      print('📥 Loading bookings with status: $_selectedStatus');
      await bookingProvider.loadUserBookings(
        user.uid,
        status: _selectedStatus,
      );
    }

    print('✅ Loaded ${bookingProvider.bookings.length} bookings');

    // Preload tour info
    for (final booking in bookingProvider.bookings) {
      if (!_tourCache.containsKey(booking.tourPackageId)) {
        try {
          final tour = await _tourService.getTourPackageById(booking.tourPackageId);
          _tourCache[booking.tourPackageId] = tour;
        } catch (_) {
          _tourCache[booking.tourPackageId] = null;
        }
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _cancelBooking(TourBooking booking, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy booking'),
        content: Text(
          'Bạn có chắc chắn muốn hủy booking "${booking.bookingNumber}"? '
          'Vui lòng kiểm tra chính sách hủy tour trước khi xác nhận.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hủy booking'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final bookingProvider = context.read<TourBookingProvider>();
      await bookingProvider.updateBookingStatus(
        booking.id!,
        BookingStatus.cancelled,
        cancelledAt: DateTime.now(),
        cancellationReason: 'Người dùng tự hủy',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy booking thành công')),
        );
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi hủy booking: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<TourBookingProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt tour của tôi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sắp tới'),
            Tab(text: 'Đã hoàn thành'),
            Tab(text: 'Đã hủy'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        child: Builder(
          builder: (context) {
            if (bookingProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final filteredBookings = _getFilteredBookings(bookingProvider.bookings);
            
            if (filteredBookings.isEmpty) {
              return _buildEmptyState();
            }
            
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredBookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = filteredBookings[index];
                return _buildBookingCard(booking, context);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String description;
    IconData icon;

    switch (_tabController.index) {
      case 0:
        title = 'Chưa có tour sắp tới';
        description = 'Bạn chưa có tour nào sắp khởi hành. Hãy đặt tour ngay!';
        icon = Icons.calendar_today;
        break;
      case 1:
        title = 'Chưa có tour hoàn thành';
        description = 'Bạn chưa hoàn thành tour nào.';
        icon = Icons.check_circle_outline;
        break;
      case 2:
        title = 'Chưa có tour bị hủy';
        description = 'Bạn chưa hủy tour nào.';
        icon = Icons.cancel_outlined;
        break;
      default:
        title = 'Chưa có booking';
        description = 'Bạn chưa đặt tour nào.';
        icon = Icons.receipt_long;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(TourBooking booking, BuildContext context) {
    final tour = _tourCache[booking.tourPackageId];
    final participantCount = booking.numberOfAdults +
        booking.numberOfChildren +
        booking.numberOfInfants;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to booking detail (sẽ implement sau)
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Booking number & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.bookingNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(booking.status),
                ],
              ),
              const SizedBox(height: 12),

              // Tour info
              if (tour != null) ...[
                Text(
                  tour.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tour.destination,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Text(
                  'Tour ID: ${booking.tourPackageId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Booking details
              _buildInfoRow(
                Icons.calendar_today,
                'Ngày khởi hành',
                _dateFormat.format(booking.departureDate),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.people,
                'Số người',
                '$participantCount người (${booking.numberOfAdults} người lớn${booking.numberOfChildren > 0 ? ', ${booking.numberOfChildren} trẻ em' : ''}${booking.numberOfInfants > 0 ? ', ${booking.numberOfInfants} em bé' : ''})',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.payment,
                'Tổng tiền',
                _currencyFormat.format(booking.totalAmount),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.info_outline,
                'Thanh toán',
                _getPaymentStatusText(booking.paymentStatus),
              ),
              const SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_canReview(booking))
                    OutlinedButton.icon(
                      onPressed: () => _openReviewScreen(context, booking, tour),
                      icon: const Icon(Icons.rate_review_outlined),
                      label: const Text('Viết đánh giá'),
                    ),
                  if (_canReview(booking)) const SizedBox(width: 8),
                  if (booking.status == BookingStatus.pending ||
                      booking.status == BookingStatus.confirmed)
                    TextButton.icon(
                      onPressed: () => _cancelBooking(booking, context),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Hủy booking'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (tour != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TourDetailScreen(tour: tour),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('Xem chi tiết'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canReview(TourBooking booking) {
    if (booking.id == null) return false;
    if (booking.paymentStatus != PaymentStatus.paid) return false;
    if (booking.status == BookingStatus.cancelled) return false;
    return true;
  }

  void _openReviewScreen(
    BuildContext context,
    TourBooking booking,
    TourPackage? tour,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || booking.id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewFormScreen(
          tourId: booking.tourPackageId,
          bookingId: booking.id!,
          userId: user.uid,
          tourTitle: tour?.title,
          onSubmitted: _loadBookings,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  String _getPaymentStatusText(PaymentStatus status) {
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
        return 'Lỗi thanh toán';
    }
  }
}

