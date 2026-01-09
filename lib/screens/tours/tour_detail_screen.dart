import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_travel_app/models/tours/tour_package.dart';
import 'package:smart_travel_app/providers/tours/tour_package_provider.dart';
import 'package:smart_travel_app/widgets/tours/tour_itinerary_widget.dart';
import 'package:smart_travel_app/widgets/tours/tour_inclusions_widget.dart';
import 'package:smart_travel_app/screens/tours/tour_booking_screen.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel_app/services/reviews/tour_review_service.dart';
import 'package:smart_travel_app/screens/reviews/review_list_section.dart';
import 'package:smart_travel_app/models/reviews/tour_review.dart';
import 'package:smart_travel_app/services/tours/tour_booking_service.dart';
import 'package:smart_travel_app/screens/reviews/review_form_screen.dart';
import 'package:smart_travel_app/models/tours/tour_booking.dart';

/// Screen chi tiết tour với tabs
class TourDetailScreen extends StatefulWidget {
  final TourPackage tour;

  const TourDetailScreen({
    super.key,
    required this.tour,
  });

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;
  List<TourReview> _reviews = [];
  bool _isLoadingReviews = true;
  bool _checkingEligibility = true;
  bool _canWriteReview = false;
  String? _eligibleBookingId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    // Tăng viewCount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TourPackageProvider>().incrementViewCount(widget.tour.id!);
      _loadReviews();
      _checkReviewEligibility();
    });
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final list = await TourReviewService.instance.getReviewsByTour(widget.tour.id!);
      if (!mounted) return;
      setState(() {
        _reviews = list;
        _isLoadingReviews = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingReviews = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải đánh giá: $e')),
      );
    }
  }

  Future<void> _checkReviewEligibility() async {
    setState(() {
      _checkingEligibility = true;
      _canWriteReview = false;
      _eligibleBookingId = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _checkingEligibility = false;
          _canWriteReview = false;
          _eligibleBookingId = null;
        });
        return;
      }

      final bookings = await TourBookingService.instance.getUserBookings(user.uid);
      // Điều kiện: booking thuộc tour này, paymentStatus == paid, không cancelled
      for (final b in bookings) {
        final isSameTour = b.tourPackageId == widget.tour.id;
        final paid = b.paymentStatus == PaymentStatus.paid;
        final notCancelled = b.status != BookingStatus.cancelled;
        if (isSameTour && paid && notCancelled && b.id != null) {
          final hasReview =
              await TourReviewService.instance.hasReviewForBooking(b.id!);
          if (!hasReview) {
            setState(() {
              _checkingEligibility = false;
              _canWriteReview = true;
              _eligibleBookingId = b.id;
            });
            return;
          }
        }
      }

      setState(() {
        _checkingEligibility = false;
        _canWriteReview = false;
        _eligibleBookingId = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkingEligibility = false;
        _canWriteReview = false;
        _eligibleBookingId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kiểm tra điều kiện đánh giá: $e')),
      );
    }
  }

  void _openWriteReview() {
    if (!_canWriteReview || _eligibleBookingId == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewFormScreen(
          tourId: widget.tour.id!,
          bookingId: _eligibleBookingId!,
          userId: user.uid,
          tourTitle: widget.tour.title,
          onSubmitted: () async {
            await _loadReviews();
            await _checkReviewEligibility();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  void _onBookTour() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TourBookingScreen(tour: widget.tour),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final priceText = '${formatter.format(widget.tour.basePrice)}₫';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar với image carousel
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _imagePageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: widget.tour.images.length,
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: widget.tour.images[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  // Image indicators
                  if (widget.tour.images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.tour.images.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentImageIndex == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tour info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.tour.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Location
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.tour.destination,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Rating & Reviews
                      Row(
                        children: [
                          const Icon(Icons.star, size: 20, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            widget.tour.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${widget.tour.reviewCount} đánh giá)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Tour details
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildDetailChip(
                            Icons.calendar_today,
                            '${widget.tour.durationDays}N${widget.tour.durationNights}Đ',
                          ),
                          _buildDetailChip(
                            Icons.people,
                            '${widget.tour.minGroupSize}-${widget.tour.maxGroupSize} người',
                          ),
                          _buildDetailChip(
                            Icons.language,
                            widget.tour.language ?? 'Tiếng Việt',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Tabs
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Tổng quan'),
                    Tab(text: 'Lịch trình'),
                    Tab(text: 'Bao gồm'),
                    Tab(text: 'Đánh giá'),
                    Tab(text: 'Chính sách'),
                  ],
                ),
              ],
            ),
          ),
          // Tab content - sử dụng SliverToBoxAdapter với height được tính động
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Tính height cho TabBarView
                final screenHeight = MediaQuery.of(context).size.height;
                final statusBarHeight = MediaQuery.of(context).padding.top;
                final appBarHeight = kToolbarHeight;
                final bottomBarHeight = 100.0; // approximate bottom bar height
                final tourInfoHeight = 249.0; // tour info + TabBar height
                final availableHeight = screenHeight - 
                    statusBarHeight - 
                    appBarHeight - 
                    bottomBarHeight - 
                    tourInfoHeight;
                
                return SizedBox(
                  height: availableHeight > 0 ? availableHeight : 400,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      TourItineraryWidget(itinerary: widget.tour.itinerary),
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: TourInclusionsWidget(
                          inclusions: widget.tour.inclusions,
                          exclusions: widget.tour.exclusions,
                        ),
                      ),
                      _buildReviewsTab(),
                      _buildPolicyTab(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Sticky bottom bar
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
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Từ $priceText',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  Text(
                    '/ người',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _onBookTour,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Đặt tour ngay',
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
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.tour.description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Điểm nổi bật',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.tour.destinations.map((dest) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 20, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dest,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_isLoadingReviews) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          if (_checkingEligibility)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (_canWriteReview)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openWriteReview,
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text(
                  'Viết đánh giá',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _checkingEligibility
                    ? 'Đang kiểm tra điều kiện đánh giá...'
                    : 'Bạn cần có booking đã thanh toán của tour này để viết đánh giá.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          const SizedBox(height: 12),
          ReviewListSection(
            reviews: _reviews,
            onWriteReview: _canWriteReview ? _openWriteReview : null,
            onReload: () async {
              await _loadReviews();
              await _checkReviewEligibility();
            },
            tourId: widget.tour.id!,
          ),
          ],
      ),
    );
  }

  Widget _buildPolicyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chính sách hủy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Loại: ${widget.tour.cancellationPolicy.type}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          ...widget.tour.cancellationPolicy.rules.map((rule) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: Colors.orange[700],
                ),
                title: Text(rule.description),
                subtitle: Text(
                  'Hoàn ${rule.refundPercentage}% tiền',
                  style: TextStyle(
                    color: rule.refundPercentage > 0
                        ? Colors.green[700]
                        : Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
          if (widget.tour.cancellationPolicy.notes != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.tour.cancellationPolicy.notes!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (widget.tour.termsAndConditions != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Điều khoản và điều kiện',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.tour.termsAndConditions!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
