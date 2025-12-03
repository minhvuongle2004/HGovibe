import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/tours/tour_booking.dart';
import '../../services/bookings/admin_booking_service.dart';
import '../../services/tours/admin_tour_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/page_header.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  final _bookingService = AdminBookingService.instance;
  final _tourService = AdminTourService.instance;
  final _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  late final TabController _tabController;
  final List<_BookingTab> _tabs = const [
    _BookingTab(label: 'Pending', status: BookingStatus.pending),
    _BookingTab(label: 'Confirmed', status: BookingStatus.confirmed),
    _BookingTab(label: 'Cancelled', status: BookingStatus.cancelled),
    _BookingTab(label: 'Completed', status: BookingStatus.completed),
  ];

  BookingStatus _selectedStatus = BookingStatus.pending;
  PaymentStatus? _paymentStatusFilter;
  DateTimeRange? _dateRange;

  final _searchController = TextEditingController();
  final _tourFilterController = TextEditingController();
  Timer? _searchDebounce;

  final List<TourBooking> _bookings = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  static const int _pageSize = 20;

  final Map<String, String> _tourTitleCache = {};

  Stream<int> get _pendingCountStream =>
      _bookingService.watchPendingCount();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final newStatus = _tabs[_tabController.index].status;
      if (newStatus != _selectedStatus) {
        setState(() => _selectedStatus = newStatus);
        _loadBookings(reset: true);
      }
    });
    _loadBookings(reset: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _tourFilterController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadBookings({bool reset = false}) async {
    if (_isLoading || _isLoadingMore) return;
    if (!_hasMore && !reset) return;

    setState(() {
      if (reset) {
        _isLoading = true;
        _bookings.clear();
        _lastDocument = null;
        _hasMore = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final result = await _bookingService.getBookings(
        status: _selectedStatus,
        paymentStatus: _paymentStatusFilter,
        searchQuery: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        tourId: _tourFilterController.text.trim().isEmpty
            ? null
            : _tourFilterController.text.trim(),
        limit: _pageSize,
        startAfter: reset ? null : _lastDocument,
      );

      setState(() {
        if (reset) {
          _bookings
            ..clear()
            ..addAll(result.bookings);
        } else {
          _bookings.addAll(result.bookings);
        }
        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
      });

      _preloadTourTitles(result.bookings);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải bookings: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _preloadTourTitles(List<TourBooking> bookings) async {
    final ids = bookings
        .map((b) => b.tourPackageId)
        .where((id) => id.isNotEmpty && !_tourTitleCache.containsKey(id))
        .toSet();
    if (ids.isEmpty) return;

    final Map<String, String> fetched = {};
    for (final id in ids) {
      try {
        final tour = await _tourService.getTourById(id);
        if (tour != null) {
          fetched[id] = tour.title;
        }
      } catch (_) {
        fetched[id] = id;
      }
    }

    if (fetched.isNotEmpty && mounted) {
      setState(() {
        _tourTitleCache.addAll(fetched);
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _loadBookings(reset: true);
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _loadBookings(reset: true);
    }
  }

  void _clearFilters() {
    setState(() {
      _paymentStatusFilter = null;
      _dateRange = null;
      _tourFilterController.clear();
    });
    _loadBookings(reset: true);
  }

  Future<void> _refresh() async {
    await _loadBookings(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
              title: 'Quản lý bookings',
              subtitle: 'Theo dõi, lọc và thao tác bookings theo trạng thái',
              actions: [
                Tooltip(
                  message: 'Tải lại',
                  child: IconButton(
                    onPressed: () => _loadBookings(reset: true),
                    icon: const Icon(Icons.refresh),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTabs(),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _buildTableSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: _tabs.map((tab) {
              if (tab.status == BookingStatus.pending) {
                return StreamBuilder<int>(
                  stream: _pendingCountStream,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tab.label),
                          if (count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              }
              return Tab(text: tab.label);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm theo mã booking, email, tên khách...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<PaymentStatus?>(
                value: _paymentStatusFilter,
                decoration: const InputDecoration(
                  labelText: 'Thanh toán',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: null,
                    child: Text('Tất cả'),
                  ),
                  DropdownMenuItem(
                    value: PaymentStatus.pending,
                    child: Text('Chờ thanh toán'),
                  ),
                  DropdownMenuItem(
                    value: PaymentStatus.paid,
                    child: Text('Đã thanh toán'),
                  ),
                  DropdownMenuItem(
                    value: PaymentStatus.refunded,
                    child: Text('Đã hoàn tiền'),
                  ),
                  DropdownMenuItem(
                    value: PaymentStatus.failed,
                    child: Text('Thất bại'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _paymentStatusFilter = value);
                  _loadBookings(reset: true);
                },
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _tourFilterController,
                decoration: InputDecoration(
                  labelText: 'Tour ID',
                  hintText: 'Nhập ID tour',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      if (_tourFilterController.text.isEmpty) return;
                      _tourFilterController.clear();
                      _loadBookings(reset: true);
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _loadBookings(reset: true),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(
                _dateRange == null
                    ? 'Khoảng ngày'
                    : '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}',
              ),
            ),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Xóa bộ lọc'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableSection() {
    if (_isLoading && _bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AdminEmptyState(
              icon: Icons.receipt_long,
              title: 'Chưa có booking nào',
              description:
                  'Thử thay đổi bộ lọc hoặc kiểm tra lại trạng thái để xem các booking phù hợp.',
              actionLabel: 'Tải lại',
              onAction: () => _loadBookings(reset: true),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    return _buildBookingRow(booking);
                  },
                ),
              ),
            ),
          ),
          if (_hasMore)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _isLoadingMore ? null : () => _loadBookings(),
                icon: _isLoadingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more),
                label: Text(_isLoadingMore ? 'Đang tải...' : 'Tải thêm'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingRow(TourBooking booking) {
    final participantCount = booking.numberOfAdults +
        booking.numberOfChildren +
        booking.numberOfInfants;
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(booking.bookingNumber)),
          SizedBox(
            width: 200,
            child: Text(
              _tourTitleCache[booking.tourPackageId] ??
                  booking.tourPackage?.title ??
                  booking.tourPackageId,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.contactInfo.fullName),
                Text(
                  booking.contactInfo.email,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(DateFormat('dd/MM/yyyy').format(booking.departureDate)),
          ),
          SizedBox(
            width: 80,
            child: Text('$participantCount người'),
          ),
          SizedBox(
            width: 120,
            child: Text(
              _currencyFormat.format(booking.totalAmount),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(width: 120, child: _buildStatusChip(booking.status)),
          SizedBox(
            width: 140,
            child: _buildPaymentChip(booking.paymentStatus),
          ),
          SizedBox(
            width: 140,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  if (booking.id == null) return;
                  context.push('/bookings/${booking.id}');
                },
                child: const Text('Xem chi tiết'),
              ),
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
}

class _BookingTab {
  final String label;
  final BookingStatus status;

  const _BookingTab({
    required this.label,
    required this.status,
  });
}

